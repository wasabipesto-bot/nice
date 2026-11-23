# NiceMidOut: the middle-out join in Lean

A Lean 4 model of the middle-out join's CPU reference (`common/src/midout/cpu.rs`, `coord.rs`, `arith.rs`),
checked against the Rust on fixture tables, and a proof about the model. It builds on the earlier library `Nice`
(namespace `NiceSearch`, required from this repository at commit `4cdaa47f`, directory `proofs/`) for `IsNice`,
digits, the range, the top certificate and the bottom walk.

## Summary

A Lean 4 model of the middle-out join's CPU reference is machine-checked (Lean and Mathlib v4.33.1, standard
axioms only) to return, for every base 3–128 with a range, every valid coordinate, every fitting shape and every
whole-quanta field, every number in that field whose square and cube together use each digit of the base exactly
once, and only such numbers; consequently, for any list of whole-quanta fields covering a coordinate, a number is
nice exactly when one of the fields returns it, and if every field's search returns no nice number the base has
none. The theorems are about the Lean model, which was checked against the Rust CPU reference on fixture tables
(whole slices and fields at bases 10–40, whole slices at base 50; coordinates, fields, tops, parents, children, the
prefilter and the final check at bases 64 and 65); they do not cover the Rust code itself, the GPU kernels, or the
coordinator's record of which fields were searched.

## What is proved

All for `c.Valid` (bases 3–128 whose range exists, positions `k0 ≤ q0 < k1 ≤ L`; exactly what the executable
constructor `Coord.withDigits` guarantees, `Coord.valid_of_withDigits`) and a shape with `sh.Fits c`.

**Per field** (`NiceMidOut/EndToEnd.lean`, `NiceMidOut/WholeBase.lean`). `Coord.WholeQuanta c vs vz` is the plain
condition on a field `[vs, vs + vz)`: `0 < vz`, `lo ≤ vs`, `vs + vz ≤ vEnd`, the quantum divides `vs − lo` and `vz`.
The model's field function accepts exactly these fields (`Coord.fieldDigits_isSome_iff`), and `searchField`
returns an outcome exactly for a fitting shape and such a field (`searchField_isSome_iff`): acceptance is proved,
not assumed.
- `searchField_complete_wq`: for a whole-quanta field, `searchField` returns an outcome, and every nice `n` whose
  renumbered value `c.vOfN n` lies in the field is among its nice numbers (`searchField_complete` is the same with
  the hypothesis `c.fieldDigits vs vz = some _`).
- `sliceRun_complete`: the same `n` is reported, with prefilter verdict `true`, by the run form `sliceRun` of its
  slice, one of the field's slices.
- `searchField_sound`: every number `searchField` returns is nice and has `c.vOfN n` in the field.

**For a whole base** (`NiceMidOut/WholeBase.lean`). `Coord.Covers c fs`: every value of `[lo, vEnd)` lies in one of
the fields `fs` (pairs `(vs, vz)`).
- `isNice_iff_mem_fields`: for whole-quanta fields covering `[lo, vEnd)`, `IsNice c.b n` iff some field's search
  returns `n`. Instances: the whole coordinate as one field (`isNice_iff_mem_wholeField`) and one field per
  quantum (`isNice_iff_mem_quantumFields`; tilings `Coord.wholeField`, `Coord.quantumFields`, proved whole quanta
  and covering).
- `no_nice_of_searched`: for a valid coordinate and fields covering `[lo, vEnd)`, if every field's search returned
  an outcome and every outcome's list of nice numbers is empty, no number is nice in base `c.b`.
  `no_nice_of_searched_withDigits`: the same for `Coord.withDigits b k0 k1 q0 = some c`, concluding
  `∀ n, ¬ IsNice b n`. These are the statements a claim about a whole base rests on.

