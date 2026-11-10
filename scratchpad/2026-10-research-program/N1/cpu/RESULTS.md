# N1 CPU: the join at the transversal shape on the CPU (2026-11-10, ivory)

Branch `exp/n1-transversal-cpu` on the fork (wasabipesto-bot/nice) at a32d78c, from `origin/main` c0c357a; worktree
`~/projects/nice/.worktrees/n1-transversal-cpu`. Raw output in `raw/`, the summariser is `analyze.py`
(`python3 analyze.py raw/runB.log` etc.; the `raw/summary_*.txt` files are its output).

**Provenance tags used below.** **[M]** measured on ivory today (counts are exact counts over the units run;
times are wall seconds of one thread under `nice -n 19`, Zen 2 EPYC-Rome VM, AVX2 path); **[D]** derived
from measured numbers by arithmetic stated next to it; **[MC]** the director's Monte Carlo (`mc_b6x.txt`).

## 0. Headline

| CPU s per admissible n, one thread | b60 | b62 | b64 |
|---|---|---|---|
| today's shape (f0 3, k 6, p 2), mid-base production field [M] | 3.48e-11 | 1.90e-11 | the mid-base field is empty; @0.55: 1.20e-11 |
| today's shape, mean of 10 field locations [M, 1 round] | 2.25e-11 | 1.55e-11 | 6.81e-12 |
| (L − 4, 9, 5), exact bottom extension [M] | 1.25e-11 | 4.87e-12 | 3.52e-12 |
| (L − 4, 9, 5), affine bottom extension [M] | 7.62e-12 | 3.52e-12 | 3.62e-12 |
| (L − 4, 9, 4) = 4-digit unit, 5th digit as key, affine (two-level) [M] | 3.46e-12 | 2.65e-12 | ≈ 3.53e-12 [D: affine − its extension] |
| **ratio** new/today (field above), exact ext. [M] (3 rounds: median, min–max) | 0.357 (0.357–0.358) **×2.80** | 0.256 (0.256–0.257) **×3.90** | 0.293 (0.288–0.295) **×3.41** |
| **ratio**, affine ext. [M] | 0.219 (0.219–0.220) **×4.57** | 0.185 (0.184–0.189) **×5.41** | 0.299 (0.291–0.302) ×3.35 |
| **ratio**, two-level unit [M, 2 rounds] | 0.101 (0.100–0.102) **×9.90** | 0.139 (0.138–0.140) **×7.18** | ≈ ×3.4 [D] |
| ratio, affine (L − 4, 9, 5) vs today's 10-field mean [M, 1 round] | ×2.97 | ×4.06 | ×1.84 |
| ratio, two-level vs today's 10-field mean [M/D: two runs] | ×6.5 | ×5.9 | ≈ ×1.9 [D] |

**In one paragraph.** The CPU join runs (L − 4, 9, 5) on a base's whole range one partition value at a time
with small, experiment-only changes, and is exact: unit by unit equal to the reference at every partition
value of b10–b34 (and brute force to b30, 69 at b10), on 30,000 random b40 units, 20 b54 and 6 b62
production-shape units. Per admissible n it does the AND pairs the Monte Carlo predicts (−5 %, −5 %, +20 %)
with P_T and P_B within 3 %, ÷14–18 the AND survivors, ÷25–31 the full checks and ÷14–20 the top tests of
today's shape (base averages). On one Zen 2 core it is **×2.8 (b60) / ×3.9 (b62) / ×3.4 (b64) faster than
today's shape on a production field with the code as it is**, ×4.6 / ×5.4 / ×3.4 with an affine bottom
extension, and **×9.9 / ×7.2** at b60/b62 when the unit is four partition digits with the fifth as the key
(the bottom extension then shared by 62 values). Against today's cost averaged over field locations (which
varies ×2.7 between fields and is 0 on empty ones) the ratios are lower: ×3.0 / ×4.1 / ×1.8 (affine, 5-digit
unit) and ×6.5 / ×5.9 / ≈×1.9 (two-level). Most of the CPU gain is a cheaper AND (long class lists, few
survivors: 0.25–0.43 ns against 1.0–1.15 ns), not fewer ANDs; the new cost is the bottom extension, which the
two-level unit removes. b64 is the weak base: today's shape skips its empty fields and prunes by field, so
the new shape does twice today's mean AND pairs there.

## 1. What had to change

Diff against c0c357a: `common/src/overlap_join.rs` +90 −5, `common/src/cpu_join.rs` +299 −6 (both include
docs), and a new test-only module `common/src/cpu_join/n1.rs` (567 lines: exactness tests, count/timing
drivers). Production shapes run the same code paths and produce the same results; their tests pass
(below). The new shape is reachable only through explicit experiment constructors.

