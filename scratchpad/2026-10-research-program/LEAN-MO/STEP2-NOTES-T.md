# The middle-out join in Lean, step 2, half T (tops and the generic lemmas): notes (2026-11-23)

*Written on ivory; every build on the shared box (Vast 62104162, directory `/work/tops`, own elan in
`/work/tops/.elan`, builds pinned to cores 0–9 with `taskset`, since `lake` has no job-count flag). Branch
`lean/midout-tops` on the fork `wasabipesto-bot/nice`, from `lean/midout` at `4934b0ca`; worktree
`~/projects/nice/.worktrees/lean-tops`. Paths below relative to `lean-midout/`. CI: see "Status" at the end.*

## What is on the branch

Six new files, all under `NiceMidOut/`, and six import lines in `NiceMidOut.lean`. No shared file was touched
(`Coord`, `Join`, `CoordProofs`, `RangeProofs`, `RunProofs`, `Conformance`, fixtures, lakefile unchanged). No
`sorry`, no added axiom, no `native_decide`: `scripts/check_axioms.sh` passes on 138 theorems (83 before), standard
axioms only. No new fixture table (see "Fixtures").

| file | lemmas |
|---|---|
| `TopsProofs.lean` | L4 (i) characterisation, (ii), (iii) |
| `TopsScan.lean` | L4 (i): the Rust scan as a function, equal to `topCertSplit` |
| `ClassesProofs.lean` | L3, L6 |
| `ClassesTops.lean` | L4 + L6 packaged for L10; what a listed top's interval fixes |
| `RangeDigits.lean` | L2 |
| `CheckProofs.lean` | L9 |

Commits (ordinary, trailer `Co-Authored-By: Claude Fable 5.2`): `0de99640` (L4 core + L3/L6), `5c5a7cf1` (L2, L9),
`7bcfeea8` (scan), `dd608cf7` (packaged), `38a7d77f` (L6 converse).

## The lemmas (namespace `NiceMidOut`), each statement in words

### L4, the top certificate (`TopsProofs`, `TopsScan`)

