# L51 RESULTS: d813aea profiled, ablated and retuned (RTX 3080 at 180 W, 2026-11-08; measurement only, no PR)

Measurement session on fork **`pr/top-fd-round2` `d813aea`** (= upstream main `6f060a9` + #241 + #246 + #249 (static
bucket order + the stage once per batch) + FD round 2). Experiment branch **`exp/l51-profile`** on the fork, head
**`14f87cd`** (§0). Box: Vast **59671466** (`nice-research-l51-profile`), machine **m139246**, RTX 3080 at a **180 W
cap**. Raw logs `raw/box/`, scripts `raw/scripts/`, every table below is `python3 raw/scripts/analyze51.py raw/box`
(→ `raw/analysis.txt`).

## Summary

- **Where a d813aea field goes now** (profiled shares; seconds scaled to d813aea's own unprofiled field, **79.10 s at
  b62 1e17, 15.85 s at b60 1e16 per field** on this box; L48.2's m139882 ran 73.4 s): **FD top kernel 22.8 % / 18.4 %
  (18.0 / 2.9 s), bucket 2.5 % / 2.3 %, join 55.9 % / 59.0 % (44.2 / 9.3 s), check 12.0 % / 14.4 % (9.5 / 2.3 s),
  other 6.7 % / 6.0 %**, of which the slice setup is 4.8 % / 4.5 %. Scan + fill (9.7 % / 9.0 % on #246) are gone. The
  profiled field (probe excluded) is 0.966× / 0.977× the unprofiled one in time, ×1.040 / ×0.970 in cycles (the
  profile's syncs let the card clock 104 MHz higher at b62).
- **The join by ablation** (L45's modes ported to #249's kernel, 3 interleaved profiled rounds; share of the field,
  b62 / b60): **base 10.9 % / 10.5 %, AND 14.9 % / 15.0 %, walk rounds 9.2 % / 9.0 %, prefilter 19.8 % / 23.5 %, stage
  + flush 1.1 % / 0.9 %.** #249 took the base from 15.9 % to 10.9 %; the AND rose from 8.3 % to 14.9 %
  (8.4 → 11.4 s), issue-bound by its SASS count. The per-top AND everywhere would cost ×1.14 / ×1.12 (#239 worth more
  than ever).
- **A new 3.2–3.6 % / 2.8–2.9 % lever, host-only:** the slice setup's host part is #249's `sorted_layer` (six to seven
  64-bit divisions per top-layer prefix), **2.55–2.84 s per b62 1e17 field and 0.44–0.46 s per b60 1e16 field, on the
  device thread with the GPU idle**; moving it into the field setup the client already overlaps (or computing each
  group once in u32) is ×1.03–1.04 / ×1.03 on this host's CPU (§1.1).
- **Retune (2 interleaved rounds, spill-free kernels compared; b62 / b60): no knob reaches 3 % at either field**: EPT 1 ×0.949 /
  ×0.948, EPT 3 ×0.939 / ×0.951; TRANSPOSE_MIN 128 ×1.005 / ×1.007, 256 ×0.985 / ×0.984, 512 ×0.873 / ×0.908;
  AND_GROUP 2 ×0.946 (round 1) / ×0.953, 8 ×0.990 / ×0.986; TOP_CAP 128 ×0.962 / ×0.961, 512 ×0.935 / ×0.945; FD cube 128
  ×0.991 / ×0.994, 512 ×0.994 / ×0.998; stage once per work item ×0.995 / ×1.005; SURV_FLUSH 256 ×0.999 / ×1.005,
  768 ×0.996 / ×1.008. d813aea's constants stay; nothing went to an A/B or NiceMark.
- **The 40-register spill variant of `join_kernel` costs ~3 % of the whole field in a process whose driver JIT picks
  it** (pinned images, 3 interleaved rounds: **×0.968 at b62 1e17, ×0.972 at b60 1e16**; unpinned spill / re-run pairs
  ×0.954–0.975). d813aea's own binary compiled it in **5 of 32 join kernels** (16 processes at 1e14; 0 of 8 in the
  timed chains), so ~1 compile in 7. A `.minnctapersm 5` or `.maxnreg 48` directive on the kernel's PTX gives a
  spill-free 44-register allocation every time at ×0.992–1.003 of the 46–48-register one (§3.3): ~3 % for the processes
  that would spill, ~0.4 % fleet-wide. **Method note: an A/B between two binaries carries this 3 % on either side with
  ~1-in-7 odds per process; record each process's join variant (`ptxjit.py`) or pin the PTX.**
- **Re-pricing (§4):** L44 §3a (AND on fewer digits) **no-go, ×0.92–0.97**; §3f (`LDS.128` digit-major AND) **no-go,
  ≤ 1 %** (quarter-warp conflicts double its shared-memory wavefronts); L40's group walk on the lean round **no-go,
  ≤ 3–4 % at the large fields with L40's NiceMark loss and a cube per SM lost**; COMPACT=2 **no-go, ≤ 0.5 %**; **the
  AND is issue-bound at about twice its shared-memory floor** (30 instructions per digit for 4 chunks, 8 of them
  address arithmetic, likely unfolded because CubeCL indexes `t_tr` with a `u32` sum): an index form that
  folds is ~4.3 % of the field in cycles, ~2–3.6 % in time; with a leaner bit iteration 3–5 % (go: zero-GPU codegen
  scoping).
- **Left at ≥ 3 % (ranked, §5):** (1) the check kernel (12.0 % / 14.4 %, L47); (2) `sorted_layer` off the device
  thread, ×1.03–1.04 (×1.05 / ×1.04 with the slices' buffers reused); (3) the AND's codegen, ×1.02–1.05 [E]. Below 3 %
  in expectation: the spill-variant directive (~0.4 % fleet-wide, ~3 % per affected process), TRANSPOSE_MIN 128
  (+0.5–0.7 %).
- **Exact throughout:** every full-kernel run gave the exact counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b60
  1e16, two fields, 460,847,952,346 / 30,871,838,404), every config passed at 1e14 first.
- **The box (59671466) can be destroyed:** every log, PTX-replay record and SASS dump is in `raw/box/`, nothing is
  running on it.

## 0. Setup

- **Box:** Vast **59671466** (`nice-research-l51-profile`), machine **m139246** (L38's; L47's box 59671449 is a second
  3080 in the same host), RTX 3080 10 GB, driver 580.159.03, CUDA 12.8 toolkit, **power limit 180 W** (default 340 W;
  every timed run sat at 174–180 W), Xeon E5-2630 v4, cgroup quota 9.6 CPUs, 62 GB RAM, toolchain 1.99.1. Created
  05:43 UTC, self-destroys ~12:43. This machine runs d813aea at **79.1 s** per b62 1e17 field (L48.2's m139882: 73.4 s,
  ~1475 MHz against ~1360 here); shares, not seconds, are what transfers between boxes.
- **Trees and binaries** (`raw/box/trees.txt`): **`B`** = fork `pr/top-fd-round2` **d813aea** itself (md5 `dd7e5fdf`);
  **`E`** = fork **`exp/l51-profile` `c153707`** (md5 `2117ef97`) = d813aea + `ddf6a29` (L37/L45's profile timers,
  cherry-picked from `0cfbc7d`; three conflict hunks with #249 resolved by hand, `prof_counts` rewritten for #249's
  implicit work items) + `c153707` (the top split into FD / clipped launch, one empty mark per batch, L45's ablation
  modes ported to #249's kernel, and every knob below as an environment variable passed to the kernel as a comptime
  value, so each value compiles its own kernel and the defaults reproduce d813aea's). `client_E` (md5 `3aa5344e`) is
  the NiceMark client of `E`. The branch's head `14f87cd` adds only a split of the profile's slice-setup timer (§1.1).
- **Knobs** (`raw/scripts/cfg.sh`): `NICE_EXP_JOIN_ABL` 0 full / 1 AND only / 2 walk without the prefilter and stage /
  3 walk + prefilter, no stage / 4 no AND (L45's c a b p z); `_TMIN` (TRANSPOSE_MIN), `_EPT`, `_AG` (AND_GROUP),
  `_TCAP` (TOP_CAP; 512 loads two tops a thread and transposes two chunk sets, 128 leaves half the threads out of the
  copy), `_FLUSH` (SURV_FLUSH), `_STAGE` (0 once per top batch = d813aea, 1 once per work item), `_SPILLCNT`, and
  `NICE_EXP_FD_WG` (the FD top kernel's cube size; its grid follows). `JOIN_WG` stays 256.
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b62 7997740455941656911841, b60
  1366406074057412100454), one untimed 1e14 warm-up field per process; b62 1e17 = 1 field, b60 1e16 = 2 fields (per-field
  means). nvidia-smi every 5 s; clock = mean SM MHz over samples at ≥ 90 % utilisation. Every process has its own
  CubeCL PTX cache, replayed afterwards through the driver's JIT (`ptxjit.py`, L45's) for its registers and spills.
- **Order (box UTC):** `E` built 05:52–05:57, `B` 05:57–06:01 beside the sanity chain (every config once at 1e14, b62
  and b60 in one process, 05:57–06:02); **main chain** 06:02–06:46 (3 rounds, each b62 1e17 then b60 1e16, modes
  c a b p z d u B, order rotated by 3 each round; the sanity caches' JIT replay and `client_E`'s build (3 jobs, niced)
  overlapped round 1's first 13 minutes, and no mode of round 1 is slower than in rounds 2–3); **screen** 06:46–07:04
  (first form, stopped by its name bug, §3) and 07:17–08:44 (`chain_screen2.sh`); the slice-setup split and the stage
  spill counts 07:07–07:17 (`E2` built 07:04–07:07, overlapping the last 25 s of one screen run); pinned spill images
  and B's spill frequency 08:44–09:14 (§3.3). Nothing else ran on this GPU.

## 1. Part A: where the field goes on d813aea (mode c, 3 profiled processes per field)

Medians of the 3 rounds (the rounds in brackets). "Share" is of the **profiled** field (device time excluding the
profile's own count probe), so the shares sum to 100 %; "in B s" scales each share to d813aea's own **unprofiled**
median (`B`: **79.10 s** at b62 1e17, **15.85 s** at b60 1e16 per field). L45's split of #246 (m139250, 180 W; shares of
its unprofiled field, which its profiled field exceeded by 0.6 % / 2.0 %) beside it.

| phase | b62 1e17 profiled s (rounds) | share | in B s | L45 #246 share | b60 1e16 profiled s (rounds) | share | in B s | L45 #246 share |
|---|---|---|---|---|---|---|---|---|
| **top: FD kernel** (`top_fd_kernel`, seeds incl.) | 17.42 (16.67, 17.42, 17.57) | **22.8 %** | 18.03 | 25.2 % | 2.843 (2.846, 2.843, 2.817) | **18.4 %** | 2.91 | 21.0 % |
| top: clipped-block launch (`top_kernel`, 4 a field) | 0.003 | 0.0 % | 0.00 | 0.0 % | 0.002 | 0.0 % | 0.00 | 0.0 % |
| top: scan + fill (gone with #249) | — | — | — | 9.7 % | — | — | — | 9.0 % |
| **bucket** | 1.92 (1.92, 1.94, 1.92) | **2.5 %** | 1.99 | 2.3 % | 0.349 | **2.3 %** | 0.36 | 2.3 % |
| **join** | 42.73 (41.13, 42.73, 43.23) | **55.9 %** | 44.23 | 48.1 % | 9.12 (9.15, 9.12, 9.11) | **59.0 %** | 9.34 | 51.7 % |
| **check** | 9.20 (8.83, 9.20, 9.26) | **12.0 %** | 9.52 | 9.1 % | 2.232 (2.239, 2.232, 2.218) | **14.4 %** | 2.29 | 11.3 % |
| **other** | 5.12 | **6.7 %** | 5.30 | 6.3 % | 0.927 | **6.0 %** | 0.95 | 6.6 % |
| · slice setup (`JoinDevice::new`, 11 / 2 slices a field) | 3.70 (3.85, 3.70, 3.62) | 4.8 % | 3.83 | 2.6 % | 0.690 | 4.5 % | 0.71 | 2.5 % |
| · per-batch inputs | 0.74 | 1.0 % | 0.76 | 2.1 % | 0.131 | 0.8 % | 0.13 | 2.3 % |
| · reads | 0.20 | 0.3 % | 0.21 | 0.7 % | 0.044 | 0.3 % | 0.05 | 0.8 % |
| · one empty mark per batch | 0.04 | 0.05 % | — | 0.1 % | 0.007 | 0.04 % | — | 0.1 % |
| · unattributed | 0.41 | 0.5 % | 0.43 | 0.8 % | 0.056 | 0.4 % | 0.06 | 0.9 % |
| **field, profiled (excl. probe)** | **76.41** (73.79, 76.41, 76.90) | 100 % | | | **15.48** (15.56, 15.48, 15.39) | 100 % | | |
| field, unprofiled: `B` (d813aea) / `E` (defaults) | **79.10** (79.33, 78.63, 79.10) / 79.06 | | | | **15.85** (15.87, 15.85, 15.56) / 16.42 | | | |

- **Profiled against unprofiled:** the profiled field (probe excluded) is 0.966× / 0.977× d813aea's unprofiled one in
  time; it ran 104 MHz faster at b62 (1462 against 1358 MHz: the per-kernel syncs' idle gaps let the card clock up
  under the cap, as in L45), so in cycles it is ×1.040 (b62) and ×0.970 (b60, where 6–7 clock samples a run make the
  clock ±3 %). The probe (the profile's per-batch count reads) is 5.2 s / 0.83 s and excluded. An empty mark costs
  11.6 / 10.5 µs per batch (3,288 / 625 batches).
- **What moved since #246** (L45, a different machine, so shares): scan + fill (9.7 % / 9.0 %) are gone (#249); the
  FD kernel is 22.8 % / 18.4 % (FD round 2: 5.30 / 4.55 ms per batch at 11 / 9 slots); **the join is the majority again
  (55.9 % / 59.0 %)**; **the check is 12.0 % / 14.4 %**, the largest share it has had (L47's lead); the slice setup
  doubled its share (§1.1).
- **`E` against `B`:** at b62 1e17 the defaults of `E` run d813aea's speed (79.06 against 79.10 s, every round within
  0.5 %); at b60 `E`'s unprofiled runs of rounds 1–2 compiled the 40-register spill variant of `join_kernel` and lost
  3.6–4.0 % (16.50 / 16.42 against 15.87 / 15.85 s); round 3's did not (15.69 against 15.56 s, ×0.992). §3.3.

### 1.1 The slice setup (`JoinDevice::new`), split (tree `E2`, 2 profiled processes per field, 07:07–07:12)

| | b62 1e17 (11 slices), rounds | per slice | b60 1e16 (2 slices a field), rounds | per slice |
|---|---|---|---|---|
| slice setup total | 3.68, 3.96 s | 0.35 s | 0.630, 0.642 s | 0.32 s |
| · host: **`sorted_layer`** (#249's counting sort of the top layer by group) | **2.55, 2.84 s** | 0.24 s | **0.438, 0.463 s** | 0.23 s |
| · host: everything else (bit-mask words, power table, bounds) | 0.002, 0.002 s | | 0.0004 s | |
| · buffers created and allocated (synchronised) | 1.13, 1.12 s | 0.10 s | 0.190, 0.176 s | 0.09 s |
| · `warm_top` (synchronised) | 0.003 s | | 0.002 s | |

- **`sorted_layer` is 2.55–2.84 s of the b62 1e17 field (3.2–3.6 % of d813aea's 79.1 s) and 0.44–0.46 s of b60 1e16
  (2.8–2.9 %)**, all of it on the device thread between slices, with the GPU idle. It does six to seven 64-bit
  divisions per top-layer prefix (`p0 % nk`, `p0 % m1`, `· pdiv_m1 % m1` twice, `p0 % p0mod`) over ~2.8 M prefixes a
  slice, on a 2.2 GHz Broadwell here; it depends only on the field setup, which the client prepares on another thread
  with 6× headroom (L44 §3e). **Moving it there, or computing each prefix's group once in u32 arithmetic, is
  ×1.03–1.04 at b62 1e17 and ×1.03 at b60 1e16 on this host** (less on a faster CPU), host-only and exact by
  construction. The buffers' creation (0.10 s a slice: 1.4 % / 1.2 %) is bundle C's per-slice reuse.

## 2. Part A: the join by ablation (L45's modes on #249's kernel, profile on, 3 interleaved rounds)

Join-kernel seconds per field (between syncs), medians of 3 rounds; marginal costs in the order z → a → b → p → c;
"share" = % of the profiled field (b62 76.41 s, b60 15.48 s); "in B s" = share × d813aea's unprofiled field; "cycles" =
seconds × the mode's own mean SM clock (each mode draws its own power and runs at its own clock under the cap).

| part | b62 1e17 s | % of join | share | in B s | G-cycles (% of join) | per round | L45 #246 share | b60 1e16 s | % of join | share | in B s | G-cycles (% of join) | L45 #246 share |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **base** (z: work items, the batch load from the group segments + transposed copy, wave loads + prefilter terms, the per-batch stage check) | **8.30** | 19.4 % | **10.9 %** | 8.59 | 13.1 (21.1 %) | 8.23, 8.30, 8.30 | 15.9 % | **1.62** | 17.8 % | **10.5 %** | 1.66 | 2.6 (20.4 %) | 15.4 % |
| **AND** (a − z: transposed ORs, clipped-chunk range test, popcounts) | **11.41** | 26.7 % | **14.9 %** | 11.81 | 15.6 (25.2 %) | 11.48, 11.37, 12.04 | 8.3 % | **2.32** | 25.4 % | **15.0 %** | 2.37 | 2.6 (20.9 %) | 8.3 % |
| **walk rounds** (b − a: vote, pop, plane barrier) | **7.05** | 16.5 % | **9.2 %** | 7.29 | 9.6 (15.5 %) | 7.15, 7.09, 6.27 | 6.4 % | **1.40** | 15.3 % | **9.0 %** | 1.43 | 2.3 (18.3 %) | 7.0 % |
| **prefilter** `walk_pf_lean` (p − b) | **15.14** | 35.4 % | **19.8 %** | 15.67 | 22.5 (36.3 %) | 14.95, 15.28, 15.28 | 16.1 % | **3.64** | 39.9 % | **23.5 %** | 3.72 | 5.6 (44.4 %) | 19.2 % |
| **stage + flush** (c − p) | **0.83** | 1.9 % | **1.1 %** | 0.86 | 1.2 (1.9 %) | −0.69, 0.69, 1.33 | 1.3 % | **0.15** | 1.6 % | **0.9 %** | 0.15 | −0.5 | 1.9 % |
| **join (mode c)** | **42.73** | 100 % | **55.9 %** | 44.23 | 61.9 | 41.13, 42.73, 43.23 | 48.1 % | **9.12** | 100 % | **59.0 %** | 9.34 | 12.5 | 51.7 % |

Per mode (join s/field; mean SM MHz per round; the join kernel's registers per process):

| mode | b62 1e17 join (rounds) | MHz | regs | b60 1e16 join (rounds) | MHz | regs |
|---|---|---|---|---|---|---|
| c full (d813aea's kernel) | 42.73 (41.13, 42.73, 43.23) | 1478, 1462, 1432 | 48, 48, 46 | 9.12 (9.15, 9.12, 9.11) | 1380, 1369, 1376 | 46, 48, 48 |
| a AND only | 19.71 (19.71, 19.67, 20.34) | 1470, 1455, 1410 | 45, 39, 40 | 3.94 (3.94, 3.98, 3.83) | 1380, 1245, 1350 | 40, 40, 39 |
| b walk, no prefilter, no stage | 26.76 (26.86, 26.76, 26.61) | 1425, 1440, 1423 | 40, 39, 40 | 5.34 (5.47, 5.34, 5.24) | 1405, 1350, 1425 | 40 |
| p walk + prefilter, no stage | 41.90 (41.82, 42.04, 41.90) | 1453, 1412, 1512 | 47 | 8.98 (8.98, 9.04, 8.89) | 1451, 1436, 1482 | 47 |
| z no AND | 8.30 (8.23, 8.30, 8.30) | 1588, 1412, 1965 | 37–40 | 1.62 (1.62, 1.63, 1.61) | 1485, 1650, 1582 | 36–37 |
| d per-top AND (TMIN 2^30) | 53.41 (54.13, 51.74, 53.41) | 1408, 1431, 1460 | 48 | 10.99 (11.06, 10.99, 10.98) | 1430, 1431, 1419 | 47–48 |

- **Counts:** c and d gave the exact counts in every round (b62 1e17 1,020,844,021,499 / 62,584,252,554; b60 1e16,
  two fields, 460,847,952,346 / 30,871,838,404); a and p count the join survivors exactly and check nothing; b's
  checksum compare fires +1 to +5 times in 10^12, z's 0–2 (L37's device, as in L45). The clock of z's runs is from few
  samples (its kernels leave the card under 90 % busy between syncs).
- **The base fell from 15.9 % to 10.9 % of the field** (15.96 → 8.30 s at b62, two machines): #249's batch load reads
  a group's records in order instead of gathering them through `tl`, and its rider checks the stage once per batch.
  **The AND rose from 8.3 % to 14.9 %** (8.35 → 11.41 s; 12.0 → 15.6 G-cycles). An issue count of its SASS reproduces
  the 15.6 G to 80–90 % (§4), so it is issue-bound; the likely reading (not separately measured) is that with the
  gather latency gone its instructions no longer overlap anything. It is now the third-largest item of the field after
  the FD kernel and the prefilter, ahead of the check.
- **The survivor path** (walk + prefilter + stage) is 23.0 s / 5.2 s, **30.1 % / 33.5 % of the field**; the prefilter
  alone is a fifth of the b62 field and almost a quarter of b60's.
- **Stage + flush is ~1 %** with the stage checked once per batch (its round-to-round spread, ±1 s, is the noise of
  differencing two 42-s modes).
- **#239's transposed AND still pays more than ever:** the per-top AND everywhere (d) costs +10.7 s of join at b62 1e17
  (**×1.142** on the profiled field) and +1.9 s at b60 (**×1.117**); L45 measured ×1.094 / ×1.075 on #246.

## 3. Part B: retune screens (unprofiled, one binary, every value its own comptime kernel, 2 interleaved rounds)

`chain_screen2.sh`: per round b62 1e17 then b60 1e16, every variant once, the base (d813aea's constants) at the start and
in the middle of each block; round 2 runs the list reversed. **Ratio = local base ÷ variant**, the local base being the
base runs of the same round nearest in time before and after (the base's own runs scattered by up to 3 % within a
block, b62 round 1: 76.27–78.72 s; the round-mean ratio is in `raw/analysis.txt`). After every run its join kernel was replayed through
the driver's JIT; a run that had compiled the 40-register spill variant (§3.3) was kept as `*_spill<k>` and re-run, up
to twice, so the ratios compare spill-free kernels (TOP_CAP 512 compiles 40 registers + 8 B in every process: its
third try stands). Every run gave the exact counts.

The first form of the chain (`chain_screen.sh`, 06:46–07:04) had a name bug (`${v%2}` turned `tm512`, `ag2`, `tc512`,
`fd512` into unknown names, which ran the defaults); its valid runs (round 1 b62: base, EPT 1/3, TMIN 128/256, AG 8,
base2) were kept, the two mislabelled ones count as base runs (`base3`, `base4`), and `chain_screen2.sh` (07:17–08:44)
finished round 1 with two more base runs (`base5`, `base6`) and ran round 2.

### 3.1 The retune table (× = local base ÷ variant; mean of 2 rounds, per round in brackets; > 1 is faster)

| knob | value (d813aea's in bold) | b62 1e17 | b60 1e16 | cubes/SM | verdict |
|---|---|---|---|---|---|
| EPT (`JOIN_WG` 256) | 1 | ×0.949 (0.949, 0.949) | ×0.948 (0.949, 0.947) | 5 | loses 5 % |
| | **2** | 1 | 1 | 5 | **stays** |
| | 3 | ×0.939 (0.937, 0.940) | ×0.951 (0.955, 0.947) | 4 | loses 5–6 % |
| TRANSPOSE_MIN | 128 | ×1.005 (1.005, 1.006) | ×1.007 (1.012, 1.003) | 5 | **+0.5–0.7 %: noise level (base runs scatter ±1.3 %); < 3 %, recorded** |
| | **192** | 1 | 1 | 5 | stays |
| | 256 | ×0.985 (0.982, 0.988) | ×0.984 (0.987, 0.981) | 5 | loses 1.5 % |
| | 512 (= per-top AND everywhere) | ×0.873 (0.870, 0.875) | ×0.908 (0.898, 0.918) | 5 | loses 9–13 % (#239's value: ×1.10–1.15) |
| AND_GROUP | 2 | ×0.946 (round 1; round 2 compiled the spill variant three times: ×0.910) | ×0.953 (0.949, 0.957) | 5 | loses 5 % |
| | **4** | 1 | 1 | 5 | stays |
| | 8 | ×0.990 (0.996, 0.983) | ×0.986 (0.984, 0.987) | 4 | loses 1–1.5 % (~5.6 issued per digit and chunk against 7.5, but one cube per SM fewer) |
| TOP_CAP (TMIN scaled) | 128 (TMIN 96) | ×0.962 (0.957, 0.967) | ×0.961 (0.962, 0.960) | 5 | loses 4 % |
| | **256** | 1 | 1 | 5 | stays |
| | 512 | ×0.935 (0.941, 0.928) | ×0.945 (0.954, 0.935) | **3** | loses 5.5–6.5 % (shared-memory bound) |
| FD kernel cube size | 128 | ×0.991 (0.986, 0.996) | ×0.994 (1.015, 0.973) | FD 16 warps/SM | neutral |
| | **256** | 1 | 1 | 16 warps/SM | stays |
| | 512 | ×0.994 (0.990, 0.998) | ×0.998 (1.017, 0.980) | 16 warps/SM | neutral |
| stage check cadence | **once per top batch** | 1 | 1 | 5 | stays |
| | once per work item | ×0.995 (0.991, 0.998) | ×1.005 (1.017, 0.994) | 5 | neutral; at b60 98.8 M pairs a run (0.32 % of the checked) go past a full stage to the list (§3.4) |
| SURV_FLUSH | 256 | ×0.999 (0.999, 0.999) | ×1.005 (1.017, 0.993) | 5 | neutral |
| | **512** | 1 | 1 | 5 | stays |
| | 768 | ×0.996 (0.998, 0.995) | ×1.008 (1.020, 0.997) | 5 | neutral (0.85 M pairs past the stage at b60) |

- **No retune reaches 3 % at either field; every constant tuned on an older kernel is still at (or within noise of)
  its optimum on d813aea.** The kill fires for every knob: recorded, nothing shipped, no A/B or NiceMark was due
  (`chain_ab.sh` was written for a winner and not run).
- **Noise:** the base's own runs within a round scatter by up to 2.6 % (b62 round 1: 76.27–78.72 s over 46 minutes;
  cause not known; the host carries L47's 3080 too), hence the local base; with it the two rounds
  of a variant agree to ≤ 1 % at b62 and ≤ 2 % at b60 (one exception: the FD sizes and the cadence/flush variants at
  b60, ±2 %, all straddling 1). Every ratio within ±1 % of 1 is noise.
- **TRANSPOSE_MIN 128** is the only positive: +0.5 % / +0.7 %, the same sign in all four runs. It moves transposition
  into batches of 128–191 tops (the third batch of a work item). Too small to ship; if a join PR goes up anyway, the
  gate could ride along after a NiceMark check (the small-bucket scenarios are where #239's gate came from).
- **The losers say where the kernel sits:** EPT 2 is still the wave size (1 halves the lanes per wave and doubles the
  waves of the 256–479-entry buckets; 3 costs a cube per SM); AND_GROUP 4 is still right, but AND_GROUP 8 loses only
  1–1.5 % while taking the kernel to 4 cubes per SM: amortising the AND's per-digit iteration over more chunks nearly
  pays for a cube, which is §4's point about where the AND's cost is; TOP_CAP 512 is
  shared-memory bound (3 cubes per SM); the FD kernel's cube size does not matter (same 16 warps per SM at every size);
  the stage cadence and flush level are flat since #249's once-per-batch check.

### 3.2 Registers and occupancy (the driver's JIT of every process's PTX; `raw/box/*_jit.txt`)

Shared memory per join cube: 8 top arrays × TOP_CAP words + `t_tr` (TOP_CAP × 8 B) + the stage (8 KiB) + ~0.1 KiB =
18.1 KiB at TOP_CAP 256 (13.1 at 128, 28.2 at 512), plus 1 KiB the hardware reserves per cube, against 100 KiB per SM.

| variant | `join_kernel` registers (spill-free processes) | cubes per SM (registers / shared memory) | what changes |
|---|---|---|---|
| base | 46–48 | **5** (5 / 5) | |
| EPT 1 | 38–40 | **5** (6 / 5) | waves of 256 entries: 2 waves for most b62 buckets (256–479 entries) |
| EPT 3 | 63–64 | **4** (4 / 5) | waves of 768: more empty lanes, one cube fewer |
| AND_GROUP 2 | 46 (or 40 + 16–32 B spills) | 5 | the digit iteration amortised over 2 chunks instead of 4 |
| AND_GROUP 8 | 53–55 (or 48 + 16 B spills) | **4** (4 / 5) | 8 accumulators per entry slot |
| TOP_CAP 128 (TMIN 96) | 46–48 | 5 (5 / 7) | twice the batches per work item; half the threads idle in the transposed copy |
| TOP_CAP 512 | **40 + 8 B spill in every process** | **3** (6 / 3) | shared-memory bound |
| TRANSPOSE_MIN 128 / 256 / 512 | 46–48 | 5 | the gate only |
| FD cube 128 / 512 | `join_kernel` unchanged; `top_fd_kernel` 108 / 107 (b62 / b60) at every size | FD: 16 warps per SM at 128, 256 and 512 (4 × 128, 2 × 256, 1 × 512) | grid shape only |
| stage per work item, SURV_FLUSH 256 / 768 | 46–48 | 5 | |

### 3.3 The 40-register spill variant of `join_kernel`

Every process compiles its kernels from CubeCL's PTX through the driver's JIT. For d813aea's join kernel the JIT
allocated either 46–48 registers with no spill or **40 registers with 24 B of spills (3 `STL` / 3 `LDL`, in the work-item
and batch-load code at `0x0b20`–`0x0e20`, not in the inner loops)**, depending on the process (CubeCL's per-process
ordering of the shared arrays changes the PTX, L45). L45 saw no runtime spill on #246 (0 of 100); L46's review saw it on
#249 (7 of 37 images). Here:

- **How often:** `E`'s unprofiled default processes 5 of 21 (main chain `u` 2 of 6, both at b60; the screen's base runs
  3 of 15), `E`'s profiled `c` 0 of 6, the other screen configs 0–4 of 4–7 processes each (`TOP_CAP 512`: 40 + 8 B in
  every process, a different variant); **d813aea's own binary `B` 5 of 32 join kernels in 16 processes at 1e14 (`bfreq_*`: three at b62, two at b60),
  0 of 8 in the main and sanity chains: about one compile in seven to eight**.
- **What it costs** (the same config spilled and then re-run spill-free, `raw/analysis.txt` "Spill tax"; same round,
  minutes apart): **b62 1e17 ×1.028–1.048 slower in eight pairs (median ×1.039); b60 1e16 ×1.026–1.031 in three pairs,
  and `E`'s `u` against `B` ×1.036 / ×1.040.** The variants with one `STL` (stage once per work item) or 48 registers +
  16 B (AND_GROUP 8) cost ≤ 1 %. Likely most of the cost is not the spill traffic (two stores and loads per batch) but
  the tighter allocation: the spill variant's outer loop carries more recomputation (1,071 instructions, 294 `IMAD`,
  against 1,046 and 274; the inner loops are the same size).
- **Pinned** (`chain_post.sh`, 3 interleaved rounds per field, unprofiled; L45's `pin.py`): S = a spilled process's PTX
  cache as it was, N = the same cache with the join kernel from the same config's spill-free process, D = S's PTX with
  `.minnctapersm 5` added to `join_kernel` (the occupancy the kernel runs at, which CubeCL's `__launch_bounds__(256)`
  does not state; the driver's JIT then allocates 44 registers, no spill):

| image | b62 1e17 s/field (rounds) | vs N (per round) | b60 1e16 s/field (rounds) | vs N (per round) | `join_kernel` |
|---|---|---|---|---|---|
| S: the spill variant, as compiled | 79.21 (79.21, 79.17, 79.50) | **×0.968** (0.973, 0.968, 0.965) | 15.92 (16.03, 15.92, 15.89) | **×0.972** (0.963, 0.973, 0.972) | 40 + 24 B (3 `STL`) |
| N: spill-free, same config | 76.69 (77.03, 76.64, 76.69; rounds 4–5: 75.62, 76.93) | 1 | 15.44 (15.43, 15.50, 15.44; 15.44, 15.52) | 1 | 48 / 46 |
| D: S's PTX + `.minnctapersm 5` | 77.44 (77.69, 77.26, 77.44) | ×0.992 (0.992, 0.992, 0.990) | 15.52 (15.52, 15.52, 15.46) | ×0.999 (0.995, 0.999, 0.999) | 44, no spill |
| M: S's PTX + `.maxnreg 48` (rounds 4–5, `chain_post2.sh`) | 76.36 (74.86, 77.86) | ×0.999 (1.010, 0.988) | 15.44 (15.36, 15.52) | ×1.003 (1.006, 1.000) | 44, no spill |

- **The spill variant costs 3.2 % / 2.8 %** of the whole field with everything else identical (every kernel image
  pinned; exact counts in every run, 1e14 checks first).
- **Both directives make the driver's JIT allocate 44 registers with no spill** (the same 1,208-instruction SASS), within
  ×0.992–1.003 of the 46–48-register allocation, i.e. at its speed within this session's noise. CubeCL emits
  `__launch_bounds__(256)` only; a `__launch_bounds__(256, 5)` (which NVRTC turns into `.minnctapersm 5`) would make
  every process's join kernel spill-free. Worth ~3 % to the ~1-in-7 processes that spill today, ~0.4 % fleet-wide
  (below 3 % in expectation); and it removes a 3 % coin-flip from every A/B.

### 3.4 Pairs past a full stage (`NICE_EXP_JOIN_SPILLCNT=1`, one profiled run each, 07:12–07:17)

| config | b62 1e17 | b60 1e16 (2 fields) |
|---|---|---|
| d813aea (stage once per top batch, flush at 512) | 0 | 0 |
| stage once per work item | 0 | 98,787,209 (0.32 % of the checked pairs) |
| SURV_FLUSH 768 | | 852,535 |
| TOP_CAP 512 | | 35 |

All exact (the pairs past a full stage go to the list directly and are checked like the rest).

## 4. Re-pricing by arithmetic (brief part C; no builds)

Inputs (§2, in d813aea's unprofiled seconds, b62 1e17 / b60 1e16; fields 79.10 / 15.85 s): **AND 11.81 / 2.37 s
(14.9 / 15.0 %)**, walk rounds 7.29 / 1.43 s, prefilter 15.67 / 3.72 s, stage + flush 0.86 / 0.15 s; survivor path
(walk + prefilter + stage) 23.8 / 5.3 s (30.1 / 33.5 %). AND pass rate (join survivors ÷ pairs tested): 1.021e12 ÷
2.532e13 = **4.03 %** (b62), 4.608e11 ÷ 5.520e12 = 8.35 % (b60). Clock rule (L44 §1.5): an issue trim keeps 50–85 % of
its cycle gain in wall time under the cap; L40's group walk kept 47 %.

**The AND as compiled** (d813aea's `join_kernel`, b62, driver JIT, `raw/box/sass/san_base_4_*.sass`): the transposed
AND's digit loop (`0x2bd0–0x2da0`, one copy per entry slot) is **30 instructions per digit for the group's 4 chunks**:
4 `LDS` + 4 `LOP3` (the ORs) are the work; **8 are address arithmetic** (CubeCL indexes `t_tr` with a `u32` sum,
`shared_memory_11[l + 64]` in #246's CUDA source (L45's dump; this loop is unchanged since), which likely keeps the
compiler from folding the +64/+128/+192 words into the load's immediate offset as it does in the walk
(`LDS [R18+0x283c]`): 3 `IADD3` + 4 `IMAD` with the base from `c[0x2][0x10]` + 1 `IMAD.IADD`);
**3 are loop invariants recomputed every iteration** (`ULEA`, `IMAD.MOV R37 = 4`, `IMAD.U32`); 11 are the set-bit
iteration over the two mask words (`ISETP`, `SEL`×4, `BREV`, `FLO`, `IADD3`, `LOP3`×2, `BRA`). Per (warp, group of 4
chunks, both entry slots): 2 × (10 + 12 × 30) + 4 × ~25 (per-chunk pass masks, clip word, popcounts) ≈ **840 issued**.
Over the field's 3.907e13 padded pairs (85–95 % of them in transposed batches) that is **12.5–14.0 G-cycles at full
issue (272 warp-instructions a clock) against the measured AND of 15.6 G** (b62; b60 2.3–2.5 against 2.6 G). The AND
is issue-bound; the likely reason it grew (L45 8.4 s, here 11.8 s) is that #241 and #249 removed the base latency it
used to overlap with.

**(a) L44 §3a, the AND testing fewer digits — no-go, ×0.92–0.97.** With 12 entry digits the pass rate 4.03 % gives a
per-digit pass chance 1 − p, p = 1 − 0.0403^(1/12) = 0.235 (b60: 0.187). Dropping one digit saves 1/12 of the digit
loop (86 % of the AND's issue): **−0.84 s / −0.17 s**. It multiplies the pass bits by 1/(1 − p) = ×1.31 / ×1.23, and
the survivor path follows the pass bits (rounds track the heaviest lane, so ×1.15–1.31): **+3.6 to +7.3 s / +0.8 to
+1.2 s**. Net ×0.92–0.97 at b62, ×0.94–0.96 at b60. A per-chunk skip of digits no top has needs a test per digit that
costs what the OR costs. Same verdict as L44, now against a 10× larger AND.

**(b) L44 §3f, a power-cheaper AND (digit-major `t_tr` read as one `LDS.128` per digit) — no-go, ≤ 1 %.** It removes
3 `LDS` and ~6 address instructions per digit (30 → ~21), but a 128-bit shared load is served in quarter-warp phases,
and lanes walking their sorted digits in step collide within a phase: **7.4–7.9 wavefronts per digit against 4.2–4.4
for four `LDS.32`** (`raw/scripts/lds_sim.py` → `raw/lds_sim.txt`: 12 or 14 digits from 40–62 free values; the `LDS.32`
form only conflicts on p and p + 32). Per (warp, group): shared memory 2 × 12 × 7.7 ≈ 185 SM-clocks against ~156 of
issue after the change, so it becomes shared-memory-bound at 185 against today's issue-bound ~210: **−12 % of the AND
in cycles (~1.4 s / 0.3 s, 1.8 % of the field)**, and a denser shared-load stream costs clock (the AND-only kernel ran at
1455 / 1350 MHz against the AND-free kernel's 1588 / 1582, b62 / b60, from few clock samples) → ≤ 1 % in time. The clock angle by itself is no lever: the AND is
power-dense because it is instruction-dense; cutting its instructions is the way to cut its watts.

**(c) L40's group walk on the 41-instruction round — no-go, ≤ 3–4 % at the large fields with a NiceMark loss.** Per-round
work (walk + prefilter) is 22.96 s / 5.15 s. L40 [M]: plane-rounds ×0.646 (b62) / ×0.610 (b60); its round grows by
the word pick (19 instructions; 139 against 110 SASS on #241). On the lean round (47.3 issued: 41 + 16 × 0.394):
pick on every round → ×0.646 × 66.3/47.3 = **×0.906 / ×0.855** of the per-round work = −2.2 s / −0.75 s (2.7 % /
4.7 % of the field in cycles); pick on about half the rounds (+10) → ×0.783 / ×0.739 = −5.0 s / −1.3 s (6.3 % / 8.5 %).
At L40's 47 % clock retention: **1.3–3.0 % (b62), 2.2–4.0 % (b60) in time.** Against it: L40's own small-batch loss
(MSD-strong ×0.963, 1e14 ×0.955–0.970 [M]; on batches below TRANSPOSE_MIN the group walk saves no rounds, five variants
failed to fix it), so NiceMark's kill fires; registers 47–48 + ~5 → 52–53, i.e. 4 cubes per SM instead of 5 (L40's base
was 40, so its numbers do not include that); and part of L40's measured ×1.056 was the stage checked once per group,
which #249 has banked already.

**(d) L37's COMPACT=2 — no-go, ≤ 0.5 %.** [M] on main: ×1.015 in time, ×1.007 in cycles at b62 1e17, with a 110-SASS
round. The rounds it saves are worth 41/110 as much on the lean round while its loop overhead stays: ≤ 0.37 × 0.7 % ≈
0.3 % in cycles (~0.5 % in time with main's clock bonus); +5 registers (L37: 40 → 45) put the kernel at 52–53, 4 cubes
per SM.

**(e) The AND's shared-load bound — the AND is issue-bound at about twice its floor; go for a codegen scoping.** LDS
wavefronts per 32-bit digit load: 1.05–1.09 (simulated: only p and p + 32 share a bank). Floor: 2 × 12 × 4 × 1.08
wavefronts per (warp, group) → **6.2–6.9 G-cycles at b62 (1.1–1.2 G at b60), 40–48 % of the measured AND**. So
52–60 % of the AND (**6.1–7.1 s, 7.8–9.0 % of the b62 field; 1.2–1.4 s at b60, in cycles**) is instruction overhead above the
shared-memory floor. The cheapest piece: an index form the compiler can fold (8 address instructions → 1, plus the 3
hoistable invariants): 30 → ~20 per digit, **−29 % of the AND's issue ≈ 3.4 s / 0.7 s = 4.3 % of the field in cycles,
~2.1–3.6 % in time**. Zero-GPU scoping first: NVRTC-compile `join_kernel` with the index masked to the array
(`(l & 511) + 64c` may let the compiler prove no wrap) or as one base pointer plus constant offsets, and read the SASS.
Together with a leaner set-bit iteration (11 → ~7) the AND's issue drops ~40 % (6.0 % of the field in cycles, 3.0–5.1 % in
time).

## 5. What is left at ≥ 3 % (ranked; d813aea on a 180 W 3080; b62 1e17 / b60 1e16)

| # | item | where it sits | expected | basis | cost / next step |
|---|---|---|---|---|---|
| 1 | **Check kernel rework** (L47, design D, in flight) | check 12.0 % / 14.4 % (9.5 s / 2.3 s) | ×1.05–1.09 / ×1.06–1.12 | [E] L47 scoping; the share it prices is confirmed here | L47's box, today |
| 2 | **`sorted_layer` off the device thread** (group each prefix once, in u32, in the field setup the client already overlaps) | 2.55–2.84 s / 0.44–0.46 s, 3.2–3.6 % / 2.8–2.9 % of the field, GPU idle | **×1.03–1.04 / ×1.03** on this host's CPU (less on faster CPUs); with the slices' buffers reused too (1.4 % / 1.2 %) ×1.05 / ×1.04 | [M] cost (§1.1); removal [D] | host-only, ~0.5 day, exact by construction; A/B + NiceMark on any 3080 |
| 3 | **AND codegen**: fold the transposed AND's shared-memory index arithmetic (8 of its 30 instructions per digit) and hoist 3 loop invariants; then a leaner set-bit iteration | AND 14.9 % / 15.0 %, issue-bound at ~2× its shared-memory floor | fold + hoist: 4.3 % in cycles, **×1.02–1.04 in time**; with the iteration (−40 % of the AND): ×1.03–1.05 | [D] SASS issue model (80–90 % of the measured AND) + [E] the cap's 50–85 % | zero-GPU scoping (NVRTC + SASS of an index form), then one A/B; rider for the next join PR |
| 4 | spill-free `join_kernel` allocation (`__launch_bounds__(256, 5)`, i.e. `.minnctapersm 5`) | the 40-register spill variant, ~1 compile in 7 | **~×1.03 for the processes that compile it, ~×1.004 fleet-wide**: below 3 % in expectation | [M] §3.3 (pinned) | a CubeCL launch-bound option or a PTX post-pass; cheap rider; makes A/Bs cleaner |
| 5 | TRANSPOSE_MIN 192 → 128 | | ×1.005 / ×1.007 | [M] screen, noise level | rider only, after a NiceMark check |
| — | no lever priced at ≥ 3 % | FD kernel 22.8 % / 18.4 % (none new here; persistence −1 to +2 %, L44 §2A); prefilter 19.8 % / 23.5 % (L44 §3b no-go stands); bucket 2.5 %; per-batch inputs 1.0 % | | | |
| — | no-go (§4, §3) | group walk ≤ 3–4 % at the large fields with a NiceMark loss and a cube per SM lost; COMPACT=2 ≤ 0.5 %; the AND on fewer digits ×0.92–0.97; `LDS.128` AND ≤ 1 %; every retune knob | | | |

## 6. Files

- `RESULTS.md`: this file. `BRIEF.md`: the brief.
- `raw/analysis.txt`: `python3 raw/scripts/analyze51.py raw/box` (every table above: sanity, main chain, phases,
  ablation, screen with local and round-mean bases, spill pairs, pinned images, B's spill frequency).
- `raw/lds_sim.txt`: `python3 raw/scripts/lds_sim.py` (shared-memory wavefronts of the transposed AND's loads, §4).
- `raw/box/` (the box's `/root/l51/logs` and chain outputs): `san_*` (sanity, every config at 1e14), `m_<mode>_<field>_r<n>`
  (main chain), `x_up_*` (the slice-setup split, tree `E2`), `x_spc*` (spill counter), `s_<variant>_<field>_r<n>`
  (screen; `*_spill<k>` the spill-variant runs that were re-run), `pchk_*` / `pn_<S|N|D|M>_*` (pinned join images),
  `bfreq_*` (B's spill frequency): `.log` (harness output, `GPU_PROFILE` lines) and `.smi` (nvidia-smi every 5 s);
  `*_jit.txt` (every process's join kernel through the driver's JIT: registers, local bytes, SASS size, STL/LDL);
  `pins.txt`; `trees.txt`, `box-info.txt`, `power.txt`, `nvidia-smi.txt`, `build_*.log`, `chain_*.out`, `go*.out`.
- `raw/box/sass/` (gzipped): SASS of every kernel of the sanity processes (`san_<cfg>_<i>_<hash>.sass.gz`; the join
  kernel is entry 4 (b62) and 9 (b60); `san_base_4_*` is the one §4 reads) and of the pinned images (`S/N/D/M60|62_4_*`).
- `raw/scripts/` (run on the box from `/root/l51`): `setup.sh`, `build.sh`, `buildclient.sh`, `run.sh`, `run_pin.sh`,
  `cfg.sh` (config → environment), `go.sh`, `go2.sh`, `chain_sanity.sh`, `chain_main.sh`, `chain_screen.sh` (first form,
  stopped), `chain_screen2.sh`, `chain_extra.sh`, `chain_post.sh`, `chain_post2.sh`, `chain_ab.sh` (written for a ≥ 3 % winner;
  not run);
  `ptxjit.py`, `cbor_min.py`, `jitlog.py`, `pin.py`, `pick.py` (L45's), `nm_table.py` (L48's); `patch51.py` (the
  experiment commit `c153707` as a script over d813aea + `ddf6a29`), `patch51b.py` (`14f87cd`); `analyze51.py`,
  `lds_sim.py`; `pull.sh`.
- Branch **`exp/l51-profile`** on the fork, head **`14f87cd`** (`ddf6a29` profile timers on d813aea, `c153707` the
  split, ablation modes and knobs, `14f87cd` the slice-setup split). Experimental only; no PR.
