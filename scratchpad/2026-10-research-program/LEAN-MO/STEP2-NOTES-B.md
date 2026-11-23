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
