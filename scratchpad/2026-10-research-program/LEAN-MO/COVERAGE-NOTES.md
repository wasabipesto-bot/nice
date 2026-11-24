# Coverage certificate for a searched base (2026-11-24)

*Fork branch `lean/midout` from `05747baa`; worktree `~/projects/nice/.worktrees/lean-midout`. Built only in the
fork's CI. Coordinator format read from `dev/mo-clean` at `eb9ef776` (`scripts/midout_coordinator.py` last changed
there in `0c45dccd`).*

## Status

- `lean/midout` head **`a37347c3`**, green: https://github.com/wasabipesto-bot/nice/actions/runs/45344607920
  (`lake build --wfail`; conformance 102,603 checks; axioms: 246 theorems, standard axioms only; the new coverage
  step; fixtures regenerate). Commits on top of `05747baa`: `0937ba28` (the check, its theorems, the executable,
  tests, scripts, CI step; run 45336473004 green), `bfae74ec` (README; the checker's timing line; run 45338131303
  green), `a37347c3` (item 5, C1: each nice number once; README). No `sorry`, no added axiom, no `native_decide`.
  The coverage theorems use `propext`, `Quot.sound` (`no_nice_of_coversB`, `no_nice_of_certOk` also
  `Classical.choice`, through the whole-base theorem).
- Mutant on `lean/scratch-cov` (`coversRaw` with `| some _ => true`, the check that the last gap `[r, vEnd)` is
  empty forgotten): the build fails in `coversRaw_sound` (`CoverRaw.lean:78`, `of_decide_eq_true hr`: `hr : true =
  true`, not `decide (e ≤ r) = true`) and in `coversRaw_complete`; run
  https://github.com/wasabipesto-bot/nice/actions/runs/45336501221 (failure, as wanted). Not merged.
- The workflow `.github/workflows/lean-midout-temporary.yml` gained one step (below); nothing else in CI changed.
- `lean/scratch-cov` (not merged anywhere): the mutant commit `e055520d`, its undoing `d04d9355`, a merge of
  `lean/midout` (`04d8037b`; **its default merge message has no Co-Authored-By trailer**, noted rather than
  rewritten since amending is not allowed), then the C1 commits that were later copied to `lean/midout`.

## Definitions and theorems

`NiceMidOut/CoverRaw.lean` (core Lean only, no Mathlib), on plain numbers:

```lean
def wqRaw (lo e q : Nat) (f : Nat × Nat) : Bool :=
  decide (0 < f.2) && decide (lo ≤ f.1) && decide (f.1 + f.2 ≤ e) &&
    (f.1 - lo) % q == 0 && f.2 % q == 0
def reach : Nat → List (Nat × Nat) → Option Nat
  | cur, [] => some cur
  | cur, f :: fs => if f.1 ≤ cur then reach (max cur (f.1 + f.2)) fs else none
def sortFields (fs : List (Nat × Nat)) : List (Nat × Nat) := fs.mergeSort fun x y => decide (x.1 ≤ y.1)
def coversRaw (lo e q : Nat) (fs : List (Nat × Nat)) : Bool :=
  fs.all (wqRaw lo e q) && match reach lo (sortFields fs) with
    | some r => decide (e ≤ r) | none => false

theorem wqRaw_iff : wqRaw lo e q f = true ↔
    0 < f.2 ∧ lo ≤ f.1 ∧ f.1 + f.2 ≤ e ∧ (f.1 - lo) % q = 0 ∧ f.2 % q = 0
theorem reach_sound : ∀ fs cur r, reach cur fs = some r →
    ∀ v, cur ≤ v → v < r → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2
theorem coversRaw_sound (h : coversRaw lo e q fs = true) :
    (∀ f ∈ fs, wqRaw lo e q f = true) ∧ ∀ v, lo ≤ v → v < e → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2
theorem reach_complete : ∀ fs cur e, fs.Pairwise (fun x y => decide (x.1 ≤ y.1) = true) →
    (∀ f ∈ fs, f.1 < e) → (∀ v, cur ≤ v → v < e → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2) →
    ∃ r, reach cur fs = some r ∧ e ≤ r
theorem coversRaw_complete (hw : ∀ f ∈ fs, wqRaw lo e q f = true)
    (hcov : ∀ v, lo ≤ v → v < e → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2) : coversRaw lo e q fs = true
```