**What the statements do not say.**
- *Soundness's "is nice"* goes through the model's final check, which is `uniqueDigits`, the mirror of the Rust's
  `unique_digits` (distinct count and total count both `b`), proved equivalent to `IsNice` (`finalCheck_iff`). (In
  the first version of this model the final check was `IsNice` itself, so that half was true by construction.) The
  substantive content of the theorems is completeness (the join's pruning loses no nice number) and that returned
  numbers lie in their field.
- *Each nice number is returned once* is not proved.
- *The run form.* `searchField` (in the theorems) is built on the definitional join `sliceSurvivors`; `sliceRun`,
  which mirrors the Rust's order and counters and is what the fixtures compare survivor by survivor, is linked to
  it by the permutation lemma `sliceRun_surv_perm` (and `sliceRun_complete`), not by being the same function.
- *Refusals not modelled.* The model does not refuse where the Rust does for reasons of machine arithmetic: the
  `u128` range and overflow checks of `Coord::with_digits`, the prefilter's `assert!(b^(k+2) < 2^96)`, the mask
  width `b ≤ M::BITS`. It therefore accepts more coordinates and fields than the Rust; that is harmless for the
  theorems (they hold for all of them), but those cases have no Rust counterpart.

**The lemmas it is composed from** (namespace `NiceMidOut`):

| group | file | main results |
|---|---|---|
| coordinate and fields | `CoordProofs`, `WholeBase` | `Coord.nOfV_vOfN`, `Coord.vOfN_div_quantum`, `Coord.mem_field_iff`, `Shape.mem_slicesOf_iff`, `Shape.slicesOf_nodup`, `Coord.mem_fieldSlices_iff`, `Coord.existsUnique_quantum`, `Coord.field_disjoint`, `Coord.fieldDigits_isSome_iff` |
| range | `RangeProofs`, `RangeDigits` | `baseRangeC_eq` (the executable range is the library's), `Coord.valid_of_withDigits`, `mem_range_of_isNice`, `Coord.le_numDigits_pow` |
| residue classes | `ClassesProofs` | `mod_mem_roots_of_isNice`, `roots_nodup`, `mem_probesOf_of_isNice`, `count_probesOf_of_isNice`, `mod_mem_roots_of_mem_probesOf` |
| tops | `TopsProofs`, `TopsScan`, `ClassesTops` | `mem_unitTops_of_isNice`, `topCertSplit_mhi`, `highDigit_of_mem_unitTops`, `topCertScan_eq` (the scan as the Rust runs it equals the certificate), `probed_top_of_isNice`, `unitTops_prefix` |
| bottoms | `Bottoms`, `BottomsExact`, `BottomsNodup`, `BottomsKids` | `mkParent_mem_parents_of_isNice`, `mem_parents_iff`, `mem_bottomsSorted_iff`, `parents_nodup`, `childMask_digits`, `childMask_of_isNice`, `mem_kidsOf_of_isNice`, `kid_of_mem_kidsOf` |
| pairing | `Pairing` | `disjoint_top_lowSet`, `pairSurv_of_isNice`, `mem_probeSurv_of_isNice`, `mem_sliceSurvivors_of_isNice` |
| prefilter | `Prefilter` | `midPrefilter_of_isNice` (with the exemption: `midPrefilter_of_lt`, `lt_numDigits_of_not_exempt`, `bare_rule_rejects_69`), `midPrefilter_of_mem_unitTops` |
| final check | `CheckProofs` | `finalCheck_iff` (the `unique_digits` mirror accepts exactly the nice numbers) |
| run form | `RunProofs` | `sliceRun_surv_perm`, `sliceRun_survivors`, `sliceRun_checked`, `sliceRun_parents` |

## Model, tested, proved

- **Model**: every definition in `Coord.lean` and `Join.lean` is a Lean function written to mirror the Rust
  reference; the theorems are about these functions, not about the Rust.
- **Tested against the Rust** (`lake exe conformance` against `fixtures/`, written by
  `common/examples/midout_lean_fixtures.rs`; CI regenerates them from the Rust and compares checksums):
  - *End to end*: every slice of every field, counters and every survivor in order (`sliceRun`), the definition's
    survivors as a set (`sliceSurvivors`), and `searchField` on the whole base and on its first quantum, at bases
    10, 12, 13, 14, 17, 18, 19, 20, 22, 24, 25 with shapes `k ≤ 5` (`whole.json`); whole slices (run form in
    order with counters, and the definition) at base 30 shape (2, 6) and base 40 shape (3, 8), six slices each,
    and at base 50 shape (4, 10) (one slice, 380 survivors; `wide.json`).
  - *Components at bases 64 and 65* (`b64.json`): coordinates (4, 8, 5), (4, 9, 6) at 64 and (4, 8, 5) at 65
    (derived values, `v` and `n_of_v` samples, fields and slice lists); 3,000 top certificates; the tops of one
    unit of the production shape (4, 10) and of 300 units of (4, 16); whole parent lists at shapes (2, 5), (1, 4)
    and sampled parents and child masks of two (4, 10) slices; 4,000 prefilter verdicts at `k = 10`.
  - *The final check* (`check.json`): `unique_digits`' distinct count and verdict on 1,580–2,033 numbers per base
    at bases 10, 12, 13, 14, 17, 20, 25, 30, 40, 50, 64, 65: random numbers of the range, the range's 20 lowest
    and highest numbers and the 20 just outside each end, numbers one or two digits short of nice where random
    sampling finds them (bases 10–25), and at base 10 every number of the range.
  - Covered by the fixtures only, never by a proof: the bit-sliced word of the pairing (modelled by its meaning),
    the work counters `children`, `chunks`, `pairs`, `flat`, `kept`, `words`, `clipped`, the `f64` products of the
    chunk key, the 384-bit (`U384`) and `u128` arithmetic and the modular product `mm` (exact naturals here), the
    digit expansion of `unique_digits`, and the mask width (masks are `Finset ℕ` here, so widths above 64 bits are
    untested beyond the small bases).
- **Not covered at all**: the Rust code itself, the GPU kernels and their device-side check, compilers, drivers
  and hardware, and the coordinator's record of which fields were searched.

## Building and checking

Lean `v4.33.1` and Mathlib `v4.33.1` are pinned (`lean-toolchain`, `lake-manifest.json`). From this directory:

```
lake exe cache get          # Mathlib's compiled files
lake build --wfail          # the model and every proof; warnings fail the build
lake exe conformance        # the model against the Rust tables
bash scripts/check_axioms.sh
```

`scripts/check_axioms.sh` prints `#print axioms` for every theorem of a `NiceMidOut` module (listed by the Lean
environment itself) and fails on `sorryAx`, `Lean.ofReduceBool` / `ofReduceNat` (`native_decide`) or any axiom
other than the three standard ones. Every theorem depends on at most `propext`, `Classical.choice` and
`Quot.sound`. The repository's workflow `.github/workflows/lean-midout-temporary.yml` runs these three steps and
regenerates the fixtures from the Rust to compare their checksums.

A second kernel check: the toolchain's `leanchecker` replays the compiled declarations. It was run on each of the
`NiceMidOut.*` modules that hold declarations (all accepted) and with `--fresh` on `NiceMidOut.EndToEnd`
(replaying its whole import closure, Mathlib included: accepted). The root module `NiceMidOut`, which only imports
the others, was not checked (the tool did not finish on it).
