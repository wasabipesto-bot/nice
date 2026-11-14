# CPU2 review: the skip walk over the CPU join's top certificates (`e0bf513e`)

Reviewer: independent (not involved in writing the change), 2026-11-14, on ivory, CPU only.
Reviewed: fork `exp/cpu-top-skip-squashed` = `e0bf513e` on upstream main `41b4b405` (same tree as
`exp/cpu-top-skip` head `d3630e30`: tree `48f8212b` for both). Worktrees: `.worktrees/review-cpu2`
(branch head, with two `#[path]` hook lines appended for my tests, not committed;
`review/review-hooks-branch.patch`) and `.worktrees/review-cpu2-main` (`41b4b405` + one hook line,
`review/review-hooks-main.patch`).

## Verdict

**Sound as far as I can tell.** I found no way for the change to skip a block whose certificate
passes, and no way for the carried state to be applied to another join, slice, field, base,
thread or an earlier partition. My re-derivation of the rule agrees with the author's; an
exact big-integer check of the run bound on about 9 million adversarial (block, position) pairs
placed at digit boundaries found the computed run never above the exact one (and equal to it in
75 % of cases, so the check is sharp); and main and the branch produce byte-identical tops,
survivors, checked counts and hits on fields and partition orders the author did not use
(details in "What I verified"). No fix is required before a PR. There is one resource finding
worth deciding on (memory per worker thread, M1), and a few low-severity items.

## Findings

### M1 (medium, resources, not results): the per-thread `next` array and the retained scratch

`common/src/cpu_join.rs:152-159` (`Scratch::next: Vec<u16>`, one entry per top-layer prefix of the
slice) together with `client/src/main.rs:863-871` (one `Scratch` per worker thread, in a
`thread_local!`, for the life of the process).

- Every worker thread now holds `2 · tlay.len()` bytes for the slice it runs. The production
  slices the author profiled have 4.3–5.4 M top-layer prefixes (`raw/profile_b6{0,2}.txt`,
  "prefixes"), i.e. **≈ 9–11 MB per thread**; the slice cap `CPU_SLICE_PREFIXES = 2^24` allows
  32 MiB. At 64 threads that is ≈ 0.7 GB (cap: 2 GiB), at 128 threads ≈ 1.4 GB (cap: 4 GiB), on
  top of main's memory; for comparison the shared top layer itself is ≈ 32 B a prefix, ≈ 170 MB
  for 5.4 M prefixes, and main's docs budget it at 0.5 GiB.
- The thread-local scratch (all its buffers, not only `next`) is never freed: after a CPU-join
  field it stays allocated through later stride-walk fields and for the life of the client
  (`clear(); resize(..)` keeps the capacity). With `map_init` the scratches were dropped when the
  field ended.

Not a correctness issue. Suggested: state the per-thread cost in the PR body and the module doc;
free the thread-locals when a field ends (e.g. `rayon::broadcast(|_| JOIN_SCRATCH.take())`
after the slice loop), so the memory is held only while a join runs. The entry itself cannot
shrink much (it is an absolute partition number, up to 4096 in production). I did not measure the client's RSS (ivory allows
two threads).

### L1 (low, maintainability with a soundness edge): `run` re-derives the cube's `from`

`common/src/cpu_top_fd.rs:669-684` (`TopFdSetup::run`, the `failed == 0` branch) re-implements
`cert`'s computation of the first certified position (the carry walk past the run of `b − 1`
and the d/d+1 digit) for the cube, because `cert` returns before scanning it. Today the two
agree (I checked them line by line; `while pos >= z && digit(..) == top` equals `while at(pos)
== top` because `top != 0`). But the rule's soundness depends on `run` only pairing positions
that `cert` certifies: if one copy changes and the other does not, `run` could pair an
uncertified position and claim a run that is not one. Suggested: one helper `first_certified(x,
d, sp, z, bz) -> Option<u32>` used by both. `a_failing_run_fails_at_every_block` would catch a
divergence only statistically.

