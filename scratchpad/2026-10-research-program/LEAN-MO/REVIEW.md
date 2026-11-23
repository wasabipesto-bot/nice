**Verdict: (b) — the README's claim is accurate with stated corrections.** The two theorems say what the README says, about the Lean model. Their hypotheses hold at the real base-64 and base-65 parameters, checked by the kernel. The model in the theorems is the one run against the Rust tables. The trust path is clean. The corrections are about scope and wording: the end-to-end statements are per field and depend on the model's own `fieldDigits` accepting the field; soundness holds by construction; and at base 64 the conformance tests the parts one at a time, never the whole join.

*Independent review, 2026-11-23 07:20–10:45 UTC, by a reviewer who did not write the proof. I read on ivory and built and experimented only in `/work/review` on the Vast box. Branch `lean/midout` was checked out at `5eb715f3bd42cb362df7dfe41b914c1ade96452e`. I changed nothing on any branch.*

## Findings, ranked

### A. Wrong or overstated

None of the theorem statements is wrong. Two sentences overstate what the theorems or tests give:

- **A1. Soundness is true by construction, and nothing says so.**
  - The evidence: `finalCheck` is defined as `decide (IsNice b n)` (`NiceMidOut/Join.lean:35–37`), and `searchField` filters its output with it (`Join.lean:182`). So "every returned number is nice" (`searchField_sound`, `EndToEnd.lean:155–170`) follows from the definition and says nothing about the join's pruning.
  - What it does not cover: the Rust's `unique_digits` (`common/src/midout/arith.rs:92–111`, U384 digit expansion) is not modelled, and its docstring at `Join.lean:35` says "`arith::unique_digits(n, b).1`". `uniqueDigits_snd` (`CheckProofs.lean:38`) proves that a Lean mirror of it equals `finalCheck`, but that mirror is not the function in `searchField`, and it is not in the end-to-end dependency closure (see "What I ran", item 7).
  - How thin the test of the Rust's check is: the whole-base fixtures contain exactly one nice number, 69 in base 10. Mutant M9, a final check that also accepts 70, passes all 81,484 conformance checks.
  - The fix: README §"What is proved" (`README.md:19`) should say that soundness's "is nice" half is the model's final check by definition. The real content of the result is completeness (nothing is lost) plus "`v(n)` is in the field".
- **A2. "Tested against the Rust … on base-64/65 samples" (`README.md:44–46`) reads stronger than the fixtures are.**
  - At base 64 no slice is joined end to end, and neither `sliceRun` nor `sliceSurvivors` nor `searchField` ever runs at base 64.
  - `unit_tops` is compared at the production shape (4, 10) for **one** unit; the other 300 units are at (4, 16).
  - Parent lists are compared at shapes (2, 5) and (1, 4). Parent samples at (4, 10) cover 2 slices, 300 members each.
  - The prefilter is compared at `k = 10` only. Certificates are compared at the production pair (10, 12) and at 14 other pairs, 200 each.
  - End-to-end comparisons (`searchField`, `sliceRun`, `sliceSurvivors`) exist only for bases 10, 12, 13, 14, 17, 18, 19, 20, 22, 24 and 25, at shapes with k ≤ 5.
  - The fix: say "base-64/65 components (coordinates, fields, slices, certificates, unit tops, parents, children, prefilter); whole slices and fields at small bases only".

### B. Should fix

- **B1. The end-to-end theorems are per field, and they are conditional on the model's `fieldDigits` accepting the field.**
  - The evidence: both theorems take `hf : c.fieldDigits vs vz = some (t0, t1)` (`EndToEnd.lean:70`). `searchField` returns `none` unless `fieldDigits` does (`Join.lean:178`). So the statements alone hold for a model whose `fieldDigits` refuses fields the Rust accepts. In the extreme case, a `fieldDigits` that always returns `none` makes both theorems vacuous.
  - I showed this concretely with mutant **M6**, which refuses the last field of every coordinate (`vs + vz < vEnd`). With the one lemma it breaks, `fieldDigits_whole`, stubbed (that lemma is not used by the end-to-end theorems), `searchField_complete` and `searchField_sound` **still build with only the standard axioms**. Only the conformance catches M6 (`b64 (4,8,5) field_digits …`).
  - The lemmas that would close this exist but sit outside the end-to-end closure:
    - `Coord.fieldDigits_whole` (`CoordProofs.lean:305`);
    - `Coord.lo_le_vOfN` and `Coord.vOfN_lt_vEnd` (`CoordProofs.lean:46, 103`);
    - `Coord.existsUnique_quantum` (`:352`).
  - The fix: state the field hypothesis directly as whole quanta (`0 < vz`, `lo ≤ vs`, `vs + vz ≤ vEnd`, `Q ∣ vs − lo`, `Q ∣ vz`), as SCOPE §2 proposed. Add a base-level corollary: for any list of accepted fields tiling `[lo, vEnd)`, the union of the outcomes is exactly the nice numbers of the base. Until then, the README should not say or imply "the search of a base finds every nice number"; it proves this per field only.