`NiceMidOut/Coverage.lean`, for a coordinate and the executable's inputs:

```lean
def Coord.coversB (c : Coord) (fs : List (ℕ × ℕ)) : Bool := coversRaw c.lo c.vEnd c.quantum fs
theorem Coord.coversB_sound (h : c.coversB fs = true) :
    (∀ f ∈ fs, c.WholeQuanta f.1 f.2) ∧ c.Covers fs
theorem Coord.coversB_complete (hw : ∀ f ∈ fs, c.WholeQuanta f.1 f.2) (hcov : c.Covers fs) :
    c.coversB fs = true
theorem Coord.coversB_iff : c.coversB fs = true ↔ (∀ f ∈ fs, c.WholeQuanta f.1 f.2) ∧ c.Covers fs

theorem no_nice_of_coversB (hc : Coord.withDigits b k0 k1 q0 = some c) (hcov : c.coversB fs = true)
    (hrun : ∀ f ∈ fs, ∃ o, searchField c sh f.1 f.2 = some o ∧ o.nice = []) : ∀ n, ¬ IsNice b n

def certOk (b k0 k1 q0 : ℕ) (recs : List (ℕ × ℕ × ℕ)) : Bool :=
  match Coord.withDigits b k0 k1 q0 with
  | some c => c.coversB (recs.map fun r => (r.1, r.2.1)) && recs.all fun r => r.2.2 == 0
  | none => false
theorem no_nice_of_certOk (hok : certOk b k0 k1 q0 recs = true)
    (hrec : ∀ c, Coord.withDigits b k0 k1 q0 = some c →
      ∀ r ∈ recs, ∃ o, searchField c sh r.1 r.2.1 = some o ∧ o.nice.length = r.2.2) :
    ∀ n, ¬ IsNice b n
```

`no_nice_of_coversB` is `no_nice_of_searched_withDigits` with `(coversB_sound hcov).2` for `Covers`.
`no_nice_of_certOk` is the statement on the checker's own inputs (base, digits, the records
`(range_start, range_size, nice_count)`): if the checker says yes and each record's field, searched with one shape
`sh`, returned an outcome with as many nice numbers as recorded (so none, since `certOk` demands every count 0),
base `b` has no nice number.

**Overlaps and duplicates are allowed.** The whole-base theorem needs only `Covers` (every value in some field);
a value searched twice cannot hide a nice number. Refusing overlaps would add a hypothesis nothing uses and
make the check reject a coordinator record in which a field was (legitimately) reissued and searched twice.
The checker prints the number of overlapping fields as a diagnostic.

**Order.** `reach_sound` holds for any order; sorting by start (stable merge sort) is only what makes the check
succeed on any covering list (`coversRaw_complete`). The cost is one sort and one pass: O(n log n).

## The executable

```
lake exe coverage BASE K0 K1 Q0 FILE      # FILE: lines `range_start range_size nice_count`, - for stdin
python3 scripts/coverage_fields.py submissions.jsonl fields.txt
```

- `scripts/coverage_fields.py` (standard library) takes the coordinator's `submissions.jsonl` and writes one line
  per submission whose `"accepted"` is exactly `true`; every other record is skipped (counted on stderr). Columns:
  `work.range_start`, `work.range_end − work.range_start`, `len(submission.nice_numbers)`. **The second column is
  the field's length in v, not the coordinator's `range_size`**, which (per `common/examples/midout_fields.rs`)
  counts the numbers n of the field. Every entry of `nice_numbers` counts (a niceonly client lists only nice
  numbers; entries whose `num_uniques` is not the base are reported on stderr and still make the count non-zero,
  so the checker errs towards "no"). All accepted records must share one base and one coordinate id
  `midout:K0,K1,Q0`; the script writes them in a comment line and prints the `lake exe coverage` command.
