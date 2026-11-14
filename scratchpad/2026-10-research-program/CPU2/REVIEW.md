# CPU2 review: the skip walk over the CPU join's top certificates (`e0bf513e`)

Reviewer: independent (not involved in writing the change), 2026-11-14, on ivory, CPU only.
Reviewed: fork `exp/cpu-top-skip-squashed` = `e0bf513e` on upstream main `41b4b405` (same tree as
`exp/cpu-top-skip` head `d3630e30`: tree `48f8212b` for both). Worktree `.worktrees/review-cpu2` (detached
at the branch head; clean again: my test modules were attached by `#[path]` hook lines,
`review/review-hooks-branch.patch`, reverted afterwards); a main worktree (`41b4b405` +
`review/review-hooks-main.patch`) and a mutant worktree, both removed. Nothing was pushed or
committed.

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

All runs `nice -n 19`, at most two threads, `CARGO_TARGET_DIR=~/projects/nice/target`, release,
CPU only (no GPU features). Code under `CPU2/review/`, outputs under `CPU2/review/out/`.

1. **The branch's own tests and the existing CPU-join tests** (`cargo test --release -p
   nice_common -- cpu_top_fd cpu_join`, `review/branch-tests.txt`): 22 passed, 5 ignored (opt-in),
   0 failed, including the three new tests and `stepped_certificates_equal_the_divided_ones` at
   `MAX_STEPS` 12. `cargo clippy -p nice_client -- -D warnings` clean.
2. **The run bound against exact arithmetic** (`review/exact_run_check.rs`, a child module of
   `cpu_top_fd` so it calls the private `run_of`; `out/exact-7-64.txt`, 3 min). Bases 7–64; per base
   the whole band plus 3 random sub-fields; every `f0` with `w < 2^32`, `o` 1–2, `cap = f0 + o`;
   `span` ∈ {1, b, b², 4096, 65535, 2^32−1}; 40 trials per setup, each a random certifiable position
   `(j, i)` and a random block, from which I compute with malachite the digit boundary `T = (⌊a^j/b^i⌋
   + 1)·b^i` and the last block `P*` whose `e^j < T`, then test the blocks `P*`, `P*+1`, `P*+2`,
   `P*−1..4`, `P* − 2^t (±1)` for t < 48 and `P* − k·span`, i.e. blocks whose `e^j` sits just
   below / at / above the boundary and at every scale of distance from it. For each I compare
   `run_of` with the exact run (the count of blocks `P, P+1, …` with `e^j < T`) and the exact
   "certified at `i`" (`i >= max(cap, ndig(e^j − a^j), h)` by big integers).
   **29.9 M evaluations, 8.97 M at certified positions: 0 above the exact run**, 6.74 M (75 %)
   exactly equal to it (capped at `span`); no evaluation at an uncertified position was above
   either. On the same blocks, `cert(.., true)` failed 7.37 M times (3.52 M runs > 64), and **657 M
   later blocks inside those runs re-certified by `Base::cert_parts`: all fail.**
3. **Main against the branch, end to end** (`review/cmp_common.rs` + `cmp_main.rs` /
   `cmp_branch.rs`, child modules of `cpu_join`). For every event, the partition's tops (count
   and a hash of their `Debug` form, in order: the branch's through `CpuJoin::tops` with the
   carried `next`, by a copy of `run`'s carry/reset rule; main's certifying every block) and
   `run_partition`'s survivors, checked count and hits with the simulated thread's own long-lived
   `Scratch` (the real `run`, on both). Schedules: rayon-like chunks of 1–24 partitions dealt to 3
   threads, chunks swapped out of order, retries of the same partition, steps back by one, gaps
   of 1–30 (crossing `RUN_GAP`), several joins (fields and slices) interleaved on the same thread
   states; then each join again ascending on a fresh thread. **Outputs byte-identical** (sha256 in
   `out/SHA256SUMS`):
   - small bases (`out/*-small.txt.xz`): b10–b34, 3 random fields per base (offsets and sizes
     50 k–3 M, not the author's start/middle/end), every supported `(t, k, p)` with `p` 0–2 and ≤ 2 M
     prefix-partitions: 567 joins, 276,077 partition events, 5.82 M tops; 204,885 events worked
     out runs, 2.03 M prefix entries were above their partition at entry (skip-eligible).
   - production shapes (`out/*-production.txt`): b44, b48, b52, b57–b64 at 0 %, 7.1 %, 83 % and
     the band's end, 1e14/1e15/1e16 fields (b44, b48 whole band, 2 slices at b48 and b52); 37
     fields, 3,132 partition events, 892 M tops, 26.1 G survivors, 1.43 G checked, 774 M
     skip-eligible entries; 17 of the fields have tops. Many of these fields have no tops (their
     field certificate fails), b62 among them, so:
   - fields hunted for tops (`out/*-hunt.txt`): 1e15 fields at b58, b60 (2), b62 (3), b63 (2),
     b64 (3) and **1e17 fields at b62 (`4409579838396751579500`) and b64
     (`39667873456105019795018`), first and last slice**, windows at the start, middle and end of
     each slice: 13 fields, 1,017 events, 340 M tops, 15.0 G survivors, 0.90 G checked, 470 M
     skip-eligible entries.
   No field had a hit (none expected); identity is carried by the tops hashes and the counts.
4. **The checks can see a bug** (mutation tests, mutants deleted afterwards): (a) the run
   inflated by 2^-10 relative (`run_of`'s `(1 − 2^-40)` → `(1 + 2^-10)`): my exact check reports
   violations at once (`out/mut-bound-exact.txt`, e.g. b22: run_of 21 > exact 20), and so does
   the author's `a_failing_run_fails_at_every_block` (`out/mut-bound-author-test.txt`); (b) the
   carried state allowed for a step back (`last < v` → `last != v`, in `run` and my copy): the
   small-base comparison differs from main on 3,056 lines (`out/mut-state-small.txt.xz`).
5. **The client change**: the only change is `map_init(Scratch::default, ..)` → a
   `thread_local!` `RefCell<Scratch>` borrowed around `run_partition`; partition distribution
   (`(0..parts).into_par_iter()`, the reduce, the progress tick) is unchanged. Re-entrancy,
   panics, multiple fields and slices, resumes: see the rule's step 5 and Informational.
6. **The write-up's numbers**: recomputed from `raw/ab3-runs.txt` and `raw/ab2-runs.txt`
   (`review/recompute_ab.py`, output `review/out/recompute_ab.txt`): ab3 b60 ×1.132 (min ×1.124,
   rounds 1.118–1.139), b62 ×1.140 (×1.139, 1.130–1.145), b64 ×1.009 (×1.008, 1.002–1.015); ab2
   ×1.127 / ×1.135 / ×1.005 — all as reported, counts identical in every run of both files.
   `tests-skip-full-v1.txt` matches §3 (334,914 / 142,224,583 / 4,096 / 127,054 / 52,075; 268
   shapes, 1,168,507 tops, 788,862 not certified). The squashed commit's tree equals `d3630e30`'s
   (`48f8212b`), so the `new3` timings are of the reviewed code. Only labelling issue: L3.

## What I could not verify

- **The speed-up at production thread counts.** The A/B is one thread over 12–32 contiguous
  partitions of one slice per base; the client's per-thread scratch at ≥ 8 threads is untimed
  (the author says so). Under rayon's splitting, a thread whose next partition is more than
  `RUN_GAP` = 8 above its last loses the run analysis, and one below it loses the state, so the
  gain at 64 threads could be noticeably below ×1.13; and memory (M1) is unmeasured.
- **Whole fields.** Neither the author nor I ran a whole production field through both; my
  comparison covers windows (start/middle/end of first and last slices) of 30 production-shape
  fields with tops and whole joins only at b10–b34.
- **Hits.** No compared field contains a nice number, so "hits identical" is vacuous here; the
  tops and survivor/checked identity is what carries the claim (a skipped passing top would
  change the tops hash).
- I did not re-time anything (the machine allows two threads; my comparisons ran beside other
  load), and did not run the GPU tests that use the CPU join as a reference.
- b35–b40 were left out of the exhaustive small-base sweep: at b35 one enumerated shape needs
  more memory than ivory has (the process was killed by the OOM killer); production shapes at
  b44+ were covered instead.
