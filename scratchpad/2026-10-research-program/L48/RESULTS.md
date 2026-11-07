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

SPIRV_PLACEHOLDER

EXACTNESS_PLACEHOLDER

SCREEN_PLACEHOLDER

AB_PLACEHOLDER

PLAN_PLACEHOLDER

FILES_PLACEHOLDER
