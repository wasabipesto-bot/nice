# L45 RESULTS: measurement session on #246 — the top scan + fill priced directly, the lean join re-priced (2026-11-06)

Measurement only: no prototype, no PR. Branch **`exp/join-l45-measure`** on the fork, head **`8a07c05`** (= fork
`pr/join-lean-prefilter` `f3fb390` (#246 on #241 on main `6f060a9`) + `0cfbc7d` (L37's `a5ccbb5` profile timers,
one conflict hunk with #241's `rec_len` resolved by keeping both) + `532d2c8` (the top-phase split, L37's ablation
switches ported to the lean kernel, stage-cadence modes 7 / 8 / 15, a spill counter) + `8a07c05` (one empty profile
mark per batch, to price a mark)). Box: Vast **59406446** (`nice-research-l45-measure`), machine **m139250**, RTX 3080 at
a **180 W cap**. Raw logs `raw/box/` (the box's `/root/l45/logs`; SASS of every join kernel that ran in
`raw/box/sass/`), scripts `raw/scripts/`, every table below is `python3 raw/scripts/analyze45.py raw/box`
(→ `raw/analysis.txt`).

## Summary

- **Top phase, measured (item 1's step 0):** at b62 1e17 (unprofiled field 100.23 s, 180 W) the FD kernel is
  25.23 s (**25.2 %**), the clipped-block launch 0.002 s (0.0 %), `top_scan_kernel` 1.06 s (**1.1 %**),
  `top_fill_kernel` 8.63 s (**8.6 %**); at b60 1e16 (19.63 s per field) 4.12 s (**21.0 %**), 0.001 s, 0.21 s
  (**1.0 %**), 1.56 s (**8.0 %**). **Scan + fill = 9.69 s = 9.7 % (b62) and 1.77 s = 9.0 % (b60)**, 0.254 / 0.257 ns
  per kept top (= L31's 0.22–0.26). 3 profiled runs per field (spread ≤ 3.5 %; scan + fill ≤ 0.9 %); the profiled
  field (probe excluded) is +0.6 % / +2.0 % over the unprofiled one, an empty profile mark costs 12 µs per batch.
- **Kill verdict, roadmap item 1 (scan + fill < 5 %): not fired** (9.7 %, 9.0 %): item 1 goes to its build; the
  ceiling for removing scan + fill outright is ×1.107 / ×1.099.
- **The lean join by ablation** (L37's modes ported to #246, 3 interleaved profiled rounds; % of the field, b62 1e17 /
  b60 1e16): **base 15.96 s (15.9 %) / 3.03 s (15.4 %), AND 8.35 s (8.3 %) / 1.62 s (8.3 %), walk 6.42 s (6.4 %) /
  1.37 s (7.0 %), prefilter 16.11 s (16.1 %) / 3.77 s (19.2 %), stage + flush 1.34 s (1.3 %) / 0.37 s (1.9 %)**; join
  48.17 s (48.1 %) / 10.15 s (51.7 %). Against L44's derived split the AND is 8.4 s, not 1.1 s (#241's top record
  took the latency that hid it), the base 16 s, not 21. The per-top AND (TMIN 2^30) would cost ×1.094 / ×1.075.
- **Stage cadence:** checking the stage every 8 chunks or once per top batch instead of every chunk is **×1.020–1.023
  at both fields, unprofiled** (3 interleaved rounds, every round ×1.018–1.033; cycles ×1.03–1.05); every 4 chunks
  ~two thirds of that. Exact; the stage never fills even once per batch (0 pairs past it in all six counted runs).
  The barrier waits are ~2.5 s of L44's 23 s of non-issue join time, not its bulk.
- **Spill vs no-spill:** the runtime path (NVRTC PTX → the driver's JIT) compiled #246's join kernel to 47–48
  registers with no spills in **all 100** processes recorded; L41's 40 registers + 28 B of spills is nvcc's offline
  compile of the same CUDA source (reproduced: 28 B at b62 and b60). Timed with every kernel image pinned (3 rounds):
  nvcc's spill variant is **1.7–2.9 % slower in the join (1.4–1.5 % of the field)** than nvcc's spill-free build at
  5 cubes/SM, and **no slower than the runtime's own compile**, which is itself 3.4–3.5 % slower in the join (1.7 % of
  the field) than nvcc's spill-free build. Two more images (2 rounds) put that in the front end: NVRTC's PTX is as
  slow under the offline ptxas 12.8 as under the driver's JIT, and nvcc's PTX is fast only with a 5-cube launch bound
  (without one, ptxas targets 40 registers and spills, and lands at the runtime's speed).
- **Kill verdict, roadmap item 5:** no part with a lever reaches 5 %: the cadence is ~2 %, the compile path ~1.7 %,
  spills ~0 in production. No build (box time 2 h 40 min of the 3.5 h). The cadence (s8 or s15) is a rider for the
  next join PR; the AND at 8 % of the field reopens L44 §3a/§3f's AND ideas for re-pricing.
- **Item 4:** the check measured directly is 9.1 % / 11.3 % of the field (L44 derived 9.5 / 11.4): its premise holds.
- **Exact throughout:** every timed run of a full-kernel mode (c, d, s7, s8, s15, u, the A/B, N/M/S/P/Q) gave the exact
  counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b60 1e16, two fields, 460,847,952,346 / 30,871,838,404).
- **The box (59406446) can be destroyed:** every log, trace and SASS dump is in `raw/box/`, nothing is running.

## 0. Setup

- **Box:** Vast 59406446, machine m139250 (L29–L35's), RTX 3080 10 GB, driver 580.159.03 (CUDA 13.0 driver API),
  CUDA 12.8 toolkit (offline `nvcc`, `cuobjdump`). **Power limit 180 W** (default 340; every timed run sat at 174–180 W).
  Xeon E5-2630 v4, cgroup quota 9.6 CPUs, 62 GB RAM. Toolchain 1.99.1. Created ~11:10 UTC, self-destructs ~16:10.
- **One binary** `E2` (md5 `74d32433`, tree `8a07c05`) for every timed run; `E` (`532d2c8`, md5 `3b45e71c`, no null
  mark, same kernels) ran only the sanity chain.
- **Modes** (`NICE_EXP_JOIN_ABL`, comptime, one kernel each; L37's numbering): **c** 0 = #246's kernel; **a** 1 = AND
  only (the pass masks formed, range-tested on clipped tops and popcounted into `and_count` as in c, no walk);
  **b** 2 = the walk's rounds without `walk_pf_lean` and without the stage (each popped bit's index folded into a
  checksum); **p** 3 = walk + `walk_pf_lean`, passes counted in a register, no stage; **z** 4 = no AND (every pass
  mask 0; tops, transposed copy, wave loads and prefilter terms, per-chunk stage check as in c); **d** = c with
  `NICE_EXP_JOIN_TMIN=2^30` (per-top AND everywhere); **s7 / s8** = c with the stage checked every 4 / 8 chunks and
  after a batch's last (L37's 7 / 8); **s15** = c with the stage checked once per top batch, after its last wave and
  before the clip words are cleared (the first of its two barriers is what keeps the clear after every thread's last
  chunk). Every mode keeps #246's direct-to-list path for a full stage, so c, d, s7, s8, s15 are exact by construction,
  and they were (§2). In a, b and z an XOR of every entry's loaded words is folded into a never-true compare (L37's
  device), which fires a handful of times in b (+5 to +7 survivors in 10^12) and once or twice in z.
