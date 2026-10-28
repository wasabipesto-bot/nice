# Experiments

One section per experiment, newest first. Each records: lead id, date, box (Vast id
and GPU, or host), commit(s) under test, exact commands, raw data path, the table,
and the one-line conclusion. Benchmark claims follow PROPOSAL.md §5: same box,
interleaved A/B, ≥3 rounds, median and spread per scenario, no scenario −2 %.

## L1.3 Field-certificate bottom prune, GPU A/B (2026-10-28, agent; `L1/PRUNE.md`, `L1/prune-raw/`)

Branches on the fork: `rp/field-cert-prune` (head 4670ffe; the prune is c1174c1, the rest
tests), `rp/field-cert-prune-base` (2d740d3 = 85b5b4e + the same harness, the A tree),
`rp/field-cert-prune-ept` (6e4e895, prune + EPT override). Vast RTX 3080 (58056651),
1e16 fields, 2 per base, the L1.2 starts, A B A B A B (3 rounds), median s/field (spread):

| base | main | prune | speed-up | bottoms removed |
|---|---|---|---|---|
| 58 | 69.36 (0.9 %) | 60.18 (1.1 %) | **1.153×** | 59.5 % |
| 60 | 45.26 (1.2 %) | 39.52 (1.2 %) | **1.145×** | 54.6 % |
| 62 | 26.98 (1.0 %) | 19.07 (0.6 %) | **1.415×** | 74.3 / 66.7 % |
| 64 | 83.42 (2.4 %) | 50.79 (0.6 %) | **1.643×** | 77.1 % |

NiceMark nice-only, 3 rounds, every scenario on the join in both trees: b58_msd_weak
+17.6 %, b58_msd_strong +32.5 %, b60_msd_weak +20.1 %, b62_msd_weak +43.9 %; score
2892 → 3705 (+28 %). Batches and slots identical (buffers still sized by the unpruned
count). At 1e14 production size the prune removes 73–86 %, so production gains are
probably larger (unmeasured).

Exactness on the box: CUDA kernel compiles; 194 host tests; `cubecl_cuda_join_matches_the_cpu_reference`,
the dense-field and whole-field CUDA tests, the CPU reference test, and the throughput
harness with `NICE_TEST_JOIN_COMPARE=1` (join = stride on 1e14 fields) all pass; clippy
`--features gpu -D warnings` clean. One behavioural ripple: the prune tree records 0.94× the
AND survivors and correspondingly more unfiltered prefilter survivors (2–2.5e-4 of
survivors), i.e. survivors that overflow the join kernel's staging area go to the check list
unfiltered, as on main but a little more often; +0.3–0.4 % full checks, and b64 crosses the
dense-field test's 1e-4 limit. Fix for the PR: flush every 16 tops or a larger stage.

**EPT sweep with the prune (`rp/field-cert-prune-ept`):** EPT 2 is best at every base:
×1.088 (b58, 1 round), ×1.053 (b60, 1 round), ×1.060 (b62, 2 rounds), ×1.139 (b64, 2
rounds) over EPT 4; EPT 1 worse than 2 everywhere. Prune + EPT 2 vs main at EPT 4:
**1.51× at b62, 1.91× at b64** (against the L1.2 numbers on the same machine, not
interleaved). So PR #205's EPT 6 and the EPT 5 note both give way to EPT 2 once the prune
is in; pruned buckets are 3–4× smaller, so the wave shrinks.

## L1.2 GPU join phase profile by base (2026-10-28, agent; `L1/GPU-RESULTS.md`, branch `rp/gpu-profile` on the fork)

Vast RTX 3080 (instance 58051111, $0.134/h), upstream 85b5b4e + `NICE_EXP_GPU_PROFILE=1`
(costs 3.9–6.3 % of device time; shares from profiled runs, seconds from unprofiled),
1e16 fields, 2 per base, CubeCL CUDA.

| base | roots | device s/field | top | bucket | join | check | other |
|---|---|---|---|---|---|---|---|
| 58 | 4 | 68.8 | 19.5 % | 3.8 % | 64.8 % | 4.7 % | 7.3 % |
| 60 | 2 | 45.2 | 23.3 % | 5.1 % | 55.8 % | 5.3 % | 10.5 % |
| 62 | 2 | 26.1 | 21.9 % | 7.2 % | 57.9 % | 3.6 % | 9.5 % |
| 64 | 8 | 83.1 | 7.1 % | 3.3 % | 82.6 % | 3.1 % | 3.9 % |

