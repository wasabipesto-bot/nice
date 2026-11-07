# L48 RESULTS: FD top kernel, round 2 (RTX 3080 at 170 W, 2026-11-07)

Experiment branch **`exp/top-fd-round2`** on the fork, head **`f168b28`**: `f3fb390` (fork `pr/join-lean-prefilter`
= upstream main `6f060a9` + #241 + #246) + `9a93531` (levels 1–4 and 103 behind `NICE_EXP_TOPFD`) + `c27ed83`
(level 5) + `c50f584` (level 6) + `f168b28` (level 7). PR branch **`pr/top-fd-round2` `bedc658`** on the fork: one
commit on `f3fb390`, level 6 without knobs, batches planned at `SURV_PER_PREFIX` 1 with slices cut as before, CHANGELOG
line; PR not opened, body in `PR-BODY.md` (bundle `raw/pr-top-fd-round2.bundle`). Box: Vast **59529585** (`nice-research-l48-fdround2`), machine m139882,
RTX 3080 10 GB, **170 W cap** (default 320 W). Raw logs `raw/box/` (the box's `/root/l48/logs` and chain outputs;
CUDA sources, SASS and driver-JIT SASS per level in `raw/box/sass/`), scripts `raw/scripts/`, patches `raw/patch/`
(`p1.py` levels 1–4, `p3.py` level 5, `p2.py` the PR form), tables in `raw/*_table.md`.

## Summary

- **Bar met; `pr/top-fd-round2` `bedc658` pushed to the fork (one commit on `f3fb390`, CHANGELOG line ending
  `([#NNN](...))`), `PR-BODY.md` written; PR not opened.** A/B against `f3fb390` (3 interleaved rounds, 170 W,
  §6): **b62 1e17 ×1.082** (1.076, 1.083, 1.086; 107.90 → 99.76 s; clock-normalised ×1.111), **b60 1e16 ×1.070**
  (1.068, 1.075, 1.070; 21.32 → 19.92 s; ×1.054), b62 1e16 ×1.093 (×1.197), **b64 1e16 ×0.997 (neutral; FD off)**,
  1e14 set ×1.014–1.034; **NiceMark ×1.029** over 6 rounds, every scenario ×1.018–1.036 and every single round ≥
  ×1.003 (b58 MSD-weak ×1.018, MSD-strong ×1.036, b60 ×1.034, b62 ×1.033). Exact everywhere (§3).
- **What shipped = level 6:** L36's three trims (carried c0 and b^c0 − 1 − d, the short path above the run, no
  a/e/clip on steps), the append's plane scans as one ballot, early-exit carries in the step, and `SURV_PER_PREFIX`
  2 → 1 for the batches only (slices keep their size through a new `SLICE_SURV_PER_PREFIX` = 2).
- **Kernel alone** (ns per stepped slot, normalised; §4): level 0 0.2045 / 0.2021 (b62 1e17 / b60 1e16) → **level 1
  (trims) 0.1554 / 0.1537 (−24 %)** → **level 2 (+ballot) 0.1454 / 0.1444 (−29 %)** → level 3 (+partial x mod b^c0)
  0.1504 / 0.1526 (**worse than 2**, dropped) → level 4 (plan; same kernel as 3) 0.1498 / 0.1576 → level 6 (2 + early-exit
  carries + plan) **0.1424 / 0.1493**. `B` against `P2` in production batches: the FD kernel per (prefix, slot)
  **0.2424 → 0.1678 ns (−30.8 %) at b62 1e17, 0.2447 → 0.1644 (−32.8 %) at b60 1e16**; stepped slot −32 % / −31 %.
- **Screen** (whole fields, one binary, 2 rounds; §4): vs level 0, level 1 ×1.041 / ×1.031, level 2 ×1.047 / ×1.043,
  level 3 ×1.044 / ×1.039, **level 4 ×1.063 / ×1.059**; then level 6 ≈ 0.6 % ahead of 4 and 1.3 % / 0.6 % ahead of 7.
- **The first PR form failed NiceMark** (§5): with the constant also cutting slices (`max_slice_prefixes`), NiceMark's
  sampled b60 window went from 2 slices to 1 and lost 2.4 % in **all six rounds (×0.972–0.980)**, while the fields
  passed (×1.074 / ×1.057). Keeping the slices (`P2`) fixed it (×1.034) and was a little faster on the fields too.
