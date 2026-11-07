# L48 RESULTS: FD top kernel, round 2 (RTX 3080 at 170 W, 2026-11-07)

Experiment branch **`exp/top-fd-round2`** on the fork, head **`f168b28`**: `f3fb390` (fork `pr/join-lean-prefilter`
= upstream main `6f060a9` + #241 + #246) + `9a93531` (levels 1–4 and 103 behind `NICE_EXP_TOPFD`) + `c27ed83`
(level 5) + `c50f584` (level 6) + `f168b28` (level 7). PR form (no knobs, the shipped level only, CHANGELOG line):
**`3d2395b`** on `f3fb390`, SUMMARY_PR_LINE. Box: Vast **59529585** (`nice-research-l48-fdround2`), machine m139882,
RTX 3080 10 GB, **170 W cap** (default 320 W). Raw logs `raw/box/` (the box's `/root/l48/logs` and chain outputs;
CUDA sources, SASS and driver-JIT SASS per level in `raw/box/sass/`), scripts `raw/scripts/`, patches `raw/patch/`
(`p1.py` levels 1–4, `p3.py` level 5, `p2.py` the PR form), tables in `raw/*_table.md`.

SUMMARY_PLACEHOLDER

## 0. Setup

- **Box:** Vast 59529585, machine m139882, RTX 3080 10 GB (VBIOS 94.02.42.00.8E), driver 580.178.04, CUDA 12.8
  toolkit (offline `nvcc`, `cuobjdump`), **power limit 170 W** (default 320 W; the container cannot change it; every
  timed run sat at 167–170 W). Xeon E5-2660 v3, cgroup quota 19.2 CPUs. Toolchain 1.99.1. Nsight Compute is in the
  image but the container has no access to the GPU's performance counters (`ERR_NVGPUCTRPERM`,
  `RmProfilingAdminOnly: 1`), so instruction counts below are static SASS, not executed instructions.
- **Trees and binaries** (`raw/box/trees.txt`; one shared target dir, `cargo clean -p nice_common` before each
  build; lavapipe builds in their own target dir):

  | tree | source | binaries (md5, first 8) |
  |---|---|---|
  | `B` | `f3fb390` (the base) | `B` da541f0a, `client_B` bfe977d3 |
  | `X` | `exp/top-fd-round2` `9a93531` (levels 0–4, 103) | `X` f720bf52, `client_X` 5c5a7c41, `X_naga`, `X_spv` |
  | `X7` | `exp/top-fd-round2` `f168b28` (levels 0–7, 103) | `X7` 7296db4a |
  | `P` | `3d2395b` (the PR form: level 6 without knobs) | `P` 244f1fd3, `client_P` 8084e3c7, `P_naga`, `P_spv` |

- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60 1366406074057412100454, b62
  7997740455941656911841, b64 41242006262957161709568), one untimed 1e14 warm-up field per process; b62 1e17 = 1
  field, 1e16 = 2 fields in flight (per-field means), metric `device=`. nvidia-smi every 5 s; clock = mean SM MHz over
  samples at ≥ 90 % utilisation; "cycles" = device seconds × the run's mean clock (the clock-normalised ratio).