| base | µs/prefix | RX 9070 XT | AND survivors/prefix | prefilter survivors (= full checks) |
|---|---|---|---|---|
| 58 | 11.44 | 11.2 | 63.7k | 3.84k |
| 60 | 8.51 | 6.8–7.3 | 43.8k | 3.10k |
| 62 | 9.96 | 9.2–9.6 | 34.8k | 2.20k |
| 64 | 26.84 | 19.5 | 139.8k | 8.77k |

- Everything but the join kernel costs 4–5 µs per prefix at every base; tops per prefix
  1180–1300 everywhere. The join kernel carries the whole b64 jump (23.0 µs vs 6.1 at b62).
- Survivors per prefix = tops × roots × bucket occupancy (930–1210 at every base) × AND
  pass rate. b64/b62 survivors 4.02× = roots 8/2. b58/b60 1.45× (pass rate 1.41 % vs 1.81 %).
- **Join kernel cost model** (10 fields, four bases, max error 1.9 %): **0.58 ps per
  lane-pair, lanes padded to whole 1024-entry waves, plus 74 ps per AND survivor.** Wave
  padding is 1.07–1.10× at b58/b60 and 1.69–1.72× at b62/b64 (buckets of ~1200 spill into
  a second wave): ~18 % of b64 device time, 12 % of b62's.