- **Shape gate.** `JoinParams::supported_experiment` (GPU limits dropped: `b^k < 2^63` instead of `2^40`, no
  `b^(3k) < 2^128`, `o − p ≤ 1` kept) and `FieldSetup::new_experiment` / `CpuJoin::new_experiment`
  (`FieldSetup::new` and `CpuJoin::new` are unchanged wrappers of the same body with the old gate).
  `for_length` is untouched, so the client and the GPU never see the new shape.
- **Prefilter depth.** The `P mod b^(k2 − f0) < 2^32` condition (and `k2 ≤ 12`) is a GPU constraint; under
  the experiment gate only `b^mid < 2^32` is required, so `mid = 2`, `k2 = 11` at k 9 and the CPU's
  fixed-point (`lean`) prefilter applies unchanged (`dm = ⌊P/b^(k−f0)⌋ mod b^mid` was already computed in
  u128, then narrowed — fine).
- **9-digit residues.** `Base::bot_dfs` (reference bottom list) now takes `r³ mod b^(j+1)` = `(r² mod
  b^(j+1))·r`, the same digit, since `r³` passes u128 at k 9 (same results for every shape).
  `CpuJoin::extend` computes `r³` in the 256-bit `W4` when `b^(k−1)` cubed passes u128 (`wide`, a flag set
  at setup; production shapes keep the u128 path).
- **Not needed after all.** The key-level code (`o − p = 1`) already handles `o = p` (keyspace 1, the last
  bottom digit is the partition's last digit); `TopFdSetup` takes the step `h = b^(k − f0) = b^5` and its
  `fits` checks pass at b54–b64 (`fd` is used, and stepped tops equal divided tops, §2);
  `CPU_SLICE_PREFIXES` does not bind (the whole-base top layer at depth t − p = 4 has 5.2e5 prefixes at b62,
  1.6e6 at b64).
- **Instrumentation (experiment).** `run_partition_counted` adds operation counts and phase times
  (`JoinCounts`; production `run` passes `None`); `SurvMode` (`Full`/`NoCheck`/`AndOnly`, a pub field,
  `Full` by default) lets the timing split the survivor path by difference; in `AndOnly` the record
  collects the AND survivors (used by the exactness tests).
- **Affine bottom extension (task 5, experiment).** `enable_affine_extend` + `extend_affine` (§5).

Note on the full check: today's shape calls the seeded `get_is_nice_with_known_lsd(n, b, 3, mask)`; at f0 = 4
the CPU join falls back to plain `get_is_nice` (no seeded variant for 4 known digits). The check is 1–3 %
of the new shape's time, so this does not move the ratio.

## 2. Exactness

**(a) Existing tests.** `cargo test --release -p nice_common -- overlap_join cpu_join cpu_top_fd`:
31 passed, 0 failed (the ignored ones are opt-in, including the N1 tests) — this includes
`cpu_join_matches_the_reference_on_the_test_windows` (`check_partitions` on every window),
`stepped_tops_equal_divided_tops_on_production_fields`, `every_scan_finds_the_same_pairs`,
`reference_join_equals_brute_force`, `reference_join_finds_69_in_base_10`, the field-prune and slice tests
(`raw/existing_tests.log`). The whole `nice_common` suite (release, no GPU features): 188 passed, 0 failed,
11 ignored (`raw/full_suite.log`).
The opt-in `cpu_join_matches_the_reference_on_production_fields` with `NICE_TEST_CPU_JOIN_REF=24` (24
partitions of each production-size field b42/b50/b57/b60/b62/b64 at today's shape against the reference:
join survivors, prefilter survivors, hits) passes (`raw/prod_fields_ref.log`). Production shapes take
exactly the old arithmetic (the `wide` and affine paths are off for them); the only new work on their hot
path is a `None` check per key and per class scan, and a mode compare per AND survivor. `cargo clippy` was
not run on the experiment branch.

**(b) Whole-base units at small bases** (`n1_whole_base_units_are_exact_at_small_bases`,
`raw/exact_small.log`). The field is the base's whole range, the unit one partition value (no key level,
p = o), shape = largest k (L − 1) with f0 = 2 where the length allows it (f0 1 at L = 3, f0 0 at b10, f0 3
at b33/b34 to keep the unit count down). For **every** partition value: the fast CPU join's AND-survivor
set, prefilter-survivor set and hits equal the reference `join_range`'s at the same shape (prefilter by
its definition, `mid_mirror_wide`), and stepped tops equal divided tops. Then the union over units:
equal to brute force over every n of the base (AND survivors by their definition, and the nice numbers)
for b ≤ 30, and the hits equal the reference over the whole base at a contiguous "today-kind" shape
(whose own survivors also equal brute force at b ≤ 30).