- **Codegen** (§2): every level keeps 2 blocks of 256 per SM (107–113 registers, no spills on NVRTC→driver-JIT or
  nvcc); the PR's `top_fd_kernel` is **108 / 107 registers** (b62 / b60; base 110 / 108), static SASS 4,472 / 4,280
  (base 3,888 / 3,696; the growth is the rare re-forming branch and the early-exit branches). Per-slot executed
  instruction counts could not be taken (no counter access in the container). Direct SPIR-V: TopFdKernel 280–298
  blocks at b57–b64 (base 298–310; level 3 reached 391 > TopKernel's 386).
- **The plan at level 4** (§7): b62 1e17 7 slots (max), 2,438 MiB, 3,756 batches (base 5, 1,670, 6,439); b60 1e16 6,
  2,260 MiB, 600 batches per field (base 4, 1,566, 1,350). In the PR (`P2`): **b62 1e17 9 slots, 2,457 MiB, 4,009
  batches; b60 1e16 8, 2,431 MiB, 675.** All within the 10 GB card's 2,560 MiB budget, by the plan's unchanged bounds;
  no overflow re-run anywhere.
- **Exactness** (§3): every level (1–4 the full list; 5, 6, 7, 103 the device test) and both PR forms: #240's device
  test, #235's certificate test, CPU-reference parity, both dense fields, whole b42, the 1e14 COMPARE, every timed
  field = the exact counts; lavapipe naga + direct SPIR-V; WGSL lint; fmt; clippy ×3.
- **Beyond the brief:** levels 5–7 (early-exit carries; level 3 dropped) and the slice constant; the brief's L44 note
  "the append is one ballot + one atomic today" was not so on `f3fb390` (it was `plane_sum` + `plane_exclusive_sum`).
- **The box (59529585) can be destroyed** (everything pulled to `raw/box/`, nothing running).

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
  | `P` | `3d2395b` (first PR form: level 6 without knobs, slices cut at 1 survivor too) | `P` 244f1fd3, `client_P` 8084e3c7, `P_naga`, `P_spv` |
  | `P2` | `c468a31` = the pushed `bedc658`'s tree (slices cut at 2, `SLICE_SURV_PER_PREFIX`) | `P2` d20840ca, `client_P2` 71684fce, `P2_naga`, `P2_spv` |

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
| 5 | level 4 + the step's carries and borrows past each addend's words propagated only when there is one, and the binary addends cut to comptime word bounds (c2 = 2wδ < 2w², k3 = 6w²δ < 6w³, Δ3 < 3w²·2^(32·limbs+2)) | in the common case, at b62 1e17 (counted from the word lengths), about 11 of the step's 24 packed-digit words and 15 of its 24 binary words | a packed word plus the bias and no carry-in comes back unchanged with no carry-out (no byte reaches 256, every byte keeps bit 7, so the bias is taken back); x + 0xFFFFFFFF + 1 = x with carry 1 likewise; the words above the bounds are zero |
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
| **PR forms `P`, `P2`** (same kernels) | **108** | **4,472** | **107** | **4,280** | 0 | 2 |

- **Every level stays at 2 blocks of 256 per SM** (≤ 128 registers), no spills on either compile path.
- Static SASS grows by 560–1,050 instructions: level 1 adds the rare re-forming branch (two `pw_minus1`s and an
  `ndig_fast` per power), level 3 the fallback. Global loads go 60 → 105 at level 1 (b62), which matches the word counts: +48
  power-table words on the re-forming branch, +15 for the seed's two `pw_minus1`s, −18 for the carry tests' reads of
  b^c0 (not traced per branch in the SASS). None of the added code runs in a stepped slot in the common case; the executed cost is the kernel-alone time
  (§4). Per-slot executed instruction counts
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
| **PR forms `P`, `P2`** (= level 6; same kernels) | **280** | **289** | **289** | **280** | **298** |

Level 3's fallback pushes TopFdKernel past TopKernel at b64 (391 > 386); it still compiled and passed on lavapipe,
but it is one more reason not to ship it. The PR form is below level 0.

## 3. Exactness (`raw/xsum_table.md`, `raw/box/x_*`, `raw/box/cmp_*`, `raw/box/lvp*`)

**CUDA** (RTX 3080), the brief's list per level (`chain_x.sh`; binary `X` at `NICE_EXP_TOPFD` = 1–4, the PR forms
`P` and `P2`), plus #240's device test alone at every level including 5–7 and 103 (`q_topfd_*`):

| run | #240 FD vs top kernel | CPU reference | #235 certificates (intervals / kept / above c0 / carry) | dense b58 1e15 (survivors / checked) | dense b62 1e16 | whole b42 (join survivors / checked) | 1e14 COMPARE b57 / b60 / b62 / b64 (join = stride) | unit `join_plan::` / `cubecl_join::` |
|---|---|---|---|---|---|---|---|---|
| level 1 | ok: 26 fields, 279 batches, 237,948,545 tops | ok | ok: 102,365 / 33,582 / 203,413 / 69,824 | ok: 254,938,965 / 14,396,829 (16 a launch, 0 re-run) | ok: 120,013,475 / 7,355,827 (5, 0) | ok: 417,789,835 / 16,879,877, no hits | ok: 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759 | 7 ok / 4 ok |
| level 2 | ok, the same | ok | ok, the same | ok, the same | ok, the same | ok, the same | ok, the same counts | 7 ok / 4 ok |
| level 3 | ok, the same | ok | ok, the same | ok, the same | ok, the same | ok, the same | ok, the same counts | 7 ok / 4 ok |
| level 4 | ok: **24 fields, 259 batches, 281,513,809 tops** | ok | ok, the same | ok, the same (16, 0) | ok, the same (**9** a launch, 0) | ok, the same | ok, the same counts | 7 ok / 4 ok |
| `P` | ok: 24 / 259 / 281,513,809 | ok | ok, the same | ok, the same (16, 0) | ok, the same (9, 0) | ok, the same | ok, the same counts | 7 ok / 4 ok |
| **`P2`** (the PR) | ok: **26 fields, 279 batches, 343,985,470 tops** (slices as before, larger batches) | ok | ok, the same | ok, the same (16, 0) | ok, the same (**9**, 0) | ok, the same | ok, the same counts | 7 ok / 4 ok |
| levels 5, 6, 7, 103 (FD test only) | ok: 24 / 259 / 281,513,809 at 5–7 (the level-4 plan); 103: 26 / 279 / 237,948,545 | | | | | | | |

- Every count is the base's (L38's main counts, which #241 and #246 keep). The FD test's coverage follows the plan:
  at level 4 and in `P` it covers 24 fields instead of 26 because the two heavy 1e16 production fields at b60 and
  b62 plan as one slice (their "last slice" entries are gone); in `P2` the slices are back (26 fields) and the batches
  hold more partitions (343,985,470 tops checked, against 237,948,545 at levels 0–3).