- **B2. "For every base `b`" (`README.md:10`) should read "every base 3–128 with a range".**
  - `Coord.Valid` requires `3 ≤ b ≤ 128` (`Coord.lean:68`).
  - `withDigits` does not model the Rust's `u128` range and overflow refusals (`coord.rs:194, 207–208`), so the model accepts coordinates the Rust refuses. That over-approximates and is harmless, but should be said.
  - Likewise for the prefilter's `assert!(b^(k+2) < 2^96)` (`cpu.rs:237`), which panics in the Rust and is absent from the model.
- **B3. The run form is linked to the theorems by a permutation lemma only.** That lemma is correct. Two consequences need saying:
  - `sliceRun` (what the fixtures compare in order) is not in the closure of `searchField_complete/sound`. It is linked by `sliceRun_surv_perm` (`RunProofs.lean:123`) and `sliceRun_complete`.
  - Mutant M5b (the run form's interval strict at the low end) leaves both end-to-end theorems proved with standard axioms (stubbing only run-form lemmas). Only `sliceRun_complete` loses its proof (sorryAx), and the conformance catches it.

  So "the function in the theorems is the tested function" holds for `searchField` itself, which `checkWhole` runs on whole fields (`Conformance.lean:133–142`). It holds for the run form only through the permutation lemma.
- **B4. Some proof failures under mutation are brittleness, not dependence.** M1 (the top certificate asked from `k + 1` instead of `k`) and M3b (exempting *more* numbers from the prefilter) are mutations under which, by my reading, both theorems remain **true**:
  - M1 yields a weaker mask and fewer rejections, and the final check is the definition;
  - M3b exempts more, so more numbers pass.

  Yet the proofs break, at `mem_unitTops` / `cert_of_mem_unitTops` and at `midPrefilter_of_lt`, because those lemmas state the exact positions. That is fine, but "the proof broke" is not evidence that a detail matters. It is the M1b/M1c/M3/M5/M8 rows below that show the theorem depends on the correctness-relevant details.

### C. Notes

- **C1.** "Each nice number is reported once" is not proved. The README says so at `:24`. `slicesOf_nodup` and `field_disjoint` exist, but there is no theorem about duplicates in `o.nice`.
- **C2.** The Rust's `search_field` collects from threads and sorts unstably (`cpu.rs:960–1000`). The model is sequential with `mergeSort`. They are equal as multisets; this is not modelled and needs no proof beyond C1.
- **C3.** `IsNice` (library `Spec/Nice.lean:18`, `outputDigits` = `Nat.digits` of n² then of n³, a permutation of `range b`) is the property the project means.
  - It is stricter than production's `get_is_nice` (`client_process.rs:223+`), which checks distinctness only and so accepts n = 0. The two agree inside the base range (library `numUniques_eq_iff_isNice`, used in `uniqueDigits_snd`). Nice numbers are in the range by `mem_range_of_isNice`, which is proved, not assumed.
  - Brute force agrees: by the Lean definition over each base's range, bases 3–22 give exactly `[69]` at base 10 and nothing else. An independent Python brute force over all n from 1 up to the digit-count limit gives the same, and `niceOf 10 = [69]` is proved by `decide +kernel`.
- **C4.** The authors' `leanchecker` run of the root module `NiceMidOut` was killed (rc=137), and so was mine (rc=137, 68 s). The root module only imports the others; every one of the 18 submodules passes on its own. That gap is cosmetic, but the README should not claim "leanchecker clean" without saying it was per module.
- **C5.** The fixtures were regenerated by CI from the Rust on `lean/midout` itself (`.github/workflows/lean-midout-temporary.yml`, run 45127427003 green on `5eb715f3`).
  - Against `dev/mo-clean` head `eb9ef776`, the only difference in `common/src/midout/cpu.rs` is 168 added test lines, so the fixtures come from the reference code.
  - I did not rerun the Rust generator myself. `sha256sum -c SHA256SUMS` passes on my clone.

## The six points

1. **Definitions.**
   - `IsNice`, `digit` and `numDigits` (library `Spec/Digits.lean:18, 21`) and the base range are as the project means them; see C3. `baseRange` is the Rust closed form, proved equal to the executable `baseRangeC` (`baseRangeC_eq`) and compared with the Rust for bases 3–128.
   - `Coord`, `Valid`, `withDigits`, `vOfN`, `fieldDigits`, `Shape`, `Fits`, `slicesOf` and `searchField` mirror `coord.rs:193–301` and `cpu.rs:75–117, 937–1000` line by line. I compared them myself. The exceptions are B2's missing refusals and the mask-width check.
   - `FieldOutcome.nice` is the sorted list of survivors that pass the prefilter and `IsNice`, which matches the Rust's `pass && unique_digits(n).1`.
2. **Vacuity: the hypotheses hold at the real parameters.** All checked by kernel `decide`, standard axioms only:
   - `Coord.withDigits 64 4 8 5 = some c64` and `Coord.withDigits 65 4 8 5 = some c65`;
   - `(⟨4,10⟩ : Shape).Fits` both;
   - `fieldDigits` of the fixture fields `[39558033859753602449408, +1008806316530991104)` at base 64 and `[104439929854222367887348, +7080084705493800000)` at base 65 are `some (12345, 12352)`.

   With these, `b64_instance` and `b65_instance` instantiate both theorems. `prod_ok` checks every production coordinate of `coord.rs:101–115`: 64 and 65 at (4,8,5) and (4,9,6), and 68–70 at (4,9,6). For each, the coordinate is built, `forCoord` gives (4,10) and fits, and the first quantum field is accepted.
   - The conclusion is not empty: `b10_69` derives `69 ∈ o.nice` for base 10's whole field from `searchField_complete`, and `#eval` gives `{nice := [69], survivors := 1, checked := 1, slices := 10}`.
   - `Valid` and `Fits` are neither too strong (real instances satisfy them) nor too weak.
   - `searchField` returns `none` only when `Fits` or `fieldDigits` fails, and both mirror the Rust's refusals. The only exceptions are the Rust's `b ≤ M::BITS` and `u128` refusals, where the model returns `some` and the Rust refuses. But see B1: the statement itself does not prevent a broken `fieldDigits`.
3. **Tested equals proved.**
   - `searchField`, the constant in both theorems, is executed directly by the conformance on whole fields of bases 10–25: its nice list and its survivors, checked and slices counters are compared with the Rust (`Conformance.lean:133–142`).
   - `sliceSurvivors`, the definition inside `searchField`, is compared per slice with the Rust's survivors as a multiset sorted by n (`:127–131`).
   - `sliceRun` is compared in order and on all 12 counters (`:124–126`).
   - The chain `sliceRun.surv ~ sliceSurvivors.map (prefilter verdict)` is `sliceRun_surv_perm`, and I read its proof: it goes through `mergeSort_perm` on the parents and the chunk flattening, and the parents' reorder only filters by class.
   - In both forms `o.nice` / `pass` is the `midPrefilter` verdict on the top's `mhi`, then the final check.
   - Same constants: the conformance imports the same `NiceMidOut` modules, and there is no second copy of any definition. Limits: A2 and B3.
4. **Mutants.** See the table below. Every mutation that makes the theorems false breaks a lemma inside the end-to-end closure. I confirmed this for M5, whose first failure was outside the closure, by stubbing that lemma: the build then fails in `mem_sliceSurvivors_of_isNice`. The conformance catches every mutant except M9. **No mutant escaped both.** The mutants worth reporting are M6 (B1), M5b (B3) and M9 (A1).
5. **Axioms and trust.**
   - `#print axioms` on `searchField_complete`, `searchField_sound`, both `_of_withDigits` forms, `sliceRun_complete` and `sliceRun_surv_perm` gives `[propext, Classical.choice, Quot.sound]`.
   - The authors' script reports 191 theorems, standard axioms only.
   - A source scan of `NiceMidOut/` and of the library at `4cdaa47f` found no `sorry`, `native_decide`, `implemented_by`, `extern`, `unsafe`, `partial`, `admit`, `axiom` or `opaque`. There is one `decreasing_by`, with a real proof, in the library's `Model/Stride.lean:140`, which is not on the path. The only `set_option` is `exponentiation.threshold` in the library's `Const.lean`.
   - The pinned dependency is verified: `.lake/packages/Nice` HEAD is `4cdaa47fa12eed47cbc6728175ebc3c9ef856959`, its working tree is clean, `git ls-remote` gives `refs/heads/lean-proofs` at the same commit, and Mathlib is at `0df444a3…` per the manifest.
   - `leanchecker` passed on all 18 `NiceMidOut.*` modules (rc=0 each), including `EndToEnd`, `Join` and `Coord`, and on the 22 library modules (`Nice.*`, see "What I ran"). The root module was killed (C4).
   - Trust base beyond the kernel: Mathlib's `Nat.digits`, `List.Perm` decidability, and `decide +kernel` in my own checks. For the conformance only (not the proofs): the compiled code with GMP naturals and `@[csimp]` replacements.
6. **The gap to the running code.**
   - The README says plainly (`:42–52`) that the theorems are about the model, and lists as not covered: the Rust itself, U384 and u128 arithmetic, the bit-sliced word, the f64 chunk key, the mask width, the GPU kernels and device check, compilers, drivers and hardware, and the coordinator's bookkeeping.
   - Missing or understated:
     - that the final check is the definition and not the Rust's `unique_digits` (A1);
     - that base-level coverage is not part of the theorem (B1);
     - "reported once" is listed (`:24`);
     - the fixture coverage at base 64 (A2);
     - the Rust's refusals that are not modelled (B2).
   - Mask widths above 64: the model has no width at all (`Finset ℕ`), so b ≤ 128 with `u128` masks is untested beyond the small bases (all < 64). The README's "mask width" line covers this.
   - The sentence "a proof that it finds every nice number of a field and nothing else" (`:4`) is accurate. Read as "nothing else" in the pruning sense, it is stronger than it sounds, because of A1.

## Mutant table

Each mutant is one definition changed in a scratch copy (`/work/review/mut/`). "Theorem true after mutation?" is my analysis; the other columns were run. "Proof" means `lake build NiceMidOut` (the lemmas named are where elaboration first failed, with whether each is in the dependency closure of `searchField_complete`/`searchField_sound`). "Conformance" is the model-only conformance (imports `NiceMidOut.Join`, so it runs even when proofs break), with the first mismatch.

| id | mutation (file:line) | theorem true after mutation? | proof | conformance |
|---|---|---|---|---|
| M0 | control (no-op) | yes | builds | pass, 81,484 |
| M1 | top certificate from `k+1` (`Join.lean:73`) | yes (weaker mask) | breaks: `mem_unitTops`, `cert_of_mem_unitTops` (in closure; brittleness, B4) | caught: whole b10 slice 0 counters |
| M1b | top certificate from `k−1` | no (mask meets the child's digit k−1) | breaks: `mem_unitTops`, `cert_of_mem_unitTops` (in closure) | caught: whole b10 counters |
| M1c | `mhi` from `k+1` (the SCOPE M04) | no | breaks: `mem_unitTops`, `cert_of_mem_unitTops` (in closure) | caught: `unit_tops` at b64 |
| M2 | one residue root dropped (`roots := (joinRoots b).tail`, `:33`) | no | breaks: `mod_mem_roots_of_isNice` (in closure) | caught: roots b4 |
| M10 | class offset off by one in `probesOf` (`:141`) | no | breaks: `mem_probesOf_of_isNice` (in closure) | caught: whole b10 counters |
| M3 | prefilter exempts less: `(k+2)/2` (`:126`) | no (reads padding at odd k) | breaks: `midPrefilter_of_lt`, `midPrefilter_of_isNice` (in closure) | caught: whole b13 counters |
| M3b | prefilter exempts more: `(k+3)/2 + 1` | yes | breaks: same lemmas (statement-level, B4) | caught: whole b17 counters |
| M8 | prefilter tests positions k+1, k+2 against `mhi` (`:133`) | no | breaks: `midPrefilter_of_isNice` (in closure) | caught: prefilter table |
| M4 | child's affine coefficient `a2 = r mod b` instead of `2r mod b` (`:104`) | no | breaks: `childMask_digits` (in closure) | caught: parents (2,5) |
| M5 | top interval strict at the top end in `sliceSurvivors` (`:159`) | no | breaks: `sliceSurvivors_map`; with it stubbed, `mem_sliceSurvivors_of_isNice` (in closure) | caught: whole b10 survivors |
| M5b | strict at the low end in the run form `pairSurv` (`:266`) | the e2e theorems yes; `sliceRun_complete` no | e2e **builds, standard axioms** with run-form lemmas stubbed; `sliceRun_complete` gets sorryAx (B3) | caught: whole b10 counters |
| M7 | unit lead kept only if `a < c` (`:67`) | no (drops singleton intervals) | breaks: `mem_unitLeads` (in closure) | caught: whole b10 counters |
| M6 | field must end strictly before `vEnd` (`Coord.lean:110`) | **yes: the statement is conditional on `fieldDigits`** | only `fieldDigits_whole` breaks (not in closure); stubbed, e2e **builds, standard axioms** (B1) | caught: b64 `field_digits` |
| M6b | field digits `t1 + 1` (`Coord.lean:111`) | no (soundness: v outside field) | breaks: `mem_field_iff`, `fieldDigits_le` (in closure) | caught: b64 `field_digits` |
| M6c | field digits `t1 − 1` | no (completeness) | breaks: same (in closure) | caught: b64 `field_digits` |
| M9 | final check also accepts 70 (`:37`) | no (soundness) | breaks: `finalCheck_iff` (in closure) | **passes all 81,484** (A1) |

## What I ran myself (box `/work/review`, logs there)

1. A fresh clone at `5eb715f3`. Packages were copied from `/work/merged` and verified against the manifest revisions with clean trees. Then `lake build NiceMidOut conformance`: 6086 jobs, 0 warnings, 1 m 58 s.
2. `lake exe conformance`: "81484 checks, all equal to the Rust tables". `sha256sum -c SHA256SUMS`: all three OK.
3. `bash scripts/check_axioms.sh`: "191 theorems checked, standard axioms only".
4. `Review.lean` / `Review2.lean`: the axioms of the six main theorems; the brute-force nice lists for bases 3–22; `decide +kernel` proofs `wd64`, `wd65`, `fit64`, `fit65`, `fd64`, `fd65`, `b64_instance`, `b65_instance`, `wd10`, `b10_69` and `prod_ok`, all `[propext, Classical.choice, Quot.sound]`.
5. Python brute force on ivory, bases 3–22, all n up to the digit-count limit: only `10 [69]`.
6. `leanchecker`: 18/18 `NiceMidOut.*` modules rc=0; the root module rc=137 (killed); the library's 22 `Nice.*` modules rc=0 (`lc_lib.log`).
7. `Closure.lean`, the transitive constants of both end-to-end theorems: 133 `NiceMidOut` names, which excludes `sliceRun`, `sliceRun_surv_perm`, `fieldDigits_whole`, `uniqueDigits_snd`, the coverage lemmas and `baseRangeC_eq`. `failmap.py` maps each mutant's errors to lemmas and their closure membership.
8. 17 mutants (`mutants.sh`, `mutants2.sh`) and 3 stubbed variants (`mutsorry.sh`: S_M5, S_M6, S_M5b2). Results are in `mut/summary.txt` and `mut/ssummary.txt`.

Not done: regenerating the fixtures from the Rust myself (no Rust build on the box; CI did it at `5eb715f3`); a `--fresh` replay of Mathlib.

## Public wording I would sign

> A Lean 4 model of the middle-out join's CPU reference is machine-checked (Lean and Mathlib v4.33.1, standard axioms only) to return, for every base 3–128 with a range, every valid coordinate, every fitting shape and every whole-quanta field that the model accepts, every number in that field whose square and cube together use each digit of the base exactly once, and only such numbers. The theorem is about the Lean model, which was checked against the Rust CPU reference on fixture tables (whole fields at small bases; coordinates, fields, tops, parents, children and the prefilter at bases 64 and 65); it does not cover the Rust code itself, the GPU kernels, or the coordinator's record of which fields were searched.