- **(iii) `mem_unitTops_of_isNice`** (b ≥ 2, f0 ≤ k, lo ≤ n < hi, `IsNice b n`): `unitTops b lo hi f0 k
  (n / b^f0 mod b^(k−f0))` contains a top `t` with `t.h = n / b^k`, `t.lo = max (n / b^f0 · b^f0) lo`,
  `t.hi = min (n / b^f0 · b^f0 + b^f0 − 1) (hi − 1)` (the prefix's interval clipped to the range), and
  `t.lo ≤ n ≤ t.hi`. **`mem_unitTops_slice_of_isNice`**: the same for f0 < k with the unit written as
  `sliceSurvivors` writes it, `pip + d·b^(k−1−f0)`, `pip = n / b^f0 mod b^(k−1−f0)`, `d = n / b^(k−1) mod b`
  (via **`unit_split`**). Helpers: `mem_unitLeads`, `mem_unitTops` (membership iff: the lead's clipped
  interval, `cert … k = some mask`, `mhi = (certDigits … (k+2)).toFinset`), `top_lead_unit`.
- **(ii) `topCertSplit_mhi`** (kpos ≤ kmid): when `topCertSplit` certifies `[a, c]` with `(m, mh)`, then
  `cert b a c kpos = some m`, `cert b a c kmid = some mh` (mhi is the certificate at cap kmid) and `mh ⊆ m`.
  **`highDigit_of_mem_unitTops`**: for `t ∈ unitTops …` and every n in `[t.lo, t.hi]`, every digit of
  `t.mask` is a digit of n² or n³ at a position ≥ k (`HighDigit b k n`), every digit of `t.mhi` one at a
  position ≥ k + 2, and `t.mhi ⊆ t.mask`. Helpers: `certPositions_sublist`, `certDigits_sublist`,
  `highDigit_of_mem_certDigits`.
- **(i) `certPositions_eq_nil_of_numDigits_ne`**: two numbers of unequal digit length certify no position.
  **`mem_certPositions_iff`**: i is certified ⟺ cap ≤ i < length of y and x, y agree digit by digit at every
  position ≥ i (via `div_pow_eq_iff_digits`: equal quotients by b^i ⟺ equal digits from i up).
  **`topCertScan_eq`** (b ≥ 2, kpos ≤ kmid): `topCertScan b a c kpos kmid = topCertSplit b a c kpos kmid`,
  where `topCertScan` (new, `TopsScan.lean`) mirrors `top_cert_split` (`cpu.rs:181–216`) step for step: square
  then cube; `Nat.digits` of both ends; a power with unequal lengths skipped; the walk from the top down to kpos,
  breaking at the first differing digit, failing on a digit already in the mask, adding positions ≥ kmid to
  `mhi`. Proof route: the walk = insertions over the list of passed positions (`scanLoop_eq`); insertions =
  "nodup and disjoint, then union" (`insLoop_eq`); passed positions are a permutation of `certPositions`
  (`mem_scanPos`, `scanPos_nodup`, `scanPos_perm`); one power at a time (`scanPow_eq`).

### L6, class compatibility (`ClassesProofs`)

- **`mem_probesOf_of_isNice`**: n = t.h·b^k + d·b^(k−1) + r nice, t ∈ tv ⟹ `t ∈ probesOf b tv (r mod (b−1)) d`
  (no hypothesis on k: b ≡ 1 mod b − 1 makes every power 1, `class_split`).
- **`count_probesOf_of_isNice`**: under the same hypotheses `(probesOf b tv (r mod (b−1)) d).count t =
  tv.count t`: exactly once per occurrence, since the roots are distinct (`roots_nodup`) and a top's class picks
  one root (`root_unique`).
- **`mem_probesOf_iff`** (the probe list as a set) and the converse **`mod_mem_roots_of_mem_probesOf`**: every
  n = t.h·b^k + d·b^(k−1) + r made from a probe of class r mod (b−1) at unit d has n mod (b−1) among the roots.
- Helpers: `mod_sub_class` (n ≡ h + x ⟹ h mod m = (n mod m + m − x mod m) mod m, the probe loop's arithmetic),
  `sum_map_ite_count`.

### L4 + L6 packaged for L10 (`ClassesTops`)

- **`probed_top_of_isNice`** (b ≥ 2, f0 < k, lo ≤ n < hi, nice): some `t ∈ probesOf b (unitTops b lo hi f0 k
  (pip + d·b^(k−1−f0))) (r mod (b−1)) d` with `t.h = n / b^k`, `t.lo ≤ n ≤ t.hi`, mask digits `HighDigit b k n`,
  mhi digits `HighDigit b (k+2) n` (pip, d as above, r = n mod b^(k−1)).
- **`n_split`** (k ≥ 1): n = (n / b^k)·b^k + (n / b^(k−1) mod b)·b^(k−1) + n mod b^(k−1), the form
  `sliceSurvivors` rebuilds n in.
- **`unitTops_prefix`** (b ≥ 1, f0 ≤ k, **lo < hi**, u < b^(k−f0)): every n of a listed top's interval lies in
  `[lo, hi)`, has `n / b^f0 = t.h·b^(k−f0) + u`, lead `t.h` and unit `u` (for soundness: a survivor is a number
  of its slice and of the range).

### L3, residue classes (`ClassesProofs`)

- **`mod_mem_roots_of_isNice`**: nice n ⟹ n mod (b−1) ∈ `roots b`. **`mem_roots`**, **`roots_nodup`**.

### L2, range and lengths (`RangeDigits`)

- **`mem_range_of_isNice`** (b ≥ 2, `baseRange b = some (lo, hi)`): nice n ⟹ lo ≤ n < hi; **`mem_rangeC_of_isNice`**
  the same with the executable `baseRangeC`.
- **`numDigits_of_inBaseRange`**: inside the range every n has `(b − 2)/5 + 1` digits (from
  **`numDigits_pow_bounds`**: n with m + 1 digits has 2m+1..2m+2 square digits and 3m+1..3m+3 cube digits, so
  5m + 2 ≤ b ≤ 5m + 5); **`numDigits_eq_of_mem_range`**: every n of `[lo, hi)` has the digit count of hi − 1.
- **`Coord.digits_of_mem`** (`c.Valid`, n in the range): `numDigits n = c.L`, `1 ≤ L`, `b^(L−1) ≤ n < b^L`,
  n² has ≥ 2L − 1 digits, n³ ≥ 3L − 2. **`Coord.le_numDigits_pow`**: for every k ≤ L both powers have ≥ k digits
  (the side condition of `mem_botDfs_of_isNice` and `disjoint_high_lowSet`).

### L9, the final check (`CheckProofs`)

- **`finalCheck_iff`**: `finalCheck b n = true ↔ IsNice b n` (it is the definition, decided).
- **`uniqueDigits`** (new) mirrors `unique_digits` (`arith.rs:92`): distinct output digits, and whether both the
  distinct and the total count are b. **`uniqueDigits_snd`** (b ≥ 2): its verdict equals `finalCheck b n`, for
  every n (the total count is the range condition, `length_outputDigits`).

## Reused from the earlier library (`NiceSearch`, 4cdaa47f), unchanged

`cert`, `certDigits`, `certPositions`, `certPositions_digit`, `highDigit_of_cert`, `le_certFloor`,
`HighDigit`, `HighDigit.mono`, `exists_cert_of_isNice`, `div_mul_le_and_le`, `digit`, `digit_eq_getD`,
`digit_eq_zero_of_le`, `numDigits`, `lt_numDigits_iff`, `numDigits_le_iff`, `numDigits_eq_iff`,
`numDigits_pos_of_ne_zero`, `joinRoots`, `mem_joinRoots_of_isNice`, `residueTarget`, `IsNice`, `outputDigits`,
`numUniques_eq_iff_isNice`, `InBaseRange`, `inBaseRange_of_isNice`, `memBaseRange_of_inBaseRange`,
`inBaseRange_of_memBaseRange`, `baseRange`. From step 1: `baseRangeC_eq`. `class_eq` (SCOPE's suggestion for
L6) was not used: its hypothesis shape (`P·w + n mod w = n`) does not fit the probe formula; `mod_sub_class` +
`class_split` are shorter.

## Not proved, and why

- **MAXPOP 17** (L4's optional base-64 fact for the device layout): not attempted (optional, device-only).
- **L11-type exactness** of the tops' side (every listed top certified only if its interval contains a candidate,
  no duplicate tops): not in scope; `count_probesOf_of_isNice` and `unitTops_prefix` are the pieces of it that
  were cheap.
- The Rust's `U384` arithmetic and digit expansion, and the mask words, are not modelled (exact ℕ, `Nat.digits`,
  `Finset`), as in step 1. In particular `unique_digits(0)` (whatever `U384::digits` returns for 0) is not
  modelled; 0 is in no range.

## Model against the Rust: two edges, neither reachable, no finding

1. **`topCertSplit` with kmid < kpos** differs from `top_cert_split`: the model's `mhi` is `certDigits` at cap
   kmid, so it would include certified positions in `[kmid, kpos)`, which the Rust never scans. The Rust documents
   `kmid >= kpos`; its callers use kmid = kpos (`top_cert`) and kmid = k + 2 > kpos = k (`unit_tops`). Hence the
   hypothesis `kpos ≤ kmid` in `topCertScan_eq` and `topCertSplit_mhi`. **Optional change to propose** (not made;
   not needed by any lemma): define the model's `mhi` with cap `max kpos kmid`, which would make the equality
   unconditional.
2. **`unitLeads` with hi = 0**: `hi − 1` truncates to 0 and the clipped interval `[0, 0]` can be listed; that is
   why `unitTops_prefix` assumes `lo < hi` (a `Coord` from `withDigits` always has it). The Rust's `end − 1` on
   u128 would underflow there; no range is empty for a base the search runs.

## Fixtures

No new table. The lemmas are about the model, so a model mutant in their area breaks the proof itself: checked on
the box (not committed) with the step-1 mutant M04c, `unitTops` calling `topCertSplit … k (k + 1)`:
`lake build NiceMidOut.TopsProofs` fails at `mem_unitTops` (and everything after it), where the fixtures had needed
the deep (4, 16) table. The Rust-to-model link for the scan is unchanged: `topCertSplit` is already diffed against
3,000 Rust `top_cert_split` results (`b64.json`), and `topCertScan_eq` ties the step-by-step scan to it.

## What L10 needs from this half

For a nice n of the field (with `c.Valid`, `sh.Fits c`, so f0 ≤ q0 < k1 < k ≤ L, f0 < k):
1. `mem_range_of_isNice` (n in `[lo, hi)`), then `Coord.le_numDigits_pow` with k (and k − 1) ≤ L for the bottoms'
   and the pairing's side conditions.
2. `probed_top_of_isNice`: the top `t` in the probes of class `r mod (b−1)` (r = n mod b^(k−1), the class of the
   parent `mkParent` gives, `p.cls = p.r mod (b−1)`) at unit `d = n / b^(k−1) mod b`, with the unit already written
   `pip + d·b^(k−1−f0)` as in `sliceSurvivors`; `t.lo ≤ n ≤ t.hi` is the interval test; the mask facts feed
   `disjoint_high_lowSet` (half B's L7), the mhi facts feed the prefilter (half B's L8).
3. `n_split` to rewrite `t.h·b^k + d·b^(k−1) + x.1` (x.1 = r from the child) back to n.
4. `d < b` and `r mod (b−1) < b − 1` for the two `List.range` loops of `sliceSurvivors` (one line each:
   `Nat.mod_lt`).
5. `finalCheck_iff` for the final filter; for soundness, `unitTops_prefix` and `mod_mem_roots_of_mem_probesOf`.
   Matching L1's slice: `Shape.slice_digits`/`mem_fieldSlices_iff` use `n / b^f0 mod b^(k−1−f0)`, the same `pip`.

## Build times (box, cores 0–9)

elan + Lean 4.33.1 + clone + `lake exe cache get`: about 4 min (05:52–05:56 UTC). First `lake build` of the two
first files (incl. the earlier library from source): 2m24s. Each new file afterwards 10–20 s; incremental
`lake build --wfail` of the whole library ≈ 20 s; axiom check ≈ 30 s. Peak memory use seen by `free -g`: 17 GB used
of 31 (both halves). Conformance executable not rerun on the box (no model or conformance file changed); it runs
in CI on every push.

## Status

Head `38a7d77f` on `fork/lean/midout-tops`, green (fixtures 1m41s; build --wfail + conformance + axioms 8m32s): https://github.com/wasabipesto-bot/nice/actions/runs/45125119602 (runs on the three intermediate pushes were cancelled by the next push; the first, `0de99640`, was green: run 45121476286). Box: `/work/tops` left idle; no pull
request, nothing pushed to `origin`, `lean/midout` untouched. Nothing was denied by the tooling.
