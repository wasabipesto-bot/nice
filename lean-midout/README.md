# NiceMidOut: the middle-out join in Lean

A Lean 4 model of the middle-out join's CPU reference (`common/src/midout/cpu.rs`, `coord.rs`, `arith.rs`),
checked against the Rust on fixture tables, and a proof that it finds every nice number of a field and nothing
else. It builds on the earlier library `Nice` (namespace `NiceSearch`, required from this repository at commit
`4cdaa47f`, directory `proofs/`) for `IsNice`, digits, the range, the top certificate and the bottom walk.

## What is proved

**The end-to-end theorem** (`NiceMidOut/EndToEnd.lean`), for every base `b`, every coordinate `c` with
`c.Valid` (what the executable constructor `Coord.withDigits` guarantees: `Coord.valid_of_withDigits`), every
shape `sh` with `sh.Fits c`, every field `[vs, vs + vz)` that the model's `Coord.fieldDigits` accepts (whole
quanta inside the coordinate):

- `searchField_complete`: `searchField c sh vs vz` returns an outcome, and every nice `n` whose renumbered value
  `c.vOfN n` lies in the field is among its nice numbers. `sliceRun_complete`: the same `n` is reported, with
  prefilter verdict `true`, by the run form `sliceRun` (the Rust's order and counters) of its slice, which is
  one of the field's slices.
- `searchField_sound`: every number `searchField` returns is nice and has `c.vOfN n` in the field.
- `searchField_complete_of_withDigits`, `searchField_sound_of_withDigits`: the same with the coordinate built
  by `Coord.withDigits`.

No hypothesis beyond these: in particular nothing about the base being 64, about the range's ends, or about
clipped tops. Not proved: that each nice number is returned once (the survivor list's exactness).

**The lemmas it is composed from** (namespace `NiceMidOut`):

| group | file | main results |
|---|---|---|
| coordinate and fields | `CoordProofs` | `Coord.nOfV_vOfN`, `Coord.vOfN_div_quantum`, `Coord.mem_field_iff`, `Shape.mem_slicesOf_iff`, `Shape.slicesOf_nodup`, `Coord.mem_fieldSlices_iff`, `Coord.existsUnique_quantum`, `Coord.field_disjoint` |
| range | `RangeProofs`, `RangeDigits` | `baseRangeC_eq` (the executable range is the library's), `Coord.valid_of_withDigits`, `mem_range_of_isNice`, `Coord.le_numDigits_pow` |
| residue classes | `ClassesProofs` | `mod_mem_roots_of_isNice`, `roots_nodup`, `mem_probesOf_of_isNice`, `count_probesOf_of_isNice`, `mod_mem_roots_of_mem_probesOf` |
| tops | `TopsProofs`, `TopsScan`, `ClassesTops` | `mem_unitTops_of_isNice`, `topCertSplit_mhi`, `highDigit_of_mem_unitTops`, `topCertScan_eq` (the scan as the Rust runs it equals the certificate), `probed_top_of_isNice`, `unitTops_prefix` |
| bottoms | `Bottoms`, `BottomsExact`, `BottomsNodup`, `BottomsKids` | `mkParent_mem_parents_of_isNice`, `mem_parents_iff`, `mem_bottomsSorted_iff`, `parents_nodup`, `childMask_digits`, `childMask_of_isNice`, `mem_kidsOf_of_isNice`, `kid_of_mem_kidsOf` |
| pairing | `Pairing` | `disjoint_top_lowSet`, `pairSurv_of_isNice`, `mem_probeSurv_of_isNice`, `mem_sliceSurvivors_of_isNice` |
| prefilter | `Prefilter` | `midPrefilter_of_isNice` (with the exemption: `midPrefilter_of_lt`, `lt_numDigits_of_not_exempt`, `bare_rule_rejects_69`), `midPrefilter_of_mem_unitTops` |
| final check | `CheckProofs` | `finalCheck_iff`, `uniqueDigits_snd` |
| run form | `RunProofs` | `sliceRun_surv_perm` (the run form's survivors are a permutation of the definition's), `sliceRun_survivors`, `sliceRun_checked`, `sliceRun_parents` |

## Model, tested, proved

- **Model**: every definition in `Coord.lean` and `Join.lean` is a Lean function written to mirror the Rust
  reference; the theorems are about these functions, not about the Rust.
- **Tested against the Rust** (`lake exe conformance` against the tables in `fixtures/`, produced by
  `common/examples/midout_lean_fixtures.rs`): the model's outputs on every slice of the small-base whole-base
  runs and on base-64/65 samples. These parts of the Rust are covered by the fixtures only, never by a proof:
  the bit-sliced word of the pairing (modelled by its meaning: a child is in the word iff its mask misses the
  top's), the work counters `children`, `chunks`, `pairs`, `flat`, `kept`, `words`, `clipped`, the `f64`
  products of the chunk key, the 384-bit (`U384`) and `u128` arithmetic and the modular product `mm` (exact
  naturals here), and the mask width (`b ≤ M::BITS`; masks are `Finset ℕ` here).
- **Not covered at all**: the Rust code itself, the GPU kernels and their device-side check, compilers, drivers
  and hardware, and the coordinator's bookkeeping of which fields were searched.

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
`Quot.sound`. The repository's workflow `.github/workflows/lean-midout-temporary.yml` runs these three steps,
and regenerates the fixtures from the Rust to compare their checksums.
