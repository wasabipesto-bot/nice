# The middle-out join in Lean, step 1: notes (2026-11-22)

*Written on ivory; every build on the rented box (Vast 61919150) and in the fork's CI. Branch `lean/midout` on the
fork `wasabipesto-bot/nice`, from `dev/mo-clean` at `10ddbf17`, head `f25f988a`; worktree
`~/projects/nice/.worktrees/lean-midout`. Paths below are relative to that worktree. CI: see "Status" at the end.*

## What is on the branch

| path | what |
|---|---|
| `lean-midout/lakefile.toml`, `lake-manifest.json`, `lean-toolchain` | Lake project `NiceMidOut`; `require Nice` from `https://github.com/wasabipesto-bot/nice`, rev `4cdaa47fa12eed47cbc6728175ebc3c9ef856959`, `subDir = "proofs"` (Lake takes the subdirectory directly; no subtree copy was needed). Lean `v4.33.1`; Mathlib `0df444a3` (tag v4.33.1) and every other dependency pinned through the earlier library's own manifest (`inherited`): the same pins as #160. |
| `lean-midout/NiceMidOut/Coord.lean` (154 lines) | the coordinate, fields, shape, slices |
| `lean-midout/NiceMidOut/Join.lean` (277 lines) | the CPU reference: tops, bottoms, prefilter, the join of a slice (two forms), `searchField` |
| `lean-midout/NiceMidOut/CoordProofs.lean` (390 lines) | L1, proved |
| `lean-midout/Conformance.lean` (291 lines) | `lake exe conformance` |
| `lean-midout/scripts/check_axioms.sh`, `Axioms.lean` | `#print axioms` of every theorem of a `NiceMidOut` module (enumerated from the environment, not a hand list); fails on `sorryAx`, `ofReduceBool`/`ofReduceNat` or any axiom outside `propext`, `Classical.choice`, `Quot.sound` |
| `lean-midout/fixtures/{whole,b64,bases}.json`, `SHA256SUMS` | the Rust tables (3.6 MB) |
| `common/examples/midout_lean_fixtures.rs` (364 lines) | the fixture generator (a cargo example of `nice_common`, no new dependency) |
| `.github/workflows/lean-midout-temporary.yml` | temporary workflow, `push` to `lean/**` only (the repository's other workflows run on `main` only, so nothing else fires) |

Commits (ordinary, trailer `Co-Authored-By: Claude Fable 5.2`): `0a430349` fixtures + generator, `06a74362` model +
conformance + workflow, `0a52f49f` L1 + axiom check, `f25f988a` more fixtures (padding, deep-shape tops).

## The model, definition by definition (namespace `NiceMidOut`)

All executable and base-generic. Masks are `Finset ℕ`; `u128`/`U384` arithmetic and `mm` are exact ℕ (`r * r % m`),
so the Rust's `mm` split and `U384` are *not* modelled; they sit in the fixture link (the base-64 prefilter table
exercises `mm`'s large-modulus branch, `b^12 = 2^72`).

| Lean (file:line) | Rust (`common/src/midout/…`) | notes |
|---|---|---|
| `ceilRootC` (Coord:21), `baseRangeC` (:34) | `base_range.rs:14` `get_base_range_natural` | computable form of the earlier `NiceSearch.baseRange` (noncomputable, `Nat.find`); **refinement to prove: `baseRangeC = baseRange`** |
| `Coord` (:44), `L` (:56), `h0` (:59), `H` (:63) | `coord.rs:89`, `:199`, `:205`, `:206` | range carried as data |
| `Coord.Valid` (:68) | `with_digits` checks, `coord.rs:193–203` | the Prop the theorems assume (uses the earlier `baseRange`) |
| `Coord.withDigits` (:74) | `coord.rs:193` | executable; `none` for an error. Rust's `u128` overflow check not modelled |
| `vEnd` (:86), `vOfN` (:90), `nOfV` (:95), `quantum` (:105) | `coord.rs:230`, `:239`, `:256`, `:274` | literal |
| `fieldDigits` (:110), `fieldTs` (:116) | `coord.rs:283` | `none` where the Rust refuses |
| `Shape` (:124), `forCoord` (:132), `Fits` (:136), `slicesOf` (:145) | `cpu.rs:62`, `:75`, `:90`, `:105` | same list, same order |
| `roots` (Join:33) | `arith.rs:119` | **reuse: `NiceSearch.joinRoots`** |
| `finalCheck` (:37) | `arith.rs:92` `unique_digits(n,b).1` | **reuse: `decide (NiceSearch.IsNice b n)`** |
| `topCertSplit` (:45) | `cpu.rs:181` | **reuse: `NiceSearch.cert`, `certDigits`**; `mhi` = `certDigits` at cap `kmid` (certified positions are upward closed); unequal lengths certify nothing in both |
| `Top` (:49), `unitLeads` (:60), `unitTops` (:71) | `cpu.rs:445`, `:457–482` | `tops_tested = (unitLeads ..).length` |
| `botCertDirect` (:79) | `cpu.rs:261` | used pointwise in conformance |
| `bottomsSorted` (:86) | `bottoms`, `cpu.rs:292–404` | **reuse: `NiceSearch.botDfs`** (`pp = k − f`, fuel `k`, from `j = 0`) with its digit step `botDigits`; then sorted by `r` (the Rust's parents are sorted, `cpu.rs:529`). The Rust's incremental `r², r³ mod b^k` is not modelled (`botDigits` uses `r^2 / b^j`) |
| `Parent` (:90), `mkParent` (:103), `parents` (:108) | `cpu.rs:488`, `:513–527`, `:500` | `c2, c3` = `digit b (r^2) (k−1)` etc. (reuse `digit`) |
| `childMask` (:114) | `cpu.rs:536` | `none` for the Rust's zero mask |
| `midPrefilter` (:125) | `cpu.rs:232` | exemption `n < b^((k+3)/2)` = `div_ceil` |
| **`sliceSurvivors`** (:141) | `SliceSetup::class`, `cpu.rs:778–870` | **the definition for the theorems**: class c, unit d, probes (roots order, tops by lead), children of class-c parents in `r` order, disjoint ∧ in interval |
| `FieldOutcome` (:157), `fieldSlices` (:165), **`searchField`** (:171) | `cpu.rs:914`, `:952`, `:937` | `none` for an error; mask width `b ≤ M::BITS` not modelled; nice numbers sorted |
| `Counts` (:183), `digitFreq` (:203), `keyDigits` (:209), `chunkKey` (:214), `chunksOf` (:218), **`sliceRun`** (:232) | `cpu.rs:575`, `:727`, `:554`, `:740`, `:818–823`, `slice_join` `:624` | the run form: Rust order and all 12 counters; parents re-sorted stably by `(cls, 255 − key)`; the bit-sliced word replaced by its meaning (child in word ⟺ masks disjoint), the chunk skip by `common ∩ top.mask ≠ ∅`. `key_digits` compares `f64` products; the model compares exact ℕ (equal while products are below 2^53) |

**Two forms, one refinement to prove.** `sliceSurvivors` (the theorem target) and `sliceRun` (runs as the Rust). The
statement still to be proved: `(sliceRun b lo hi sh pip).surv` is a permutation of `(sliceSurvivors b lo hi sh pip)`
with each `mhi` replaced by `midPrefilter b sh.k n mhi`, and its counters' `survivors`/`checked` are the lengths.
Both forms are checked against the Rust on every small-base slice (the run form in order, the definition as a sorted
list). No faster form was needed to run the fixtures; a base-64 slice through the model (SCOPE §5(d)) would need
bitmask masks and was not attempted.

**Reused from the earlier library unchanged:** `digit`, `numDigits`, `IsNice`, `cert`, `certDigits`, `botDfs`,
`botDigits`, `joinRoots`, `mod_pow_div_pow` (used in the L1 proofs). The earlier `baseRange` is used in
`Coord.Valid` but cannot run; nothing of #160 was modified.

## Fixtures (`common/examples/midout_lean_fixtures.rs`)

Run: `cargo run --release -p nice_common --example midout_lean_fixtures -- lean-midout/fixtures` (≈30 s on the box,
1m23s on a runner including the build). Fixed xorshift seeds; two runs on the box gave identical SHA-256; CI's second
job regenerates them from the branch's Rust and checks the committed `SHA256SUMS` (so the tables are the code's, not
hand-edited).

- `whole.json` (1.7 MB): the 11 small bases and 17 (base, shape) pairs of `check_whole_base` (`cpu.rs:1121–1165`):
  every slice of every field, 9,411 slices with their `(t, pip)`, all 12 counters, and every survivor `(d, n, pass)`
  in the reference's order, 20,058 survivors in all (base 25: 13,947); `search_field` (one thread) on the whole base
  and on the first field; `n_of_v` of every `v` of the coordinate where it has ≤ 20,000 values (padding included).
- `bases.json` (11 kB): `roots(b)` and the exact closed-form range (`get_base_range_natural`) for every base 3–128.
- `b64.json` (2.1 MB): for coordinates (64; 4,8,5), (64; 4,9,6), (65; 4,8,5): the derived values, 500 `v_of_n`, 700
  `n_of_v` (200 in the first and last `h`, where base 65 pads), 9 fields (5 accepted incl. the whole coordinate, 4
  refused), 2 slice lists of 4,096/4,225; 3,000 `top_cert_split` on random intervals of widths 0…2^60, caps 6–14,
  splits 0/2/5 above (726 certified); one unit of (4,10) (32,768 leads, 3,733 tops); 300 units of a deep (4,16) shape
  (39 tops, where the split at k+2 matters); whole parent lists of (2,5) at three pips and (1,4) (2,233/2,233/2,212/41
  parents) with 1,600 sampled child masks; for two real (4,10) slices (1,044,653 and 1,041,389 parents): first, last,
  300 sampled parents with a child mask each, 300 random residues of the slice with their membership; 4,000 prefilter
  verdicts at k = 10 (2,000 random n and mhi as the Rust test does, 2,000 built from certified bottoms with their
  top's real mhi; 125 pass).

The (4,10) parent samples are checked pointwise (`parentAt` in `Conformance.lean`: digits `[f0, k−1)` = pip and
`botCertDirect` at depth k−1), not against the walk: a base-64 slice's walk is 16.7 M leaves. **Lemma for step 2
(L5):** membership in `bottomsSorted` ⟺ that pointwise predicate.

## Conformance result

`lake exe conformance` on the box: **81,484 checks, all equal to the Rust tables** (first version 41,993, before the
padding and deep-shape tables), 1m49s. It stops at the first difference and prints the place (e.g. `MISMATCH at
whole b25 (2, 4, 3) shape (2, 5) slice 0 survivors (in order): entry 1: model …, Rust …` when two survivors of the
fixture were swapped by hand to test it).

**Model mutants** (the model changed, the fixtures not; on the box, not committed): caught — the prefilter exemption
`⌈(k+2)/2⌉ → ⌊(k+2)/2⌋` (the Rust-side M21, which survives every Rust test, here caught at base 13: the counter
`checked` differs), no `e2 ≠ e3` in `child_mask`, the prefilter without `mhi`, a strict top interval, `key_digits` ties
reversed (order of survivors at base 20). **Not caught by the first fixtures: `mhi` from position k+1 (the Rust-side
M04)** — no tested top certifies position k+1 at those bases or at base 64's (4,10); the deep (4,16) table was added
for it and now catches it (`unit_tops` differs). The lesson for later steps: a fixture only catches what its inputs
reach; L4(ii) and L8 are the real cover.

## Disagreements between the model and the Rust

**None.** Every table matched on the first run of the conformance executable. Things met on the way, none a finding
about the search:
- My errors only: a `flatMap` argument order (Lean), `omega` and nonlinear atoms (`n % b^k0` lost its sign; fixed by
  `generalize`), an `unfold` order.
- The fixture generator first panicked: `get_base_range_u128(3)` panics (`FieldSize::new` asserts `start < end`; the
  closed form gives `[2, 2)` at base 3), so `Coord::with_digits(3, …)` panics where its doc promises an error. No field
  exists at base 3; the generator uses `get_base_range_natural` instead; the model returns `none`.
- One transient `github.com` connection failure on the box during `lake update` (retried).

## What is proved (L1), no `sorry`, no added axiom, no `native_decide`

`lean-midout/NiceMidOut/CoordProofs.lean`, checked by `scripts/check_axioms.sh` (48 theorems, standard axioms only):
- `Coord.nOfV_vOfN` — on `[lo, hi)`, `nOfV (vOfN n) = some n` (k0 ≤ k1, b > 0); `vOfN_injective`; `lo_le_vOfN`,
  `vOfN_lt_vEnd`: v is a bijection from the range onto its image inside `[lo, vEnd)`.
- `vOfN_div_quantum` — L1(a): `(v(n) − lo) / Q = n / b^q0 mod b^(k1−q0)`.
- `mem_field_iff`, `vOfN_mem_field_iff` — L1(b): for `fieldDigits vs vz = some (t0, t1)`, `vs ≤ v(n) < vs + vz` ⟺
  `t0 ≤ digits_[q0,k1)(n) < t1`; `fieldDigits_le` (t1 ≤ b^(k1−q0)), `fieldDigits_whole` (the whole coordinate is the
  field `(0, b^(k1−q0))`).
- `Shape.mem_slicesOf_iff`, `slicesOf_nodup`, `slice_digits`, `slice_mem_slicesOf` — L1(c): the slices of t are
  exactly the pips below `b^(k−1−f0)` whose digits `[q0, k1)` are t, without repeats.
- `Coord.mem_fieldSlices_iff` — a field is a whole number of slices: for n of the range, n's slice
  `n / b^f0 mod b^(k−1−f0)` is in `fieldSlices` ⟺ v(n) is in the field.
- `vOfN_mem_quantum_iff`, `existsUnique_quantum`, `field_disjoint` — L1(d): every n lies in exactly one quantum, fields
  with disjoint digit ranges share no n.

Hypotheses are the minimal digit-position ones (`0 < b`, `k0 ≤ q0 ≤ k1`, `f0 ≤ q0 < k1 < k`, `lo ≤ n < hi`), not
`Coord.Valid`, so they hold for any range. **What is model, tested, proved:** every definition above is *model*; all
of them are *tested* against the Rust on the tables above; only the L1 statements are *proved*, and they are about the
model's `vOfN`, `nOfV`, `fieldDigits`, `slicesOf`, `fieldSlices`, not about the Rust.

## Build times

- Box (96 visible threads, CPU quota ≈ 23): elan + Lean + Rust 1.100 install ≈ 6 min; `lake update` (clones of the fork
  and Mathlib) + `lake exe cache get` (8,690 files) ≈ 12 min incl. one retry; first `lake build` of `Nice` (the earlier
  library from source) + the model ≈ 1 min; `lake build conformance` (C compilation of every imported module) 1m52s;
  conformance run 1m49s; rebuild after a proof edit ≈ 10 s.
- CI (`f25f988a`, run 44994398962, 11 min): fixture regeneration job 1m12s; Lean job: cache + `lake build --wfail` 1m39s, conformance 8m41s (of which about 7 min compiling the executable's imported modules on a 4-core runner, 70 s running), axioms 32 s.

## What step 2 should start with

1. Fix the two refinements the model already names, before any join lemma, because every later theorem leans on them:
   `baseRangeC = baseRange` (via `ceilRootC = ceilRoot`, bisection invariant) and the pointwise characterisation of
   `bottomsSorted`/`parents` (L5(a)): `q ∈ bottomsSorted b k f v ⟺ q.1 < b^k ∧ q.1 / b^f = v ∧ botCertDirect b q.1 k
   = some q.2` (from `mem_botDfs_of_isNice`'s induction, both directions), plus `Nodup`/`Sorted`.
2. Then L2, L3, L9 (mostly reuse) and L4: `topCertSplit` = `cert` pair, `mhi ⊆ mask` at positions ≥ k+2, and
   `unitTops` lists every nice n's top (template `mem_topLayer_of_isNice`).
3. Keep `sliceRun ≈ sliceSurvivors` (the permutation statement above) as a separate item; it is the L7 chunk refinement
   at set level, needed only for the claim that the *run* (and so the Rust's counters) is the theorem's object.
4. Before each lemma, add the fixture that would catch its mutant (the M04 lesson): e.g. small-base shapes where the
   prefilter is not exempt and tops certify position k+1.

## Status

Head `f25f988a` on `fork/lean/midout`, green: https://github.com/wasabipesto-bot/nice/actions/runs/44994398962
(earlier green run on `06a74362`: https://github.com/wasabipesto-bot/nice/actions/runs/44992831227; the run on
`0a52f49f` was cancelled by the next push). Box left idle; no pull request, nothing pushed to `origin`.

## After step 1 (2026-11-22, 06:50–07:50 UTC)

### A. One model: tested = proved-about (`lean/midout`, head `4934b0ca`)

Green CI on the head: https://github.com/wasabipesto-bot/nice/actions/runs/44996514840 (8m07s; conformance 81,484
checks equal; axiom check 83 theorems, standard axioms only). Commits: `5fd938de` (range), `951abecb` (run form as
functions), `4934b0ca` (refinement). No `sorry` anywhere in the tree.

1. **`baseRangeC = baseRange`** — proved (`NiceMidOut/RangeProofs.lean`): `ceilRootC_go_eq` (bisection invariant
   `lo^e < x ≤ hi^e`, `hi − lo ≤ 2^fuel` ⇒ the result is `ceilRoot e x`, via the earlier library's `le_ceilRoot_iff`),
   `ceilRootC_eq` (for `e ≠ 0`, every x; the initial fuel `log2 x + 2` suffices by `Nat.lt_log2_self`),
   `baseRangeC_eq` (all b), and `Coord.valid_of_withDigits` (a coordinate the executable constructor accepts satisfies
   `Coord.Valid`, the theorems' hypothesis).
2. **`sliceRun` against `sliceSurvivors`** — proved (`NiceMidOut/RunProofs.lean`), finished by 07:04, so nothing was cut.
   To make it provable, `sliceRun` was first rewritten from a loop with mutable state into list functions
   (`sliceSetup`, `probesOf`, `kidsOf`, `chunkCommon`, `pairSurv`, `probeSurv`, `probeCounts`, `unitRun`, `unitSurv`,
   `unitCounts`; `sliceSurvivors` now names the same `probesOf`/`kidsOf`, unchanged in meaning); the conformance
   tables were rerun on the new form: all 81,484 equal, so the tested model is this one.
   - `sliceRun_surv_perm`: `(sliceRun b lo hi sh pip).surv ~ (sliceSurvivors b lo hi sh pip).map (fun x => (x.1,
     x.2.1, midPrefilter b sh.k x.2.1 x.2.2))`, for every b, range, shape, pip (no hypotheses). Lemmas: the chunk skip
     loses nothing (`probeSurv_eq`, from `chunkCommon_subset`: the common mask lies in every child's), the chunks
     concatenate to the children (`chunksOf_flatten`), the key order is a permutation of `r` order (`mergeSort_perm`),
     nested `flatMap`s commute up to permutation (`flatMap_comm_perm`), the setup's tops are `unitTops` per unit.
   - **Counters, exactly:** proved — `survivors` = the survivor list's length (`sliceRun_survivors`), `checked` = the
     number of reported survivors with `pass` (`sliceRun_checked`), `parents` = `(parents b sh pip).length`
     (`sliceRun_parents`). `tops_tested` and `tops` are by definition the sums of `unitLeads`/`unitTops` lengths (no
     separate theorem). **Not proved, tested only** (against the Rust on all 9,411 small-base slices): `children`,
     `chunks`, `pairs`, `flat`, `kept`, `words`, `clipped` — they describe the work, depend on the chunk order, and no
     theorem is about them. Not proved either: that `survivors` equals the brute-force predicate count (L11).
   - Still model-to-Rust only by fixtures: the bit-sliced word (`cpu.rs:826–849`) is modelled by its meaning, and the
     `f64` products of `key_digits` by exact ℕ.

### B. Two Rust tests on `dev/mo-clean` (head `eb9ef776`, one commit on `10ddbf17`)

In `common/src/midout/cpu.rs`'s test module, no fixture file, expected values recomputed in the test:
- `deep_shape_tops_equal_their_definition`: 3,000 random units of the shape (4, 16) at base 64 through `unit_tops`,
  against the certificate's definition from the interval's two ends (position i certified ⟺ both ends' powers have
  the same length and agree at every position ≥ i; repeats counted afterwards; `mhi` = positions ≥ k + 2). 358 tops,
  200 of them certify position k + 1 (asserted > 100 and > 10).
- `prefilter_exemption_boundary_equals_full_digits`: bases 10, 13, 17, 24, 40, 64, every k = 1..12 with b^(k+2) < 2^96,
  n in b^j ± 40 (j counted: least with 2j ≥ k + 2), mhi empty, full, random: below b^j the prefilter must pass, from
  b^j on the verdict must equal the rule on the full digits of n², n³ (their length ≥ k + 2 is asserted). 8,640
  exempt, 141 pass and 8,715 fail by the rule (asserted > 1000, > 50, > 1000).

**Kill evidence** (box, scratch copy `/work/mutsrc`, release, `cargo test -p nice_common --lib -- midout::`, 31 tests;
the mutations by text, since `CEIL/box/mut_list.sh`'s line numbers are for `c2152084`):

| mutant | edit | result |
|---|---|---|
| M21 (both sides) | `prefilter` and the test helper `prefilter_digits`: `(k + 2).div_ceil(2)` → `(k + 2) / 2` | **killed only by** `prefilter_exemption_boundary_equals_full_digits` (30 pass, 1 fail) |
| M04 (as listed) | `top_cert_split`: `if j >= kmid` → `if j + 1 >= kmid` | killed by the new test **and** by the existing `top_certificate_equals_its_definition` (as `CEIL/RESULTS.md` records: the list's M04 was already killed in Rust) |
| M04c (caller) | `unit_tops`: `top_cert_split(.., k, k + 2)` → `(.., k, k + 1)` (the form the Lean mutant took) | **killed only by** `deep_shape_tops_equal_their_definition` |

Unmutated: both pass. So the correction to my step-1 wording: the Rust's tests already catch M04 inside the scan; what
they missed was the same error at the caller, and the M21 exemption change.

**Timings and checks** (box, 23-CPU quota): the two new tests 0.04 s release, 0.13 s debug; the midout suite 13.5 s
release (31 tests), 53.2 s debug (52.97 s without the new tests: they add 0.2 s). `just lint` rc 0 (134 s, fmt +
clippy both feature sets, `-D warnings`; one pre-existing manifest warning about `web-sys` in `wasm-client`, not an
error). Production CI's test commands: `cargo test --locked --release --no-fail-fast` rc 0 (257 s; `libpq-dev`
installed on the box for it); `NICE_REQUIRE_NVRTC=1 cargo test --locked --release -p nice_common --features gpu --lib`
with NVRTC 12.9.86 from PyPI as CI fetches it: rc 0, 295 passed, 72 ignored (394 s). The file was edited on ivory
and synced; the committed `cpu.rs` is byte-identical (SHA-256) to the one tested on the box, so no bundle was needed.
Pushed `git push -u fork dev/mo-clean` (`10ddbf17..eb9ef776`); no pull request.

### C. The design map and `DESIGN.md` (on ivory)

`tools/check_refs.py interactive/midout-map.html` at `eb9ef776`: **88 refs, 0 bad** (the tests were inserted after
`cpu.rs:1339`; no map reference and no inline `DESIGN.md` reference points past it; `print_inline_refs.py` shows no
out-of-range line). Changed in the map only the head its references are checked against: the sub-title, the "Line
numbers are into" note, the refs comment and the `repoNote` string (`10ddbf17` → `eb9ef776`, 4 lines). `DESIGN.md`
unchanged: its head mention (line 4) says the text was *written* from `10ddbf17`, which stays true.

Now out of date in `DESIGN.md`:
- §7: "A mutation test of it (27 mutants) left 3 alive after three independent tests were added: two change only work
  counts, one edits an exemption no test base reaches" — M21 is now killed (by the boundary test); 2 survive (M17, M26,
  work counts only), after five independent tests; and the caller form of M04 is a new, now-killed mutant.
- §9 (line 598): the branch size "14,405 at `10ddbf17`" — now 14,578 insertions in 24 files against `origin/main`.
- §10: "head `10ddbf17`, 22 commits" — now `eb9ef776`, 23 commits on `66259bb0`; `cpu.rs` 1,460 lines → 1,628.
- Measurement rows naming `10ddbf17` (§8 line 570, the map's line 171) are about what was measured then and stay right.

### `lean/midout` and a moving `dev/mo-clean`

Nothing was merged between them; `lean/midout` stays on `10ddbf17`. To regenerate its fixtures for a new
`dev/mo-clean` head H: in a scratch worktree at H, copy (not merge) the generator, `git show
lean/midout:common/examples/midout_lean_fixtures.rs > common/examples/midout_lean_fixtures.rs`, run `cargo run
--release -p nice_common --example midout_lean_fixtures -- OUT` and compare `sha256sum OUT/*.json` with
`lean-midout/fixtures/SHA256SUMS`. Equal: the model still describes H (done today for H = `eb9ef776`: all three
tables byte-identical, as expected for a tests-only commit). Different: copy the tables onto `lean/midout` in an
ordinary commit and let its CI run conformance; a mismatch then means either a change in the Rust the model must
follow (edit the model, rerun) or a defect in the Rust (report it with the smallest input). The CI's own
"regenerate and compare" job only checks the branch's own `10ddbf17` code.
