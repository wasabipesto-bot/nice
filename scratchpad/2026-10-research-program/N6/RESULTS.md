# N6: can the join test fewer top certificates? (2026-11-13, ivory, CPU only)

Tags: **[M]** measured here (exact counts over the sample, CPU), **[D]** derived from measured numbers by
the arithmetic shown, **[A]** assumed, **[E]** an earlier program measurement (cited).

## 0. Answer

**Close it.** Failing (prefix, partition) pairs cluster strongly — 94–96 % of failures are followed by another
failure along the partition axis, and 64–70 % lie in runs of 128 or more — and the tests that any exact
test-and-skip order must still do are only 0.35–0.37 of today's [M]. But the order that reaches that floor
needs each GPU thread to jump on its own, and in lockstep warps it costs more than today (×1.13–1.18 the
work at b62/b64, central prices). The schemes that keep the warps uniform are **group certificates in two
passes**: test a run of 16 or 32 consecutive partitions of a prefix as one interval, then walk only the runs
that pass. They are exact (0 violations in 4.1e8 pairs) and remove

| share of top-test work removed, net of the scheme's own cost | b60 1e16 | **b62 1e17** | **b64 1e17** |
|---|---|---|---|
| g16 or g32 groups (the better of the two), pass 1 ahead of today's 16-slot batches (batches unchanged) [D] | 48 % | **39.7 %** | **41 %** |
| same, if a passing test's append is 0.2 of a test (bandwidth estimate) [D/A] | 45 % | **37 %** | **39 %** |
| g32, top stage fully decoupled from the batches (one FD seed per prefix) [D] | 45 % | 42 % | 43 % |
| same, append 0.2 [D/A] | 42 % | 39 % | 41 % |
| g16 inside each batch (one extra kernel, nothing else changes) [D] | 44 % | 36 % | 37 % |

