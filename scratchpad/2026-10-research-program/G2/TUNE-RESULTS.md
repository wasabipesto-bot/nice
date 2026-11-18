# G2 port: offline tuning, 2026-11-18 08:10–12:30 UTC (ivory only)

Brief: `G2/TUNE-BRIEF.md`. Branch `g2-cubecl-local`, from `9ff100e6` (+ `a6e5f29c`, a repro example) to **`4170a781`**,
eleven ordinary commits, never pushed. Bundle `G2/port/g2-cubecl-local.bundle` re-created; `G2/port/g2_cubecl.rs` is a copy.

**Labels.** [M] = measured: ACO instruction counts (Mesa 26.0.8 RADV, GFX1201, drm-shim), ptxas/nvdisasm SASS counts
(NVRTC 12, sm_86), exactness on lavapipe 26.0.8. [P] = predicted: every time below. No GPU was used; no timing claim
comes from lavapipe.

## Summary

- **Part A (RDNA4):** the 3b step's VALU per wave-iteration fell **217 → 169 (−22 %)** [M], 3a **222 → 52** [M],
  phase 1 **74 → 58 vcyc** [M], the transpose about **131 → 40 vcyc per task** [M, static diff], the whole kernel
  **1,746 → 1,228 vcyc** [M]. **LDS 25,600 → 21,504 B, VGPRs 192 → 120, 8 → 12 waves per SIMD** (ACO's unit:
  wave32 slots, i.e. 4 → 6 wave64) [M]. The GPU prep makes the parents in one root pass instead of two, at 229 instead of 311 + 338 vcyc per root [M].
- **Every change is exact on lavapipe** (both staged super-units, whole, SPIR-V, W = 8 and W = 16, GPU prep at W = 8) [M].
  New proofs: 16-chunk rounds (`--fill 1024`, the W ≥ 32 setting, so far run only on the 3080 at W = 32) now fit lavapipe and pass at W = 8 and 16; **W = 16 with
  `--cmask 1` now runs and passes** (it crashed lavapipe's 512-bit JIT before). W = 32 / 64 still run nowhere; the
  rewritten transpose was checked against the definition at W = 8/16/32/64 in a CPU simulation [M].
- **Issue-bound model for the card** (`G2/port/model_rdna4.py --tune --b3=169 --xp=40`): kernel bound
  **3.185 → 2.145 ms (−33 %)** [P]. **Predicted ratio: central ×6.4 (×6.1–6.7 at efficiency 0.75), ×4.8–8.1 over
  efficiency 0.55–0.95 and prep 0.15–0.45 ms, ×4.4–8.7 with main's ±8 %** [P]. Before: ×4.5 (×3.4–5.6) with the same
  model. The ×4.0 stop line is now below the whole band — on a model that has not met the card.
- **Part B (NVIDIA ×1.34):** found from generated code, not timed:
  1. **The "bottom side 1.75 against 0.63 ms" comparison was not like for like.** nvcc removed v10's whole
     transpose and probe setup from v10's probes-off kernel as dead code (its mode-0 SASS has no SHFL and no FLO;
     5,184 B of shared memory against 32,200 B in mode 2) [M]. CubeCL's mode 0 keeps them (atomics). v10's 0.63 ms
     is phase 1 only; the honest comparison is the full kernel, 6.0 against 4.54 ms.
  2. **CubeCL lowers every shared-memory atomic `load()` to `atomicAdd(p, 0)`** (cubecl-cpp `compile_atomic_load`)
     [M]. 3a read two `comm` words per chunk per probe that way: 16 chunks → 32 same-address shared atomics per
     probe. Whether nvcc warp-aggregates them (VOTEU + FLO + one ATOMS + SHFL) or issues them per lane (32-way
     same-address ATOMS) **flips with unrelated code**: aggregated in `9ff100e6` with `--tdig 0`, per lane with
     `--tdig 1` [M, SASS of both builds]. **That is the mechanism of the unexplained "+2.8 ms with `--tdig 1`"**
     (identical table contents, different 3a codegen) [P: mechanism found, not timed]. The tuned 3a has no
     atomics (90 SASS instructions per probe, 0 ATOMS) [M].
  3. Parent records were three LDG.32, probe words four LDS.32, records four STG.32, where v10 used one 128-bit
     access each [M]; now vectors (one LDG.128 / LDS.128 / STG.128) [M].
  4. Not the cause: `idxGlobal % warpSize` (one MUFU.RCP for the kernel, CSE'd) [M]; bounds checks (none,
     `launch_unchecked`); spills (none, 48–60 registers; v10 76 registers and 24 B of local memory) [M].