- `coverage` prints: the coordinate (accepted or refused; `lo`, `vEnd`, quantum, number of quanta); whether every
  field is whole quanta (count and first offender); the first gap and the number of overlapping fields
  (diagnostics, not proved); whether `Coord.coversB` holds; how many fields report a nice number; the check time;
  and the verdict. Exit 0 exactly when `certOk BASE K0 K1 Q0 records` is true (the proved function decides; the
  diagnostics do not), 1 for no, 2 for bad arguments or input.
- Its "yes" line: *"YES (certOk): if each listed field's search really returned what is recorded, then by
  no_nice_of_searched_withDigits (through no_nice_of_certOk) base b has no nice number. Not checked: that the
  searches ran, or ran correctly (the Rust or GPU code, the hardware), or that this file matches the
  coordinator's record."*

**What a "yes" does not mean.** It is a statement about the Lean model's `searchField`: "if each recorded search
returned what the model's `searchField` returns, the base has none". It does not check that any search ran, that
the Rust CPU code or a GPU kernel computes what the model computes (only fixtures tie them), that the client
submitted what it found, that the coordinator recorded it faithfully, or that the shape used was one fixed shape
(the theorem holds for any one shape; the record does not name it). "Each nice number appears exactly once in a
field's outcome" (audit note C1) is still unproved and is not needed for this "no nice number" direction.

## Tests

`lake exe coverage_tests` (`CoverageTests.lean`; 2,368 checks, green in CI). For every base 5–30 with a range and
each of the digit triples (0,1,0), (0,2,0), (0,2,1), (1,2,1), (1,3,2), (0,3,1) that `Coord.withDigits` accepts (113
coordinates), on lists built from `Coord.quantumFields`:
- accepted: the quantum fields in order; the whole coordinate as one field; reversed; a fixed shuffle (stride
  coprime to the length); every field twice; overlapping blocks of 2 and of 3 quanta together; the whole field
  plus a duplicate quantum;
- refused: the empty list; the first field dropped (gap at the start); the last dropped (gap at the end), also
  shuffled; the middle one dropped (gap in the middle), also with the list duplicated; and, added to a covering
  list, a field one longer than a quantum, a field starting before `lo`, a field at `vEnd`, an empty field, a
  field off the quantum grid (each such list covers, so only the whole-quanta check refuses it);
- `certOk`: true with all counts 0, false with one count 1, false with the last field missing; false for base 11
  (no range), for `q0 < k0` and for `k1 > L`.
- Base 64, coordinate (4, 8, 5) (lo = 2^75, vEnd = 2^76, quantum 2^57): the 262,144 single-quantum fields
  generated in the test: `coversB` true in **362 ms** (in order) and 172 ms (reversed), `certOk` 200 ms; without
  the last field, refused in 182 ms. Whole test program: 1.0 s (GitHub runner, compiled).

CI step "Coverage certificate" (also green): `scripts/coverage_testdata.py` writes a synthetic coordinator record
(one accepted submission per quantum, a rejected one for every third field), `scripts/coverage_fields.py` extracts
it, `coverage` checks it, and the exit code is compared: base 10 (0,2,1) complete (exit 0); first, fifth and last
field present only as a *rejected* submission (exit 1: the script really takes accepted ones only); one field
reporting a nice number (exit 1); base 20 (1,3,2) complete (0) and without its last field (1). **Base 64, 262,144
accepted records** (153 MB jsonl): extraction 1.9 s; `coverage 64 4 8 5`: **2.6 s in all, of which reading and
parsing the 262,146-line file 2.0 s and the decision `certOk` 207 ms**, exit 0; without the last field exit 1
(2.6 s); the same file under (4, 8, 6) (quantum 2^63, 4,096 quanta) exit 1, every field not whole quanta.

Example output (base 64, complete):
```
base 64, coordinate digits (k0, k1, q0) = (4, 8, 5), 262144 fields listed (read and parsed in 1985 ms)
certOk: true
coordinate: accepted; values [lo, vEnd) = [37778931862957161709568, 75557863725914323419136), quantum 144115188075855872, 262144 quanta
whole quanta: every field
gaps: none (0 fields overlap others; overlaps are allowed)
covers [lo, vEnd) (Coord.coversB): yes
fields reporting a nice number: 0 (0 nice numbers in all)
check time (certOk): 207 ms
YES (certOk): if each listed field's search really returned what is recorded, then by no_nice_of_searched_withDigits (through no_nice_of_certOk) base 64 has no nice number. Not checked: that the searches ran, or ran correctly (the Rust or GPU code, the hardware), or that this file matches the coordinator's record.
```
Without the last field the gap line reads `gaps: first uncovered values [75557719610726247563264,
75557863725914323419136)` and the verdict `NO (certOk is false): ...`.