so the brief's kill line (40 % at b62 and b64) is reached only on the most favourable pricing, by margins
(0–3 points) smaller than the costs I could not price (append share, compaction, an extra kernel and its
launches); the batch-preserving design misses it at b62 (39.7 %). At a field that is **≈ ×1.09 at b62 and b60**
(top share 22 % / 18.5 %, [E]) and **≈ ×1.035 at b64** (8.4 % since #254), for a two-kernel restructuring of the
top stage. Counts are exact and stable (two independent
samples agree within 0.003, field bootstrap ±0.003–0.006); the cost conversion rests on one measured price
(seed = 1.77 steps) and two estimates. Confidence that no exact scheme clears 40 % with margin at b62: high;
that the g16-ahead design would deliver ≈ 37–40 % on a GPU: moderate.

If the director wants the ×1.09 at b62 anyway, the scheme to prototype is §4's "g16 ahead"; what would decide
it is one GPU number, the append share of a passing top (§5).

## 1. What a top test is

**Shape.** Every production field the join takes runs `(t, k, p) = (L − 3, 6, 2)` (`JoinParams::for_length`):
`f0 = L − t = 3`; the partition is `n`'s digits at positions 3 and 4, the key position 5. The host builds the
*top layer* once per slice: every prefix `P0` of depth `t − p = L − 5` (a block of `b^5` consecutive `n`) whose
certificate passes and whose ancestors' passed (`Base::top_layer`, breadth first, cap `k = 6`). A **top test**
is one `(P0, v)` pair, `v` a partition value in `0..b²`: the block `P = P0·b² + v`, i.e. the `b³` numbers
`[P·b³, P·b³ + b³ − 1]` (clipped to the slice at its two ends), certified by `Base::cert(a, e, 6)`. On the
GPU, `top_fd_kernel` gives each layer prefix a thread that walks the batch's 16 consecutive partitions (one
launch = 16 slots, `join_plan::SLOTS`; fewer on small devices, 11–13 on CUDA b64 since #250), seeding `P²`,
`P³` by division at the batch's first slot and stepping them by five digit-array additions after that (`a^j =
P^j·b^(3j)`, consecutive partitions are consecutive `P`); `top_kernel` takes the two clipped blocks per slice.
Passing pairs are appended (a 32-byte record, one atomic per plane) into their bucket groups for the join.

**What it certifies.** For `j = 2, 3`: the digits of `n^j` that are the same for every `n` of the block — the
common top digits of `a^j` and `e^j` from `c0 = max(6, ndig(e^j − a^j))` up, minus `a^j`'s run of `b − 1`s and
the digit above it when `e^j`'s value at `c0` is one more (that digit is then `d` or `d + 1` for every `n`; the
closure uses it, Hall's condition on the two such intervals). The pair passes iff those common digits are
distinct (a 64-bit mask) and the closure leaves each interval a free digit. With a `b³`-wide block, `e² − a² ≈
2n·b³` and `e³ − a³ ≈ 3n²·b³`, so (`raw/example.py`, [M]):

| base | L | n² / n³ digits | its layer prefix (b^5) certifies | the pair (b^3) certifies | new positions |
|---|---|---|---|---|---|
| 60 | 12 | 24 / 36 | n² 18–23, n³ 30–35 (12 digits) | n² 16–23, n³ 28–35 (16) | n² 16, 17; n³ 28, 29 |
| 62 | 13 | 25 / 37 | n² 18–24, n³ 30–36 (14) | n² 16–24, n³ 28–36 (18) | n² 16, 17; n³ 28, 29 |
| 64 | 13 | 26 / 38 | n² 18–25, n³ 31–37 (15) | n² 16–25, n³ 29–37 (19) | n² 16, 17; n³ 29, 30 |

(one position more or less with the field's leading digit and the carry run: a pair adds 2 positions of `n²`
for 53–86 % of pairs and 2 of `n³` for 60–80 %, 1 or 3 otherwise [M], §3).

**Why a pair fails.** Its prefix passed, so the prefix's 12–15 common digits are distinct. The pair adds about
four digits, two per power, and fails iff one of them repeats a prefix digit or another new one; in 2 % of
failures the closure empties an interval instead. With ~14 of 62 digits taken and four new draws about a third
survive: measured 0.31–0.35 [M]. The new digits change at very different speeds along `v`, the GPU's walk: one
step moves `n` by `b³`, `n²` by `≈ 2n·b³`, `n³` by `≈ 3n²·b³`. At b62 with leading digit 2.5 that is `≈ 5·b^15`
and `≈ 18·b^27`: `n²`'s position 17 changes every ~775 partitions (five values per prefix), position 16 every
~12; `n³`'s position 29 every ~210, position 28 every ~3.4 (b64 with leading digit 8: n² every ~240 / ~4, n³
every ~1,250 / ~20). A repeat in a slow digit kills hundreds of consecutive partitions, one in a fast digit one
to a dozen. That is the clustering structure of §3 and it decides every scheme of §4.

**What it costs, and what it recomputes.** RTX 3080, b62 [E: EXPERIMENTS L35.1]: a stepped slot 0.198 ns, a
seeded slot 0.350 ns (a seed = 1.77 steps); later 0.14–0.15 ns per FD test on both cards [E: the 11-11
profile]; "the step's additions are unmeasurably small — what remains is the two certificate scans, the
remainder, the carry tests and the append". So a test costs the scan of its 16–19 common digits, the low words
for `x mod b^c0` and the append; every test rescans the 12–15 digits its prefix already certified, which are
the same for all `b²` of its pairs. Share of a field [E]: 22–23 % at b62 1e17 and 18–19 % at b60 1e16 (3080,
9070 XT), b64 1e17 16.7 % before #254 and **8.4 % after** (FD at power-of-two bases, CUDA).

**What the field certificate removes first.** `fc = cert(s, e − 1, 6)`: if it fails the field has no tops at all
— 8 of 96 sampled fields at b60, **17 of 96 at b62**, 10 of 96 at b64 [M]. Otherwise it only prunes bottoms;
nothing on the top side skips work because of it (every top's mask contains it). The layer then removes the
`b^5` prefixes that fail: of the `b` prefixes under a certified `b^6` block 0.64–0.68 are in the layer [M], and
each of those is tested at all `b²` partitions.

## 2. Method and sample

Code: branch `n6-top-counts` in `~/projects/nice/.worktrees/n6-top-counts` (from `origin/main` a7a59c1; commit 21908a7,
pushed to the fork as `exp/n6-top-counts`): `common/src/overlap_join/n6.rs` (`Base::n6_detail`: `cert_parts` without
its early exit, every common digit with its position; the next digit boundary of a power) and
`common/examples/n6_top_counts.rs` (the driver). CPU build, no GPU features; one thread per run, `nice -n 19`.

Sample, per base and seed (seeds 1 and 2, independent): **48 production-size fields** (b60 1e16, b62 and b64
1e17), one at a random place in each 48th of the base's valid range, aligned down to a multiple of the field
size from the range's start; in each, **25 random `b^6` blocks** drawn uniformly inside the field. A block counts
if it and all its ancestors certify (as the top layer requires); then all `b` of its `b^5` prefixes are
certified and every prefix in the layer is tested at **all `b²` partitions**, exactly as the GPU would. Pooled
sums weight every field by its own top work (equal-size fields, uniform blocks). Every group scheme certifies its
groups with the production `Base::cert`; my detailed certificate equals `Base::cert` (pass and mask) on every
7th pair: 5.9e7 checks, 0 mismatches [M].

| base | fields (empty) | units drawn / certified | layer prefixes | pair tests | run time per seed |
|---|---|---|---|---|---|
| 60 | 96 (8) | 2,400 / 1,064 | 43,228 | 1.56e8 | 11–12 min |
| 62 | 96 (17) | 2,400 / 815 | 32,560 | 1.25e8 | 9–10 min |
| 64 | 96 (10) | 2,400 / 775 | 31,870 | 1.31e8 | 10–11 min |

Stability: every scheme ratio agrees between the two seeds within 0.003; a bootstrap over field locations
gives 95 % intervals of ±0.002–0.006 (in `raw/summary_b*.txt`). The ratios vary between fields (g32 at b62:
0.56–0.61 over 79 non-empty fields; b60: 0.46–0.64), which is why the sample spans the range.

## 3. Counts [M]

| | b60 | b62 | b64 |
|---|---|---|---|
| pairs passing | 0.349 | 0.325 | 0.312 |
| failures by a repeat / by the closure | 0.978 / 0.022 | 0.981 / 0.019 | 0.979 / 0.021 |
| first repeat n²–n² / n³–n³ / n²–n³ | 0.31 / 0.19 / 0.47 | 0.33 / 0.18 / 0.47 | 0.34 / 0.18 / 0.46 |
| a new digit repeats a prefix digit / two new digits repeat | 0.85 / 0.12 | 0.87 / 0.12 | 0.87 / 0.11 |
| repeat involves a new n² digit, offset 1 / 2 / 3 below the prefix's lowest common position | 0.29 / 0.28 / 0.02 | 0.30 / 0.27 / 0.03 | 0.27 / 0.24 / 0.07 |
| repeat involves a new n³ digit, offset 1 / 2 / 3 | 0.24 / 0.24 / 0.03 | 0.23 / 0.22 / 0.06 | 0.23 / 0.25 / 0.03 |
| fewest top digits per power that show the repeat (share of repeats) | 6: 0.01, 7: 0.50, 8: 0.44, 9: 0.05 | 7: 0.13, 8: 0.57, 9: 0.30 | 7: 0.03, 8: 0.43, 9: 0.44, 10: 0.10 |
| P(fail \| previous partition fails) / P(fail \| it passes) | 0.963 / 0.070 | 0.952 / 0.100 | 0.944 / 0.124 |
| failing pairs in runs of < 8 / 8–127 / ≥ 128 consecutive partitions | 0.06 / 0.30 / 0.64 | 0.08 / 0.27 / 0.65 | 0.12 / 0.18 / 0.70 |
| P(fail \| sibling prefix fails at that partition) / P(fail \| it passes) | 0.643 / 0.643 | 0.663 / 0.665 | 0.670 / 0.673 |
| layer prefixes with no passing partition | 0.043 | 0.011 | 0.009 |
| fewest tests of any test-and-skip order (passes + failing runs) / today | 0.373 | 0.357 | 0.351 |

Shares in the first rows are of failing pairs (the offset rows can sum past 1: both occurrences of a repeat
can be new). The layer prefix certifies the top 6 / 7 / 8 digits of n² and 6 / 7 / 7 of n³ (b60 / b62 / b64,
§1), so most repeats need the first new digit and a third (b62) to half (b64) need the second; a repeat inside
the prefix's own depth is one whose prefix ended in a carry interval that the pair resolves.

**Along the three axes.** (1) *Consecutive partitions of one prefix:* strongly clustered — failures come in
runs, two thirds of them in runs of ≥ 128 (a slow digit), the rest in short runs (a fast one). (2) *Sibling
prefixes at one partition:* independent — whether the neighbouring prefix fails at the same partition does not
change the odds (difference ≤ 0.003); and their blocks are `b²·b³` apart, so no interval certificate can cover
both. Nothing to group on this axis. (3) *Leading partition digit* (the `b` partitions sharing `v`'s high
digit = an aligned run of `b` partitions): one certificate per run catches 59–61 % of the failures (g60/g62/g64
in §4), the slow-digit ones; the fast-digit failures inside a run cannot be grouped by any interval wider than
their own few partitions.

## 4. Schemes, by exact count on the same sample

Prices (in units of one stepped FD test, the marginal cost of a failing test today): **σ = 1.8** for a seed or a
fresh certificate (1.77 measured, [E] L35.1; 3.0 pessimistic, 1.4 optimistic [A]), **ε = 0.5** for computing a
skip end (a bound on the next change of a repeated digit; [A], 1.0 / 0.25); compaction 0.1 per prefix and batch
where a scheme needs it [A]. Today = one step per pair plus one seed per prefix and 16-slot batch: `1 + (σ − 1)/16`
per pair. Pass and fail cost the same (the scans are unrolled, no early exit) except the append, which only
passing pairs do: the "α 0.2" column charges it at 0.2 of a test [A: 9e10 tests × 0.32 × 32 B ≈ 0.9 TB per b62
field ≈ 1.2 s of the ≈ 16 s top phase at 760 GB/s, i.e. ≈ 0.2 per passing test]. It is in every scheme and in
today alike, so it only dilutes the saving.

Exactness: every scheme rejects a pair only through a failing certificate of an interval that contains it
(a sub-interval's common digits include its parent's, the rule `top_layer` already relies on) or through a
repeat of two digits that the skip end proves constant until that end; counted on the sample, **0 passing
pairs rejected by any scheme** (4.1e8 pairs, every group, segment, skip and span variant).

Central prices, cost relative to today (tests relative to today in brackets); `raw/summary_b*.txt` has every
variant at all three prices:

| scheme | GPU shape | b60 | b62 | b64 | α 0.2: b62 / b64 |
|---|---|---|---|---|---|
| today | — | 1 | 1 | 1 | |
| floor: passes + failing runs | none (count only) | (0.373) | (0.357) | (0.351) | |
| skip walk, per lane | each thread jumps on its own; not SIMT-realisable | 0.404 (0.393) | 0.416 (0.384) | 0.432 (0.385) | 0.452 / 0.466 |
| skip walk, 32 random lanes in lockstep, whole span | today's mapping, decoupled | 0.977 | 1.135 | 1.181 | |
| skip-until across 16-slot batches, lockstep | today's mapping, a reach per prefix | 1.31 | 1.61 | 1.79 | |
| warp per prefix, 16 lanes over consecutive partitions, jump to the lanes' reach | new mapping | 0.653 (0.464) | 0.815 (0.509) | 0.820 (0.505) | |
| every pair not jumped as a fresh certificate (compacted list) | two-pass | 0.694 (0.393) | 0.688 (0.384) | 0.695 (0.385) | |
| **g16 / g32 ahead: pass 1 certifies groups of 16 (32) partitions, bits; batches run today's kernel over the prefixes whose bit is set** | two-pass, batches unchanged | **0.523** / 0.572 | **0.603** / 0.603 | 0.592 / **0.586** | 0.627 / 0.610 |
| g32, top stage decoupled (pass 2 walks each passing group with one seed) | two-pass, decoupled | 0.553 (0.567) | **0.583** (0.598) | **0.567** (0.581) | 0.609 / 0.592 |
| g16 inside each batch (fresh 16-wide certificate, compact, today's kernel) | +1 kernel per batch | 0.565 (0.520) | 0.645 (0.600) | 0.634 (0.589) | 0.666 / 0.655 |
| g`b` (leading partition digit), decoupled | two-pass | 0.611 (0.633) | 0.589 (0.611) | 0.577 (0.599) | |
| nested `b`-then-8, decoupled | three-pass | 0.545 (0.520) | 0.585 (0.558) | 0.595 (0.569) | |
| g8 / g4, decoupled | two-pass | 0.561 / 0.700 | 0.610 / 0.708 | 0.623 / 0.727 | |
| slow-digit segments (one integer root per change of the topmost new digit of each power; walk the runs that survive) | two-pass | 0.614 (0.639) | 0.592 (0.613) | 0.594 (0.614) | |
| segments on the two topmost new digits of n² | two-pass | 0.615 (0.516) | 0.631 (0.496) | 0.966 (0.550) | |
| decoupling alone (today's tests, one seed per prefix) | — | 0.953 | 0.953 | 0.953 | |

How each interacts with the stepped kernel and the join:
- **Group schemes** keep the one-add step: a group of `g` partitions starts at the same `a = P·b³` as its first
  pair, so pass 1 steps the prefix's groups by FD at stride `g` (a stride-`g` step is the same five additions
  with other constants) and certifies each group with the same scans (fewer digits). Pass 2 is today's kernel,
  seeded per batch, over a compacted list of prefixes; the tops reach the join per batch as today (the order
  inside a bucket segment is already arbitrary). Cost: one extra kernel per slice (g-ahead) or per batch (g16
  inside), a bit per (prefix, group) — 16–32 bytes per prefix — and a compaction. The decoupled variant also
  removes today's per-batch reseed (that alone is 0.047 of the work), but needs pass 2 to walk a group across
  batches, i.e. FD state kept between launches.
- **Skip schemes** need each thread to jump to its own next partition. The jump target is exact (a bound on the
  next change of the repeated digit, computable in floating point with a margin), but in lockstep the warp
  waits for its slowest lane and runs the reseed whenever any lane jumps (per-iteration skip probability
  3–10 % per lane and iteration, × 32 lanes): lockstep turns the 0.38–0.39 of tests into 0.60–0.64 of iterations, and at 1.8 per reseed
  the total exceeds today. Across today's 16-slot batches nothing remains (0.99 of iterations): a random warp
  almost always has a lane with work in every batch.
- **Warp per prefix** (lanes over consecutive partitions, each lane stepping at stride 16) is uniform and keeps
  the step, but every lane computes a skip end in nearly every span and every jump reseeds 16 lanes: 0.65–0.82.
- A **cheaper first stage on fewer digits** is the slow-digit segment row: catching the failures of the topmost
  new digit of each power alone keeps 0.61–0.64 of the pairs, so even a free first stage removes less than the
  groups do. Testing all new digits in the first stage is the full certificate of the pair (below).

## 5. Recommendation, and what I could not determine

**Close the question** (the kill criterion is not cleared with margin at b62, the base the server is about to
run for months). The best GPU-shaped exact scheme, groups of 16–32 partitions certified one pass ahead of
today's batches, removes 40 % of the top work at b62 and 41 % at b64 at central prices, 37 % / 39 % once the
append is charged; ×1.09–1.10 a b62 field (if the 22 % share still holds: the 11-11 profile's join rows were
superseded, its top row was not re-measured), ×1.09 a b60 field and ×1.035 a b64 field. The part of the clustering that would pay more
(the 0.36 floor) is reachable only by divergent per-thread skipping, which lockstep makes a loss.

If the director wants that ×1.09 at b60/b62 anyway: prototype **g16 ahead** — a pass-1 kernel over the slice's
top layer (one thread per prefix, FD at stride 16 over the `b²/16` groups, one bit per group), then per batch a
ballot compaction of the prefixes whose group bit is set and today's `top_fd_kernel` over that list. Exact by the
`top_layer` argument; ~a day of kernel work plus the dense compare. First measure the append share of a passing
top on the 3080 (one ablation run of `top_fd_kernel` with the append off): at α ≤ 0.05 the scheme is ≈ 40 % at
b62, at α ≈ 0.2 ≈ 37 %.

Not determined here:
- GPU prices: σ is one card's measurement on an earlier kernel; α, compaction and launch costs are estimates;
  wgpu on the 9070 XT (81 % of the fields) was not priced separately.
- Batch size: the within-batch numbers assume 16 slots; CUDA b64 runs 11–13 since #250, which helps the
  "g-ahead" scheme not at all and hurts "g16 inside".
- The remaining per-test lever is not a count: each surviving test rescans the 12–15 digits its prefix already
  certified. A pair certificate that scans only its ~4 new positions (plus the remainder words it still needs)
  would cut perhaps a fifth of a test [A, by word count: ~3.5 of the ~12 scanned words are the prefix's];
  unmeasured, and orthogonal to grouping.

## 6. Files and how to rerun

- `raw/run_main.sh` — the six runs (bases 60/62/64 × seeds 1/2; 48 fields × 25 units). Binary:
  `CARGO_TARGET_DIR=~/projects/nice/target cargo build --release -p nice_common --example n6_top_counts` in
  the worktree; usage `n6_top_counts <base> <field size> <fields> <units per field> <seed>`.
- `raw/main_b{60,62,64}_s{1,2}.log` — UNIT lines (per certified unit: counts, failure classes, every scheme's
  tests, seeds and violations), FIELD lines (per field, with the warp simulations), TOTAL.
- `raw/analyze.py` — `python3 analyze.py main_b62_s1.log main_b62_s2.log`: the tables of §3 and §4 at three
  prices, the field bootstrap and a per-field table; `raw/summary_b*.txt` are its outputs (pooled and per seed).
- `raw/example.py` — the worked certificate positions of §1.
- `raw/smoke62.log` — a 4-field smoke run (not used in the tables).