### L2 (low, tests): no test of the carried state across joins or out of order

The branch's tests run each join's partitions ascending (with or without gaps) on one
`next`, and one whole-join comparison of a carried against a fresh scratch, also ascending. The
reset paths (another join's id, `v <= last`, retries) and the `RUN_GAP` edge are not covered by
a test in the branch. My harness (`review/cmp_*.rs`) covers them (interleaved joins on shared
thread states, retries, steps back by one, gaps of 1–30, chunks out of order); something like it
belongs in the PR, since those paths are the ones the client's per-thread scratch now exercises.

### L3 (low, write-up): §5's "Final" table is not the final code

`CPU2/RESULTS.md` §5 heads the `raw/ab2-runs.txt` table "**Final**", but ab2 is `b86e4389`
(`new2`); the final code (`d3630e30` = the reviewed tree) is the §6 `raw/ab3` table. §0's headline
numbers (×1.132 / ×1.140 / ×1.009) are the ab3 ones and are right. Relabel the §5 table.

### Informational

- `vs = min(v, u16::MAX)` and the saturating `u16` entries are safe for any partition count: a
  saturated entry is still a lower bound, and at `v >= 65535` nothing is skipped (`65535 <
  65535` is false). Production uses `b^2 <= 4096` partitions.
- `TopFdSetup::try_new` now also returns `None` if `w` does not fit `u32` (`wf`); the join's
  `JoinParams::supported` already requires `b^f0 < 2^32`, so this cannot change a production
  join's route.
- `MAX_STEPS` 4 → 12 changes only whether `advance` steps or seeds; the stepped state equals a
  seeded one at every prefix (`stepped_certificates_equal_the_divided_ones` passes with 12, and
  my main-vs-branch comparison covers the join end to end).
- The client's per-thread scratch has no re-entrancy risk: `run_partition` makes no rayon calls
  (nothing in `common/` uses rayon), so a worker cannot steal another partition while holding the
  `RefCell` borrow; a panic inside releases the borrow and leaves only valid entries (each is
  written from a completed failing certificate).
- `bench.rs` (NiceMark) still uses `map_init` with a fresh scratch per job: it never carries
  state, so it measures main's walk plus `MAX_STEPS` (as the write-up says).

## The rule, re-derived

Independently of §2 of the write-up, from `Base::cert_parts` (`overlap_join.rs:826`) and
`TopFdSetup::cert`:

1. For power `j` the certificate reads `a^j`'s digits at positions `from_j .. s_j`, where `c0 =
   max(cap, ndig(e^j − a^j))` and `from_j = c0` if adding `e^j − a^j` to `a^j mod b^c0` does not
   carry out of `c0`, else the position after the first non-`(b−1)` digit at or above `c0`. In
   both cases `from_j = max(c0, h_j)`, `h_j` the lowest position from which `a^j` and `e^j`
   agree: without a carry they agree from `c0` up; with one, `e^j`'s digits from `c0` differ
   from `a^j`'s exactly on the run of `b − 1` (which become 0) and the digit above it (+1).
2. Suppose positions `(j, i)`, `(j', i')`, both `>= from`, hold equal digits. Let `X =
   ⌊a^j/b^i⌋`, so `X·b^i <= a^j <= e^j < (X+1)·b^i` (the last because `i >= h_j`). For any block
   `[a'', e'']` with `a'' >= a` and `e''^j < (X+1)·b^i`: `⌊a''^j/b^i⌋ = ⌊e''^j/b^i⌋ = X`, so (i)
   the digits from `i` up are `a^j`'s, (ii) `h''_j <= i`, (iii) `e''^j − a''^j < b^i`, so
   `ndig <= i`, and `cap <= c0 <= i`, so `c0'' <= i` (in particular `c0'' < s_j`: the power is
   not skipped). Hence `from''_j <= i`: position `i` is certified again with the same digit.
   With the same for `(j', i')`, the scan finds the repeat, or fails earlier: the block fails.
   Nothing about the closure, the `dom` digits, the scan order or clipping is used, and the
   block's `c0`/carry status may differ from the failing block's. I tried to break each step
   (a later block with a deeper `c0`, a carry that appears or disappears, `i < j·f0` where
   `a^j`'s digit is a structural 0, the two positions in the same power, the first/last
   partitions, `v + n` past the partition count) and found no counter-example; each is covered
   by the argument above.
3. In the join, partition `v + D` of top-layer prefix `p0` is block `P + D` (`P = p0·b^p + v`), so
   the run is "the smallest `D >= 1` with `(e + Dw)^j >= (X+1)·b^i`". The mean value bound
   `(e + Dw)^j − e^j <= j(e + Sw)^(j−1)·Dw` for `D <= S` gives every `D < q = G/(j(e + Sw)^(j−1)w)`
   (`G = (X+1)b^i − e^j`) failing; `n = min(S, ⌈q⌉)` (at least 1) covers `D = 0 .. n−1`, all `< q`
   and `<= S`. Taking the minimum over the pair's two positions is right; which pair is taken
   does not matter for soundness.
4. f64 (`run_of`): `(a^j mod b^i)/b^i` is bounded above by `(r+1)/b^m` from the top `m <= 4`
   digits (exact upper bound; 0 when `i <= j·f0`, correct since `b^(j·f0) | a^j`); `d_j` is exactly
   `e^j − a^j` (`advance`: `d2 = δ(2a+δ)`, `d3 = δ(3a²+3aδ+δ²)`), `w4_f64` truncates two words
   (relative error < 2^-51), and since `i >= c0`, `d_j/b^i < 1`. Every term of `g` is in [0, 1]
   with absolute error below ~2^-50, far below the absolute margin 2^-40, so `g < G/b^i`. `e`
   is overestimated (`(P + 1 + S)·w·(1 + 2^-40)`, the `u128 → f64` rounding is relative 2^-53),
   the quotient's remaining relative errors (a few 2^-53) are covered by `(1 − 2^-40)`, so the
   computed `n < q`, and `⌈n⌉ − 1 < n < q`. Casts: `n` is compared with `span` before `as u32`;
   `i`, `j` fit `u8` (positions < 48, `order` < 96 entries < 256); `seen`/`slot` index digits
   < 64; `b^i` for `i <= s_3` fits `W4` (`try_new`'s `fits`), and as f64 (< 2^260) has no range
   problem. The numbers' magnitude (to ~2^77 at b64, cubes to ~2^231) enters only through
   relative errors, which do not grow with magnitude.
5. Carried state (`cpu_join.rs:630-640`, `722`, `737`): an entry `next[x] = v₀ + n` written in
   partition `v₀` asserts "prefix `x`'s blocks in partitions `v₀ .. v₀+n−1` fail" — a fact about
   the join, not about the thread's history — so it may be used at any later partition `v > v₀`
   of the same join, however many partitions were skipped in between. The code uses it only when
   the scratch's last partition is of the same join (`id` from a process-wide `fetch_add`,
   unique per `CpuJoin::new`; `CpuJoin` is not `Clone`) and strictly below `v`, and every entry
   was written at a partition `<= last < v`. Any other case (first use, other join, `v <=
   last`: retry, step back, restart) clears every entry. Entries are indexed by the slice's
   top-layer index, fixed per join. Slices are separate joins (`process_field_join` builds one
   `CpuJoin` per slice), fields too, and a restarted client starts with fresh thread-locals.
   Clipped blocks never read or write an entry; prefixes out of the slice's `plo..phi` in a
   partition leave theirs alone. An overwrite in a partition with `runs` off writes `v + 1`,
   which is never below the entry it replaces (that entry was `<= v`, or the block would have
   been skipped). The `u16` saturation is a lower bound (see Informational).

## What I verified, and how

TBD

## What I could not verify

TBD