- **Kernel alone:** #240's `cubecl_cuda_top_fd_timing` (first slice of the production plan, 40 batches of
  consecutive partitions → c, 40 of every other partition, where every FD slot seeds → g, three rounds a process);
  **stepped slot s = (k·c − g)/(k − 1)**, k = slots a batch, normalised by `top_kernel`'s time in the same round
  (L36's method, `raw/scripts/topt48.py`).

## 1. The levels (`NICE_EXP_TOPFD`, read in `JoinDevice::new` and passed to `top_fd_kernel` as a comptime)

Cumulative unless said otherwise. Each is exact by construction (the argument is given with each); level 0 is
#240's kernel (the same CUDA source, registers and SASS as `B`'s, `raw/registers.txt`).

| level | adds | what it removes from a stepped slot | why it is exact |
|---|---|---|---|
| **1** | L36.2's three trims, ported: **carried c0 and e = b^c0 − 1 − d** (L36's `LC0`, but carrying b^c0 − 1 − d instead of b^c0 − d), **short path for scanned words above the run** (`LSCAN`), **stepping slots skip a, e and the clip test** (`LCLIP`) | both power-table reads (`ndig_fast`'s compare and the carry test's b^c0), `ndig_fast` itself, the binary step of d (it becomes the step of e), the carry test's add-and-compare (now one subtraction chain whose borrow is the carry), the per-digit c0 test / selects / low term / run bookkeeping for every scanned word after the run ended, and the multiply, add and six compares forming a, e and the clip flags | d grows by its step each slot; while d < b^c0, c0 = max(cap, ndig(d)) cannot move (ndig(d) ≤ c0 and ndig is non-decreasing); d ≥ b^c0 ⟺ e borrows, and then d = b^c0 − 1 − e (mod 2^32nl) is recovered and c0, e re-formed as at a seed (no re-forming once c0 = sp, where the carry test is skipped). The carry is (x mod b^c0) + d ≥ b^c0 ⟺ x mod b^c0 > e. The run ends only at a digit ≥ c0, so after it every digit is above c0 and the per-digit step reduces to setting its bit in both masks. Only P = plo and P = phi can be clipped, and a step uses neither a nor e. |
| **2** | the append's plane scans as **one ballot**: count = popcount of the ballot, rank = popcount of the ballot's bits below the lane (up to 128 lanes a plane) | `plane_sum` (a `REDUX` on sm_86) and `plane_exclusive_sum` (5 `SHFL.UP` + adds, 1 more `SHFL` and a select): SHFL 7 → 2, VOTE 0 → 2, POPC 8 → 10 in the kernel's SASS | the same two numbers from the same flags |
| **3** | **partial x mod b^c0**: words of x ending 4+ digits below c0 are left out; with dd = e − H (H the partial sum), the carry is decided unless dd < b^p (p = the first kept word's position), and then the left-out words are added and the test redone | for the cube at b62 1e17 (c0 ≈ 28) three of the five words below c0 (the `low` value and its multiply-add into the remainder), for the square one of three | L < b^p for the left-out sum L, and H ≡ 0 mod b^p: H > e → carry; else carry ⟺ L > dd, impossible when dd ≥ b^p. `103` = level 3 with the fallback forced whenever a word is left out (tests that path). |
| **4** | `SURV_PER_PREFIX` 2 → 1 in `join_plan.rs` (kernel = level 3) | about half the seeds per field (more slots a batch), fewer batches and slices | the plan's budget and binding bounds are unchanged; a batch whose survivors overflow its list is re-run in smaller batches, as before |
| 5 | level 4 + the step's carries and borrows past each addend's words propagated only when there is one, and the binary addends cut to comptime word bounds (c2 = 2wδ < 2w², k3 = 6w²δ < 6w³, Δ3 < 3w²·2^(32·limbs+2)) | at b62 1e17 about 11 packed-digit words (of 24) and 15 binary words (of 24) of the step | a packed word plus the bias and no carry-in comes back unchanged with no carry-out (no byte reaches 256, every byte keeps bit 7, so the bias is taken back); x + 0xFFFFFFFF + 1 = x with carry 1 likewise; the words above the bounds are zero |
| **6** | level 5 **without** level 3's partial remainder | | |
| 7 | level 4 without level 3's partial remainder (= levels 1 + 2 + 4) | | |

Levels 5–7 are beyond the brief's four: level 3 measured slower than level 2 in the kernel-alone test (§4), so the
shipped candidate needed a level without it, and the step's carry propagation (L36: the step is 13 % of the slot)
was a cheap exact cut in the same stepped-slot arithmetic. **The PR form is level 6.**

L44's "append ... one plane ballot + one atomic per plane today": on `f3fb390` the append was `plane_sum` +
`plane_exclusive_sum` + one atomic + `plane_broadcast`; level 2 makes it one ballot + popcounts + the atomic + the
broadcast. What remains per kept top (the nine record stores, `top_b` and the `nroots` bucket atomics) is the
destination L46 changes, and was not touched.

## 2. Codegen gate (`raw/registers.txt`, `raw/box/sass/`)

CubeCL's CUDA source of `top_fd_kernel` from 1e14 fields at b62 and b60, (a) through the runtime's own path (NVRTC
PTX from CubeCL's PTX cache, JIT-loaded by the driver: `ptxjit.py`, L45's) and (b) offline `nvcc -cubin -arch=sm_86
-O3`. Both paths give the same registers and static SASS at every level here:

| level | b62 registers | b62 SASS (static) | b60 registers | b60 SASS | spills | blocks of 256 per SM |
|---|---|---|---|---|---|---|
| 0 (= `B`) | 110 | 3,888 | 108 | 3,696 | 0 | 2 |
| 1 | 113 | 4,488 | 110 | 4,288 | 0 | 2 |
| 2 | 113 | 4,456 | 110 | 4,256 | 0 | 2 |
| 3 | 110 | 4,936 | 113 | 4,672 | 0 | 2 |
| 103 | 112 | 4,792 | 107 | 4,536 | 0 | 2 |
| 5 | 108 | 4,944 | 111 | 4,688 | 0 | 2 |
| **6** | **108** | **4,448** | **107** | **4,264** | 0 | 2 |
| 7 | 113 | 4,456 | 110 | 4,256 | 0 | 2 |
| **PR form `P`** | **108** | **4,472** | **107** | **4,280** | 0 | 2 |

- **Every level stays at 2 blocks of 256 per SM** (≤ 128 registers), no spills on either compile path.
- Static SASS grows by 560–1,050 instructions: level 1 adds the rare re-forming branch (two `pw_minus1`s and an
  `ndig_fast` per power: LDG 60 → 105, all on that branch), level 3 the fallback. These are not executed by a stepped
  slot in the common case; the executed cost is the kernel-alone time (§4). Per-slot executed instruction counts
  could not be taken (no counter access, §0).
- Level 2's append in SASS: SHFL 7 → 2, VOTE 0 → 2, POPC 8 → 10 (b62).

**Direct SPIR-V** (lavapipe, `cubecl-spirv`; `blocks.py` on the CUBECL_DEBUG_LOG of #240's light FD test;
`raw/box/blocks_*.txt`): TopFdKernel's basic blocks, which bound that compiler's recursion, against TopKernel's
368–386 at b57–b64:

| | b57 | b58 | b60 | b62 | b64 |
|---|---|---|---|---|---|
| level 0 (`f3fb390`'s kernel) | 298 | 304 | 304 | 298 | 310 |
| levels 1, 2 | 247 | 256 | 256 | 247 | 265 |
| level 3 | 355 | 373 | 373 | 355 | **391** |
| level 103 | 325 | 340 | 340 | 325 | 355 |
| **PR form `P`** (= level 6) | **280** | **289** | **289** | **280** | **298** |

Level 3's fallback pushes TopFdKernel past TopKernel at b64 (391 > 386); it still compiled and passed on lavapipe,
but it is one more reason not to ship it. The PR form is below level 0.

EXACTNESS_PLACEHOLDER

## 4. Screen: levels 0–4 (and 4/6/7) on whole fields, and the kernel alone

**Whole fields** (binary `X`, one binary for every level, 2 interleaved rounds, order 0→4 then 4→0, nothing else on
the box, 06:22–06:48; `raw/scr_table.md`): device s/field, medians; per-round ratios against level 0; clock = mean SM
MHz per level.

| level | b62 1e17 s (rounds) | vs 0 (per round) | b60 1e16 s (rounds) | vs 0 (per round) | MHz b62 / b60 |
|---|---|---|---|---|---|
| 0 | **105.05** (104.55, 105.54) | | **20.79** (20.82, 20.75) | | 1382 / 1323 |
| 1 | 100.91 (100.82, 101.00) | ×1.041 (1.037, 1.045) | 20.16 (20.29, 20.03) | ×1.031 (1.026, 1.036) | 1367 / 1406 |
| 2 | 100.37 (100.75, 99.99) | ×1.047 (1.038, 1.056) | 19.93 (19.89, 19.96) | ×1.043 (1.047, 1.040) | 1350 / 1367 |
| 3 | 100.63 (100.61, 100.66) | ×1.044 (1.039, 1.049) | 20.01 (20.05, 19.98) | ×1.039 (1.039, 1.039) | 1378 / 1363 |
| **4** | **98.85** (98.75, 98.95) | **×1.063** (1.059, 1.067) | **19.62** (19.67, 19.58) | **×1.059** (1.059, 1.060) | 1335 / 1332 |

Then (binary `X7`, 2 interleaved rounds, 07:06–07:22; `raw/s6_table.md`) levels 4, 6 and 7:

| level | b62 1e17 s (rounds) | b60 1e16 s (rounds) | MHz b62 / b60 |
|---|---|---|---|
| 4 | 99.49 (98.28, 100.70) | 19.88 (19.71, 20.05) | 1354 / 1294 |
| **6** | **98.88** (98.34, 99.42) | **19.76** (19.69, 19.83) | 1313 / 1309 |
| 7 | 100.15 (100.14, 100.17) | 19.87 (19.85, 19.88) | 1321 / 1341 |

- Every run had the exact counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b60 1e16 460,847,952,346 /
  30,871,838,404).
- **Level 1 (the trims) is ×1.04 / ×1.03**, as L36 measured on all5 (×1.041). The ballot adds ~0.6 / 1.2 points,
  the partial remainder takes a little back, `SURV_PER_PREFIX` 1 adds ~1.5–2 points. Level 6 (5 without the partial
  remainder) is the fastest of 4/6/7 at both fields, by about 1 % — inside the runs' spread, so the choice rests on
  the kernel-alone numbers below.
- The clock wanders by up to 6 % between runs of one configuration at this cap (1276–1443 MHz), so single-round
  differences of 1–2 % are noise.

**The kernel alone** (#240's `cubecl_cuda_top_fd_timing`; binary `X` 06:48–06:52 for levels 0–4, `X7` 07:22–07:24
for 2/6/7; 2 processes per level and field, 3 rounds each = 6; `raw/topt_table.md`, `raw/t6_table.md`). ns per
(prefix, slot); stepped s normalised to the median `top_kernel` time of the field's runs; levels 4, 6, 7 run the
level-4 plan (k = 7 / 6 slots a batch, a larger first slice):

| level | b62 1e17: k | FD consecutive c | all-seed g | **stepped s** | vs 0 | b60 1e16: k | c | g | **stepped s** | vs 0 |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | 5 | 0.2400 | 0.3900 | **0.2045** | | 4 | 0.2404 | 0.3751 | **0.2021** | |
| 1 | 5 | 0.2010 | 0.3914 | **0.1554** | −24.0 % | 4 | 0.2060 | 0.3619 | **0.1537** | −23.9 % |
| 2 | 5 | 0.1930 | 0.3863 | **0.1454** | −28.9 % | 4 | 0.1982 | 0.3504 | **0.1444** | −28.6 % |
| 3 | 5 | 0.1975 | 0.3915 | **0.1504** | −26.5 % | 4 | 0.2036 | 0.3542 | **0.1526** | −24.5 % |
| 4 | 7 | 0.1833 | 0.3566 | 0.1498 | (−26.8 %) | 6 | 0.1825 | 0.3478 | 0.1576 | (−22.0 %) |
| 2 (`X7`) | 5 | 0.1942 | 0.3940 | 0.1480 | | 4 | 0.1992 | 0.3621 | 0.1447 | |
| **6** | 7 | **0.1740** | 0.3537 | **0.1424** | (−30.4 %) | 6 | **0.1738** | 0.3447 | **0.1493** | (−26.1 %) |
| 7 | 7 | 0.1779 | 0.3537 | 0.1479 | (−27.7 %) | 6 | 0.1772 | 0.3432 | 0.1533 | (−24.1 %) |

- **The trims take 24 % off the stepped slot** at both fields (L36 on all5: 22.3 / 22.9 %), and **the ballot another
  5 points (−28.9 / −28.6 %)**.
- **The partial remainder costs 2.4 / 4 points instead of saving** (level 3 against level 2): the left-out words are
  the cheap ones (their powers have few limbs), and the test that replaces them (a subtraction chain kept as dd, the
  word-position case split and the comparison with b^p) costs about as much, with 3 more registers at b60 and +480
  SASS for the fallback. Dropped (levels 6/7).
- **The early-exit carries take ~3.7 / 2.6 % off** (level 6 against 7, same plan) — less than their instruction
  count suggested; the step's word adds were partly hidden behind the scan.
- In production batches (FD consecutive c, seeds included), **level 6 is 0.1740 against 0.2400 ns per (prefix, slot)
  at b62 1e17 (−27.5 %) and 0.1738 against 0.2404 at b60 1e16 (−27.7 %)**; the seeded slot (g) is ~2.4× a stepped one
  after the cuts (1.9× before), which is what makes the larger batches (level 4) worth ~2 points of the field.
- Levels 4/6/7's s comes from a different first slice and k, so its "vs 0" is only indicative; levels 2 and 7 have
  the same kernel and agree at b62 (0.1480 / 0.1479).

AB_PLACEHOLDER

PLAN_PLACEHOLDER

FILES_PLACEHOLDER