| base | whole-base shape (t, k, p) | units | AND survivors | prefilter surv. | hits | today-kind shape: survivors | brute force |
|---|---|---|---|---|---|---|---|
| b10 | (2, 1, 1) | 10 | 1 | 1 | [69] | (2, 1, 0): 1 | yes |
| b12 | (2, 2, 1) | 12 | 4 | 0 | [] | (2, 2, 0): 4 | yes |
| b14 | (2, 2, 1) | 14 | 16 | 0 | [] | (2, 2, 1): 16 | yes |
| b17 | (2, 3, 1) | 17 | 88 | 7 | [] | (3, 2, 1): 81 | yes |
| b18 | (2, 3, 1) | 18 | 124 | 12 | [] | (3, 2, 1): 117 | yes |
| b20 | (2, 3, 1) | 20 | 1,599 | 135 | [] | (3, 2, 1): 1,496 | yes |
| b22 | (3, 4, 2) | 484 | 2,398 | 80 | [] | (3, 3, 1): 7,593 | yes |
| b24 | (3, 4, 2) | 576 | 1,864 | 63 | [] | (3, 3, 1): 5,887 | yes |
| b25 | (3, 4, 2) | 625 | 51,324 | 2,303 | [] | (3, 3, 1): 152,498 | yes |
| b28 | (4, 5, 3) | 21,952 | 28,589 | 709 | [] | (4, 3, 1): 354,291 | yes |
| b29 | (4, 5, 3) | 24,389 | 26,163 | 617 | [] | (4, 3, 1): 345,824 | yes |
| b30 | (4, 5, 3) | 27,000 | 171,278 | 5,136 | [] | (4, 3, 1): 1,918,211 | yes |
| b33 | (4, 6, 3) | 35,937 | 1,802,528 | 57,515 | [] | (5, 4, 2): 6,737,763 | reference only |
| b34 | (4, 6, 3) | 39,304 | 2,326,021 | 73,783 | [] | (5, 4, 2): 8,761,127 | reference only |
| b40 | (5, 7, 4) | 30,000 random of 2,560,000 | 2,951,168 | 84,833 | [] | — | reference only |

b35 has no digit-sum root (no candidates at all), so b33/b34 stand in for it. b40 unit by unit only (every
unit would take ~9 h; `raw/exact_b40_30k.log`). b10 finds 69 as a whole-base unit (its last digit).

**(c) Production-sized units.** b54 (L = 11), shape (7, 9, 5) = (L − 4, 9, 5), whole range, 20 random
partition values (`n1_transversal_units_match_the_reference`, `raw/exact_c_b54.log`): fast join =
reference on every unit — 1,788 tops, 55,757 AND survivors, 1,630 prefilter survivors (sets equal, not
just counts), 0 hits; stepped tops = divided tops; `wide` (256-bit r³), `lean` (fixed-point prefilter at
k2 = 11) and `fd` (stepped certificates) all on. The same at **b62**, (9, 9, 5), 6 random units
(`raw/exact_c_b62.log`): 519,940 tops, 28,446,950 AND survivors, 1,021,153 prefilter survivors, sets equal
to the reference's on every unit.

## 3. Counts per admissible n [M], against the Monte Carlo

