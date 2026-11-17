# G2 CubeCL port: living notes (started 2026-11-17 07:43 UTC)

Brief: `G2/PORT-BRIEF.md`. Benchmark ported: `G2/BENCH.md` (kernel v10, ×5.13 on an RTX 3080). Window plan:
`G2/WINDOW-PLAN.md`.

## Where it stands (update at the end of every session)

- **2026-11-17 10:25 UTC, end of day 1:**
  - **Kernel v10 and its preparation are ported to CubeCL.**
  - **Exact on lavapipe 26.0.8 with both compilers**, on both staged super-units, whole super-units:
    - every unit's survivor set equals the prototype's;
    - the counts equal the CPU reference;
    - the GPU prep's parent order equals the CPU's.
  - Exact at plane widths 8 and 16, for both transposes and both entry counts.
  - SPIR-V and WGSL have identical atomic operations in all 20 kernel variants.
  - **Priced for RDNA4 with ACO:** predicted **×4.4 central, ×3.3–5.6**. The ×4.0 stop line is inside the band.
  - **Window plan and driver written; dry run complete on lavapipe:**
    - every stage ran: exactness, rotated G2 rounds, main's harness, the spare, and the analysis with the verdict
      path (exercised on synthetic main logs);
    - `G2/port/raw/dryrun/`.
  - Bundle `G2/port/g2-cubecl-local.bundle` is current (head `3a3a4672`).
- **Next, in order:**
  1. **The window on the card.** It is the only way to prove the W = 64 path and settle the ratio.
  2. If the card lands near ×4.0:
     - an LDS diet to 12 waves (u16 pending indices via shared `fetch_or`, plus a smaller probe table);
     - precomputed slice offsets (−1 VALU per digit in the 3b step).
     Each must be re-proven on lavapipe.
  3. A CUDA run of the CubeCL port on a rented 3080 (cubecl-cuda), to compare with the hand CUDA v10's 1.123 fs.
     This is optional: it tells how much CubeCL itself costs.
- **What I would not do:** spend window time on the ballot transpose. ACO prices it 4× the shuffle one; it is in
  the window only as the fallback if the shuffle's W = 64 path is wrong.