## Part A: changes, in commit order

ACO counts are per wave-iteration of the loop (`aco/loops.py`, W = 64, fill 1024, mode 2 with records unless noted);
"vcyc" = VALU + 4 × quarter-rate + 2 × 64-bit (ACO's cost table). Exact = the lavapipe set below. Card times are
the issue-bound model's bound per phase [P]; CUDA is predicted from SASS counts, not timed.

| # | change | commit | ACO before → after [M] | waves/SIMD | exact | predicted card [P] | predicted CUDA [P] |
|---|---|---|---|---|---|---|---|
| 1 | slices at row stride 65: 3b address = `v_bfe` + `v_add_lshl` (3 VALU/digit, was 4); W = 64 transpose stores contiguous | `9dc873d0` | 3b VALU 217 → 185 | 8 | yes | 3b 2.02 → 1.72 ms | small (stores conflict-free) |
| 2 | pending children as u16 (odd slots ORed after the next barrier), probe list in the same words; keep / chunk heads in registers | `b7d6af65` | LDS 25,600 → 21,504 B; VGPRs 192 → 120; phase 1 VALU 56 → 64 (vcyc 74 → 82); 3b 185 → 181 | **8 → 12** | yes (+ fill 1024) | phase 1 +0.04 ms; occupancy +50 % (not in the model) | 4 blocks/SM instead of 3 (shared 21.0 KB, 60 regs); phase 1 91 → 118 SASS (later 111) |
| 3 | 3b branch-free (entries past the list read 0, unkept lanes masked); probe byte offset in the list entry; kept counted in 3a; rank masks hoisted | `a1e8d528` | 3b VALU 181 → 171, SALU 60 → 46; noout 137 → 130 | 12 | yes | 3b −0.09 ms | — |
| 4 | 3a from per-digit common masks: one wave builds `cmv[v]` (chunks where digit v is common) per round; a probe ORs 17 words | `e654c4d7` | 3a VALU 222 → 52, LDS ops 36 → 21 | 12 | yes | 3a 0.33 → 0.08 ms | removes the 32 same-address atomics per probe (item B2): −0.5 ms at `--tdig 0`, up to −2.8 ms where nvcc did not aggregate |
| 5 | plane index uniform (`plane_sum` of lane 0's); `d & 63` so the child-mask multiplies are 24-bit; compaction rank masks hoisted | `14d4f01a` | phase 1 vcyc 82 → 58 (q 2 → 0; SALU 43 → 63); whole 1,620 → 1,488 | 12 | yes | phase 1 0.43 → 0.31, transpose 0.38 → 0.30 ms | — |
| 6 | parent records as `Vector<u32, 4>`; `--cuda-src DIR` (CubeCL's CUDA source without a device) | `44ae651b` | unchanged (`buffer_load_dwordx3`) | 12 | yes | 0 | phase 1 LDG 3 → 1, 118 → 108 SASS; gather 3 → 1 |
| 7 | probe digit words as a shared `Vector<u32, 4>` | `ac2d3672` | 3b VALU 173 → 169 | 12 | yes (+ `--tdig 1`) | 3b −0.04 ms | 3b 383 → 375 SASS, LDS ops 44 → 38 |
| 8 | survivor records as `Vector<u32, 4>` | `72b284af` | unchanged (ACO had merged them) | 12 | yes | 0 | 3b 375 → 364 SASS, STG 11 → 5 |
| 9 | GPU prep in one root pass (`--prep2 1`, default): compact parent list, scatter over 1.04M list entries | `b96cd80d` | hist 311 + scatter 338 vcyc per root → hist2 370 per root + scatter2 7 per parent | — | yes (records, order, segments, digits, list count) | root passes 0.48 → 0.27 ms | similar share of the 0.70 ms prep |
| 10 | shuffle transpose on 32-bit halves: rotation (`v_alignbit`) + `v_bfi` per half and stage; j = 32 swaps halves | `df428f34` | whole vcyc 1,484 → 1,228, v64 113 → 41 (≈ −64 vcyc per task) | 12 | yes (+ W = 16 cmask 1) | transpose 0.30 → 0.12 ms | transpose task 187 → 159 SASS |
| 11 | prep's `parent()`: digits from 32-bit halves, distinctness as popcount(mask) = 18, r mod 63 in 32 bits | `4170a781` | hist2 370 → 229 vcyc per root (v64 69 → 27, quarter-rate 18 → 12) | — | yes (+ `--prep2 0`) | root pass 0.27 → 0.17 ms | fewer emulated 64-bit ops in the prep |

**Totals [M]:** 3b 217 → 169 VALU (records; noout 130), SALU 60 → 45; 3a 222 → 52; phase 1 vcyc 74 → 58; probe
setup unchanged at 453 (`--tdig 0`; `--tdig 1` makes it 6); whole kernel vcyc 1,746 → 1,228; 2,917 → 2,545
instructions. **Stop rule for part A:** met at 08:32 (change 1 alone was −14.7 % of 3b VALU; change 2 reached 12 waves).

**Model, phase bounds [P]** (ms; `--tune --b3=169 --xp=40`; before = `9ff100e6` with its default `--tdig 0`):

| | setup | phase 1 | transpose | 3a | 3b (VALU / LDS) | kernel | GPU prep (band; issue-bound estimate) |
|---|---|---|---|---|---|---|---|
| before | 0.07 | 0.39 | 0.37 | 0.33 | 2.02 / 1.45 | 3.19 | 0.3–0.6 |
| after | 0.07 (0.00 with `--tdig 1`) | 0.31 | 0.12 | 0.08 | 1.57 / 1.45 | **2.15** (2.07 with `--tdig 1`) | 0.15–0.45 (hist2 0.17 + rank sort ≈ 0.07 + rest ≈ 0.03) |

The 3b step's VALU bound is now 8 % above its LDS bound (34 × 512 B per wave-step at 128 B/clk/CU): further VALU cuts there
buy little unless the LDS traffic falls too. The static count also includes about 13 VALU of the slab allocation
(a plane reduction and moves), taken once per 256 records of a plane [M listing]; without them the 3b step is at its
LDS bound (≈ 156 VALU, 1.45 ms) and the kernel bound about 2.03 ms. The headline keeps the static 2.15 ms, the
method used before the tuning.

**Prediction for the RX 9070 XT [P]:** ratio = 5.1 / (G2 + 0.093 fs).

| efficiency | G2 end to end | ratio (A, `--tdig 0`) | ratio (D, `--tdig 1`) |
|---|---|---|---|
| 0.95 | 0.54–0.61 fs | ×7.3–8.1 | ×7.5–8.3 |
| 0.75 (central) | 0.67–0.74 fs | **×6.1–6.7** | ×6.3–6.9 |
| 0.55 | 0.91–0.97 fs | ×4.8–5.1 | ×4.9–5.3 |

With main's base mean ±8 %: **×4.4–8.7**. Same method before the tuning: ×4.5 central (×3.4–5.6). Caveats: the
model sees issue only (no barriers, latency, bank conflicts, occupancy); 12 waves argue for the upper half of the
efficiency band, the unmodelled share grows as the modelled work shrinks, which argues the other way. Neither is
quantified.

**CUDA (RTX 3080) [P]:** full kernel 6.0 → about 5.0–5.6 ms (3a atomics −0.5, 3b −61 SASS per step ≈ −0.4 ms if
issue-bound as before, phase 1 +20 SASS but one LDG.128 instead of three, occupancy 3 → 4 blocks/SM), prep 0.70 → 0.45–0.6 ms:
**about 1.25–1.45 fs against v10's 1.12, ×1.1–1.3** (was ×1.34), and ×4.4–5.1 against the 3080's main. Not timed.

## Part B: what the port executes that v10 does not (SASS, sm_86, per loop body) [M]

`G2/port/raw/tune/cuda/`: `nvc.py` (NVRTC with cubecl-cuda's options, ptxas `-v`, nvdisasm), `sass_loops.py`;
v10 = `k_main10<MODE>` of `bench/g2bench.cu` as a device-only unit; base = `9ff100e6` + `--cuda-src`; head = `df428f34` (the kernel is unchanged by `4170a781`).

| loop (W = 32) | v10 | base `--tdig 0` | base `--tdig 1` | head `--tdig 0` | head `--tdig 1` |
|---|---|---|---|---|---|
| registers / stack | 76 / 24 B local | 48 / 0 | 58 / 0 | 60 / 0 | 58 / 0 |
| phase 1, per 256-parent step | 82 (1 LDG.128) | 91 (3 LDG.32) | 90 | 111 (1 LDG.128) | 105 |
| transpose, per 32-row task | 292 per 64-row chunk | 181 | 185 | 159 | 166 |
| 3a, per probe | 241 + inner 94 | 301 + 62 per 4 chunks, 8 ATOMS **aggregated** | 283 + 50 per 4 chunks, 8 ATOMS **per lane** | 90, 0 ATOMS | 91, 0 ATOMS |
| 3b, per step | 366 | 425 | 398 | 364 | 367 |
| whole cubin (instructions) | 5,344 (both modes) | 1,944 | 1,672 | 1,880 | 1,616 |

- v10's probes-off kernel (mode 0) is 28 registers and 5,184 B of shared memory: phase 1 plus a remnant; the
  port's mode 0 is 40 registers with the transpose's atomics and the probe setup still in it.
- Phase 1 is now *longer* on CUDA than in the base (111 against 91: the u16 slots and the deferred odd write); it is
  shorter on ACO. Its cost is latency (global loads) more than issue, and the LDG.128 cuts the load instructions 3×.
- Remaining CUDA-only differences: 15 shared atomics in the kernel (transpose `fetch_and`, `cmv` build loads, list
  counter, slab counter); `plane_sum` lowered to a shuffle loop bounded by the runtime `warpSize` (outside hot loops);
  BRA.DIV + WARPSYNC around every ballot/shuffle nvcc cannot prove convergent.

## Exactness evidence [M] (`G2/port/raw/tune/ex_c9/`, `ex_c11/`, `ex_c13/`; scripts `raw/tune/ex.sh`, `bda.sh`)

Every commit passed, before it was made, the set below on lavapipe 26.0.8, SPIR-V build, whole super-units 712012851
and 391856203 (4,032 jobs each, launches of 252): every unit's survivor set equal to the prototype's, counts equal
to the CPU reference, 0 kernel errors; with GPU prep also the records' order and words, class segments and top digits.

| run | W | prep | options |
|---|---|---|---|
| S8_su1, S8_su2 | 8 | GPU | defaults (fill 512) |
| S16_su1_cm0, S16_su2_cm0 | 16 | host | `--cmask 0` |
| S8_su1_f1024, S8_su2_f1024 | 8 | GPU | `--fill 1024` (16-chunk rounds: first time on lavapipe; the 3080 runs used them at W = 32) |
| S16_su1_cm0_f1024 | 16 | host | `--cmask 0 --fill 1024` |
| S8_su1_xp0_f1024 | 8 | GPU | `--xpose 0 --fill 1024` |
| from `df428f34`: S16_su1/su2_cm1_f1024 | 16 | host | `--fill 1024` (cmask 1) |
| once each | 8 | GPU | `--noout` (a1e8d528), `--tdig 1` (ac2d3672), timing paths `--no-sets` / `--noout` / `--burst` (72b284af), `--prep2 0` on 256 jobs (4170a781) |

Still unproven: the W = 32 and W = 64 paths (lavapipe gives full planes only to 16; the transpose's W = 64 logic is
covered by `raw/tune/xpose_sim.py` only), W = 16 with GPU prep (lavapipe's 512-bit JIT still crashes in the prep).
The mini dry run of the updated window driver passed on lavapipe (`raw/tune/dryrun_mini/`).

## Tried and dropped

- A uniform skip of the second list entry when the list's tail is short (3b): +5 static VALU for ≈ 2 dynamic; reverted
  before commit.
- A probe table of 3 words (16 fields + the 17th in the list entry): not needed once the list shared the pending
  slots' words; it would have cost 2 VALU per entry for split fields.
- 8-chunk rounds for the LDS budget: doubles rounds and 3a scans; the u16 route was cheaper.
- `v_perm`-built addresses (1 VALU per digit): needs a 256-byte row stride, 16 KB of slices; no LDS budget.
- 32-bit child masks (phase 1, gather): about −4 vcyc per use; not worth the risk today.
- `--ept 4` (four list entries per step; generalised record path): 3b 326 VALU per 4 entries = 163 per 2 against
  169 [M], but twice the tail waste per round (≈ 8 % against 4 % of entry slots) [P]: neutral; reverted.
- The probe setup in 32-bit halves (`--tdig 0`): about −0.03 ms [P]; D (`--tdig 1`) removes it entirely, so left.
- ACO does not emit `ds_read_b128` for the vector probe words (two `ds_read_b64`); not pursued.
- NVIDIA PTX/SASS from PyPI: installed (nvrtc, nvcc's ptxas, nvdisasm from `nvidia-cuda-nvdisasm`, 312 MB venv under
  the worktree) and removed at the end; `cuobjdump` has no wheel.

## What remains

1. **The window on the card**, with `4170a781`; variants and order in `WINDOW-PLAN.md` (D every round; optional P =
   the pre-tuning `9ff100e6` binary for one round, to measure the tuning itself).
2. A CUDA re-time of the tuned port on a rented 3080 (predicted ×1.1–1.3 of v10).
3. If the card lands below the model: the probe setup in 32-bit halves (or D as default), 32-bit child masks,
   the prep's two 64-bit multiplies (hist2 is still 27 v64 + 12 quarter-rate per root).
4. Upstream: CubeCL's `atomicAdd(p, 0)` for atomic loads on CUDA is worth an issue (a plain volatile/relaxed load
   would do); the draft-issue habit of `port/CUBECL-LOOP-BREAK-ISSUE-DRAFT.md` applies.

## Tools added (all in the worktree or `G2/port/raw/tune/`)

- `g2_cubecl --cuda-src DIR` (build with `cubecl-cuda`): CubeCL's CUDA source for the chosen modes without a device.
- `bda.sh TAG`: build, W = 64 SPIR-V dump, ACO, loop counts. `ex.sh TAG`: the exactness set, two runs at a time.
- `nvc.py`, `sass_loops.py`: NVRTC → PTX/cubin → ptxas resources → SASS loops with source-line spans.
- `xpose_sim.py`: the shuffle transpose, both forms, against the definition.
- `model_rdna4.py --tune [--b3=N --xp=N --p1=N]`.