- **Entries per thread (`NICE_EXP_JOIN_EPT`, 2 interleaved rounds, first field):** 5 gives
  ×1.12 (b62) and ×1.19 (b64) over 4; 6 (= PR #205) gives ×1.08 / ×1.13, matching #205's
  own 3080 numbers. So 5 beats #205 by 3.4 % / 5.4 % on this card. Needs a third round and
  other GPUs before it is a claim. The model fitted on EPT 4 predicts 5 and 6 within 0.6–3.4 %.
- L4: the check kernel is 3.1–5.3 % of device time (3.8–9.8 % of the join's), under the
  15 % kill criterion.
- Caveats: no hardware counters (`ncu` blocked on Vast); the b60 window used is denser
  (44k survivors/prefix vs ~26k on the 9070 XT's fields) so b60's µs/prefix reads high.

**What the prune should buy (director's estimate from the model, to be measured):** per prefix the
AND term is tops × roots × padded occupancy × 0.58 ps: b58 2.9 µs, b60 1.5, b62 2.8, b64 11.4;
the survivor term 4.7 / 3.2 / 2.6 / 10.3 µs. Pruning 73–86 % of bottoms (1e14 fields) cuts
the AND term by 2× at the current wave size (one wave instead of two) and by 3–7× with a
smaller wave, leaving survivors unchanged: 10–30 % of device time by base.

## L3.0 Detailed mode on the GPU (2026-10-28, agent; `L3/NOTES.md`)

RTX 3080, `auto` = CubeCL CUDA. b40_detailed 1.04e10 n/s, b50_detailed 7.8e9 (references
2.4e9 / 1.5e9 are for a weaker card). CPU 16 threads: b40 4.4e7, b50 2.86e7, one thread
1.87e6. GPU = 236–273× this CPU. `nvidia-smi dmon`: SM 98–99 %, memory controller 0 %.
Kernel: one thread per number; n², n³ in u32 limbs; digits peeled by long division by b⁵
in shared memory; OR into a mask, popcount, one shared atomic into the histogram. About
750 (b40) / 1,000 (b50) integer ops per number ≈ the card's integer throughput:
**compute-bound on the divisions.** The L2 finite-difference scheme (digit arrays updated by
addition) removes exactly those divisions, so L2 and L3 are one lead with a CPU prototype first.

## L1.1 CPU join counts by base (2026-10-28, agent; `L1/RESULTS.md`, branch `rp/l1-selectivity` a76984f on the fork)

Item 23's field per base plus a second field, 6 stratified partitions per field, ivory (EPYC
Rome) under `nice -n 19`, 3 threads; a second round reproduced counts exactly and stage
times within ±5 %. Ignored tests `cpu_join::selectivity::l1_selectivity`, `l1_probe_windows`.

| | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| roots | 4 | 2 | 2 | 8 |
| L / digits of n², n³ | 12 / 23, 35 | 12 / 24, 36 | 13 / 25, 37 | 13 / 26, 38 |
| bottoms per key list (per class) | 54.8k (961) | 54.9k (931) | 72.7k (1191) | 76.4k (1212) |
| ANDs per top | 3,844 | 1,863 | 2,383 | 9,702 |
| top popcount (n² + n³ known) | 15.7 (7.7 + 7.9) | 16.2 (8.1 + 8.2) | 17.3 (8.9 + 8.5) | 18.4 (9.6 + 8.9) |
| AND pass rate, measured / uniform model | 1.37 / 1.40 % | 1.64 / 1.42 % | 1.25 / 1.23 % | 1.06 / 1.06 % |
| AND survivors per top | 52.7 | 30.5 | 29.8 | 103 |
| full checks per top | 3.3 | 2.0 | 1.9 | 6.6 |
| CPU ms per prefix | 5.8 | 3.5–3.9 | 4.0–4.4 | 11.0–11.5 |
| RX 9070 XT µs per prefix (BACKLOG 68) | 11.2 | 7.0 | 9.4 | 19.5 |

- ANDs per top = roots × mean class size within 0.1 %: hypothesis A holds exactly.
- Pass rates follow the uniform model C(b−pc, 12)/C(b, 12); b64's tops know the most
  digits, so its pass rate is the lowest (0.85× b62). Net AND survivors per top: b64 3.5× b62.
- Tops per prefix (1.2–1.3k) and certificate cost (405–471 ns per prefix tried) are flat.
- Of the +7.6 ms per prefix from b60 to b64: 52 % survivor handling (range test, prefilter,
  dispatch, 32–41 ns each), 33 % the ANDs (0.22 ns each), 9 % full checks. ANDs are 13–17 %
  of a partition at b58–b62 and 26–27 % at b64. CPU scan shares match item 23's Zen 2 profile.
- CPU cost per prefix relative to b60: ×1.6 / 1 / ×1.15 / ×3.1; GPU: ×1.6 / 1 / ×1.33 / ×2.8.

**Lever counts (share of ANDs skipped).** Sub-bucketing by mask ∩ S: digits 0..s−1 skip
21–42 % (s = 4–8); the s most frequent top digits skip 56–81 %, but those digits are the
field's own certificate (4–7 leading digits of n², n³ every top knows). **Dropping bottoms
that share a digit with the field certificate skips 66 / 60 / 70 / 79 % of ANDs at
b58/60/62/64 with no bucketing.** CPU saving bound: 7–12 % at b58–b62, 20–23 % at b64
(only failing ANDs are skipped). GPU share unknown until the GPU profile lands.

## L1.0 Digit-sum class roots per base (2026-10-28, director, no hardware)

In the join each top probes one bottom bucket per root of x² + x³ ≡ b(b−1)/2 (mod b−1)
(overlap_join.rs module doc). The root count by base, from a 3-line enumeration:

| base | b−1 | roots | measured µs/prefix (RX 9070 XT, BACKLOG 68) | survivors per top-layer prefix |
|---|---|---|---|---|
| 58 | 57 = 3·19 | 4 | 11.2 | — |
| 60 | 59 prime | 2 | 6.8–7.3 | ~26k |
| 62 | 61 prime | 2 | 9.2–9.6 | 27–44k |
| 64 | 63 = 7·9 | 8 | 19.5 | 112–176k |

Roots for 40–97: 40:4 41:6 42:2 43:0 44:2 45:2 46:8 47:0 48:2 49:2 50:8 51:0 52:4 53:2
54:2 55:0 56:4 57:6 58:4 59:0 60:2 61:4 62:2 63:0 64:8 65:1 66:4 67:0 68:2 69:2 70:4
71:0 72:2 73:12 74:2 75:0 76:12 77:2 78:4 79:0 80:2 81:2 82:10 83:0 84:2 85:4 86:4
87:0 88:4 89:6 90:2 91:0 92:4 93:2 94:4 95:0 96:4 97:10. (Zero roots = residue-dead
bases, which the server never inserts; matches the known list.)

Reading: the b64 survivor count per prefix is ~4× b62's, exactly the roots ratio 8/2;
per-prefix time is ~2× because the tops phase does not scale with roots. b58 > b60
follows the same ordering (4 vs 2 roots). Hypothesis A of L1 is therefore the
explanation to beat; the CPU counting run (L1/RESULTS.md) checks it and sizes the
signature-bucketing lever.