- **2026-11-17 ~11:55 UTC, CubeCL port on a rented RTX 3080 (Vast 61056498, CUDA runtime):**
  - **Exact at W = 32 on real hardware:** both super-units, all variants (shuffle / ballot transpose, ept 1 / 2,
    scan / ballot ranks).
  - **Same-box, same-session timing** (`BENCH.md` §"CubeCL port on CUDA"):
    - CubeCL **1.573 fs** against hand CUDA v10 **1.147 fs**: ×1.37 slower.
    - The kept word is at parity (32.5–34.4 against 32.9 ps).
    - The gap is the bottom side (1.9 against 0.63 ms) and the GPU prep (1.03 against 0.44 ms).
    - Main on that box: 6.396 fs. The port as it stands is ×3.79 against it; v10 is ×5.07.
  - **New on the branch:**
    - `--cuda` (the GPU part is now generic over the runtime);
    - `--ranks 1` (ballot + popcount, default; CubeCL's plane scans cost 0.76 fs on CUDA);
    - `--cut` (phase-skip timing).
  - **lavapipe at 512-bit crashes** ("stack smashing", in lavapipe's process) with `--gpu-prep`, with either
    compiler. The main kernel alone at W = 16 still passes. That is a lavapipe defect in the wide mode, not
    reproduced at 256-bit.
  - **The AMD prediction is unchanged in centre:** ×4.5 (×3.3–5.7).
    - It is now re-derived from CubeCL's own CUDA components times card/3080 factors: phase 3 ×0.44–0.85 from the
      ACO model; the rest ×0.6–1.0, centred on main's ×1/1.24.
  - **The bottom side and prep fixes above are now the highest-value work before the window.** Each 0.1 fs is
    about ×0.35 of ratio near ×4.5.
- **Bimodal CubeCL timing across processes on the 3080:** full kernel about 6.0 or about 7.4–7.6 ms. Branch head
  is now `02075501` (queued launches in timing runs); the bundle is current.
- **Next session, in order:**
  1. Common masks inside the transpose (registers, no shared atomics).
  2. Parent records as one 16-byte load.
  3. A radix-sort prep.
  4. Find the bimodality.
  5. Re-time on CUDA if a box is available, then the AMD window.
- **Window plan changes from the CUDA dry run:** see `WINDOW-PLAN.md` (the driver ran end to end against the CUDA
  binaries with `HARNESS=…cubecl_cuda… G2EXTRA=--cuda`).

- **2026-11-17 ~13:00 UTC, the three fixes landed** (branch head **`997339bc`**; bundle `G2/port/g2-cubecl-local.bundle`
  re-created; `G2/port/g2_cubecl.rs` is a copy):
  1. **Common masks from the transpose's registers** (`--cmask 1`, default).
     - After the shuffle stages, each lane compares its column against the plane's valid rows.
     - One ballot per block, and lane 0 `fetch_and`s it into the chunk's two words. At W = 64 that is 2 atomics
       per chunk, against the old pass's 1,024 (q, v) tests and up to 1,024 `fetch_or` per round.
     - `comm` starts at all ones. The slice pass remains for `--cmask 0` and `--xpose 0`.
  2. **Parent records as one run of 4 words** (mask lo, mask hi, cacc, r4).
     - ACO now emits one `buffer_load_dwordx3` per parent in phases 1 and 2, where there were two loads.
     - `Array<Vector<u32, 4>>` was abandoned: the compile errors were a local `par` shadowing the array (renamed
       `parity`), not vectors.
  3. **Preparation:** histogram, scan, atomic scatter into a temporary, then a **per-bucket rank sort** (one cube
     of 64 per bucket; rank = number of smaller r4 in the bucket, from 8 KB of shared memory for buckets ≤ 2,048,
     else global) instead of one thread's insertion sort per bucket. The largest bucket is 573 / 554.
     **Plus each top's digit words once per super-unit** (`tdig_kernel`, 239k tops) instead of in every cube: the
     probe setup loop goes from 441 to 13 ALU per pass.
  - **Exactness [M], lavapipe 26.0.8, both compilers, both super-units, whole** (`G2/port/raw/fixes/G_*`):
    - W = 8 with GPU prep: PASS. Survivor sets, counts, and the records' order and words, class segments and top
      digits all equal the CPU's.
    - W = 8 with `--cmask 0` and with `--xpose 0`: PASS.
    - W = 16 with `--cmask 0`: PASS.
    - **W = 16 with `--cmask 1` crashes lavapipe's 512-bit JIT** ("stack smashing detected", both compilers,
      before the first mode).
      - Bisect: it needs both the ballot of `piece == vp` and its shifted value feeding the `fetch_and`; a
        constant in either place passes.
      - The W = 8 build of the same code is exact, and the W = 64 path has no shift.
      - I read this as a lavapipe defect, like the 512-bit `--gpu-prep` crash. **But W = 16 + cmask 1 is not
        proven.**
  - **Atomics:** 25 variants (W 8 / 32 / 64, cmask 0 / 1, xpose 0 / 1, modes, records on and off, the five prep
    kernels). SPIR-V = WGSL, **0 mismatches**.
    - The first comparison showed 6 "mismatches": WGSL kept dead `atomicAnd`s from a runtime-`&&`-comptime
      condition. They are now purely comptime.
  - **ACO (GFX1201, W = 64, full mode):**
    - 2,310 instructions (2,779 before), 192 VGPRs, LDS 25,600 B, 8 waves. LDS is still the limit.
    - In mode 0 the VGPRs fall from 108 to 36.
    - Per-iteration: probe setup 13 ALU (441); phase 1 102 (88); the slice common pass gone; 3a 295; 3b 319 (306).
      The 3b loop is unchanged in substance; ±13 is scheduling.
    - Prep kernels: rsort 86 instructions, LDS 8 KB per 64-thread group (8 waves); tdig 626 instructions per 32
      tops.
  - **Predicted effect** (no card measured the fixes):
    - The RDNA4 issue-bound model hardly moves: 0.685 → 0.697 fs. The removed work was small *in issue*: setup
      0.07 ms, common pass 0.07 ms.
    - But on the 3080 those phases cost far more than their issue count. Measured by phase cuts: the common pass
      0.40 ms, probe setup 0.18 ms, prep 1.03 against cub's 0.44 ms. They are latency and atomics, which the bound
      model does not see.
    - **The CUDA-based prediction** (the CubeCL port's measured 3080 components, minus the cut costs, prep assumed
      back to about 0.5 ms):
      - bottom side 1.98 → about 1.4 ms;
      - end-to-end 1.573 → **about 1.33 fs on the 3080** (v10 1.147);
      - ×4.4 against main there (×3.8 before).
    - **RX 9070 XT** (the same components × card/3080 factors, as before): central **×5.4** (×4.0–6.9), against
      ×4.5 before the fixes. Both rest on the CUDA savings being real. The cut timings make them likely, but they
      are not measured.

## Worktree, branch, build

- **Worktree and branch:**
  - Worktree `~/projects/nice/.worktrees/g2-cubecl`, local branch `g2-cubecl-local` on upstream main `7e0113fc`.
    It is **never pushed**.
  - A thin bundle for the window: `G2/port/g2-cubecl-local.bundle`. Prerequisite `7e0113fc`; it must be
    re-created after every new commit:
    ```
    git bundle create … origin/main..g2-cubecl-local
    ```
- **Code:**
  - `common/examples/g2_cubecl.rs`, about 1,500 lines: kernel module, prep module, host side, CPU reference, model
    counts.
  - `common/Cargo.toml`: an `[[example]]` entry with `required-features = ["cubecl"]`, and an `env_logger`
    dev-dependency (already in Cargo.lock).
- **Build** (one profile, own target dir `target-g2` at about 3 GB; check `df -h /` first; `-j 2`; nice 19):
  ```
  cd ~/projects/nice/.worktrees/g2-cubecl; export CARGO_TARGET_DIR=$PWD/target-g2
  nice -n 19 cargo build --offline --release -j 2 -p nice_common --example g2_cubecl --features cubecl                          # WGSL
  cp target-g2/release/examples/g2_cubecl g2bin/g2_wgsl
  nice -n 19 cargo build --offline --release -j 2 -p nice_common --example g2_cubecl --features cubecl-spirv,cubecl/spirv-dump  # SPIR-V (+ dump)
  cp target-g2/release/examples/g2_cubecl g2bin/g2_spirv
  nice -n 19 cargo test --offline --release -j 2 -p nice_common --features cubecl-spirv --no-run   # main's harness (dry run)
  cp target-g2/release/build/nice_common/<hash>/out/nice_common-<hash> g2bin/main_spirv_test
  ```
  - Each switch of features relinks in 1.5–3 min.
  - The example binary's name is the same for both compilers, so copy it after each build.
- **Run on lavapipe** (container `localhost/lvp26`):
  ```
  podman run --rm --cgroups=disabled -v $PWD:$PWD -v $D:$D -w $OUT -e VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json -e LP_NUM_THREADS=2 [-e LP_NATIVE_VECTOR_WIDTH=512] localhost/lvp26 $PWD/g2bin/g2_spirv $D --jobs all --batch 252 [--gpu-prep]
  ```
  - `--batch 252`: lavapipe limits buffers, and the record slabs of 4032 cubes × 32 planes need 717 MB at once.
  - `LP_NATIVE_VECTOR_WIDTH` sets lavapipe's plane width:
    - 256 gives W = 8 (the default);
    - 512 gives W = 16, with full planes;
    - 1024 and 2048 report 32 and 64 but run **only 16 lanes per plane** (partial subgroups). The kernel detects
      this (plane error counter) and the run is invalid.
  - **Options:**
    - `--jobs all | C0-C1:D0-D1`, `--batch N`, `--reps N`, `--modes 0,1,2`;
    - `--noout` (no survivor records), `--no-sets` (counts only);
    - `--gpu-prep` (GPU preparation, timed and checked against the host's), `--fill 512|1024`, `--xpose 0|1`,
      `--ept 1|2`;
    - `--force-w W --fill 1024` (compile for another plane width; compile only, to dump its SPIR-V);
    - `--model FILL` (print the kernel's dynamic loop counts and exit), `--debug-lanes`, `--cpu-full`.
  - **Debugging:**
    - `cubecl.toml` in the working directory with `[compilation.logger] level = "full"` logs every kernel's source.
    - `CUBECL_DEBUG_SPIRV=dir` writes the `.spv` modules (needs the `cubecl/spirv-dump` feature).
    - `RUST_LOG=warn` shows wgpu and Vulkan validation messages.
- **RADV for GFX1201 offline:**
  - Container `g2mesa` (from lvp26 plus build dependencies; `podman exec g2mesa …`).
  - Mesa 26.0.8 RADV-only build with `-Dtools=drm-shim` in `mesa/` (`mesa-inst/`, shim in
    `mesa-26.0.8/build/src/amd/drm-shim/`).
  - `aco/`: `pipec` (N22's), `reflect.py`, `summarize.py`, `loops.py`. `aco/aco.sh DIR…` compiles every `.spv` in
    each DIR to `<kernel>.aco.txt`. RADV reports "AMD Radeon RX 9070 XT (RADV GFX1201)", subgroup 64.

## Design of the port (what is identical to v10, what is not)

- **Identical:**
  - Inputs, and the parents' order: stable by (class, 255 − key8), same key-digit rule.
  - 64-child chunks of the ordered certified children.
  - Per round: the common-mask skip as a list of (probe slot, chunk mask).
  - Lane = chunk (16 lanes per entry, 16 probe streams).
  - Slices laid out [(v·16 + q)·2 + half], so a 16-lane group reads 128 contiguous bytes.
  - Two entries per unit per step by default (`--ept 2`).
  - Survivor records: (unit << 16 | probe slot, first parent of the chunk, word lo, word hi), in plane-private
    slabs of 256.
  - Counts: children, chunks, flat, kept, survivors, lane slots.
- **Different:**
  - **Probe digits:** 6-bit fields, 5 per word, 4 words. The pad is the probe's own first digit, not a zero slice.
    The skip test's probe mask is recomputed from the digits (no `prob_m`, as v11).
  - **Phase 1:** `plane_exclusive_sum` / `plane_sum`, with per-plane totals double-buffered in shared memory (one
    barrier per 256 parents).
  - **Phase 2, `--xpose 1` (default):** shuffle transpose that is W-generic. Each plane holds W rows of a chunk as
    64/W blocks of W×W bits; log2 W `plane_shuffle_xor` stages act on the whole u64, because the stage masks are
    the same for every block. Lane l then holds column s·W + l of every block s.
    - W = 64 stores 2 words.
    - W = 32 stores one half per segment.
    - W < 32 ORs W-bit pieces into an 8 KB atomic staging array, then copies it.
  - **Phase 2, `--xpose 0`:** 64 ballots per chunk segment, writer lane v % W (kept for comparison).
  - **Common masks:** from the slices (digit v is common iff slice v equals the chunk's valid mask), via shared
    `fetch_or`.
  - **Rounds:** `fill` children per round, comptime. It is 1024 (16 chunks) for W ≥ 32 and 512 for W < 32. The
    staging array pushes shared memory to 33.4 KB > lavapipe's 32 KB. Chunking, kept incidences and survivors do
    not depend on fill.
  - **Full planes assumed and checked:** `PLANE_DIM == W` and `UNIT_POS % W == UNIT_POS_PLANE`, with violations
    counted. Any non-zero error counter makes the run invalid; the binary says so and fails.
  - **GPU preparation (`prep` module, 4 launches):**
    - histogram of parents per key (16,128 buckets) over the 9,298,544 depth-4 roots, uploaded once as r4 values;
    - one-cube scan, which also gives the class segments;
    - atomic scatter;
    - per-bucket insertion sort by r4, which restores the CPU's stable order exactly.
    - It replaces CUDA's cub select-if + radix sort.

## CubeCL 0.10 pitfalls hit (all fixed)

1. **A Rust `const` as a mutable variable's initial value** (`let mut x = SLAB;`) is a comptime value. Reassigning
   it fails with `u32: From<NativeExpand<_>>` at the `#[cube]` span. Use a literal.
2. **`plane_broadcast(v, 0u32)`** wants a host `u32`. Use `plane_sum` of a value only lane 0 holds.
3. **`if comptime!(a) || runtime_b`** does not type-check. Set a runtime flag inside a comptime `if`.
4. **`comptime!(if … { } else { } as usize)`** needs parentheses. `let mut nch = comptime!(…)` followed by a
   runtime assignment fails like item 1: use `min(comptime!(…), select(…))`.
5. **cubecl-spirv emits invalid structured control flow for `loop { … break … }`.**
   - lavapipe's spirv_to_nir: "OpSelectionMerge instruction is required to precede an OpBranchConditional".
   - wgpu then reports only "Buffer with '' label is invalid" at the next `write_buffer`. WGSL was fine.
   - Fixed with `while going` and no `break`.
   - **Anyone writing CubeCL for the AMD card should test SPIR-V on lavapipe with `RUST_LOG=warn`.**
6. **Atomic stores:** each is alone in its basic block (inits, zeroing loops, resets). SPIR-V and WGSL agree in
   every variant (below).

## Exactness evidence [M] (all under `~/projects/nice/.worktrees/g2-cubecl/g2out/`)

The full super-unit means 4032 jobs, in launches of 252.

| run | compiler | W | transpose | prep | super-unit | result |
|---|---|---|---|---|---|---|
| `spirv/run_4jobs.txt`, `wgsl/run_4jobs.txt` | SPIR-V / WGSL | 8 | ballot | host | 712012851, 4 jobs | PASS |
| `spirv_full/run_all.txt` | SPIR-V | 8 | ballot | host | 712012851 full | PASS (counts = CUDA's v10 and the C++ reference exactly: children 33,705,647, chunks 528,635, flat 250,486,772, kept 123,163,397, surv 11,768,560) |
| `wgsl_full/run.txt` | WGSL | 8 | ballot | host | 712012851 full | PASS |
| `spirv_full_su2/run.txt` | SPIR-V | 8 | ballot | host | 391856203 full | PASS |
| `spirv_full_gpuprep/run.txt` | SPIR-V | 8 | ballot | GPU | 712012851 full | PASS, GPU order = CPU's |
| `S_w8_xp1_su1`, `S_w8_xp1_su2` | SPIR-V | 8 | shuffle | GPU | both full | PASS |
| `S_w16_xp1_su1`, `S_w16_xp0_su1` | SPIR-V | 16 | shuffle / ballot | host | 712012851 full | PASS |
| `W_w8_xp1_su1`, `W_w16_xp1_su1` | WGSL | 8 / 16 | shuffle | GPU / host | 712012851 full | PASS |
| `S_w8_ept1`, `S_w8_ept2` | SPIR-V | 8 | shuffle | host | 712012851 full | PASS |

**Atomics** (`python3 -I T26B/review2-box/scripts/atomcmp.py g2out/atom_spirv/compile.log g2out/atom_wgsl/compile.log`):
- **20 kernel variants:**
  - W = 8 and W = 64 (forced);
  - both transposes;
  - modes 0, 1 and 2, with and without records;
  - the four prep kernels.
- **Result:** the SPIR-V and WGSL modules have identical atomic store / RMW / load counts, with 0 mismatches.

## What is not yet proven

- **The W = 64 and W = 32 code paths** have never run.
  - lavapipe gives full planes only up to 16 lanes. At 32 and 64 it runs partial planes, which the kernel detects.
  - **What differs from the tested W = 8/16 code:**
    - the number of shuffle stages (comptime; the j = 16 and j = 32 stage masks);
    - the store branch (whole words instead of OR-ed pieces);
    - fill 1024 instead of 512;
    - `bal[1]` in the ballot variant.
  - The window's first step runs them on the card with full self-checks.
- **The card's clocks, occupancy in practice, and main's base mean on the card.** These have to be measured.

## RDNA4 pricing [M for ACO, E for time] (`g2out/aco_*/`, model `G2/port/model_rdna4.py`)

**ACO, GFX1201, wave64** (the main kernel, W = 64, fill 1024, full mode):
- 192 VGPRs (pre-scheduling demand 31), 108 SGPRs, no spills;
- **LDS 25,600 B, 8 waves per SIMD.** LDS is the limit: ACO raises VGPRs to the 8-wave budget, and `--ept 1` does
  not lower them;
- 2,175–2,779 instructions.

**Prep kernels:**

| kernel | wave size | VGPRs | waves per SIMD |
|---|---|---|---|
| hist, scatter | wave32 | 24 / 36 | 32 |
| scan | wave64 | 48 | 32 |
| bucket sort | wave64 | 12 | 32 |

**Per wave-iteration** (`aco/loops.py`, mode 2, xpose 1):

| loop | what | ALU | VALU | SALU | LDS | waits |
|---|---|---|---|---|---|---|
| 0 | probe digits (20 unrolled trailing-zeros on u64) | 441 | 413 (+20 v64) | 7 | 1 | 187 |
| 1 | phase 1 (256 parents per cube step) | 88 | 46 | 32 | 4 | 30 |
| 2 | common masks | 34 | 23 | 9 | 2 | 12 |
| 3 | 3a probe list | 295 | 222 | 37 | 36 | 112 |
| 4 | **3b step: 2 entries × 64 lanes = 128 lane slots, with records** | **304** | **208** | **56** | **40** (34 `ds_read_b64`) | 85 |
| 4, no records | | 231 | 171 | 20 | 40 | 59 |
| 4, ept 1 (64 slots) | | 176 | 114 | 42 | 20 | 58 |

- **The 3b step, per digit:** `v_bfe`, `v_lshl_add`, `v_lshlrev` (address) and half a `v_or3`. The address is 3
  VALU per digit; precomputed byte offsets would make it 2 (about −16 % of the step).
- **Transpose:** the shuffle version unrolls to about 88 VALU (19 of them 64-bit) per chunk-task. The ballot
  version is a 64-iteration loop of about 7 VALU + 5 SALU + one store each, about 448 VALU per task: **5× more**.
- **Dynamic counts** (`g2_cubecl --model 1024`, super-unit 712012851):
  - 262,528 phase-1 cube steps;
  - 36,148 rounds;
  - 73,355 3a iterations;
  - 460,954 3b cube steps (14.19M list entries);
  - 32,256 setup iterations.

**Model** (`model_rdna4.py`):
- **Card assumptions:** 64 CUs / 128 SIMD32 at 3.1 GHz; wave64 VALU in two passes; LDS 128 B/clk per CU.
- **Bound per phase in ms (VALU-bound everywhere):**

  | setup | phase 1 | transpose | common | 3a | 3b |
  |---|---|---|---|---|---|
  | 0.07 | 0.33 | 0.31 (ballots: 1.31) | 0.07 | 0.33 | 1.95 (LDS 1.45) |

- **Kernel bound: 3.06 ms, 0.685 fs** per admissible n.
- **Efficiency 0.95 / 0.75 / 0.55** (the RTX 3080's 3b ran at about 0.95 of its INT-issue bound; the rest is
  unknown):

  | efficiency | kernel | GPU prep | end-to-end |
  |---|---|---|---|
  | 0.95 | 3.2 ms | 0.45–0.9 ms | 0.82–0.92 fs |
  | 0.75 | 4.1 ms | 0.45–0.9 ms | 1.02–1.12 fs |
  | 0.55 | 5.6 ms | 0.45–0.9 ms | 1.35–1.45 fs |

  The GPU prep range is CUDA's 0.45 ms to twice that.
- **Tops and survivor checks:** 0.115 fs on the 3080 × (card main / 3080 main) ≈ **0.093 fs**.
- **Main on the card [D]:**
  - N22 measured the b64 1e17 field at 0.55 (start 58557331862957161709568, our 900006) in 92.8–96 s, with #255
    included.
  - Today's main lacks #255 (×1.05 at b64, N17.1), so ≈ 97–101 s, against 123.0 s on the RTX 3080 today: the card
    is **×1.24 faster on main**.
  - Base mean ≈ 6.347 / 1.24 = **5.1 fs** (±8 %: one field's ratio applied to the mix).
- **Prediction: ratio = 5.1 / (G2 + 0.093)**
  - central (eff 0.75): **×4.2–4.6, i.e. ×4.4**;
  - optimistic (0.95): ×5.1–5.6;
  - pessimistic (0.55): ×3.3–3.5.
  - The ×4.0 stop line is inside the band. Central is just above it.
- **Things ACO does badly, or that cost here:**
  - Every 64-bit op is a pair: 28–104 v64 per kernel.
  - LDS sets occupancy at 8 waves, against production's 16. 21 KB would give 12 waves.
  - Probe setup unrolls 20 u64 trailing-zeros (441 ALU per probe pass, small in total).
  - `s_delay_alu` and waits are about a quarter of the 3b loop's instruction stream.
  - Ballots as uvec4 are cheap: a `v_cmp` into an SGPR pair.
  - The shuffle stages use DPP / `v_permlanex16` / `v_permlane64`.
- **Variants worth trying on the card** (in the window: A = shuffle + ept 2, B = ballot, C = ept 1). For a later
  window:
  - LDS ≤ 21 KB for 12 waves (8-chunk rounds with 8-lane groups, or u16 lists);
  - precomputed slice byte offsets in the probe table (−1 VALU per digit).

## Window

`G2/WINDOW-PLAN.md`; scripts in `G2/port/window/` (`env.sh`, `smp.sh`, `run_g2.sh`, `run_main.sh`, `go_g2.sh`,
`analyze_g2.py`).

**Dry run [M], 09:34–10:19 UTC:**
- Workspace: `~/projects/nice/.worktrees/g2-cubecl/win`, in container `g2mesa` (`podman start g2mesa` to resume).
- Settings: `DEV=lvp`, `G2JOBS=0-1:0-63`, `G2BATCH=252`, `REPS=2`, `SZ64=1e14`, `NMAIN=1`.
- **Results:**
  - Exactness A / A (second super-unit) / B: PASS.
  - 21 G2 timing runs (rounds 1–3 plus the spare): every one PASS, counts equal.
  - Main fields 1 and 6: 620 s and 732 s on lavapipe. On lavapipe the harness's warm-up must be 1e14, because
    smaller fields route to stride.
  - `analyze_g2.py` printed every table. Its verdict path ran on synthetic main logs (`raw/dryrun/`).
- Sampling is empty on lavapipe, as expected: no AMD sysfs.
