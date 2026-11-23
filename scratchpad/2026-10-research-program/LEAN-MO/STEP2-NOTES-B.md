# The middle-out join in Lean, step 2, half B (bottoms, pairing, prefilter): notes (2026-11-23)

*Branch `lean/midout-bottoms` on the fork, from `lean/midout` at `4934b0ca`; worktree
`~/projects/nice/.worktrees/lean-bottoms` on ivory; builds on the box (Vast 62104162) under `/work/bottoms`. Paths
relative to `lean-midout/`. Status, head and CI run: see "Status" at the end.*

## What is on the branch

New files only (plus my import lines in `NiceMidOut.lean`); no shared file, model definition or fixture changed.

| file | lines | what |
|---|---|---|
| `NiceMidOut/Bottoms.lean` | 167 | L5(a) completeness, L5(b) the child's digits, digit bookkeeping |
| `NiceMidOut/BottomsExact.lean` | 301 | L5(a) exactness: bottom list and parent list = the residues `bot_cert_direct` accepts |
| `NiceMidOut/BottomsNodup.lean` | 116 | no repeats in the bottom and parent lists |
| `NiceMidOut/BottomsKids.lean` | 56 | L5(b) converse: every paired child is an accepted depth-`k` residue |
| `NiceMidOut/Prefilter.lean` | 131 | L8 with the exemption |
| `NiceMidOut/Pairing.lean` | 106 | L7, and the slice-level statement L10 needs |

All in namespace `NiceMidOut`, no `sorry`, no added axiom, no `native_decide` (`decide` only, in
`bare_rule_rejects_69`); the axiom check covers them all (standard axioms only).

## The lemmas (Lean name: statement in words)

**L5(a), parents: completeness** (`Bottoms.lean`)
- `mem_bottomsSorted_of_isNice`: for nice `n` (`b ≥ 2`) with `k ≤ numDigits (n²)` and `k ≤ numDigits (n³)`,
  `(n mod b^k, lowSet b n k) ∈ bottomsSorted b k f (n div b^f mod b^(k−f))`, for every `f`.
- `mkParent_mem_parents_of_isNice`: for nice `n` with `k − 1` digits in both powers,
  `mkParent b k (n mod b^(k−1), lowSet b n (k−1)) ∈ parents b sh (n div b^f0 mod b^(k−1−f0))` — `n`'s parent record
  (residue, mask = its `2(k−1)` low output digits) is in its slice's parent list (the slice as `CoordProofs` defines it).
- `mkParent_fields`: that record's `r`, `mask`, `cls` are the residue, the mask, the residue mod `b − 1`.

**L5(a), parents: exactness** (`BottomsExact.lean`; `LowDistinct b x j` = the digits of `x²`, `x³` below `j` are
pairwise distinct as positions)
- `botCertDirect_eq_some_iff`: `botCertDirect b x j = some m ⟺ LowDistinct b x j ∧ m = lowSet b x j`.
- `mem_bottomsSorted_iff`: `q ∈ bottomsSorted b k f v ⟺ q.1 < b^k ∧ (∀ i ∈ [f, k), digit b q.1 i = v div b^(i−f) mod b)
  ∧ botCertDirect b q.1 k = some q.2` (b ≥ 2; no other hypothesis). This is STEP1-NOTES' "membership in
  `bottomsSorted` ⟺ the pointwise predicate" (the predicate `parentAt` of `Conformance.lean` checks on the (4,10)
  samples), now proved.
- `mem_parents_iff`: `p ∈ parents b sh pip ⟺ p = mkParent b sh.k (p.r, p.mask) ∧ p.r < b^(k−1) ∧ p.r has digits
  [f0, k−1) of pip ∧ botCertDirect b p.r (k−1) = some p.mask`.