Not tested: a real coordinator run (no rented machine, and the production API is never contacted); the synthetic
records follow the format of `midout_coordinator.py` at `eb9ef776` field by field, but were not produced by it.

## Item 5: each nice number exactly once (the audit's C1)

Started at 06:20 (everything above green). `NiceMidOut/Once.lean` (with list lemmas in the core-only
`NiceMidOut/NodupMap.lean`):

```lean
theorem searchField_nice_nodup (hc : c.Valid) (ho : searchField c sh vs vz = some o) : o.nice.Nodup
theorem searchField_count_eq_one (hc : c.Valid) (hfit : sh.Fits c) (hw : c.WholeQuanta vs vz)
    (h : IsNice c.b n) (hv1 : vs ≤ c.vOfN n) (hv2 : c.vOfN n < vs + vz) :
    ∃ o, searchField c sh vs vz = some o ∧ o.nice.count n = 1
theorem sliceSurvivors_nodup_n (hb : 2 ≤ b) (hk : 1 ≤ sh.k) :
    ((sliceSurvivors b lo hi sh pip).map fun s => s.2.1).Nodup
```

The argument: a survivor of slice `pip` at class `c`, unit digit `d`, top `t` and child `x` has
`n = t.h·b^k + d·b^(k−1) + x.1` with `x.1 = p.r < b^(k−1)` and `d < b` (`split_read`), so `n` gives back `x.1`, `d`,
`t.h` and the class `x.1 mod (b − 1)`; a top of a unit is determined by its lead (`top_eq_of_h`), a parent by its `r`
(`parent_eq_of_r`) and so its child (`kid_eq_of_fst`); the lists walked have no repeats (`unitLeads_nodup`,
`unitTops_nodup`, `probesOf_nodup` through `root_unique`, `kidsOf_nodup`, `fieldSlices_nodup`), and a survivor's
digits `[f0, k − 1)` are its slice (`survivor_slice`, the step inside `survivor_mem_field`). Two generic lemmas
(`nodup_map_flatMap`, `nodup_map_filterMap`: the values of a flatMap over a list without repeats have none when each
part's have none and a value determines its part) carry it level by level. The nice list is a sublist of the
survivors' numbers (two filters) up to the merge sort's permutation.

**Status: proved, green on `lean/midout` (`a37347c3`, run 45344607920).** Developed on `lean/scratch-cov` first
(runs 45341333959: failed on two missing imports only; 45341772561 and 45343070880: green). The audit's C2 (the Rust collects from
threads and sorts unstably) stays unmodelled; with no repeats, two sorted lists with the same members are equal, so
it reduces to the Rust returning the same set, which this does not prove.

## How it was built

ivory cannot build Mathlib, so everything was compiled in the fork's CI. The core-only file `CoverRaw.lean` and
the executables' logic were also checked on ivory with the toolchain's plain `lean` (no `lake`; no Mathlib) against
a local stub of the coordinate (in the scratchpad, never committed), which caught three mistakes before the
first push. For item 5 the same was done with a larger stub (`Top`, `Parent`, `unitLeads`, `unitTops`, `probesOf`,
`kidsOf`, `sliceSurvivors`, `searchField` copied verbatim; the library lemmas they use stated as stub axioms): the
whole `Once.lean` body type-checked there before its first CI run, whose only errors were two missing imports.
Mathlib-only tactics (`split_ifs`, `ring`) were avoided in the new files so that the stub check applies.

## Tooling note

At 06:21 a command of mine on the scratch worktree chained `git revert` with `git commit --amend` (a slip: amending
is not allowed). The tooling denied the whole command; nothing ran, nothing was amended. The revert was then made as
an ordinary commit (`d04d9355`).