"Admissible" = n in a digit-sum root class (the brief's definition): a unit's admissible count is its
range × roots/(b − 1) / b^p (b60 7.07e10 per whole-base unit, b62 3.42e11, b64 4.47e12; today's
partitions of the field's CPU slice 0: b60 9.42e10, b62 1.31e11, b64 3.10e11). Per-base admissible:
b60 5.49e19, b62 3.13e20, b64 4.80e21.

Sources: **new** = (L − 4, 9, 5), whole range, random partition values (b60, b62: run A, 24 units; b64:
25 units, 17 of run A and 8 of run B64 — they agree to 0.1 %). **today mid** = today's shape on the CPU
slice 0 of a mid-base production field, 24 live partitions (run A; 1e16 at b60 = one slice, 1e17 at b62 →
slice 0 of 7, [7.9977e21, +1.54e16)). At b64 the mid-base 1e16 field is **empty** (its field certificate
repeats a digit: no top survives the layer; the 18 units run did zero work), so b64's "today mid" column is
the field at 0.55 of the range (run E64, 24 units, counts; its first 8 are run B64's timed units). **today mean** = 10 production fields at 0.05, 0.15, …, 0.95
of the range, 3 random live partitions each (run C; at b62 2 of the 10 fields and at b64 4 of the 10 are
empty and count as zero work, as the client sees them). The counts of the new shape barely vary between
units (CV < 1 %), today's vary by ±50 % between fields.

Rows: top tests = partition-extended top-layer slots certified; tops = certified; bottom candidates =
bottom-list residues mod b^f0 the extension visits (`bp_r`, after today's field prune); extended = those
that survive the fixed partition digits below k − 1; valid bottoms = listed bottoms (all k digits valid;
today's after its field prune); AND pairs = ANDs performed; prefilter survivors are the full checks (the
code checks exactly the prefilter's survivors). P_T = tops × b^f0 / all n of the unit; P_B = valid
bottoms / b^(k − p).

**b60** (L = 12; new = (8, 9, 5), today = (9, 6, 2))

| per admissible n | new | MC new | today mid (1e16) | today mean (10 fields) | MC today |
|---|---|---|---|---|---|
| top tests | 2.03e-6 | | 5.62e-5 | 4.14e-5 | |
| certified tops (P_T) | 4.08e-7 (0.179) | (0.183) −2 % | 2.03e-5 (0.149) | 1.44e-5 (0.106) | (0.104): mid **+43 %**, mean +2 % |
| bottom candidates | 9.30e-5 | | 1.08e-6 | | |
| extended (fixed digits ok) | 1.68e-5 | | 4.60e-7 | | |
| valid bottoms (P_B) | 8.84e-6 (0.0482) | (0.0482) 0 % | 1.59e-5 (0.116, pruned) | | (0.254 unpruned) |
| AND pairs | 8.63e-3 | 9.07e-3 −5 % | 1.72e-2 | 1.05e-2 | m9 1.06e-2 / m10 1.68e-2: mid **+63 %** / +2 %, mean −1 % / −38 % |
| AND survivors | 2.33e-5 | 2.67e-5 −13 % | 6.48e-4 | 3.77e-4 | 5.07e-4: mid +28 %, mean −26 % |
| prefilter survivors = full checks | 8.69e-7 | | 4.34e-5 | 2.44e-5 | |

**b62** (L = 13; new = (9, 9, 5), today = (10, 6, 2))

| per admissible n | new | MC new | today mid (1e17 s0) | today mean (10 fields) | MC today |
|---|---|---|---|---|---|
| top tests | 1.54e-6 | | 3.89e-5 | 2.90e-5 | |
| certified tops (P_T) | 2.54e-7 (0.123) | (0.127) −3 % | 1.26e-5 (0.0986) | 9.44e-6 (0.0738) | (0.0696): mid **+42 %**, mean +6 % |
| bottom candidates | 2.57e-5 | | 6.50e-7 | | |
| extended | 4.94e-6 | | 2.44e-7 | | |
| valid bottoms (P_B) | 2.66e-6 (0.0614) | (0.0608) +1 % | 8.14e-6 (0.072, pruned) | | (0.305 unpruned) |
| AND pairs | 7.56e-3 | 7.98e-3 −5 % | 7.12e-3 | 6.71e-3 | m9 6.32e-3 / m10 1.02e-2: mid +13 % / −30 %, mean +6 % / −34 % |
| AND survivors | 1.39e-5 | 2.67e-5 **−48 %** | 2.99e-4 | 2.51e-4 | 2.03e-4: mid **+47 %**, mean +23 % |
| prefilter survivors = full checks | 4.99e-7 | | 1.83e-5 | 1.55e-5 | |

**b64** (L = 13; new = (9, 9, 5), today = (10, 6, 2))

| per admissible n | new | MC new | today @0.55 (1e16) | today mean (10 fields) | MC today |
|---|---|---|---|---|---|
| top tests | 3.52e-7 | | 8.83e-6 | 5.01e-6 | |
| certified tops (P_T) | 5.17e-8 (0.110) | (0.113) −3 % | 2.76e-6 (0.092) | 1.57e-6 (0.052) | (0.062): @0.55 **+48 %**, mean −16 % |
| bottom candidates | 2.08e-6 | | 2.90e-7 | | |
| extended | 4.24e-7 | | 1.04e-7 | | |
| valid bottoms (P_B) | 2.33e-7 (0.0621) | (0.0622) 0 % | 3.50e-6 (0.065, pruned) | | (0.290 unpruned) |
| AND pairs | 6.84e-3 | 5.72e-3 +20 % | 5.95e-3 | 3.49e-3 | m9 4.45e-3 / m10 7.20e-3: @0.55 **+34 %** / −17 %, mean −22 % / **−52 %** |
| AND survivors | 1.07e-5 | 6.67e-6 **+60 %** | 2.69e-4 | 1.55e-4 | 2.07e-4: @0.55 +30 %, mean −25 % |
| prefilter survivors = full checks | 3.92e-7 | | 1.67e-5 | 9.6e-6 | |

**Flags (> 30 % off the Monte Carlo).**
- *New shape:* only the AND survivors, −48 % at b62 and +60 % at b64 (−13 % at b60). The MC has 8 (b62)
  and 2 (b64) survivor events at k 9; the measured rates rest on 5.7e7 and 3.8e8 events. Treat the MC's
  k-9 survivor column as noise; P_T, P_B and pairs of the new shape are within 5 % (b60, b62) and 20 % (b64
  pairs).
- *Today's shape:* P_T (+42 % to +48 %), AND pairs and survivors of the **mid-base** fields are off because
  P_T depends strongly on where the field sits (0.06–0.15 at b60 between neighbouring fields, 0 for a fifth
  of the b62/b64 fields). The MC's P_T is a base average, and the 10-field mean matches it (−16 % to +6 %),
  survivors within 26 %. The field-prune pair column depends on the field size relative to b^9/b^10 (slice
  0 at b62 is 1.5e16 ≈ 1.1 b^9).
- Today's valid bottoms are listed after the field prune, so P_B is not the MC's unpruned P_B (the prune
  keeps 0.21–0.45 of them, consistent with the MC's prune(m, 6) at m 9–10).

**Ratios of counts, new / today mean [D]:** AND pairs ×0.82 (b60), ×1.13 (b62), ×1.96 (b64); AND survivors
÷16, ÷18, ÷14.5; full checks ÷28, ÷31, ÷24.5; top tests ÷20, ÷19, ÷14; certified tops ÷35, ÷37, ÷30.

**Per-base totals of the new shape [D = per admissible n × admissible per base]:** b62: top tests 4.8e14,
certified tops 7.9e13, bottom-candidate visits 8.0e15 (2.57e-5 × 3.13e20; = 8.78e6 per unit × 9.16e8
units), extended 1.5e15, valid bottoms 8.3e14, AND pairs 2.36e18, AND survivors 4.3e15, full checks
1.6e14. b60: 1.1e14 / 2.2e13 / 5.1e15 / 9.2e14 / 4.9e14 / 4.7e17 / 1.3e15 / 4.8e13. b64: 1.7e15 / 2.5e14
/ 1.0e16 / 2.0e15 / 1.1e15 / 3.3e19 / 5.1e16 / 1.9e15.

## 4. Timing [M] (one thread, `nice -n 19`, ivory; CPU s per admissible n)

Each unit runs three times back to back: full, then the survivor path cut after the prefilter (`NoCheck`),
then cut after the in-range test (`AndOnly`). Phases: tops (FD advance + certificates), bottom extension
(once per unit), list (per key: advance + class listing; includes the tops' bucket sort), scan = the AND
scan with its survivor path; AND = the `AndOnly` scan (the ANDs plus the survivor call and in-range test
of every AND survivor), prefilter = `NoCheck` − `AndOnly`, check = full − `NoCheck` (differences of
separate runs, so ±1e-13 noise; small negatives at b64). Shapes interleaved unit by unit within a round.

**Run B (main A/B; 12 units per shape, 3 rounds; `raw/runB.log`, `raw/summary_runB.txt`; b64 from run B64,
8 units, 3 rounds):**

| | today (mid-base field) | new, exact extension | new, affine extension | ratio exact (median of rounds, min–max) | ratio affine |
|---|---|---|---|---|---|
| b60 | 3.48e-11 | 1.25e-11 | 7.62e-12 | 0.357 (0.357–0.358) = **×2.80** | 0.219 (0.219–0.220) = **×4.57** (×4.54–4.57) |
| b62 | 1.90e-11 | 4.87e-12 | 3.52e-12 | 0.256 (0.256–0.257) = **×3.90** | 0.185 (0.184–0.189) = **×5.41** (×5.30–5.43) |
| b64 (today @0.55) | 1.20e-11 | 3.52e-12 | 3.62e-12 | 0.293 (0.288–0.295) = **×3.41** | 0.299 (0.291–0.302) = ×3.35 |

Run A (24 units per shape, 3 rounds, exact extension only; `raw/summary_runA.txt`) agrees: b60 0.359
(×2.78, ×2.78–2.79), b62 0.260 (×3.84, ×3.83–4.00). The spread between rounds is < 3 %; between units of
one shape the CV is 1.5–4 % (7 % for b64 affine) — one outlier unit at b62 today (3.8e-11, during a build
on another core) does not move the medians.

**Against the base average of today's cost** (run C: 10 field locations × 3 partitions, one round, full
mode only; `raw/summary_runC.txt`): today's cost per admissible n varies ×2.7 between fields at b60
(1.28e-11 … 3.44e-11) and is 0 on empty fields (2/10 at b62, 4/10 at b64). Means: b60 2.25e-11, b62
1.55e-11, b64 6.81e-12. Against the affine new shape of the same run: **b60 ×2.97, b62 ×4.06, b64 ×1.84**
[M, one round; the 10-field mean has roughly ±15 % (b60/b62) to ±25 % (b64) sampling error, D]. b64's
lower ratio is today's shape skipping its empty fields and its field prune (the new shape does 2× today's
mean AND pairs there, §3).

**Phase breakdown** (run B, median of rounds; % of the unit's total):

| | tops | extension | list | AND (+ in-range) | prefilter | check | ns per AND [D] |
|---|---|---|---|---|---|---|---|
| b60 today | 7.4e-12 (21 %) | 0.07e-12 (0 %) | 0.64e-12 (2 %) | 1.71e-11 (49 %) | 3.5e-12 (10 %) | 6.0e-12 (17 %) | 0.99 |
| b60 new exact | 0.22e-12 (2 %) | 8.81e-12 (71 %) | 0.32e-12 (3 %) | 2.61e-12 (21 %) | 0.29e-12 (2 %) | 0.16e-12 (1 %) | 0.30 |
| b60 new affine | 0.22e-12 (3 %) | 4.07e-12 (53 %) | 0.31e-12 (4 %) | 2.57e-12 (34 %) | 0.31e-12 (4 %) | 0.15e-12 (2 %) | 0.30 |
| b62 today | 6.71e-12 (35 %) | 0.04e-12 (0 %) | 0.38e-12 (2 %) | 7.72e-12 (41 %) | 1.42e-12 (7 %) | 2.67e-12 (14 %) | 1.09 |
| b62 new exact | 0.17e-12 (4 %) | 2.47e-12 (51 %) | 0.09e-12 (2 %) | 1.86e-12 (38 %) | 0.15e-12 (3 %) | 0.11e-12 (2 %) | 0.25 |
| b62 new affine | 0.17e-12 (5 %) | 1.14e-12 (32 %) | 0.10e-12 (3 %) | 1.87e-12 (53 %) | 0.18e-12 (5 %) | 0.09e-12 (3 %) | 0.25 |
| b64 today @0.55 | 1.65e-12 (14 %) | 0.02e-12 (0 %) | 0.12e-12 (1 %) | 6.83e-12 (57 %) | 1.70e-12 (14 %) | 1.67e-12 (14 %) | 1.15 |
| b64 new exact | 0.04e-12 (1 %) | 0.20e-12 (6 %) | 0.01e-12 (0 %) | 2.96e-12 (84 %) | 0.39e-12 (11 %) | ~0 | 0.43 |
| b64 new affine | 0.04e-12 (1 %) | 0.09e-12 (3 %) | 0.01e-12 (0 %) | 2.93e-12 (81 %) | 0.56e-12 (15 %) | ~0 | 0.43 |

Where the CPU ratio comes from [D]: at b62 today spends 6.7e-12 on tops and 11.8e-12 on the scan; the new
shape spends 0.17e-12 on tops (÷40: ÷25 top tests, each ~35 % cheaper, 111 against 172 ns) and 2.1e-12 on the scan for
about the same number of ANDs — **a quarter of the cost per AND**: its class lists are ~15,000 bottoms
long instead of ~300 (one top's mask against a long stream, no per-class overhead) and only 0.18 % of its
ANDs survive (4.2 % today, each a ~20-cycle call). What the new shape adds is the bottom extension.

Unit sizes [M]: one (L − 4, 9, 5) unit is 1.7 s (exact) / 1.2 s (affine) at b62, 0.88 / 0.54 s at b60,
15.7 / 16.2 s at b64 (8 roots: 13× the admissible n of a b62 unit) on one Zen 2 core. Setup (whole-base
top layer at depth 4 + the bottom DFS to f0 = 4 + the FD constants) is 1.6–2.7 s once per base (+0.3–0.4 s
for the affine table), i.e. nothing.

## 5. Bottom-build cost (task 5)

**What the extension costs [M/D].** A (L − 4, 9, 5) unit extends **every** residue of the base's bottom
list (`bpre`: residues mod b^4 whose 8 low output digits are distinct; 6.57e6 at b60, 8.78e6 at b62,
9.30e6 at b64) through its four fixed digits at positions 4–7; 18–20 % survive ("extended"), and the
fifth digit (position 8) is the affine step of `list`. Measured per unit [M]: b60 0.62 s, b62 0.84 s, b64
0.89 s with the exact arithmetic (256-bit r³ and two 256-bit divisions, **95 ns per visited residue** [D]),
i.e. 71 % / 51 % / 6 % of the unit. Per base [D]: 8.0e15 visits at b62 (2.57e-5 per admissible n), of
which 1.5e15 survive — the NOTES' "1.5e15 cheap linear extensions" is the survivor count; the work is the
visits, ×5.2 more.

**Affine extension, one level [M].** `enable_affine_extend` builds, once per base, `⌊r0²/b^4⌋`,
`⌊r0³/b^4⌋` and `r0²` mod b^7 for each `bpre` residue (24 B each: 211 MB and 0.38 s at b62); a unit then
adds its fixed digits V by `⌊r²/b^4⌋ = ⌊r0²/b^4⌋ + 2·r0·V + V²·b^4` and `⌊r³/b^4⌋ = ⌊r0³/b^4⌋ + 3·r0²·V +
3·r0·V²·b^4 + V³·b^8` (mod b^7), two 128-bit reductions per residue, and reads positions 4..10 off the
result. Rows identical to the exact extension (`n1_affine_extension_equals_the_exact_one`: 40 random
units at each of b54, b60, b62, b64, 2.1e8 rows, every column equal; `raw/affine_equal.log`). Cost **44 ns
per visit** [D] (b60 0.29 s, b62 0.39 s, b64 0.42 s per unit): the extension falls from 71 → 53 % (b60) and
51 → 32 % (b62) of the unit, and the ratio to today improves ×2.80 → ×4.57 (b60) and ×3.90 → ×5.41 (b62).
At b64 (6 % → 3 %) it does not matter.

**Two-level: units that share the extension [M].** The unit (L − 4, 9, **4**) — four partition digits
(positions 4–7), the fifth (position 8) as the existing key level inside the unit — is exactly 62 (b62)
of the 5-digit units in one, sharing one extension. Same certificates, so the same counts of tops, valid
bottoms, pairs and survivors (§3, checked: b60 identical to 4 digits); the code needed nothing new
(`o − p = 1` is today's key level). Run D (`raw/summary_runD60.txt`, 4 units × 2 rounds, full mode, phases
from the counters):

| b60 | total | tops | extension | list | scan | ratio to today mid | to today mean (run C) |
|---|---|---|---|---|---|---|---|
| (8, 9, 5) affine | 7.55e-12 | 0.22e-12 | 4.03e-12 (53 %) | 0.30e-12 | 2.99e-12 | 0.221 ×4.53 | ×2.97 |
| (8, 9, 4) key level, affine | **3.46e-12** | 0.20e-12 | **0.07e-12 (2 %)** | 0.18e-12 | 3.01e-12 | **0.101 ×9.90** (×9.79–10.01) | **×6.5** |
| today (9, 6, 2) | 3.42e-11 | 7.27e-12 | 0.07e-12 | 0.62e-12 | 2.61e-11 | 1 | |

| b62 | total | tops | extension | list | scan | ratio to today mid | to today mean (run C) |
|---|---|---|---|---|---|---|---|
| (9, 9, 5) affine | 3.49e-12 | 0.17e-12 | 1.16e-12 (33 %) | 0.10e-12 | 2.06e-12 | 0.183 ×5.46 | ×4.06 (run C) |
| (9, 9, 4) key level, affine | **2.65e-12** | 0.16e-12 | **0.02e-12 (1 %)** | 0.05e-12 | 2.41e-12 | **0.139 ×7.18** (×7.12–7.24) | **×5.9** |
| today (10, 6, 2) | 1.90e-11 | 6.74e-12 | 0.04e-12 | 0.38e-12 | 1.18e-11 | 1 | |

(b62: run D62, 3 units × 2 rounds, `raw/summary_runD62.txt`; a key-level unit there is 2.1e13 admissible n,
56 s on one core; its top layer at depth 5 is 2.6e7 prefixes, 2 GB RSS, run under `ulimit -v 3.4 GB`.
At b62 the key-level scan is 17 % slower per admissible n than the 5-digit unit's (2.41e-12 against
2.06e-12; same ANDs and the same class lists); I have not found why (b60 shows no such difference). b64's key-level top layer (~1e8 prefixes) does not fit ivory; its extension is 3 % of the unit
anyway.)

So the two-level build removes essentially all of the bottom cost (÷60 on the extension), and what is
left of the new shape is the AND scan (87 %). Its price: a unit is 62× larger (4.2e12 admissible n at
b60, ~15 s on one core; 2.1e13 and ~75 s at b62), and the host top layer is one digit deeper (depth t − p
= 5 at b62: 2.6e7 prefixes, ~0.85 GB as `(u128, u64)`; it could be generated on the fly from the depth-4
layer instead).

**Other shapes at b60 [M, run D]:** (f0 4, k 8, p 4) affine: 8.87e-12 (×3.86 vs today mid) — k 8 doubles
the pairs (1.64e-2 per admissible n) and the survivors (9.7e-5), the scan is 97 %. (f0 3, k 9, p 6),
run as p 5 + key digit (62^6 units do not fit the u32 partition index): 1.47e-11 (×2.33) — the tops are
84 % of it (1.0e-4 top tests per admissible n, ×51 the f0 4 shape's: a top block is b^3 numbers instead
of b^4, so there are b times as many), pairs 4.9e-3, survivors 4.8e-6.

## 6. What I think the model in NOTES §3 gets wrong

1. **The bottom side is not "1.5e15 cheap linear extensions".** 1.5e15 is the number that *survive* the
   fixed digits; a 5-digit unit visits every residue of the base's bottom list, 8.0e15 per base at b62
   (5.1e15 b60, 1.0e16 b64), each with full-width arithmetic. On the CPU that is 51–71 % of the new shape
   at b60/b62 with exact arithmetic and 32–53 % with the affine form. It disappears only when units are
   grouped so that the last partition digit varies inside the unit (the key-level (L − 4, 9, 4) unit,
   measured: extension 2 %). For the GPU: one visit per ~300 ANDs (b62), but a visit is 100–400 AND-equivalents
   of arithmetic on the CPU (44–95 ns against 0.25 ns), so the bottom build is the same order of work as the
   AND scan unless the unit is "4 digits of π, the 5th as a key" (÷62 visits).
2. **The cost per AND pair is not shape-independent.** The model prices pairs at today's rate. On the CPU
   a new-shape AND costs 0.25–0.43 ns against 1.0–1.15 ns today (§4): class lists ~50× longer (15,000
   bottoms instead of ~300) and 20× fewer survivors per AND (0.18 % against 4.2 %). This, not the pair
   count, is most of the CPU ratio. Whether a GPU gains the same (fewer, longer bucket scans; fewer
   divergent survivors) is for the tile benchmark; it is a gain the model leaves out.
3. **Pairs are "the same as today" only at b62.** New/today-mean pairs: ×0.82 (b60), ×1.13 (b62), ×1.96
   (b64). At b64 today's shape gains from its field prune and from whole empty fields (4 of 10 sampled
   1e16 fields have no certified top at all and cost nothing), which the transversal unit cannot use
   (§3). The MC's own field-prune columns already say ×1.3 at b64 (m 9); measured is ×2.
4. **Survivors and checks fall more than projected:** survivors ÷16 / ÷18 / ÷14.5 (model ÷7.6), full checks
   ÷28 / ÷31 / ÷24.5 (model ÷8+). The MC's k-9 survivor rates rest on 2–8 events: measured 2.33e-5 (b60),
   1.39e-5 (b62), 1.07e-5 (b64) per admissible n, from 2e7–4e8 events.
5. **Top tests fall ÷14–20 against today's base average** (÷25 against b62's mid-base field), not ÷60 —
   the certified tops fall ÷30–37.
6. **Today's counts depend on where the field is.** The calibration and the "today" column use one
   mid-base field; P_T there is +42–48 % over the base average at b60/b62/b64 (@0.55), the b64 mid-base
   field is empty, and per-field cost varies ×2.7 at b60. Compare whole-base designs against a base
   average (the MC's whole-base P_T matches the 10-field mean to −16…+6 %), not against one field.
7. **The ×3 headline is about right on the CPU, and better with the two-level unit.** Against today's
   base average: (L − 4, 9, 5) affine ×2.97 (b60), ×4.06 (b62), ×1.84 (b64); key-level (L − 4, 9, 4)
   ×6.5 at b60, ×5.9 at b62. The spread is mostly the base (8 roots at b64, empty fields), not noise. b64's
   ×1.8 is the weak point: the scan is 84 % of its time there and the pair count is the lever (a
   bit-parallel or block-level prune).
8. Smaller: the MC's P_T, P_B and no-prune pairs for the new shape are right (−5…+1 %, +20 % pairs at
   b64), so the count inputs to the GPU projection can use the MC for f0/k and the measured survivor rates.

## 7. Files and how to rerun

- Code: branch `exp/n1-transversal-cpu` on the fork (commits on top of c0c357a); experiment module
  `common/src/cpu_join/n1.rs`. Tests (all `#[ignore]`, run with `--ignored --nocapture`):
  `n1_whole_base_units_are_exact_at_small_bases` (`N1_BASE=b` for one base), `n1_whole_base_units_are_exact_at_base_40`
  (`N1_B40=units`), `n1_transversal_units_match_the_reference` (`N1_BASE`, `N1_EXACT_PARTS`),
  `n1_affine_extension_equals_the_exact_one`, `n1_counts_and_timing` (`N1_BASES`, `N1_SHAPES` = `today`,
  `today@frac`, `f0-k[-p][a]`, `N1_PARTS`, `N1_ROUNDS`, `N1_FULL_ONLY`). Build: `cargo build --release -p
  nice_common --tests` (no GPU features).
- `raw/runA.log` (24 units × 3 rounds, b60/b62 today vs exact; b64 aborted after round 0 — 18 empty
  today units, 17 new units — because a b64 unit takes 45 s × 3 modes), `raw/runB.log` (b60/b62 today vs
  exact vs affine, 12 × 3), `raw/runB64.log` (b64 today@0.55 vs exact vs affine, 8 × 3), `raw/runC.log` (10
  locations × 3 units, full mode, + affine), `raw/runD60.log`, `raw/runD62.log` (other shapes, key level),
  `raw/runE64.log` (24 units of b64 today@0.55, counts); `raw/summary_*.txt` = `analyze.py` of each; the
  `.err` files hold each subject's setup line (top-layer size, `bpre`, k2, flags).
- Exactness: `raw/existing_tests.log`, `raw/full_suite.log`, `raw/exact_small.log`, `raw/exact_b40.log`,
  `raw/exact_b40_30k.log`, `raw/exact_c_b54.log`, `raw/exact_c_b62.log`, `raw/affine_equal.log`.
- `runB.sh`, `runD.sh`: the run scripts (run D's b62 half was run by hand under a memory cap instead).

Caveats: timing is one shared 4-vCPU VM, one thread, `nice -n 19`; a few exactness tests and builds ran on
other cores during runs A and B (one outlier unit, medians unaffected). The survivor-path split is by
differences of separate runs. Today's 10-field means are one round of 3 partitions per field.