- `forced_iff_div`: for `r < b^k`, `f ≤ k`, `v < b^(k−f)`: the forced-digit condition ⟺ `r div b^f = v`.
- Supporting: `botDfs_sound` (every member of the walk from `(j, r, lowSet b r j)` with `r < b^j` and distinct low
  digits extends `r`, is `< b^(j+fuel)`, has distinct low digits, its `lowSet` as mask and the forced digits),
  `mem_botDfs_of_lowDistinct` (JOIN-2's induction with niceness replaced by `LowDistinct`), `lowSet_congr`,
  `lowDistinct_congr`, `lowDistinct_succ`, `botCertDirect_toFinset`, `botCertDirect_nodup_iff`, `eq_of_digit_eq`.
- `bottomsSorted_nodup`, `parents_nodup` (`BottomsNodup.lean`): no residue twice (b ≥ 2, all k, f, v, sh, pip).

**L5(b), the child's two new digits** (`Bottoms.lean`)
- `childMask_digits`: for `k ≥ 2`, any `q = (r, mask)` and any `d` (b > 0; no bound on `r` needed):
  `(c2 + a2·d) mod b = digit_{k−1}((r + d·b^(k−1))²)` and `(c3 + a3·d) mod b = digit_{k−1}((r + d·b^(k−1))³)` for the
  record `mkParent b k q` (the Rust's `parents_threads` + `child_mask`). Note the model's `a3 = 3·(r mod b)·(r mod b)
  mod b` and the earlier `botDigits`' `3·((r mod b)(r mod b) mod b) mod b` differ in form; equal mod b (proved inline).
- `childMask_of_isNice`: nice `n`, `k ≥ 2`, `k` digits in both powers ⟹ `childMask b (n's parent record)
  (digit_{k−1} n) = some (lowSet b n k)`.
- `mem_kidsOf_of_isNice`: the same child `(n mod b^(k−1), lowSet b n k)` is in `kidsOf b (parents of n's slice with
  cls = n mod b^(k−1) mod (b−1)) (digit_{k−1} n)` — the exact list `sliceSurvivors` iterates.
- `kid_of_mem_kidsOf` (`BottomsKids.lean`, the converse, for L11): every member `x` of that `kidsOf` list (any slice,
  class `c`, unit `d`, `k ≥ 2`) has `x.1 < b^(k−1)`, `x.1 mod (b−1) = c`, the slice's digits,
  `LowDistinct b (x.1 + d·b^(k−1)) k` and `x.2 = lowSet b (x.1 + d·b^(k−1)) k`.
- Bookkeeping: `unit_eq_slice_add` (`n div b^f0 mod b^(k−f0)` = slice + `digit_{k−1} n · b^(k−1−f0)`, for `f0 < k`:
  the unit `sliceSurvivors` passes to `unitTops`), `eq_top_unit_residue` (`n = (n div b^k)·b^k + digit_{k−1} n ·
  b^(k−1) + n mod b^(k−1)`, the survivor's assembly), `block_digit`, `mod_pow_succ_eq`.

**L7, pairing** (`Pairing.lean`)
- `disjoint_top_lowSet`: nice `n`, `t ∈ unitTops b lo hi f0 k u`, `t.lo ≤ n ≤ t.hi`, `k` digits in both powers ⟹
  `Disjoint t.mask (lowSet b n k)`.
- `pair_passes_of_isNice`: with `n = t.h·b^k + d·b^(k−1) + r`, the survivor test of `sliceSurvivors` holds.
- `pairSurv_of_isNice`: the run form's pair test returns `some (d, n, true)` (L7 + L8).
- `mem_probeSurv_of_isNice`: in any chunk containing the child, `(d, n, true) ∈ probeSurv b k d t ch` (the chunk skip
  through the already proved `probeSurv_eq`).
- `mem_sliceSurvivors_of_isNice` (**the composition piece**): nice `n`, `2 ≤ k`, `k` digits in both powers, a top `t` in
  `probesOf b (unitTops b lo hi f0 k (slice + digit_{k−1} n · b^(k−1−f0))) (n mod b^(k−1) mod (b−1)) (digit_{k−1} n)`
  with `t.h = n div b^k` and `t.lo ≤ n ≤ t.hi` ⟹ `(digit_{k−1} n, n, t.mhi) ∈ sliceSurvivors b lo hi sh slice(n)`.
- `mem_of_mem_probesOf`: a probed top is in the list probed.
- **Not modelled, so not proved:** the bit-sliced word (`cpu.rs:826–849`): the model already replaces it by its meaning
  (step 1), so the scope's `Nat.testBit`/`BitVec` refinement has no object in this model; it stays with the fixtures.

**L8, the prefilter** (`Prefilter.lean`)
- `midPrefilter_of_isNice`: nice `n`, `b ≥ 2`, every `x ∈ mhi` a digit of `n²` or `n³` at a position `≥ k + 2` (the
  earlier `HighDigit b (k+2) n x`) ⟹ `midPrefilter b k n mhi = true`. **No digit-count hypothesis.**
- The exemption, stated and proved: `midPrefilter_of_lt` (below `b^⌈(k+2)/2⌉` = `b^((k+3)/2)` it passes by
  definition) and `lt_numDigits_of_not_exempt` (at or above it, `k + 2 < numDigits (n^e)` for e = 2, 3, so every
  digit the rule reads is a real digit, never padding). `bare_rule_rejects_69`: the rule *without* the exemption
  rejects base 10's nice 69 at k = 3 (69² = 4761 reads a padding 0 at position 4, and 69³ = 328509 has a 0), while
  the prefilter passes it — the exemption is necessary, not only sufficient. (At base 10 the shapes have k ≤ 2, so
  this is about the rule, not a base-10 search.)
- `midPrefilter_of_mem_unitTops`: for `t ∈ unitTops ..` and nice `n ∈ [t.lo, t.hi]`, `midPrefilter b k n t.mhi = true`.
- Supporting: `cert_of_mem_unitTops` (a top's mask is `cert` of its interval at `k`, its `mhi` is `certDigits` at
  `k + 2` as a set), `certDigits_mem_highDigit`.

## Reused from the earlier library (`NiceSearch`, 4cdaa47f), unchanged

`botDfs`, `botDigits`, `botDigits_eq` (JOIN-2 step = AFF-1), `mem_botDfs_of_isNice` (JOIN-2), `lowSet`, `lowSet_zero`,
`lowSet_succ`, `mem_lowSet`, `disjoint_high_lowSet` (JOIN-3), `cert`, `certDigits`, `certDigits_eq`,
`certPositions_digit`, `highDigit_of_cert`, `le_certFloor`, `HighDigit`, `HighDigit.mono`, `digit_ne_of_isNice`,
`digit_mod_pow`, `digit_pow_mod_pow`, `digit_eq_of_modEq`, `digit_div_pow`, `digit_lt_base`, `lt_numDigits_iff`,
`mod_pow_div_pow`, `lsdBitmap`, `mem_lsdBitmap_of_isNice`, `suffixDigits_mod`, `lowDigits`, `nice_69`. From
`lean/midout`: `probeSurv_eq` (RunProofs). The scope's `prefilterAt` of #160 was not used (different rule), as expected.

## What is not proved, and why

- L7's bit-sliced word and partial-chunk mask: not in the model (see above); fixture-only, as in step 1.
- The tops' side of the composition (that `n`'s top is in `unitTops` with `t.h = n div b^k`, that it is probed at
  `n`'s class): Half T's L4/L6; `mem_sliceSurvivors_of_isNice` takes it as a hypothesis. (Half T's branch has
  `mem_unitTops_slice_of_isNice` and `mem_probesOf_of_isNice`, which look like exactly that; not checked by me.)
- Sortedness of the parent list by `r` (`mergeSort`): not needed by any theorem; not proved.
- The Rust's incremental `r², r³ mod b^k`: not in the model (step 1), so no lemma.
- L11 as a whole (exactness of survivors): only my half's converse parts are proved (`mem_bottomsSorted_iff`,
  `mem_parents_iff`, `kid_of_mem_kidsOf`, `parents_nodup`).

## Model–Rust disagreements found

**None.** Every lemma held for the model as written; no definition needed a change. **No change proposed to a shared
definition.** No new fixture: each lemma's natural mutant is already caught by the step-1 tables — `child_mask`
without `e2 ≠ e3` and the exemption ⌈⌉→⌊⌋ (M21, caught at base 13 by `checked`) and the prefilter without `mhi` are
recorded as caught in STEP1-NOTES; the parent lists are compared whole at (2,5)/(1,4) and pointwise at (4,10); the
child masks on 1,600 + 600 samples; the survivor pairing on all 9,411 small-base slices.

## What L10 needs from this half

1. `mem_sliceSurvivors_of_isNice`, with: `2 ≤ sh.k` (from `Shape.Fits`: `k > k1 > q0 ≥ 0`); `sh.k ≤ numDigits (n²)`,
   `≤ numDigits (n³)` (Half T, L2); `t ∈ probesOf ..` at `n`'s class and unit digit, `t.h = n div b^k`,
   `t.lo ≤ n ≤ t.hi` (Half T, L4(iii) + L6). The unit argument is written `slice + digit_{k−1} n · b^(k−1−f0)`;
   `unit_eq_slice_add` (here) or Half T's `unit_split` converts from `n div b^f0 mod b^(k−f0)`.
2. `midPrefilter_of_mem_unitTops` (with `mem_of_mem_probesOf`) for the `pass` filter of `searchField`.
3. The slice: `Coord.mem_fieldSlices_iff` (step 1) puts `n`'s slice in `fieldSlices`; then `finalCheck` = `IsNice`.
4. Name clash to watch at the merge: both halves are in namespace `NiceMidOut`. I renamed my
   `highDigit_of_mem_certDigits` (Half T has one with that name, 06:02 push) to `certDigits_mem_highDigit`; at my last
   check (see Status) no other name was shared. Half T's `highDigit_of_mem_unitTops` overlaps in content with my
   `cert_of_mem_unitTops` + `certDigits_mem_highDigit` (harmless duplicates).

## Build times and environment

- Box setup (elan, clone of the fork's `lean/midout`, `lake exe cache get` 8,690 files, `lake build NiceMidOut`):
  ≈ 8 min, 05:52–06:00 UTC. The earlier library builds from source in seconds per module.
- Each new file checked with `lake env lean <file>`: 7–15 s; `lake build --wfail` (whole project, incremental): < 1 min.
- `lake build` has no `-j` option ("unknown short option '-j'"); I capped the builds at 10 CPUs with `taskset -c 0-9`.
  Memory: the box showed 14–20 GB used of 31 by both halves; my builds were small.
- One slip: an `ssh` command without `ELAN_HOME=/work/bottoms/.elan` made `lake` download the Lean toolchain into
  `/root/.elan` (shared home), not into my directory; harmless, left in place, all later commands set `ELAN_HOME`.
- Conformance (`lake exe conformance`, compiling every imported module to C on the box): see Status.

## Status

Head `55a09ef0` on `fork/lean/midout-bottoms` (7 ordinary commits on `4934b0ca`), pushed 06:25 UTC, green:
https://github.com/wasabipesto-bot/nice/actions/runs/45124449585 (both jobs success: fixtures regenerate; `lake build
--wfail`, conformance, axioms). On the box before the push, with files byte-identical to the commit (SHA-256 compared):
`lake build --wfail` ok, axiom check **128 theorems, standard axioms only** (83 before), `lake exe conformance`
**81,484 checks, all equal**. First conformance build on the box (C compilation of every imported module, shared
CPU) ≈ 17 min (06:01–06:18); later runs about a minute; CI run ≈ 14 min in all. Name clashes with Half T's branch
(`fork/lean/midout-tops` at `38a7d77f`, 06:39) rechecked: none. No pull request, nothing to `origin`; box left idle
(no process of mine running; `/work/bottoms` holds the clone and `.lake`).

## The end-to-end theorem (L10), on the merged `lean/midout`

*Added 06:45–07:30 UTC. Base: the merged head `75ac981d` (Half T `38a7d77f` + this half). Work in
`~/projects/nice/.worktrees/lean-midout` on ivory, builds in a fresh clone under `/work/merged` on the box.*

**The merge itself (step 1).** `75ac981d` built as it was: `lake build --wfail` ok, axiom check 183 theorems
(standard axioms only), conformance 81,484 checks all equal. Nothing broke; no fix was needed (the one clashing name
had already been renamed on my side, `certDigits_mem_highDigit`).

**File** `lean-midout/NiceMidOut/EndToEnd.lean` (new), plus one import line and `lean-midout/README.md`. Commit
`5eb715f3`.

### Completeness

```lean
theorem searchField_complete {c : Coord} {sh : Shape} {vs vz t0 t1 : ℕ} (hc : c.Valid)
    (hfit : sh.Fits c) (hf : c.fieldDigits vs vz = some (t0, t1)) :
    ∃ o, searchField c sh vs vz = some o ∧
      ∀ n, IsNice c.b n → vs ≤ c.vOfN n → c.vOfN n < vs + vz → n ∈ o.nice
```
In words: for a valid coordinate, a shape that fits it and a field the model's own `fieldDigits` accepts (`some`
exactly when the field is non-empty, inside `[lo, vEnd)` and whole quanta), `searchField` returns an outcome, and
every nice `n` whose renumbered value `v(n)` lies in `[vs, vs + vz)` is in the outcome's list of nice numbers.

```lean
theorem sliceRun_complete {c : Coord} {sh : Shape} {vs vz t0 t1 n : ℕ} (hc : c.Valid)
    (hfit : sh.Fits c) (hf : c.fieldDigits vs vz = some (t0, t1)) (h : IsNice c.b n)
    (hv1 : vs ≤ c.vOfN n) (hv2 : c.vOfN n < vs + vz) :
    ∃ pip ∈ fieldSlices c sh vs vz,
      (digit c.b n (sh.k - 1), n, true) ∈ (sliceRun c.b c.lo c.hi sh pip).surv
```
In words: the same `n` is reported, with prefilter verdict `true`, by the run form `sliceRun` (the form the
fixtures compare with the Rust, survivor for survivor in order) of its slice, and that slice is one of the field's
slices (through `sliceRun_surv_perm`).

### Soundness

```lean
theorem searchField_sound {c : Coord} {sh : Shape} {vs vz : ℕ} {o : FieldOutcome} {n : ℕ}
    (hc : c.Valid) (ho : searchField c sh vs vz = some o) (hn : n ∈ o.nice) :
    IsNice c.b n ∧ vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz
```
In words: everything `searchField` returns is nice and has `v(n)` in the field. (The shape's fit and the field's
acceptance come from `searchField` returning `some`.) Supporting: `survivor_mem_field` — every survivor of every
slice of the field is in `[lo, hi)` with `v` in the field, whether or not it passes the prefilter or is nice.

**Not proved: "appears once".** `o.nice` has no repeats would need each nice n to be a survivor once (the tops'
side of L11: no top listed twice per probe, one probe per root); `count_probesOf_of_isNice` and `parents_nodup` are
pieces of it, the rest is not cheap. Not attempted.

### Hypotheses, against what the constructors give

- `c.Valid` is exactly what `Coord.withDigits` guarantees (`Coord.valid_of_withDigits`, step 1); the corollaries
  `searchField_complete_of_withDigits` and `searchField_sound_of_withDigits` take `Coord.withDigits b k0 k1 q0 =
  some c` instead.
- `sh.Fits c` is the model's `Shape::fits`; `searchField` itself refuses a shape that does not fit.
- `c.fieldDigits vs vz = some (t0, t1)` is the model's own field function; `searchField` refuses exactly the fields
  where it is `none`.
- **No other hypothesis was needed**: none on the base beyond `Valid` (3 ≤ b ≤ 128), none at the range's ends,
  at clipped tops or at the prefilter's exemption. One edge met and handled inside the proof: at base 3 the range
  `[2, 2)` is empty yet `Coord.Valid` can hold (L = numDigits 1 = 1, so k1 = 1); `unitTops_prefix` assumes
  `lo < hi`, so the soundness proof derives `lo < hi` from the existence of a listed top (`lo ≤ t.lo ≤ t.hi ≤
  hi − 1`) and `hi ≥ 2` (`Coord.two_le_hi`). No disagreement with the Rust; no statement turned out false.

### How it is composed

Completeness: `mem_range_of_isNice` (n in range) → `Coord.le_numDigits_pow` (k digits) →
`Coord.mem_fieldSlices_iff` (n's slice is a field slice) → `probed_top_of_isNice` (n's top among the probes of
its class and unit digit) → `mem_sliceSurvivors_of_isNice` (parent, child, disjoint masks, interval) →
`midPrefilter_of_mem_unitTops` (passes) → `finalCheck_iff` → membership in the sorted list. Soundness:
`finalCheck_iff` (nice) and `survivor_mem_field` (`Shape.mem_slicesOf_iff` and `Coord.fieldDigits_le` bound the
slice, `mem_unitTops`/`mem_unitLeads` give `lo < hi`, `unitTops_prefix` gives the survivor's range and unit, so its
slice is the slice it was found in, then `Coord.mem_fieldSlices_iff`).

### Checks at `5eb715f3`

Box: `lake build --wfail` ok (3,050 jobs), axiom check **191 theorems, standard axioms only**, conformance
**81,484 checks, all equal**; files byte-identical (SHA-256) to the commit.

Fork CI on `5eb715f3`, green (both jobs): https://github.com/wasabipesto-bot/nice/actions/runs/45127427003. (The run
on the merge head `75ac981d` was cancelled by this push, the workflow's concurrency group; the same tree had passed
all three checks on the box first.)

### A second checker: `leanchecker`

The Lean `v4.33.1` toolchain ships `leanchecker` (the former `lean4checker`): it reads a module's compiled `.olean`
and replays its declarations through the kernel again, independently of the elaborator that produced them.
- **Per module** (`lake env leanchecker <Module>`, replaying the module's own declarations on top of its imports as
  stored): every `NiceMidOut.*` module that holds declarations — all 18 (`Coord`, `Join`, `CoordProofs`,
  `RangeProofs`, `RunProofs`, `TopsProofs`, `ClassesProofs`, `RangeDigits`, `CheckProofs`, `TopsScan`,
  `ClassesTops`, `Bottoms`, `Prefilter`, `Pairing`, `BottomsExact`, `BottomsNodup`, `BottomsKids`, `EndToEnd`) —
  exit 0 with no output, about 40 s each (mostly loading Mathlib). A missing module gives exit 1 ("Could not find
  any oleans"), so the tool does load what it is given. The root module `NiceMidOut` (imports only, no declaration)
  did not finish within 600 s and was killed (exit 137), as did a `-h` call within 60 s; it holds nothing to check,
  so I did not pursue it.
- **Fresh** (`leanchecker --fresh NiceMidOut.EndToEnd`: replays every declaration in its import closure from
  scratch, the earlier library `Nice`, Mathlib, Lean core included): **exit 0, no output**, 07:06:11–07:19:08 UTC (≈ 13 min,
  one core, ≈ 3.5 GB). So every theorem above, with everything it depends on, was accepted by a second pass of the
  kernel over the compiled files. (This checks the kernel terms, not the statements: what the statements mean is
  still to be read in the source.)

Box left idle (no process of mine running); `/work/merged` holds the clone.

## After the audit (2026-11-23, 07:52–11:00 UTC)

*On `lean/midout` from `5eb715f3`, worktree `~/projects/nice/.worktrees/lean-midout`, builds in `/work/merged` on
the box (Rust 1.100.0 installed there under `/work/merged/{rustup,cargo}` for the fixture generator). Commits
`536eda22` (B1 + A1's model change), `61d38a77` (fixtures, conformance, README), and the last one listed under
Status below.*

### B1, the whole-base statement — done (`NiceMidOut/WholeBase.lean`, new)

```lean
def Coord.WholeQuanta (c : Coord) (vs vz : ℕ) : Prop :=
  0 < vz ∧ c.lo ≤ vs ∧ vs + vz ≤ c.vEnd ∧ c.quantum ∣ vs - c.lo ∧ c.quantum ∣ vz
def Coord.Covers (c : Coord) (fs : List (ℕ × ℕ)) : Prop :=
  ∀ v, c.lo ≤ v → v < c.vEnd → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2

theorem Coord.fieldDigits_isSome_iff : (c.fieldDigits vs vz).isSome ↔ c.WholeQuanta vs vz
theorem searchField_isSome_iff : (searchField c sh vs vz).isSome ↔ sh.Fits c ∧ c.WholeQuanta vs vz
theorem searchField_complete_wq (hc : c.Valid) (hfit : sh.Fits c) (hw : c.WholeQuanta vs vz) :
    ∃ o, searchField c sh vs vz = some o ∧
      ∀ n, IsNice c.b n → vs ≤ c.vOfN n → c.vOfN n < vs + vz → n ∈ o.nice
theorem isNice_iff_mem_fields (hc : c.Valid) (hfit : sh.Fits c)
    (hw : ∀ f ∈ fs, c.WholeQuanta f.1 f.2) (hcov : c.Covers fs) (n : ℕ) :
    IsNice c.b n ↔ ∃ f ∈ fs, ∃ o, searchField c sh f.1 f.2 = some o ∧ n ∈ o.nice
theorem no_nice_of_searched (hc : c.Valid) (hcov : c.Covers fs)
    (hrun : ∀ f ∈ fs, ∃ o, searchField c sh f.1 f.2 = some o ∧ o.nice = []) :
    ∀ n, ¬ IsNice c.b n
theorem no_nice_of_searched_withDigits (hc : Coord.withDigits b k0 k1 q0 = some c)
    (hcov : c.Covers fs)
    (hrun : ∀ f ∈ fs, ∃ o, searchField c sh f.1 f.2 = some o ∧ o.nice = []) :
    ∀ n, ¬ IsNice b n
```
In words: (a) the model's field function accepts exactly the plain whole-quanta fields, so acceptance is proved, not
assumed (mutant M6 now breaks `fieldDigits_isSome_iff`, which `no_nice_of_searched` uses); completeness holds for
every such field. (b) For a valid coordinate, a fitting shape and whole-quanta fields covering `[lo, vEnd)`, n is
nice iff some field's search returns it. **The claim the project would make** is `no_nice_of_searched_withDigits`:
its only hypotheses are that the coordinate was built by `Coord.withDigits b k0 k1 q0`, that the fields cover the
coordinate's values `[lo, vEnd)`, and that each field's search returned an outcome with an empty nice list (the
shape's fit and the fields' whole quanta follow from "returned an outcome", `searchField_isSome_iff`). The tiling is
only required to *cover* (overlaps allowed): the fewest honest hypotheses.

The two tilings as instances (proved): `Coord.wholeField c = [(c.lo, c.vEnd − c.lo)]` and `Coord.quantumFields c =
(List.range (b^(k1−q0))).map (fun i => (lo + i·Q, Q))`, each with `_wholeQuanta` and `_covers`, and
`isNice_iff_mem_wholeField`, `isNice_iff_mem_quantumFields`. Helpers: `Coord.fieldDigits_of_wholeQuanta`,
`vOfN_mem_of_isNice`, `Coord.b_of_withDigits`. Nothing false found.

### A1, soundness with content — done

`Join.lean` now defines `uniqueDigits` (moved from `CheckProofs`, unchanged: distinct count of `outputDigits`, and
whether it and the total count are `b`) and `finalCheck b n := (uniqueDigits b n).2`; `searchField` filters with it.
`finalCheck_iff (hb : 2 ≤ b) : finalCheck b n = true ↔ IsNice b n` is now a theorem through
`numUniques_eq_iff_isNice` and `length_outputDigits` (it was `decide_eq_true_iff`); `uniqueDigits_snd` is restated
as `(uniqueDigits b n).2 = decide (IsNice b n)`. `searchField_sound` goes through it (its hypothesis `c.Valid` gives
`b ≥ 3`). The conformance after the change: 81,484 equal (unchanged tables).

New table `fixtures/check.json` (392 kB): `unique_digits(n, b)` (count and verdict) for 12 bases (10, 12, 13, 14, 17,
20, 25, 30, 40, 50, 64, 65), 1,580–2,033 rows each, 21,077 in all: 1,500 random n of the range; the 20 lowest and 20
highest n of the range and the 20 just below and above it; up to 400 n with count ≥ b − 2 found among 400,000 random
draws (found at bases 10–25 only: 654, 434, 444, 409, 404, 63, 2 rows at 10, 12, 13, 14, 17, 20, 25; none at 30 and
above, where such numbers are too rare to sample); at base 10 every n of [47, 100) (so 69, verdict 1, and 70, count
4, verdict 0). Conformance compares the mirror's pair `(count, verdict)` and `finalCheck` with the Rust's: 21,077
checks. Mutant M9 (also accepts 70) fails at `check b10 n 70` (by construction of the row; not rerun as a mutant).

### A2, end-to-end comparisons beyond the small bases — done in part

New table `fixtures/wide.json` (14 kB), compared by `checkWide`: whole slices through `sliceRun` (12 counters, every
survivor in order) and through the definition `sliceSurvivors` (survivors as a set), at
- base 30, coordinate (2, 4, 3), shape (2, 6): 6 slices, 8 survivors; ~25 ms per slice in the model;
- base 40, coordinate (3, 6, 4), shape (3, 8): 6 slices, 98 survivors; ~0.7 s run form + 0.2 s definition per slice;
- base 50, coordinate (4, 8, 5), shape (4, 10) (production's shape, k = L): **1 slice**, 380 survivors, 147,047
  parents, 2.9 M children. The model takes ~5 min for the run form on one such slice (312 s measured on slice 0;
  the definition 12 s), so I kept one slice; the six drawn are in the generator, five not run.
All equal. Full conformance now **102,603 checks, all equal** (~10 min on 4 box cores).

**The base-64 slice** (shape (4, 10), coordinate (4, 8, 5), t = 12345, pip = 790080; Rust single-thread 24 s:
1,042,534 parents, 33.7 M children, 1.6·10^10 pairs, 251.6 M flat probes, 11,818,511 survivors). Generator mode
`--slice64` writes `slice64.json` (counters, survivor count, an order-sensitive checksum mod 2^61 − 1), conformance
mode `--slice64` compares; the table is not committed. Outcome: **did not finish**. Started 08:32:41 UTC on 6 cores
(`taskset -c 4-9`, though the model runs on one), stopped by my watchdog at 09:18:11 (45.5 min) with no counters
produced; resident memory rose to 0.89 GB within 3 minutes and stayed there (no memory pressure). The run form is
one pure function call with no progress output, so I have no rate from inside it; by extrapolation from base 50
(312 s for a slice with 147 k parents and 2.9 M children, against 1.04 M parents, 33.7 M children and 251.6 M
probe–chunk pairs here) I judge it to need several hours [judged]. Left out of the tests, as instructed; the
`--slice64` modes of the generator and of the conformance stay committed for whoever runs it longer.

### B2, B3, B4, C1, C4 — the README

`lean-midout/README.md` rewritten: the auditor's two sentences, extended with the whole-base consequence and the
wider fixtures, as its Summary; bases 3–128 with a range; the Rust's refusals not modelled (`u128` range/overflow,
the prefilter's 2^96 assertion, mask width) — the model accepts more, harmless; the run form linked by
`sliceRun_surv_perm` only; soundness's history (by construction before, through the mirror now) and that the
substance is completeness plus "in the field"; the fixtures at 64/65 component by component and the end-to-end ones
by base; `leanchecker` per module and `--fresh` on one module, the import-only root not checked; "each number
appears once" not proved. B4 (brittleness vs dependence) is the auditor's methodological point and needs no change
in the proofs; it is not repeated in the README.

### C1 ("each nice number appears exactly once") — not attempted

It needs, per nice n: one slice across the field (`slicesOf_nodup`, `field_disjoint` exist), one class and unit,
the top listed once in its unit (no lemma yet that `unitTops` has no repeats), probed once (`count_probesOf_of_isNice`
exists), the child once (`parents_nodup` exists; `kidsOf` keeps it), and the survivor determining all of them. I
judged it at 150+ lines, not short; the time went to B1/A1/A2.

### Checks and status

- Box, on the Lean and fixture tree of `61d38a77` (README-only change after): `lake build --wfail` ok; axiom check
  **208 theorems, standard axioms only**; conformance **102,603 checks, all equal** (81,484 before + 21,077 final-check
  rows + 42 wide); the regenerated tables identical across two generator runs, and the three old tables
  byte-identical to the committed ones.
- `leanchecker`, rerun on the new tree: all 19 `NiceMidOut.*` modules with declarations rc 0 (`WholeBase` included);
  `--fresh NiceMidOut.WholeBase` rc 0 (08:46:52–09:04:13 UTC). The root module was not rerun (it did not finish
  before; it only imports).
- Fork CI, all green: `536eda22` https://github.com/wasabipesto-bot/nice/actions/runs/45135243527, `61d38a77`
  https://github.com/wasabipesto-bot/nice/actions/runs/45141353006 (the fixture job regenerated `check.json` and
  `wide.json` from the Rust and matched the checksums), head **`05747baa`**
  https://github.com/wasabipesto-bot/nice/actions/runs/45145903363.
- Tooling: `pkill -f` inside an ssh command killed its own shell once (no harm; used `kill <pid>` after); Lean's
  stdout to a file is buffered, so the conformance's timing lines needed an explicit flush.
- Box left idle: no process of mine running; `/work/merged` holds the clone, the Rust toolchain and the logs;
  `/work/review` untouched.