- **Profile** (`NICE_EXP_GPU_PROFILE=1`): the device is synchronised after each kernel group; this branch splits L36's
  "top" into four marks: after `top_fd_kernel`, after the `top_kernel` launch (the clipped blocks, 4 launches per
  field), after `top_scan_kernel`, after `top_fill_kernel`; plus one empty mark per batch (`null`, a sync with nothing
  queued) to price a mark. Shares are of the **unprofiled** field (mode u = c without the profile, same rounds) unless
  marked "profiled".
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60 1366406074057412100454, b62
  7997740455941656911841), one untimed 1e14 warm-up field per process; b62 1e17 = 1 field, b60 1e16 = 2 fields
  (per-field means). nvidia-smi every 5 s; clock = mean SM MHz over samples at ≥ 90 % utilisation (whole run).
- **Each process's join kernel recorded**: every process ran with CubeCL's PTX cache on, in a fresh directory of its
  own (`cubecl.toml` in the process's working directory), so the PTX each process compiled is on disk; `ptxjit.py`
  then loads it the way the runtime does (`cuModuleLoadDataEx`, the driver's JIT, info log on) and takes the SASS from
  the driver's JIT cache (`CUDA_CACHE_PATH`).
- **Order (box UTC):** builds 11:15–11:24; sanity (every mode at 1e14, b62 + b60) 11:20–11:22; **main chain
  11:24–12:35**: 3 rounds, each b62 1e17 then b60 1e16, modes c a b p z d s7 s8 s15 u in that order, nothing else on
  the GPU; the source dump, nvcc variants and pins 12:35–12:37 and the
  register-variant rounds 12:37–12:59 (`chain_sn.sh`); spill counts 12:59–13:06; the unprofiled cadence A/B
  13:06–13:29 (`chain_ab.sh`); the compile-path rounds 13:29–13:50 (`chain_pq.sh`). Every timed run had the GPU to
  itself, except that the classifier and nvcc were first tried by hand at 11:27–11:33, beside main round 1's a, b and
  p runs at b62 (a few seconds of CPU and a GPU context that ran no kernels; those runs agree with rounds 2–3 within
  their modes' spreads). The sanity chain ran on `E` while `E2` built (untimed).

## 1. Part A: the top phase, split (mode c, 3 profiled processes per field; u = the same binary unprofiled)

Seconds per field, medians of the 3 rounds (the rounds in brackets); "% of field" = seconds ÷ the **unprofiled**
median (b62 1e17 100.23 s, b60 1e16 19.63 s per field). L44's derived budget (its §1.2–1.3, 180 W, 100.4 / 19.65 s)
beside it.

| phase | b62 1e17 s (rounds) | % of field | L44 [D] | b60 1e16 s (rounds) | % of field | L44 [D] |
|---|---|---|---|---|---|---|
| top: FD kernel (`top_fd_kernel`, seeds included) | 25.23 (24.34, 25.23, 25.25) | **25.2 %** | 26.0 s, 25.9 % | 4.124 (4.121, 4.137, 4.124) | **21.0 %** | 4.15 s, 21.1 % |
| top: clipped-block launch (`top_kernel`, 4 per field) | 0.002 | 0.0 % | (< 0.2 s) | 0.001 | 0.0 % | |
| top: `top_scan_kernel` | 1.059 (1.089, 1.059, 1.048) | 1.06 % | | 0.206 (0.200, 0.206, 0.217) | 1.05 % | |
| top: `top_fill_kernel` | 8.634 (8.523, 8.634, 8.644) | 8.61 % | | 1.563 (1.563, 1.565, 1.562) | 7.96 % | |
| **top: scan + fill** | **9.692** (9.612, 9.693, 9.692) | **9.67 %** | 8.7 s, 8.7 % (incl. clipped) | **1.770** (1.763, 1.770, 1.778) | **9.02 %** | 1.40 s, 7.1 % |
| top total | 34.92 | 34.8 % | 34.7 s, 34.5 % | 5.904 | 30.1 % | 5.55 s, 28.2 % |
| bucket | 2.339 | 2.33 % | 2.2 s | 0.458 | 2.33 % | 0.39 s |
| join | 48.17 | 48.1 % | 49.2 s | 10.15 | 51.7 % | 10.45 s |
| check | 9.140 | **9.12 %** | 9.5 s, 9.5 % | 2.217 | **11.30 %** | 2.25 s, 11.4 % |
| other: upload / inputs / read / null mark / unattributed | 2.61 / 2.13 / 0.73 / 0.08 / 0.78 = 6.33 | 6.3 % | 4.8 s | 0.50 / 0.45 / 0.16 / 0.02 / 0.18 = 1.30 | 6.6 % | 1.01 s |
| field, profiled (excl. probe) | 100.86 (98.39, 101.36, 100.86) | 100.6 % | | 20.02 (20.02, 20.05, 19.97) | 102.0 % | |
| probe (excluded) | 1.92 | | | 0.41 | | |
| **field, unprofiled (u)** | **100.23** (100.23, 100.31, 99.84) | 100 % | 100.4 s | **19.63** (19.65, 19.63, 19.62) | 100 % | 19.65 s |

- **Scan + fill is 9.7 % of the b62 1e17 field and 9.0 % of b60 1e16, measured** (L44 derived 8.7 % and 7.1 %). The
  fill is nine tenths of it (8.6 % / 8.0 %); the scan 1.06 % / 1.05 %; the clipped-block launches nothing (4 per
  field, ~0.5 ms each). Per kept top: **0.254 ns** (b62, 3.816e10 kept tops) and **0.257 ns** (b60, 6.89e9), L31's
  0.22–0.26 ns on #235 again: the code has not changed and neither has its price. Per batch: scan 164 / 152 µs, fill
  1341 / 1158 µs (6,439 / 1,350 batches per field).
- **What the profile adds:** one empty mark per batch costs 12.2 µs (b62) / 11.1 µs (b60), 0.08 / 0.015 s per field;
  scan and fill each carry one mark, so at most 0.16 s (1.6 %) of the 9.69 s is the profile's own. The whole profiled
  field (probe excluded) is 0.6 % (b62) / 2.0 % (b60) above the unprofiled one, though the profiled runs sat 90 / 20
  MHz higher (c 1538 / 1490 MHz against u 1450 / 1470: the syncs' idle gaps let the card clock up under the cap).
- **FD kernel 25.2 % / 21.0 %, check 9.1 % / 11.3 %, bucket 2.3 % / 2.3 %** all land on L44's derivation within
  1 point; "other" is 1.5 points above it (L44 derived it as a residual).
- **Kill for roadmap item 1 (scan + fill < 5 % of the field): not fired** at either field (9.7 %, 9.0 %). Removing
  scan + fill outright and adding nothing would be ×1.107 at b62 1e17 and ×1.099 at b60 1e16; the roadmap's ×1.05–1.12
  [E] for the static bucket order stands, its upper end only if the FD kernel's per-group append is close to free.

## 2. Part B: the lean join by ablation (L37's modes on #246, profile on, 3 interleaved rounds)

Join seconds per field (the join kernel alone, between syncs), medians of 3 rounds; marginal costs in the order
z → a → b → p → c; "cycles" = seconds × the run's mean SM clock (each mode draws its own power and so runs at its own
clock under the 180 W cap); "% of field" of the unprofiled field.

| part | b62 1e17 s | % of join | % of field | G-cycles (% of join) | per round (s) | b60 1e16 s | % of join | % of field | G-cycles (% of join) |
|---|---|---|---|---|---|---|---|---|---|
| base (mode z: work items, top batch + transposed copy, wave loads + prefilter terms, per-chunk stage check) | **15.96** | 33.1 % | 15.9 % | 24.9 (33.8 %) | 15.90, 15.97, 15.96 | **3.03** | 29.8 % | 15.4 % | 4.64 (30.6 %) |
| AND (a − z): the transposed ORs, the clipped-top range test, the popcounts | **8.35** | 17.3 % | 8.3 % | 12.0 (16.3 %) | 7.18, 8.33, 8.59 | **1.62** | 16.0 % | 8.3 % | 2.41 (15.9 %) |
| walk rounds (b − a): vote, pop, plane barrier | **6.42** | 13.3 % | 6.4 % | 10.2 (13.9 %) | 7.23, 6.42, 6.37 | **1.37** | 13.5 % | 7.0 % | 2.01 (13.3 %) |
| prefilter `walk_pf_lean` (p − b) | **16.11** | 33.4 % | 16.1 % | 26.5 (35.9 %) | 15.55, 16.11, 15.95 | **3.77** | 37.1 % | 19.2 % | 6.13 (40.5 %) |
| stage + flush (c − p) | **1.34** | 2.8 % | 1.3 % | 0.1 (0.2 %) | 0.96, 1.66, 1.30 | **0.37** | 3.6 % | 1.9 % | −0.05 (−0.3 %) |
| **join (mode c)** | **48.17** (46.83, 48.49, 48.17) | 100 % | 48.1 % | 73.7 | | **10.15** (10.11, 10.16, 10.15) | 100 % | 51.7 % | 15.15 |

Per mode (join s/field, rounds; profiled field excl. probe; mean SM MHz per round):

| mode | b62 1e17 join | field | MHz | b60 1e16 join | field | MHz |
|---|---|---|---|---|---|---|
| c full (#246) | 48.17 (46.83, 48.49, 48.17) | 100.86 | 1573, 1538, 1531 | 10.15 (10.11, 10.16, 10.15) | 20.02 | 1466, 1490, 1547 |
| a AND only | 24.30 (23.09, 24.30, 24.54) | 68.06 | 1495, 1518, 1518 | 4.65 (4.55, 4.66, 4.65) | 12.23 | 1522, 1515, 1530 |
| b walk, no prefilter, no stage | 30.72 (30.31, 30.72, 30.92) | 74.35 | 1555, 1536, 1510 | 6.02 (5.94, 6.02, 6.03) | 13.66 | 1490, 1505, 1511 |
| p walk + prefilter, no stage | 46.83 (45.87, 46.83, 46.87) | 89.82 | 1570, 1574, 1571 | 9.79 (9.76, 9.79, 9.79) | 17.32 | 1557, 1533, 1551 |
| z no AND | 15.96 (15.90, 15.97, 15.96) | 58.80 | 1662, 1535, 1560 | 3.03 (3.03, 2.99, 3.03) | 10.39 | 1568, 1515, 1530 |
| d per-top AND (TMIN 2^30) | 57.95 (57.97, 57.95, 55.90) | 110.33 | 1511, 1519, 1525 | 11.74 (11.76, 11.74, 11.72) | 21.52 | 1483, 1519, 1489 |

- **Counts:** c and d gave the exact counts in every round (b62 1e17 1,020,844,021,499 / 62,584,252,554; b60 1e16,
  two fields, 460,847,952,346 / 30,871,838,404). By design a, b and p check nothing (0) and count the join survivors
  as c does (a and p exactly; b +5 to +7 from its checksum compare, i.e. the device in L37 fires on a few of 10^12);
  z counts 0–1.
- **Against L44's derived split** (b62 1e17, seconds): base 20.9 → **16.0**, AND 1.1 → **8.4**, walk 8.9 → **6.4**,
  prefilter 14.8 → **16.1**, stage + flush 3.6 → **1.3** (join 49.2 → 48.2). The total holds; the parts moved:
  - **The AND is 8.4 s (17 % of the join, 8 % of the field), not 1 s.** L44 carried L37's main-tree marginal (3.7 s
    in time, 1.7 % of the join in cycles) through #241 and #246 unchanged. On main the AND's shared-memory ORs hid
    behind the base's three-array top gathers; #241 made the gather one sector, so the base shrank (29.7 s at 150 W
    on main → 16.0 s here) and the AND is exposed. In cycles it is 12.0 G, 16 % of the join, so it is not a clock
    artefact (AND-only runs at 1495–1518 MHz, z at 1535–1662). #246 also moved the clipped-top range test and the
    survivor popcount from the walk into this part (both cheap: the range test runs only on chunks with a clipped
    top).
  - **The base is 16 s, a third of the join**; L44 put 21 s there (L37's 29.7 s less #241's 7.4 G).
  - **The survivor path (walk + prefilter + stage) is 23.9 s at b62 (49.5 % of the join, 23.8 % of the field) and
    5.5 s at b60 (54 %, 28 %)**; the prefilter alone is a third of the join at b62 and 37 % at b60 (40 % in cycles).
  - **Stage + flush is 1.3 s / 0.37 s** (≤ 2 % of the field); in cycles it is zero within noise.
- **#239's transposed AND still pays:** the per-top AND (d) costs +9.8 s of join at b62 1e17 (field ×1.094) and
  +1.6 s at b60 (×1.075); L37 measured ×1.095 / ×1.072 on main.

## 3. Stage cadence: every chunk (c), every 4 (s7), every 8 (s8), once per top batch (s15)

**Profiled** (the main chain's rounds; join kernel seconds per field, medians; ratio = c ÷ mode):

| mode | b62 1e17 join (rounds) | vs c (per round) | field, profiled | b60 1e16 join (rounds) | vs c (per round) | field, profiled |
|---|---|---|---|---|---|---|
| c: every chunk (#246) | 48.17 (46.83, 48.49, 48.17) | | 100.86 | 10.15 (10.11, 10.16, 10.15) | | 20.02 |
| s7: every 4 chunks | 46.46 (46.31, 46.46, 46.61) | ×1.037 (1.011, 1.044, 1.033) | 99.51 | 9.64 (9.64, 9.68, 9.64) | ×1.053 (1.048, 1.050, 1.053) | 19.64 |
| s8: every 8 chunks | 45.44 (45.28, 45.44, 45.92) | ×1.060 (1.034, 1.067, 1.049) | 98.76 | 9.58 (9.48, 9.59, 9.58) | ×1.060 (1.066, 1.060, 1.060) | 19.50 |
| s15: once per top batch | 45.59 (45.13, 45.78, 45.59) | ×1.057 (1.038, 1.059, 1.057) | 98.81 | 9.54 (9.46, 9.58, 9.54) | ×1.065 (1.069, 1.062, 1.065) | 19.40 |

**Unprofiled interleaved A/B** (`chain_ab.sh`, after everything above; device s/field; order c s8 s15 / s15 c s8 /
s8 s15 c; nothing else on the GPU):

| mode | b62 1e17 s/field (rounds) | MHz | **vs c** (per round) | cycles | b60 1e16 s/field (rounds) | MHz | **vs c** (per round) | cycles |
|---|---|---|---|---|---|---|---|---|
| c | 99.49 (99.33, 99.98, 99.49) | 1465, 1502, 1474 | | | 19.53 (19.73, 19.53, 19.48) | 1465, 1483, 1533 | | |
| s8 | 97.35 (97.08, 97.44, 97.35) | 1467, 1505, 1456 | **×1.022** (1.023, 1.026, 1.022) | ×1.030 | 19.15 (19.21, 19.15, 19.13) | 1457, 1462, 1449 | **×1.020** (1.027, 1.020, 1.018) | ×1.035 |
| s15 | 97.51 (97.59, 97.51, 96.62) | 1449, 1475, 1438 | **×1.020** (1.018, 1.025, 1.030) | ×1.038 | 19.09 (19.09, 19.15, 19.06) | 1442, 1522, 1449 | **×1.023** (1.033, 1.020, 1.022) | ×1.049 |

- **Exact, and the stage never fills:** every cadence run gave the exact counts, and the spill counter
  (`NICE_EXP_JOIN_SPILLCNT=1`, one run each: c and s15 at b62 1e17, c, s7, s8, s15 at b60 1e16) counted **0** pairs
  written past a full stage in every run: a cube's 1,024-entry stage holds a whole top batch's prefilter passes on
  these fields, so checking once per batch never takes the direct-to-list path.
- **The per-chunk check costs ~2 % of the field:** checking every 8 chunks or once per batch is ×1.020–1.023 on both
  fields, unprofiled, every round ×1.018–1.033; checking every 4 chunks gets about two thirds of it. In the profiled
  join it is 2.6–2.7 s of 48.2 (b62) and 0.6 s of 10.2 (b60), ~5–6 % of the join. In cycles it is ×1.03–1.05 of the
  field: s15 ran 15–35 MHz below c at b62 (fewer barrier stalls, denser issue, more power per cycle: L44 §1.5's rule),
  so the cap takes back about half of the cycle gain.
- L37 saw nothing on main (every 4: −1.7 %, every 8: +2.8 % of the join, single screens); after #241 and #246 the
  join is lean enough for the barriers to show, but they are **~2.5 s of L44's 23 s of non-issue join time at b62**,
  not its bulk.

## 4. The spill and no-spill register variants of #246's join kernel

**What production compiles.** CubeCL compiles each kernel with NVRTC to PTX and hands the PTX to the driver
(`cuModuleLoadData`), whose JIT allocates the registers. Every process of this session kept its PTX (§0), and
`ptxjit.py` replayed the driver's JIT on it: **all 100 join kernels this session's processes compiled (60 main chain,
20 sanity, 18 A/B, 2 source dump) are spill-free**: 47–48 registers for c, d, s7, s8, s15 (1176–1184 SASS instructions at
b62), 40 for a, 43–44 for b, 47 for p, 37–38 for z; never a local-memory access. The register count does move by one
with CubeCL's per-process order of the shared arrays (47 or 48), the spills do not appear.

**Where L41's spills came from.** L41 compiled CubeCL's CUDA source offline (`nvcc -cubin -O3 -Xptxas -v`). This
session dumped the source of #246's join kernel from one process (`CUBECL_DEBUG_LOG`) and compiled it every way
(`chain_sn.sh`, `raw/box/nvcc.txt`):

| compile of the same CUDA source (b62; b60 identical) | registers | spills |
|---|---|---|
| NVRTC (CubeCL's options) → PTX → **driver JIT** (what runs) | 48 | none |
| NVRTC → PTX → offline `ptxas` 12.8 | 48 | none |
| `nvcc -cubin -O3` (L41's method) | **40** | **28 B stores** (5 `STL`, 4 `LDL`, 24 B local) |
| `nvcc -cubin -O3 -maxrregcount=40` | 40 | 28 B |
| `nvcc`, `__launch_bounds__(256, 6)` | 40 | none |
| `nvcc`, `__launch_bounds__(256, 5)` | 47 | none |
| L41's own spilling source (`P6`) through NVRTC → offline ptxas (b62 48, b60 47) and the driver JIT (b60) | 47–48 | none |

So the 40-register target with spills is a property of nvcc's offline compile of the source (its front end hands
ptxas different PTX from NVRTC's), not of the runtime path: **no production process compiles the spill variant**,
on this driver (580.159.03) at least. The spills, where nvcc makes them, sit in the work-item and batch-load code
(`0x0080`–`0x17d0`), not in the walk (`0x3250`–`0x3c90`): L41's reading holds.

**Timed separately** (`chain_sn.sh`): three pinned PTX caches holding every kernel of both fields, identical except
for the join kernel's image: **N** = the runtime's own NVRTC PTX (JIT at load), **M** = nvcc's cubin at 5 cubes/SM
(47 registers, no spill), **S** = nvcc's plain cubin (40 registers + 28 B of spills, L41's variant). CubeCL loads a
cubin from its PTX cache unchanged (`cuModuleLoadData` takes either); each pin passed the 1e14 counts at b62 and
b60 first. 3 rounds, order S N M / N M S / M S N, profile on, nothing else on the GPU:

| variant | b62 1e17 join s (rounds) | field s | MHz | b60 1e16 join s (rounds) | field s | MHz |
|---|---|---|---|---|---|---|
| N: runtime compile, 48 regs | 48.73 (48.31, 48.73, 48.78) | 101.45 | 1498, 1503, 1520 | 10.150 (10.150, 10.163, 10.098) | 19.98 | 1500, 1539, 1492 |
| M: nvcc, 5 cubes, 47 regs | **47.10** (46.99, 47.19, 47.10) | **99.78** | 1522, 1538, 1524 | **9.818** (9.812, 9.818, 9.843) | **19.64** | 1500, 1485, 1517 |
| S: nvcc, 40 regs + spills | 48.46 (47.40, 48.46, 48.50) | 101.18 | 1528, 1486, 1509 | 9.983 (9.983, 10.006, 9.980) | 19.94 | 1552, 1457, 1451 |

- **The spill costs 1.7–2.9 % of the join against the same compiler's spill-free build** (S vs M: ×0.972 at b62,
  per round ×0.991 / 0.974 / 0.971; ×0.984 at b60), **1.4–1.5 % of the field**; in cycles ×0.99–1.01 (S ran at
  lower clocks), so most of it is the clock, not the five stores.
- **The runtime's own compile is the slowest of the three:** N's join is 3.5 % (b62) / 3.4 % (b60) above M's, in
  every round (×0.973, ×0.968, ×0.966 at b62), 1.7 % of the field; in cycles 2.0 % / 3.5 %. The spill variant S is
  0.6 % / 1.6 % *faster* in the join than what production runs. The walk's round bodies are the same size in all
  three (82–84 SASS instructions per slot loop); the difference is elsewhere in the kernel and not located here.
- **Which half of the compile path** (`chain_pq.sh`, 2 more rounds, order P Q N M / M N Q P, every kernel pinned):
  **P** = the runtime's NVRTC PTX compiled by the offline ptxas 12.8 (48 registers, no spill), **Q** = nvcc's PTX of
  the same source (no launch bound) JIT-compiled by the driver (40 registers + 32 B of spills, 6 `STL`):

  | image | b62 1e17 join s (rounds) | vs M | b60 1e16 join s (rounds) | vs M |
  |---|---|---|---|---|
  | N: NVRTC PTX → driver JIT (the runtime) | 48.54 (48.43, 48.65) | ×1.035 slower | 10.074 (10.065, 10.082) | ×1.034 |
  | P: NVRTC PTX → offline ptxas 12.8 | 48.30 (48.02, 48.58) | ×1.030 | 10.084 (10.070, 10.098) | ×1.035 |
  | Q: nvcc PTX → driver JIT (spills) | 48.38 (48.22, 48.54) | ×1.031 | 10.003 (10.002, 10.004) | ×1.027 |
  | M: nvcc PTX + ptxas 12.8, 5 cubes/SM | **46.92** (46.88, 46.96) | | **9.745** (9.746, 9.743) | |

  The back end does not matter (N ≈ P: the driver's JIT and ptxas 12.8 allocate NVRTC's PTX alike), and N vs M
  repeats the first three rounds' 3.4–3.5 % in a second session. nvcc's PTX is the faster one, but only with a launch bound that lets
  ptxas keep 47 registers: left to itself ptxas targets 40 and spills (Q, S), and lands back at the runtime's speed.
  Why nvcc's and NVRTC's PTX of the same source differ (they differ throughout, not in line info: NVRTC's carries
  `-lineinfo`'s `.loc`s, and stripping them changes no allocation) is not found here; CubeCL's source may take
  different paths under `__CUDACC_RTC__` (untested). The lever, if any, is ~1.7 % of the field.

## 5. The two kill verdicts, and what the numbers say about roadmap items 1, 4 and 5

**Item 1 (static bucket order of the top layer), step 0 — kill (scan + fill < 5 % of the field): NOT fired.**
Scan + fill is **9.67 s = 9.7 %** of the b62 1e17 field and **1.77 s = 9.0 %** of b60 1e16 (unprofiled totals;
3 profiled runs each, spread ≤ 0.9 %), above L44's derived 8.7 % / 7.1 %. The fill is 8.6 / 8.0 points of it, the
scan 1.1 / 1.0, the clipped-block launches 0. The ceiling for removing both (nothing added back) is ×1.107 / ×1.099;
the roadmap's ×1.05–1.12 [E] stands and item 1 goes to its build (2–3 days, ~$1.5), with its own kill criteria
(< ×1.05 at either field, NiceMark < ×0.98). The per-kept-top price (0.254 / 0.257 ns) is L31's, so L44's scaling
argument was sound; the derivation came out low because it was a residual.

**Item 5 (re-price the lean join) — kill (stop at ~3.5 h of box time, build nothing; the roadmap's "no build unless one
part shows ≥ 5 % of the field" for its lever): no build.** Box time used: 11:10–13:50 (2 h 40 min). The join's
parts after #246 (b62 1e17 / b60 1e16, % of the field): **base 15.9 / 15.4 %, AND 8.3 / 8.3 %, walk 6.4 / 7.0 %,
prefilter 16.1 / 19.2 %, stage + flush 1.3 / 1.9 %**. The lever item 5 was looking for, the per-chunk barrier waits,
is real but small: checking the stage once per top batch (or every 8 chunks) is **×1.020–1.023** at both fields
unprofiled (exact; the stage never fills), under the 5 % bar, so no build on it alone. It is a clean rider for the
next join PR (one comptime branch; s8 needs no new barrier placement).
- **What it says about L44's 23 s of non-issue join time:** barrier waits are ~2.5 s of it. The AND is 8.4 s, not the
  1.1 s L44 carried over from main (#241 exposed it), so an issue model that put the AND's 7.1 G "mostly hidden behind
  the walk" undercounts it; L44 §3a (an AND on fewer digits, no-go at 1.1 %) and §3f's `LDS.128` digit-major read
  (≤ 1 % at 1.1 s) should be re-priced against 8.4 s (8 % of the field) before they are dropped. The survivor path is
  24 % / 28 % of the field, as L44 had it.
- **Spills:** no production process compiles the spill variant (0 of 100 runtime compiles: every process of the
  sanity, main and A/B chains, and the source dump); the variant L41 saw is nvcc's offline compile, and timed it is
  1.4–1.5 % of the field slower than nvcc's own spill-free build and no slower than the runtime's compile. Nothing to
  do about spills. The runtime's compile itself is 3.4–3.5 % slower in the join (1.7 % of the field) than nvcc's
  spill-free cubin, and §4 puts that in the front end (NVRTC's PTX), not in the driver's JIT. Under 5 %, not a lever
  by itself.

**Item 4 (the check kernel):** the check measured directly is **9.1 % (b62 1e17) and 11.3 % (b60 1e16)** of the
field (9.14 s, 2.22 s), where L44 derived 9.5 % / 11.4 %: the premise of its ×1.045–1.07 estimate stands, and the
scoping can start from these numbers.

**Item 1's neighbours in the same table:** the FD kernel is 25.2 % / 21.0 % (L44: 25.9 / 21.1), so item 2's ×1.04 from
the trims transfers as L44 computed; "other" (upload, small inputs, reads) is 6.3 % / 6.6 %, 1.5 points above L44's
residual, which is bundle C's pool.

## 6. Files

- `RESULTS.md`: this file.
- `raw/analysis.txt`: `python3 raw/scripts/analyze45.py raw/box` (every table above, per-run clocks and variants).
- `raw/box/` (the box's `/root/l45/logs` and chain outputs):
  - `san_*` (sanity, every mode at 1e14), `m_<mode>_<field>_r<round>` (main chain), `sn_<N|M|S>_*` (register
    variants), `pq_<N|M|P|Q>_*` (compile paths), `ab_<c|s8|s15>_*` (unprofiled cadence A/B), `spc_*` (spill counts),
    `snchk_*` / `pqchk_*` / `dbg_e14` (1e14 checks of the pins, the source dump): `.log` (harness output with the
    `GPU_PROFILE` lines) and `.smi` (nvidia-smi every 5 s).
  - `*_jit.txt`: every process's join kernel as the driver's JIT compiles it (registers, local bytes, SASS size,
    `STL`/`LDL`, image hash, cache key); `pins.txt`, `nvcc.txt`, `pq.txt`: how the pins were built.
  - `sass/`: the SASS of every join kernel that ran (from the driver's JIT cache) and of the nvcc / ptxas variants.
  - `dbg/`: CubeCL's CUDA source of the b62 and b60 join kernels (one process), its launch-bound variants, nvcc's
    report; `pq/`: the NVRTC and nvcc PTX of the same kernels (gzipped).
  - `box-info.txt`, `power.txt`, `nvidia-smi.txt`, `trees.txt`, `build_*.log`, `chain_*.out`.
- `raw/scripts/` (run on the box from `/root/l45`): `setup.sh`, `build.sh`, `run.sh` (harness + nvidia-smi, a fresh
  PTX cache per process, `PTXFROM=` pins one), `chain_sanity.sh`, `chain_main.sh`, `chain_sn.sh`, `chain_post.sh`,
  `chain_ab.sh`, `chain_pq.sh`; `ptxjit.py` (the runtime's JIT of a PTX cache, SASS from the JIT cache),
  `jitlog.py`, `cbor_min.py` (CubeCL's cache chunks), `pin.py` (pinned caches: another run's join image, a cubin, or a
  PTX directive), `pick.py`, `extract_ptx.py`, `nvrtc_vs_nvcc.sh` (L41's `P6` source three ways); `analyze45.py`;
  `pull.sh`.
- Branch `exp/join-l45-measure` (`8a07c05`) on the fork: the profile split, the ablation and cadence switches
  (`NICE_EXP_JOIN_ABL` 0–4, 7, 8, 15; `NICE_EXP_JOIN_TMIN`; `NICE_EXP_JOIN_SPILLCNT`), the null mark. Experimental only.