- **Level 103** (the partial remainder's fallback forced whenever a word is left out) passes too, so both branches of
  level 3's test are exercised; the ambiguity it guards (dd < b^p, about b^−4 per lane) never occurs in the tests.
- **Every timed field** of the screen and both A/Bs, every round, both sides: the exact counts (b62 1e17
  1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 /
  30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327; 1e14 b60 8,995,820,166 / 602,561,220, b62 4,229,527,892
  / 259,080,525, b64 13,236,144,651 / 805,128,380), no overflow re-runs (`retried=0`), no hits. NiceMark's whole-field
  b58 scenarios: the same join survivors on both sides in every round (MSD-weak 33,590,315,220, MSD-strong
  4,027,773,430).

**Lavapipe** (llvmpipe, LLVM 20.1.2, Mesa 25.2.8, 8-lane subgroups, 128 MiB buffers; `chain_lvp.sh`,
`chain_lvp_extra.sh`):

| | WGSL lint (CI's 13 `--require`s) | #240's FD test, naga | #240's FD test, direct SPIR-V | every wgpu test of `cubecl_join`, naga / SPIR-V |
|---|---|---|---|---|
| levels 1, 2, 3, 103 (`X_naga`, `X_spv`) | 16 shaders, 0 flagged, at each level | ok at each (21 fields, 142 batches, 1,018,088 tops) | ok at each | |
| level 0 (`X_spv`) | | | ok (blocks only) | |
| `P` | 16 shaders, 0 flagged | | ok | 8 ok / 8 ok |
| `P2` | 16 shaders, 0 flagged | ok (21 / 142 / 1,018,088, in the full set) | ok (in the full set) | 8 ok / 8 ok |

**Lint** (`just lint` as CI runs it, toolchain 1.99.1, own target dir): `P`: `cargo fmt --all --check` ok; `cargo
clippy -p "*" --all-targets -- -D warnings` ok default, with `--features nice_client/gpu` and with
`--features nice_client/gpu,nice_client/cubecl-spirv`. `P2`: the same four, all clean.

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
- **The early-exit carries take ~3.7 / 2.6 % off** (level 6 against 7, same plan; the b60 ranges are wide) — less
  than their instruction count suggested (not investigated).
- In production batches (FD consecutive c, seeds included), **level 6 is 0.1740 against 0.2400 ns per (prefix, slot)
  at b62 1e17 (−27.5 %) and 0.1738 against 0.2404 at b60 1e16 (−27.7 %)**; the seeded slot (g) is ~2.4× a stepped one
  after the cuts (1.9× before), which is what makes the larger batches (level 4) worth ~2 points of the field.
- Levels 4/6/7's s comes from a different first slice and k, so its "vs 0" is only indicative; levels 2 and 7 have
  the same kernel and agree at b62 (0.1480 / 0.1479).

## 5. A/B 1: `B` against `P` (the PR form of level 6, slices cut at one survivor too)

`chain_ab.sh P` 07:48–08:23 box UTC, binaries `B` / `P` and `client_B` / `client_P`, nothing else on the box; order per
round B P, P B, B P; `raw/ab_table.md`, `raw/nm_table.md`.

| field | B s/field (rounds) | P s/field (rounds) | P vs B (per round) | MHz B / P | cycles | plan B → P: slots, MiB, batches/field |
|---|---|---|---|---|---|---|
| **b62 1e17** | **107.49** (106.81, 107.81, 107.49) | **100.06** (99.54, 100.06, 100.96) | **×1.074** (1.073, 1.077, 1.065) | 1359 / 1307 | ×1.101 | 5 → 7, 1670 → 2438, 6439 → 3756 |
| b62 1e16 | 8.996 (9.01, 8.98, 9.00) | 8.265 (8.22, 8.28, 8.27) | ×1.088 (1.096, 1.085, 1.088) | 1323 / 1291 | ×1.143 | 13 → 16, 2050 → 2457, 532 → 334 |
| **b60 1e16** | **21.154** (20.99, 21.15, 21.21) | **20.005** (19.99, 20.00, 20.05) | **×1.057** (1.050, 1.057, 1.058) | 1337 / 1263 | ×1.128 | 4 → 6, 1566 → 2260, 1350 → 600 |
| b64 1e16 (FD off) | 30.518 (30.52, 30.44, 30.58) | 30.627 (30.52, 30.63, 30.73) | ×0.996 (1.000, 0.994, 0.995) | 1326 / 1357 | ×0.980 | 6 → 7, 2151 → 2396, 683 → 586 |
| b60 1e14 | 0.651 (0.66, 0.65, 0.65) | 0.633 (0.63, 0.63, 0.64) | ×1.028 (1.038, 1.035, 1.009) | | | 16, 1212 (both) |
| b62 1e14 | 0.522 (0.54, 0.52, 0.52) | 0.517 (0.52, 0.52, 0.53) | ×1.010 (1.056, 1.010, 0.983) | | | 16, 1369 (both) |
| b64 1e14 | 0.788 (0.79, 0.77, 0.79) | 0.783 (0.80, 0.77, 0.78) | ×1.006 (0.991, 0.994, 1.006) | | | |

NiceMark nice-only (`client_* niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, 6 rounds, order
alternating):

| | B | P | P vs B (per round) |
|---|---|---|---|
| score | median 6257.3 | median 6320.5 | ×1.010 (1.020, 0.996, 1.013, 1.013, 1.005, 1.007) |
| b58 MSD-weak (whole field) | 2.904e14 n/s | 2.956e14 | ×1.018 (1.009–1.023) |
| b58 MSD-strong (whole field) | 1.267e15 | 1.291e15 | ×1.019 (0.965–1.052) |
| **b60 MSD-weak (sampled)** | 5.959e14 | 5.814e14 | **×0.976 (0.972–0.980 in all six rounds)** |
| b62 MSD-weak (sampled) | 7.469e14 | 7.690e14 | ×1.030 (1.019–1.033) |

- The fields clear the bar (b62 1e17 ×1.074, b60 1e16 ×1.057, every round ≥ ×1.050), exact in every run; b64 is
  neutral (×0.996, inside its 0.5–0.7 % spread; FD is off at b64, only its plan moved).
- **But NiceMark's b60 scenario is ×0.976 in every one of six rounds: the kill fires for `P`.** Its scenario JSON
  says why: B plans the b60 window as **2 slices** (5 partitions a launch, slice weight 1.27) and P as **1 slice** (7 a
  launch): `max_slice_prefixes` also divides by `SURV_PER_PREFIX`, so at 1 it doubles the slice size wherever the
  survivor bound set it. A wider slice's field certificate prunes less (L1's PROFILE-3 measured +9.4 % real AND pairs
  at 4 instead of 11 slices), and NiceMark samples every slot as a seed, so it gets none of the stepped-slot gain to
  pay for that: its per-partition time rose from 3.59 ms × 1.27 = 4.56 ms to 4.68 ms (+2.6 %). The whole b60 field
  also went from 1.5 slices to 1 (1350 → 600 batches) and presumably paid the same, but the stepped-slot cuts more than
  covered it (and `P2`, with the slices kept, was a little faster still, §6).
- The P side runs 30–75 MHz **slower** at b62/b60 under the same cap (the opposite of #241's record): the cheaper
  slot does more work per cycle and draws more power per cycle. Clock-normalised the gains are ×1.10 (b62 1e17) and
  ×1.13 (b60 1e16).

So the PR form was changed to keep the slices (§6).

## 6. A/B 2: `B` against `P2` (the PR form: level 6, batches planned at 1 survivor, slices cut as before)

`P2` = `P` + `SLICE_SURV_PER_PREFIX` = 2 in `max_slice_prefixes` (one constant and one use in `join_plan.rs`; the
kernels are `P`'s). Its commit on the fork, **`pr/top-fd-round2` `bedc658`**, has the same tree as the tested
`c468a31` (only the commit message was reworded after the runs). `PFX=ab2 chain_ab.sh P2` 09:09–09:44 box UTC, binaries
`B` / `P2` and `client_B` / `client_P2`, nothing else on the box; order B P2, P2 B, B P2; `raw/ab2_table.md`,
`raw/nm2_table.md`.

| field | B s/field (rounds) | P2 s/field (rounds) | P2 vs B (per round) | MHz B / P2 | **cycles** (clock-normalised) | plan B → P2: slots, MiB, batches/field |
|---|---|---|---|---|---|---|
| **b62 1e17** | **107.90** (107.53, 108.08, 107.90) | **99.76** (99.92, 99.76, 99.35) | **×1.082** (1.076, 1.083, 1.086) | 1316 / 1268 | **×1.111** | 5 → 9, 1670 → 2457, 6439 → 4009 |
| b62 1e16 | 9.046 (9.09, 9.05, 9.02) | 8.276 (8.34, 8.28, 8.27) | ×1.093 (1.090, 1.093, 1.090) | 1405 / 1299 | ×1.197 | 13 → 16, 2050 → 2457, 532 → 334 |
| **b60 1e16** | **21.315** (21.42, 21.27, 21.32) | **19.923** (20.06, 19.79, 19.92) | **×1.070** (1.068, 1.075, 1.070) | 1259 / 1262 | **×1.054** | 4 → 8, 1566 → 2431, 1350 → 675 |
| b64 1e16 (FD off) | 30.696 (30.88, 30.54, 30.70) | 30.789 (31.00, 30.64, 30.79) | ×0.997 (0.996, 0.997, 0.997) | 1308 / 1333 | ×0.980 | 6 → 7, 2151 → 2396, 683 → 586 |
| b60 1e14 (3 fields) | 0.663 (0.66, 0.67, 0.66) | 0.645 (0.65, 0.65, 0.64) | ×1.028 (1.025, 1.031, 1.025) | | | 16, 1212 MiB (both) |
| b62 1e14 | 0.544 (0.55, 0.53, 0.54) | 0.526 (0.53, 0.52, 0.53) | ×1.034 (1.036, 1.015, 1.028) | | | 16, 1369 (both) |
| b64 1e14 | 0.786 (0.77, 0.80, 0.79) | 0.775 (0.79, 0.78, 0.77) | ×1.014 (0.973, 1.030, 1.016) | | | 16, 1413 (both) |

NiceMark nice-only (150 s, 6 rounds, order alternating):

| | B | P2 | P2 vs B (per round) |
|---|---|---|---|
| **score** | 6162.5, 6201.5, 6258.5, 6227.4, 6219.3, 6233.4 (median **6223.4**) | 6333.9, 6398.1, 6408.8, 6467.7, 6367.8, 6417.8 (median **6403.5**) | **×1.029** (1.028, 1.032, 1.024, 1.039, 1.024, 1.030) |
| b58 MSD-weak (whole field) | 2.898e14 n/s | 2.949e14 | ×1.018 (1.015–1.022) |
| b58 MSD-strong (whole field) | 1.246e15 | 1.291e15 | ×1.036 (1.003–1.066) |
| b60 MSD-weak (sampled; 2 slices on both sides, 5 → 8 a launch) | 5.947e14 | 6.149e14 | ×1.034 (1.026–1.037) |
| b62 MSD-weak (sampled; 2 slices, 6 → 9 a launch) | 7.449e14 | 7.697e14 | ×1.033 (1.031–1.038) |

- **The bar is met: b62 1e17 ×1.082, b60 1e16 ×1.070** (every round ≥ ×1.068), **no NiceMark scenario below ×1.0**
  in any round (lowest single round: b58 MSD-strong ×1.003). Exact counts on every run.
- **NiceMark gains ×1.03** although it seeds every slot (bit-reversed samples), i.e. it gets none of the stepped-slot
  cut: what it gets is the ballot, the carry test's single subtraction (a seed still forms c0 from the power
  table) and the larger batches' fewer launches (not separated); with the slices kept, the b60 scenario went from
  ×0.976 (`P`) to ×1.034.
- **b64 1e16 is neutral** (×0.997, per round 0.996–0.997, inside the 1.1–1.2 % spread): FD is off at b64; only its
  plan moved (6 → 7 a launch). The 1e14 set is neutral to slightly positive (×1.01–1.03; single 1e14 runs scatter ±3 %).
- **Clock:** at b62 the P2 side runs 50–100 MHz slower under the same 170 W cap (more work per cycle), so in cycles
  the gain is larger (×1.11 at b62 1e17); at b60 the clocks matched (×1.054 in cycles against ×1.070 in time).
- **P2 against P** (not interleaved, different sessions): b62 1e17 99.76 against 100.06 s, b60 1e16 19.92 against
  20.01 s; keeping the slices costs nothing on the whole fields and fixes NiceMark's b60 window.

**The kernel alone, `B` against `P2`** (same session, after everything else, 10:01–10:04; 2 processes per side and
field, 3 rounds each; `raw/tp2_table.md`). Production batches (k = the plan's slots):

| field | side | k | FD consecutive c | all-seed g | stepped s (normalised) |
|---|---|---|---|---|---|
| b62 1e17 | `B` | 5 | 0.2424 | 0.3913 | 0.2066 |
| b62 1e17 | `P2` | 9 | **0.1678 (−30.8 %)** | 0.3433 | **0.1403 (−32.1 %)** |
| b60 1e16 | `B` | 4 | 0.2447 | 0.3859 | 0.2003 |
| b60 1e16 | `P2` | 8 | **0.1644 (−32.8 %)** | 0.3292 | **0.1380 (−31.1 %)** |

The FD kernel per (prefix, slot) of a production batch is **31–33 % cheaper**; with the kernel at 25 % / 21 % of the
field that predicts ×1.08 / ×1.07, which is what the fields measured.

## 7. The plan at level 4 (and in the PR form)

On this card CubeCL reports a quarter of the 10 GB as the largest buffer, so `JoinLimits` gives a budget of
**2,560 MiB** (2.5 GiB) and a survivor list of a quarter of it (83.9 M entries). From the harness's `slots` (the
largest over the field's slices), `plan_mib` (the largest layout) and `batches` (launches per field):

| field | `f3fb390` (`SURV_PER_PREFIX` 2) | level 4 / `P` (1, slices cut at 1 too) | `P2` (1 for batches, slices cut at 2) |
|---|---|---|---|
| b62 1e17 | 5 slots, 1,670 MiB, 6,439 batches | 7 slots, **2,438 MiB**, 3,756 batches | 9 slots, **2,457 MiB**, 4,009 batches |
| b60 1e16 (per field) | 4 slots, 1,566 MiB, 1,350 batches | 6 slots, **2,260 MiB**, 600 batches | 8 slots, **2,431 MiB**, 675 batches |
| b62 1e16 | 13 slots, 2,050 MiB, 532 batches | 16 slots (the `SLOTS` cap), 2,457 MiB, 334 batches | 16 slots, 2,457 MiB, 334 batches |
| b64 1e16 | 6 slots, 2,151 MiB, 683 batches | 7 slots, 2,396 MiB, 586 batches | 7 slots, 2,396 MiB, 586 batches |

- **Every layout fits the 10 GB card's 2,560 MiB budget**, as the plan's bounds guarantee: only the survivor bound
  moved; the budget bound (`room / per_slot`) and the largest-binding bound are unchanged and now bind first at
  b62 1e17 and b60 1e16 (2,438 / 2,260 MiB at level 4; 2,457 / 2,431 MiB in `P2`, whose slices are smaller so more
  partitions fit). b64 1e16 (FD off) also gets one more partition per launch (6 → 7).
- **The survivor bound still holds with room:** the list fills at the measured rate, 0.53 prefilter survivors per
  prefix and partition at b62 1e17 (62.6e9 checked over 30.6 M prefixes × 3,844 partitions), against the 1 the
  plan now assumes for half the list, i.e. about a quarter of the list per batch; no batch overflowed in any run
  (`retried=0` everywhere, dense b58 1e15 at 16 a launch and dense b62 1e16 at 9 a launch with 0 re-runs). L1's dense
  b57 fields at up to 1.6 survivors per prefix would fill 80 % of a list planned at 1; a batch that overflows is re-run
  in smaller batches, as before.
- **Slices.** `max_slice_prefixes` divides by the same constant, so at level 4 slices doubled wherever the survivor
  bound had set their size (b60 1e16: 1.5 → 1 slice per field; the NiceMark b60 window: 2 → 1). That is what cost
  NiceMark's b60 scenario 2.4 % (§5). `P2` keeps the slice bound at 2 (`SLICE_SURV_PER_PREFIX`), so slices are what
  they were and only the batches grow.

## 8. Files

- `RESULTS.md` (this), `PR-BODY.md` (the PR's body, in L38's style; stacked on #246; PR not opened).
- `raw/patch/`: `p1.py` (levels 1–4, 103 on `f3fb390`), `p3.py` (level 5), `p2.py` (the PR form, flags `ballot
  partial spp1 ee`; the pushed commit is `p2.py ballot spp1 ee` + rustfmt + the doc of `fd_add_small` + the
  `SLICE_SURV_PER_PREFIX` constant, all in `bedc658`); `raw/pr-top-fd-round2.bundle` (`f3fb390..bedc658`).
- `raw/scripts/` (run on the box from `/root/l48`): `setup.sh`, `tree.sh`, `build.sh`, `buildclient.sh`, `run.sh`,
  `test.sh`, `regs48.sh` (+ L45's `ptxjit.py`, `cbor_min.py`), chains in the order they ran: `chain_screen.sh`,
  `chain_l6.sh` (`chain_l5.sh` was stopped during its build when level 3 turned out slower), `chain_post.sh`
  (`chain_x.sh`, `chain_lvp.sh`, `chain_ab.sh`, `chain_lint.sh`), `chain_lvp_extra.sh`, `chain_post2.sh`;
  analysis `analyze.sh` (regenerates every `raw/*_table.md`), `ab.py`, `nm_table.py`, `topt48.py`, `xsum.py`,
  `clocks.py`, `blocks.py`, `pull.sh`.
- `raw/box/`: every log (`scr_*`, `s6_*` the screens; `topt_*`, `t6_*`, `tp2_*` the kernel-alone runs; `ab_*`, `nm_*`
  A/B 1; `ab2_*`, `nm2_*` A/B 2; `x_*`, `cmp_*` CUDA exactness; `q_topfd_*` the per-level device tests; `lvp*`,
  `wgsl_*`, `blocks_*` lavapipe; `fmt_*`, `clippy_*` lint; `*.smi` the nvidia-smi samples), the chains' outputs, and
  `sass/<tree>/` (CubeCL CUDA source, nvcc SASS, driver-JIT SASS of every level's `top_fd_kernel`).
- The box (59529585) can be destroyed: everything above is pulled and nothing runs on it.

---

# Round 2 (2026-11-07 afternoon): the review's fixes, rebased onto #249

The independent review (`REVIEW.md`) said "merge with small fixes". This round makes the fixes, rebases onto PR #249's
head (fork `pr/join-static-buckets` `87958fd` = `f3fb390` + the static bucket order + the stage rider) and re-measures
the combination. Box: Vast **59555088** (`nice-research-l48-rebase`), RTX 3080 10 GB, driver 580.159.03, **180 W
cap** (not this morning's 170 W), 19.2 CPUs. Raw logs `raw/r2/box/`, scripts `raw/r2/scripts/`, tables `raw/r2/*.md`.

## R2 Summary

- **Pushed `pr/top-fd-round2` `d813aea`** (with lease, over `bedc658`): one commit on #249's head `87958fd`, CHANGELOG
  line with `([#NNN](...))`; `PR-BODY.md` rewritten (stacked on #249, backend scoping and memory stated). PR not opened.
- **Review fixes:** M1 (ballot only on planes ≤ 32 lanes, comptime gate from `plane_size_max`, two-scan fallback
  exact on CUDA when forced), M2 (the denser plan on CUDA only, via `JoinLimits::vram_budget`; wgpu keeps 2), L1 (comment
  + host test pinning the b20 windows' c0 crossings), L2 (b64 keeps its plan: identical to the base there), L3
  (headroom in the doc comment and body), L4 (CHANGELOG and body wording), nits.
- **On #249: b62 1e17 ×1.127** (82.80 → 73.44 s; rounds 1.123, 1.108, 1.127; cycles ×1.140), **b60 1e16 ×1.112**
  (16.43 → 14.77 s; 1.136, 1.108, 1.112), b62 1e16 ×1.129, b64 1e16 ×1.005 with the timed build's 12 slots (final:
  b64 runs the base's kernels and plan, ×0.991 / ×0.998 in cycles = scatter), 1e14 set ×0.978–1.059 (same plans
  both sides); **NiceMark ×1.032**, every scenario ≥ ×1.009 (b60 window ×1.052 with its 2 slices kept; lowest single
  round b58 MSD-strong ×0.972, median ×1.009). Kill not fired.
- **Plan** (10 GB card, budget 2,469 MiB): b62 1e17 5 → 11 slots, 1,463 → 2,393 MiB, 6,439 → 3,288 batches, **11
  slices on both sides, same sizes**; b60 1e16 4 → 9, 1,367 → 2,199 MiB, 1,350 → 625 batches, **2 slices per field on
  both sides**. No overflow re-run anywhere.
- **Kernel alone** (production batches): FD per (prefix, slot) −33.8 % (b62 1e17) / −34.1 % (b60 1e16); stepped slot
  −30.4 % / −31.6 %.
- **Registers:** `top_fd_kernel` 108 / 107 (b62 / b60) against #249's 112 / 108; SASS 4,360 / 4,176 against 3,760 /
  3,576; no spills, 2 blocks per SM.
- **Exact** on the combination: #249's FD-vs-top device test (and with the gate forced off), CPU-reference parity,
  both dense fields, whole b42, the 1e14 COMPARE, every timed field, lavapipe naga + SPIR-V, WGSL lint, fmt, clippy ×3.
- **The box (59555088) can be destroyed** (everything pulled to `raw/r2/box/`, nothing running).

## R2.1 What changed against `bedc658`

| review item | change |
|---|---|
| **M1** (ballot wrong on 64-lane planes under CubeCL's C++ dialects) | `ballot_append(plane_size_max) = plane_size_max <= 32`, computed in `JoinDevice::new` from `client.properties().hardware.plane_size_max` and passed to `top_fd_kernel` as a comptime `ballot`. With it, `top_slot` uses the ballot's first word alone (count = popcount, rank = popcount of the bits below the lane); without it, #249's `plane_sum` + `plane_exclusive_sum`. Host test `the_ballot_append_is_for_planes_of_at_most_32_lanes`. |
| **M2** (real memory rises to the budget; on wgpu the budget is not tied to VRAM) | `JoinLimits` gets `vram_budget` (set by `limits_of` for the CUDA runtime only, kept through `JoinCeiling::cap`). Batches plan for `SURV_PER_PREFIX_VRAM` = 1 only where `vram_budget` and the FD kernel certifies the field (`top_fd_runs`, which `JoinDevice::new` now uses too); everything else, and slices everywhere, keep `SURV_PER_PREFIX` = 2 (so `SLICE_SURV_PER_PREFIX` is gone). Host test `vram_budgets_get_larger_batches_in_the_same_slices` (b60/b62: same cuts, more slots, within budget; b64: the same plan). |
| **L1** (re-forming branch pinned only by the b20 windows) | `check_top_fd`'s doc says so; host test `top_fd_test_windows_step_across_a_c0_change` checks (u128 arithmetic) that the b20 windows step across a c0 change for both powers. |
| **L2** (b64 −0.3 %) | b64 now keeps its plan (FD off at powers of two): identical kernels and plan to the base there. |
| **L3** (headroom halves) | `SURV_PER_PREFIX_VRAM`'s doc: half full at this rate, ~80 % at 1.6, overflow above ~2 (2.0–2.1 at b62 1e17 / b60 1e16 on a 10 GB card, was 4.5–4.7), the re-run unchanged. |
| **L4** (CHANGELOG, body) | CHANGELOG: "the position each power's certificate starts at", "up to twice", "(on CUDA)"; body: no 1e16 cycle ratios, early exits 2.6–3.7 %, only the FD-vs-top device test pins the changed certificate code, b64 stated as measured. |
| nits | `dd` dropped (borrow-only loop), `fd_step_words` clamps to the arrays itself, doc of `fd_add_small`. |
| **#249** | Its `top_slot` replaced the append block; the ballot moved into `top_slot` behind the gate, #249's per-(slot, group) destination unchanged. Two textual conflicts (the append hunk, CHANGELOG), resolved by hand. |

## R2.2 Plan at b62 1e17 and b60 1e16 (`raw/r2/box/plan_CM.log`, a measurement-only test in a throwaway tree)

On this card `CubeCL` reports a largest buffer of 2,588,688,384 B, so the budget is **2,469 MiB**. Base rule (`87958fd`) against
this PR, every slice of the A/B's fields (first slice's plan):

| field | slices (base / PR) | slice sizes | first slice: slots | MiB | batches/field (harness) |
|---|---|---|---|---|---|
| b62 1e17 | **11 / 11** | identical | 5 → **11** | 1,463 → **2,393** | 6,439 → 3,288 |
| b60 1e16, field 0 / 1 | **2 / 2**, 2 / 2 | identical | 4 → **9**, 4 → 9 | 1,367 → **2,199**, 1,345 → 2,154 | 1,350 → 625 |
| b62 1e16, field 0 / 1 | 2 / 2, 2 / 2 | identical | 5 → 11, 13 → 16 | 1,463 → 2,393, 1,825 → 2,096 | 532 → 296 |
| b64 1e16 (FD off) | 1 / 1 | identical | 6 (A/B binary `C`: 12; final `F`: 6) | 1,519 (`C`: 2,361) | 683 (`C`: 342) |

- **Slices are cut exactly as before** on every field (same count, same sizes); only the batches grow.
- With #249's smaller per-slot footprint the survivor bound now binds (11 slots at b62 1e17, as the review predicted),
  and the layout is 97 % of the budget.
- The A/B binary `C` still applied the CUDA rate at b64; the final tree `F` keeps b64's plan (R2.5).

## R2.3 Codegen (`raw/r2/box/sass/`, registers via NVRTC → driver JIT and offline nvcc, identical)

| `top_fd_kernel` | b62 registers / static SASS | b60 registers / static SASS |
|---|---|---|
| `87958fd` (#249) | 112 / 3,760 | 108 / 3,576 |
| this PR (`C`) | **108 / 4,360** | **107 / 4,176** |

No spills; 2 blocks of 256 per SM on both sides. The final tree `F` gives the same (108 / 4,360, 107 / 4,176).

## R2.4 Exactness

Trees: `C` = the A/B binary (fork `exp/top-fd-round2-rb` `2bc83e0`, since deleted), `F` = `C` + the doc fixes and the
b64 plan scope (`737976a`), `G` = `F` + a clippy fix in a host test and rustfmt = **the pushed `d813aea`**, `CF` = `C`
with the ballot gate at 16 lanes (measurement only: CUDA takes the two-scan append that 64-lane planes take).

| check | result |
|---|---|
| #249's `cubecl_cuda_top_fd_matches_the_top_kernel` (per slot and group the same counts and sorted entries in the same segments; one slot group and several) | **`C` ok: 26 fields, 279 batches (23 with a clipped block), 423,133,750 tops; `CF` ok, the same; `F` ok: 26 / 279 / 375,887,645** (b64's heavy fields keep the smaller plan) |
| `cubecl_cuda_join_matches_the_cpu_reference` (b10's 69; b20–b64 windows incl. b50/b54; the b57 frontier; sliced windows; the production shape) | `C` ok |
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` (the division path; not this PR's code) | `C` ok: 102,365 / 33,582 / 203,413 / 69,824 |
| dense b58 1e15, 32 partitions (= CPU join) | `C` ok: 254,938,965 / 14,396,829, 16 a launch, 0 re-run |
| dense b62 1e16, 4 partitions (= CPU join) | `C` ok: 120,013,475 / 7,355,827, **11** a launch, 2 slices, 0 re-run |
| whole b42 field | `C` ok: 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = reference |
| 1e14 COMPARE b57 / b60 / b62 / b64 | `C` ok, join = stride: 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759 |
| host unit tests `join_plan::` (8, incl. `vram_budgets_get_larger_batches_in_the_same_slices`) and `cubecl_join::` (7, incl. `top_fd_test_windows_step_across_a_c0_change`, `the_ballot_append_is_for_planes_of_at_most_32_lanes`) | `C`, `F`, `G` ok |
| every timed field (A/B and the final check), both sides, every round | the exact counts, `retried=0`, no hits |
| lavapipe (llvmpipe, 8-lane subgroups: the ballot path), naga and direct SPIR-V, every wgpu test of `cubecl_join` (join parity, #249's FD-vs-top test on 21 fields / 142 batches / 1,018,088 tops, the certificate test, the production sample, the ticket test) | `F` (kernels = `G`'s): **8 ok / 8 ok**; TopFdKernel 278–296 SPIR-V blocks at b57–b64, below TopKernel's 363–381 |
| CI's WGSL lint (`wgsl_dump_for_lint` + `scripts/wgsl-lint.py`, the 13 `--require`s) | `F`: 14 shaders (#249 removed the scan and fill kernels), 0 flagged |
| `cargo fmt --all --check`; clippy `-D warnings` default, `nice_client/gpu`, `nice_client/gpu,nice_client/cubecl-spirv` | **`G` (the pushed tree): all clean.** (`F` failed one clippy lint, `int_plus_one` in the new host test, and fmt; fixed in `G`) |

## R2.5 A/B: `87958fd` (`S`) against this PR (`C`), 3 interleaved rounds, 180 W

`raw/r2/scripts/chain_ab.sh`, 11:29–11:57 box UTC, binaries `S` / `C`, `client_S` / `client_C`, nothing else on the
box; order S C, C S, S C. `raw/r2/ab_table.md`, `raw/r2/nm_table.md`.

| field | S s/field (rounds) | C s/field (rounds) | C vs S (per round) | MHz S / C |
|---|---|---|---|---|
| **b62 1e17** | **82.80** (82.03, 83.25, 82.80) | **73.44** (73.03, 75.14, 73.44) | **×1.127** (1.123, 1.108, 1.127); cycles ×1.140 (12–16 clock samples a run) | 1486 / 1474 |
| b62 1e16 | 6.989 (6.91, 7.05, 6.99) | 6.191 (6.30, 6.19, 6.17) | ×1.129 (1.096, 1.139, 1.133) | (3–4 samples) |
| **b60 1e16** | **16.431** (16.69, 16.43, 16.43) | **14.770** (14.70, 14.83, 14.77) | **×1.112** (1.136, 1.108, 1.112) | 1499 / 1489 (6–7 samples) |
| b64 1e16 (FD off; `C` at 12 slots) | 21.983 (21.60, 22.04, 21.98) | 21.868 (21.93, 21.86, 21.87) | ×1.005 (0.985, 1.008, 1.005) | 1464 / 1453 |
| b60 1e14 | 0.557 (0.56, 0.56, 0.55) | 0.547 (0.55, 0.55, 0.55) | ×1.018 (1.018, 1.018, 1.007) | |
| b62 1e14 | 0.486 (0.50, 0.46, 0.49) | 0.459 (0.45, 0.50, 0.46) | ×1.059 (1.097, 0.918, 1.059) | |
| b64 1e14 | 0.673 (0.69, 0.66, 0.67) | 0.688 (0.69, 0.65, 0.69) | ×0.978 (1.007, 1.026, 0.973) | |

- Every run: the exact counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 /
  10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327; the 1e14
  fields), `retried=0`.
- The 1e14 fields run 16 slots on both sides (the cap binds); at b64 1e14 the two binaries run the same kernels and
  plan, so its ×0.978 (per round 1.007, 1.026, 0.973) is run-to-run scatter (4–7 % per side).

NiceMark nice-only (150 s, 6 rounds, alternating):

| | S | C | C vs S (per round) |
|---|---|---|---|
| **score** | median **7850.3** (7745.2–7874.0) | median **8104.9** (8039.7–8174.3) | **×1.032** (1.039, 1.039, 1.035, 1.022, 1.043, 1.032) |
| b58 MSD-weak (whole field) | 3.747e14 n/s | 3.831e14 | ×1.022 (1.006–1.033) |
| b58 MSD-strong (whole field) | 1.463e15 | 1.475e15 | ×1.009 (0.972–1.020) |
| **b60 MSD-weak (sampled)** | 7.755e14 | 8.157e14 | **×1.052** (1.030–1.080); **2 slices on both sides**, 5 → 10 a launch |
| b62 MSD-weak (sampled) | 9.454e14 | 9.977e14 | ×1.055 (1.035–1.089); 2 slices, 6 → 12 |

- **The bar holds on #249: b62 1e17 ×1.127, b60 1e16 ×1.112** (every round ≥ ×1.108); every NiceMark scenario's
  ratio is ≥ ×1.009. The b60 window, which failed this morning (×0.976) when slices widened, keeps its 2 slices and
  gains ×1.052. The lowest single round is b58 MSD-strong ×0.972 (round 6; its ~1 s scenario scattered 0.965–1.052
  this morning too); its median is ×1.009.
- The FD kernel's share of a field is larger on #249 (the field is ~83 s instead of ~100–108 s), so the same kernel cut
  is worth more: ×1.127 here against ×1.082 on `f3fb390`.

**The final tree's check** (`chain_final.sh`, 12:18–12:27, binaries `S` / `F`; `F` keeps b64's plan; 3 interleaved
rounds of b64, one round of b62 1e17 and b60 1e16):

| field | S | F | F vs S (per round) | plan S → F |
|---|---|---|---|---|
| b64 1e16 | 21.49 (21.49, 21.45, 21.96) | 21.83 (21.70, 21.83, 22.01) | ×0.991 (0.991, 0.983, 0.998); in cycles about ×0.998 (F's side ran 8–11 MHz lower each round) | 6 / 1,519 MiB / 683 batches on both |
| b64 1e14 | 0.674 (0.643, 0.674, 0.699) | 0.685 (0.685, 0.685, 0.694) | ×0.983 | 16 / 1,388 on both |
| b62 1e17 (1 round) | 83.11 | 72.97 | ×1.139 | 5 → 11, 6,439 → 3,288 batches (as `C`) |
| b60 1e16 (1 round) | 16.40 | 14.69 | ×1.117 | 4 → 9, 1,350 → 625 (as `C`) |

- At b64, `F` runs exactly `S`'s kernels and plan (FD is off; the plan scope keeps 6 slots), so its ×0.991 / ×0.983
  are this session's scatter for identical work. With the plan scoped, b64 can neither gain nor lose from this PR.
- b62 1e17 and b60 1e16 reproduce `C`'s plans and gains (×1.139, ×1.117 in one round).

**The kernel alone, `S` against `F`** (#240's `cubecl_cuda_top_fd_timing`, 12:48–12:52, after everything else;
2 processes per side and field, 3 rounds each; `raw/r2/topt_table.md`). Production batches (k = each side's plan):

| field | side | k | FD consecutive c (ns per prefix and slot) | all-seed g | stepped s (normalised) |
|---|---|---|---|---|---|
| b62 1e17 | `S` (#249) | 5 | 0.2070 | 0.3234 | 0.1781 |
| b62 1e17 | `F` | 11 | **0.1371 (−33.8 %)** | 0.2963 | **0.1239 (−30.4 %)** |
| b60 1e16 | `S` | 4 | 0.2061 | 0.3037 | 0.1735 |
| b60 1e16 | `F` | 9 | **0.1358 (−34.1 %)** | 0.2806 | **0.1186 (−31.6 %)** |

#249 already made the FD kernel cheaper (its append is lighter); this PR takes another third off it in production
batches.

## R2.6 Files

- `raw/r2/scripts/`: `setup.sh`, `tree.sh`, `build.sh`, `buildclient.sh`, `run.sh`, `test.sh`, `regs48.sh`
  (+ `ptxjit.py`, `cbor_min.py`), `plan_report_patch.py` (the measurement-only plan report, tree `CM`), chains in
  order: `chain_main.sh` (C's device test, unit tests, client, plan report, registers, exactness list, the A/B
  `chain_ab.sh`; its lavapipe/lint tail was stopped after the A/B, as `F` repeats them), `chain_cf.sh` (tree `CF`: C
  with the ballot gate at 16 lanes, so CUDA takes the two-scan path), `chain_final.sh` (tree `F` = the pushed commit:
  unit tests, device test, registers, the b64 check and one b62/b60 round, lint, lavapipe), `chain_topt.sh`;
  analysis `ab.py`, `nm_table.py`, `xsum.py`, `topt48.py`, `clocks.py`, `blocks.py`, `pull.sh`.
- `raw/r2/box/`: every log (`ab_*`, `nm_*` the A/B; `fin_*` the final check; `x_C_*`, `cmp_C_*` exactness;
  `q_topfd_*` device tests; `plan_CM.log`; `lvp*`, `wgsl_*`, `blocks_*`; `fmt_*`, `clippy_*`; `topt_*`), `sass/`.
- `raw/review/`: the reviewer's model, host-test patch and outputs (unchanged).
- `raw/r2/pr-top-fd-round2-d813aea.bundle` (`87958fd..d813aea`), `raw/r2/*_table.md`, `raw/r2/registers.txt`,
  `raw/r2/clocks.txt` (`raw/r2/scripts/analyze.sh` regenerates them); `raw/PR-BODY-v1-bedc658.md` (the first body).
- The first PR form's branch head `bedc658` is superseded (force-pushed with lease); its bundle stays in
  `raw/pr-top-fd-round2.bundle`. The switchable experiment branch `exp/top-fd-round2` (`f168b28`, on `f3fb390`) is
  unchanged.
