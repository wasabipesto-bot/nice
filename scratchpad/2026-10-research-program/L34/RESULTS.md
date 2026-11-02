# L34 RESULTS: digit-transposed AND in the join kernel, RTX 3080 at 180 W (2026-11-02)

Branch **`exp/join-transpose`** on the fork, head **`432b795`** (no PR): `exp/join-all3` `0f1a8a7` plus six commits, `common/src/cubecl_join.rs` only (+197/−17):
- `5814422`, `4a04000`, `c058bea`, `73cda4c` add the transposed AND behind `NICE_EXP_JOIN_TRANSPOSE=1`.
- `13b7ad9` rustfmts it (two reflowed lines, no code change).
- `fcd6581` adds the hybrid of §9 (`NICE_EXP_JOIN_TRANSPOSE_MIN`, default 0 = every batch transposed).
- `432b795` adds two clippy allows (no code change).

The main A/B binary `F` was built from `73cda4c`, the hybrid binary `H` from `fcd6581`. Raw logs: `raw/box/` (the box's `/root/l34/logs`). Scripts: `raw/scripts/`. Analysis: `python3 raw/scripts/analyze.py raw/box > raw/analysis.txt`, profiles `python3 raw/scripts/prof.py LOG…`.

## Summary

**Follow-up (§11–12):**
- **Chosen gate: `TRANSPOSE_MIN = 192`.**
  - Gate screen on #235–#237, 2 rounds: b62 1e17 ×1.074, b62 1e16 ×1.063, b60 ×1.078, b64 ×1.173, NiceMark ×1.107, b58 MSD-strong ×1.023.
  - MIN=256 keeps the large-field gain too (×1.065–1.149) but does no better on small buckets.
  - **No MIN removes the 1e14 loss** (b62 1e14 ×0.93–0.95 at 128, 192 and 256, including 256, which transposes nothing there). It is the kernel's fixed footprint: 5 cubes per SM instead of 6.
- **PR branch `pr/join-transpose-and` at `1298ce7`:** one commit on #236's head, `TRANSPOSE_MIN`/`AND_GROUP` constants and no env knobs.
  - Everything passes at the head: fmt, clippy ×2, WGSL lint, CUDA parity incl. b50/b54, dense ×2, whole b42 (also with the gate at 0), 1e14 compare, lavapipe naga + SPIR-V.
  - A/B on #236: b62 1e17 ×1.055, b62 1e16 ×1.050, b60 ×1.062, b64 ×1.176, NiceMark ×1.075 (MSD-strong ×1.017), 1e14 ×0.96–0.98. 40 registers, 5 cubes/SM.

**Original task:**

- **Exact, and a modest win on the large fields.** The transposed AND (G=4, `73cda4c`), A/B against the switch off in the same binary, RTX 3080 at 180 W, 3 interleaved rounds, medians (§6):

  | field | speed-up | device s/field off → on |
  |---|---|---|
  | **b62 1e17** | **×1.063** | 143.17 → 134.73 |
  | b62 1e16 | ×1.075 | 12.16 → 11.32 |
  | b60 1e16 | ×1.064 | 27.08 → 25.46 |
  | b64 1e16 | ×1.140 | 38.44 → 33.72 |
  | NiceMark score | ×1.049 | 5538.6 → 5810.8 |

  - Every round of every field is faster.
  - **It loses on small buckets:** NiceMark b58 MSD-strong ×0.90, and 1e14 fields ×0.83–0.92 (§8).
- **The hybrid fixes the small-bucket loss** (`fcd6581`, `NICE_EXP_JOIN_TRANSPOSE_MIN=128`: batches of under 128 tops keep the per-top AND; 2 interleaved rounds, §9).
  - Large fields: b62 1e17 ×1.075, b62 1e16 ×1.086, b60 ×1.065, b64 ×1.129, the same as `F` within noise.
  - Small buckets: 1e14 ×0.96–0.99, b58 MSD-strong ×0.98.
  - **NiceMark ×1.085.**
  - It is the branch head. Use `NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_MIN=128` (the default MIN is 0).
- **Well below the brief's 10–18 %.**
  - The join phase lost 12.5 % at b62 1e17 and 11.9 % at b60 1e16; nothing else moved (§7). Against the L1.7 split, the AND got about **×1.3 cheaper, not 2–4×**.
  - Most likely reason, inferred from counts and not profiled: each digit load is a gather with ~2-way bank conflicts (digits d and d + 32 share a bank). So shared-memory wavefronts drop only ~25 % (64 → ~48 per warp per 32 tops) while ALU work drops ~3×. The per-top AND looks bound by shared loads, not ALU.
  - Further costs: the build (+1.4 % of the field alone), occupancy (below) and partial groups (§8).
- **Loop order:** G=4 (4 chunks per digit pass) is the fastest in every screen. The brief's order (A) (G=8) is 0.5–3.4 % behind it, and order (B) (G=1) gains nothing (§3).
- **Registers and occupancy** (ptxas, b62 join kernel, §4):
  - Base: 40 registers, 6 cubes/SM.
  - `F` G=4: **56 registers, 4 cubes/SM**. The 2 KiB transposed copy alone limits it to 5 by shared memory.
  - Hybrid: 44 registers, 5 cubes/SM.
  - The switch-off kernel is the base kernel (40 registers, 784 SASS instructions).
  - SPIR-V JoinKernel 109–112 → 123–126 blocks, no stack overflow.
- **Exactness** (§5, §9):
  - CUDA: CPU-reference parity incl. b50/b54, both dense fields, whole b42; 1e14 compare at b57/60/62/64 identical on = off.
  - Every A/B, screen and NiceMark whole-field count identical on = off.
  - Lavapipe join parity ok on naga and direct SPIR-V; CI's WGSL lint 15 shaders, 0 flagged.
  - All of this for both `F` and the hybrid (MIN=128).
  - rustfmt and clippy (default and `nice_client/gpu`) are clean at the head `432b795`.
- **Baseline split after #237** (`exp/join-all3`, §1):
  - b62 1e17: top 34.6 %, bucket 1.7 %, **join 52.8 %**, check 6.5 %, other 4.4 % (140.1 s profiled).
  - b60 1e16: top 27.5 %, **join 57.7 %**, check 8.2 %.

## 0. Setup

- **Box:** Vast 58775886 (`nice-research-l34-transpose`), machine m139250 (the machine of L29–L33's A/Bs). RTX 3080 10 GB, driver 580.159.03, **power limit 180 W** (default 340, max 374; `box/power.txt`). Xeon E5-2630 v4, cgroup quota 9.6 CPUs, 62 GB. nvcc/ptxas 12.8 for the register counts.
- **Trees** (shipped as `git archive` tarballs from ivory; built on the box with toolchain 1.99.1, one target dir, `cargo clean -p nice_common` before each build, one build at a time except where noted):

  | binary | tree | md5 | used for |
  |---|---|---|---|
  | `A` | `exp/join-all3` `0f1a8a7` | caf200d3 | register count of the base kernel |
  | `P` | `0f1a8a7` + `2ab1694`/`32b84af` (profile, cherry-picked cleanly as `36785cd` `16be176`) | 09d16f48 | baseline profile (§1) |
  | `T` | `5814422` (prototype) | 8847a4d0 | first screen, registers |
  | `TP` | `5814422` + profile | c436b74d | prototype profile (§3) |
  | `T2` | `4a04000` (knobs: build-only diagnostic, top ids from global, `find_first_set`) | a315c1b3 | second screen |
  | `T3` | `c058bea` (unrolled build) | 11cb163b | third and fourth screens |
  | **`F`** | **`73cda4c`** (= `c058bea` + default G = 4 + a warning fix) | **be8af2c0** | **exactness, A/B** |
  | `client_F`, `F_naga`, `F_spv` | `73cda4c`; `nice_client --features gpu`, `--features cubecl`, `--features cubecl-spirv` | 221187cb, 3182a2b3, 09a7f813 | NiceMark, lavapipe |
  | `H` | `fcd6581` (hybrid, §9) | 86e81a5c | hybrid screen, exactness, short A/B |
  | `client_H`, `H_naga`, `H_spv` | `fcd6581`, features as for `F` | d2175af3, 9c1e0f5b, b5fbe60c | hybrid NiceMark, lavapipe |
  | `FP` | `73cda4c` + profile | c7e35923 | profile after (§7) |

- **The switch.** `NICE_EXP_JOIN_TRANSPOSE=1` is read in `JoinDevice::new` and passed to `join_kernel` as a comptime flag, so one binary runs both sides. `NICE_EXP_JOIN_TRANSPOSE_G` = chunks per group (1, 2, 4, 8; default 4; 16 = diagnostic, below). `NICE_EXP_JOIN_TRANSPOSE_TID=1` = survivors' top ids from global memory (attempt 2). Unset: the kernel is the base kernel (switch-off CUDA source differs only in the shared-memory layout order and a one-word unused array; 40 registers and 784 SASS instructions, the same as `A`'s).
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568), one untimed 1e14 warm-up field per process; metric `device=` (mean device seconds per field). nvidia-smi sampled every 5 s; clock = mean SM MHz over samples at ≥ 90 % utilisation.

## 1. Baseline profile: `exp/join-all3` (`P`, `NICE_EXP_GPU_PROFILE=1`)

Shares of profiled device time excluding the probe; other = upload + inputs + read + unattributed (`prof_A_*.log`).

| field | device s (profiled, excl. probe) | host setup | top | bucket | **join** | check | other |
|---|---|---|---|---|---|---|---|
| b62 1e17, 1 field | 140.10 (probe 1.93) | 15.37 | 48.47 (34.6 %) | 2.38 (1.7 %) | **73.93 (52.8 %)** | 9.17 (6.5 %) | 6.14 (4.4 %) |
| b60 1e16, 2 fields | 54.49 (probe 0.89) | 4.65 | 14.98 (27.5 %) | 0.93 (1.7 %) | **31.47 (57.7 %)** | 4.46 (8.2 %) | 2.66 (4.9 %) |

- Against L30 §5 (#235 + #236, 166 s at b62 1e17, join 45.9 %): #237 took the top phase from 71.9 s to 48.5 s, so the join is now over half of device time at both fields.
- Counts at b62 1e17 equal L30's (#236's exact counts): 1,020,844,021,499 survivors / 62,584,252,554 checked, `spilled=0`. Per live bucket: 238.6 tops, 335.6 listed entries, 158,302 AND pairs (b62 1e17); 3.2 tops per bucket at b62 1e14.

## 2. The change

- **Build.** After each top batch (≤ 256 tops) is in shared memory, one more pass writes `T[c·64 + d]` (8 chunks × 64 digits, 2 KiB): bit i set iff top `32c + i` has digit d. Thread u builds chunk `u / 32`'s words for digits `u % 32` and `u % 32 + 32`, unrolled over the chunk's 32 tops (`t_lo`/`t_hi` broadcast loads), masks off bits past the batch's last top, and writes zero words for chunks past it; then one `sync_cube`.
- **AND, per group of G chunks** (`tg`). At the first chunk of each group, each entry walks the set bits of its mask (`mlo`/`mhi`, a merged lo/hi loop so the trip count is the popcount, 12 at the production shape) and ORs `T[(cb + c)·64 + d]` into G accumulators per entry slot (EPT 2 → 2G registers). Each chunk's pass mask is `~acc[0] & chunk-valid-bits`, then the accumulators shift down by one chunk. `vv` (0 for padding lanes) is ANDed into the entry's mask first, so padding lanes run no iterations. The walk, the prefilter in the walk, the stage and the flush are unchanged (the walk still reads `t_lo`/`t_hi` for `walk_pf`).
- **Loop orders:** G = 8 is the brief's order (A), all 8 chunks per digit pass; **G = 1 is order (B)**, one accumulator, the bits re-walked per chunk; G = 2 and 4 are in between. G only changes how many chunk words each digit pass loads, so one code path covers both orders.

## 3. Screens and tuning (b62 1e16, 2 fields, device s/field, one binary per screen, interleaved, in run order)

Every run in every screen had the same counts: 163,513,599,082 survivors / 10,027,698,695 checked, found 0 (= L30's exact counts). Switch-off runs span 11.83–12.21 s over the morning (3 %), so single-run differences under ~3 % are noise.

| screen (tree) | off | G=8 (order A) | G=4 | G=2 | G=1 (order B) | other |
|---|---|---|---|---|---|---|
| 1: prototype `5814422` (looped build) | 11.949, 12.210 | 11.368 | **11.144** | 11.669 | 12.111 | |
| 2: `4a04000` (+ `find_first_set`, knobs) | 11.839, 12.189 | 11.268 | **10.900** | 11.406 | | TID: G=8 11.519, G=4 11.135, G=2 11.359; **build only (G=16): 12.560**, with TID 12.622 |
| 3: `c058bea` (unrolled build) | 11.830, 12.087 | 11.187 | **10.899, 11.357** | 11.177 | | **build only: 12.130** |
| 4: head-to-head | `c058bea` 11.971, 12.191 | | `c058bea` **11.023, 11.146**; `4a04000` 11.149, 11.188 | `c058bea` 11.350, 11.338 | | |
| 5: final `73cda4c` and the hybrid `fcd6581` (§9) | 11.960, 12.067 | | 11.029, 11.294 | | | hybrid G=4, MIN=64: 12.074, 10.945; MIN=96: 10.789, 11.293; **MIN=128: 10.906, 11.116** |

- **Loop order.** G=4 is the fastest in every screen, ×1.05–1.10 on the field against the mean of the off runs beside it. G=8, the brief's order (A), is 0.5–3.4 % behind it. G=1, order (B), is no faster than off (12.11 s against 11.95 / 12.21): re-walking the 12 bits for every chunk costs about what the transposed loads save. G=8 loses to G=4 on partial batches (it loads all 8 chunks' words for every digit however few tops the batch has) and needs more registers (59 against 56 in the final tree).
- **Prototype profile** (`TP` = `5814422` + profile, b62 1e16, 2 fields; `tprof_*.log`): join phase 12.62 / 12.85 s off → **10.89 s at G=4 (−14.5 %)**, 11.52 s at G=8 (−9.5 %). Top, bucket, check and other are unchanged (within 0.1 s). The first field (310 tops per live bucket) lost 16 % of its join time, the second (129 tops per bucket) 10 %.
- **Attempt 2** (`4a04000`): the **build-only diagnostic** (G=16: build `T` and its barrier, keep the per-top AND) cost **+0.55 s per field (+4.6 %)** with the prototype's looped build. Reading survivors' top ids from global memory instead of `t_id` (TID: 1 KiB less shared memory, so 6 cubes per SM fit by shared memory again) did not help anywhere, so occupancy by shared memory was not the cost. `find_first_set` for the lowest set bit (drops a zero test per digit) is in the final tree; it measured within noise.
- **Attempt 3** (`c058bea`): unrolling the build over the chunk's 32 tops (the 64 broadcast loads pipeline instead of 32 dependent rounds) cut the build-only cost to **+0.17 s per field (+1.4 %)**. It raised G=4's registers from 48 to 56. G=4 measured the same or slightly better (screen 4: 11.08 against 11.17 for `4a04000`), so it was kept.
- **Stopped tuning there** (three attempts). Final: `73cda4c` = `c058bea` with G=4 as the default and an unused-assignment warning fixed (`let tid = if comptime!(…)`).

## 4. Registers, occupancy, shared memory, SPIR-V

`raw/box/sass/registers.txt` (`regs.sh`: CubeCL's CUDA for the b62 join kernel from `CUBECL_DEBUG_LOG`, `nvcc -cubin -arch=sm_86 -O3 -Xptxas -v`). Cubes per SM on sm_86: 256 threads per cube, 64 K registers (allocated per warp in units of 256), at most 1,536 threads, 100 KiB shared memory per SM with 1 KiB reserved per cube.

| kernel | registers | spills | SASS instr. | cubes/SM by registers | shared B per cube | cubes/SM by shared | cubes/SM |
|---|---|---|---|---|---|---|---|
| base (`A`) and `F` switch off | 40 | 0 | 784 | 6 | 14,344 | 6 | **6** (48 warps) |
| prototype G=8 / G=4 / G=2 / G=1 | 48 / 48 / 40 / 37 | 12 / 8 / 12 / 0 B | 1160 / 888 / 1104 / 1072 | 5 / 5 / 6 / 6 | 16,392 | 5 | 5 |
| `4a04000` G=4 / G=8 / build-only | 48 / 58 / 40 | 8 B / 0 / 0 | 880 / 880 / 1184 | 5 / 4 / 6 | 16,392 | 5 | 5 / 4 / 5 |
| **`F` G=4** (A/B) | **56** | 0 | 968 | **4** | 16,392 | 5 | **4** (32 warps) |
| `F` G=2 / G=8 / build-only | 45 / 59 / 40 | 0 | 944 / 1000 / 1016 | 5 / 4 / 6 | 16,392 | 5 | 5 / 4 / 5 |
| hybrid `H` MIN=64/96/128 (MIN=0) | 44 (52) | 0 | 1096 (968) | 5 (4) | 16,392 | 5 | 5 (4) |

- **The transposed path costs a third of the occupancy at G=4:** 4 cubes per SM against 6. The 2 KiB of `T` alone takes a cube from 15.0 to 17.0 KiB with the 1 KiB reservation, and six of those need 102 KiB of the 100 KiB, so shared memory allows 5; the 8 accumulators plus the unrolled build take the registers to 56, which allows 4. It is faster all the same. What 6 cubes would give was not measured: CubeCL emits `__launch_bounds__(256)` with no minimum-blocks hint, so the register cap cannot be set from the kernel, and the TID variant that frees the shared memory (§3) still had 48 registers.
- **SPIR-V** (lavapipe, direct compiler, join parity dump; `blocks_par_g4.txt`, `blocks_par_off.txt`): JoinKernel 109–112 blocks off → **123–126** with G=4 (+14). No stack overflow.
- **WGSL** (CI's lint dump with the switch on, naga): JoinKernel b57 has 36 constant divisions (L30's base: 34), 0 flagged.

## 5. Exactness (`F`, `NICE_EXP_JOIN_TRANSPOSE=1`, G=4)

| check | result |
|---|---|
| `cubecl_cuda_join_matches_the_cpu_reference` (`x_ref_g4.log`): b10's 69, windows b20–b64 incl. **b50 and b54** (after refused layouts), the b57 frontier partitions 0/1000/3248 tight and refused, sliced windows, production shape | **ok**, 89 s |
| dense b58 1e15, 32 partitions (`x_dense58_g4.log`) | **ok**: 254,938,965 survivors / 14,396,829 checked, asserted equal to the CPU join (= L30) |
| dense b62 1e16, 4 partitions (`x_dense62_g4.log`) | **ok**: 120,013,475 / 7,355,827, asserted equal to the CPU join (= L30's #236 counts) |
| whole b42 field, `NICE_TEST_JOIN_FULL_FIELD=1` (`x_whole_g4.log`) | **ok**, 66 s: 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits (= L33); the test checks the join against the CPU reference and the stride pipeline |
| `NICE_TEST_JOIN_COMPARE=1`, 1e14 at b57/60/62/64, switch on and off (`cmp_on_g4_e14.log`, `cmp_off_e14.log`) | both pass (join = stride, found 0); **counts identical on = off**: b57 4,850,227,888 / 268,123,373; b60 2,694,700,282 / 180,517,288; b62 1,439,469,648 / 88,159,810; b64 5,702,041,796 / 346,647,759 (= L30/L33). Plan MiB identical (1193/1201/1369/1413) |
| A/B fields (§6) | survivors and checked **identical on and off in every run** of every field (they are exact since #236, so any difference would be a defect) |
| every screen run (§3), all G, TID, build-only, hybrid | identical counts |
| lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8), **naga**: join parity with the switch on (`lvp_par_naga_g4.log`) | **ok**, 95 s, all windows incl. b50/b54 and the b57 frontier |
| lavapipe, **direct SPIR-V**: join parity on (`lvp_par_spv_g4.log`) and off (`lvp_par_spv_off.log`) | **both ok**, 113 s / 105 s, no stack overflow |
| CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe naga with the switch on, `scripts/wgsl-lint.py` with CI's 13 `--require`s; `wgsl_lint_g4.log`) | **15 shaders, 0 flagged**, rc 0 |
| `cargo fmt --all --check` | `73cda4c`: two reflowed lines (`lint_fmt.log`), fixed in `13b7ad9`; **the head `432b795` is clean** (`fmt_Hc.log`) |
| clippy `-p "*" --all-targets -D warnings`, default and `--features nice_client/gpu` (rustc 1.99.1) | `fcd6581`: 3 findings (`clippy_*.log`): `manual_is_multiple_of` on the kernel's `cb % tg` and on a const assert, and `struct_excessive_bools` (the TID knob made `JoinDevice` four bools). `432b795` allows the first in the kernels module, uses `is_multiple_of` in the const assert and allows the second on `JoinDevice`: **both clean** (`clippy2_*.log`). No kernel code changed |

## 6. A/B: switch off vs `NICE_EXP_JOIN_TRANSPOSE=1` (G=4), one binary `F`, interleaved off/on per round (`chain_ab.sh`, 07:14–07:49 box UTC, nothing else on the box)

Device seconds per field; medians; spread = (max − min) / median; clock = mean SM MHz at ≥ 90 % utilisation. Every timed run sat at the 180 W cap (mean power 178–180 W per run, ≤ 71 °C). `raw/analysis.txt` has the `per_field` metric too (same ratios within 0.01).

| field | off (rounds) | spread | **on** (rounds) | spread | **speed-up** | per round | saving / field | clock off / on | clock-normalised |
|---|---|---|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | 143.96, 143.17, 142.99 (**143.17**) | 0.7 % | 135.24, 132.80, 134.73 (**134.73**) | 1.8 % | **×1.063** | 1.065, 1.078, 1.061 | −8.44 s | 1437 / 1433 | ×1.066 |
| b62 1e16, 2 fields | 12.198, 11.956, 12.160 (12.160) | 2.0 % | 11.326, 11.316, 11.139 (11.316) | 1.7 % | **×1.075** | 1.077, 1.057, 1.092 | −0.84 s | 1438 / 1468 | ×1.053 |
| b60 1e16, 2 fields | 27.479, 27.082, 26.918 (27.082) | 2.1 % | 25.508, 25.456, 25.304 (25.456) | 0.8 % | **×1.064** | 1.077, 1.064, 1.064 | −1.63 s | 1456 / 1458 | ×1.063 |
| b64 1e16, 2 fields | 38.441, 38.987, 38.271 (38.441) | 1.9 % | 33.617, 33.888, 33.715 (33.715) | 0.8 % | **×1.140** | 1.143, 1.150, 1.135 | −4.73 s | 1454 / 1409 | ×1.176 |

- **Every round of every field is faster with the switch on** (lowest per-round ratio 1.057).
- **Counts identical on and off in every run:** b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327 (all = L30's exact counts); found 0. Layouts identical (slots 5/13/4/6, plan MiB 1671/2050/1566/2151).
- The base is faster than any earlier A/B on this machine: b62 1e17 143.2 s (L30's combined #235 + #236: 166.2 s; #237 accounts for the rest).

### NiceMark nice-only

`client_F niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, off/on × 3, `NICE_API_BASE=http://127.0.0.1:9` (`nm_*.json`).

| | off | on | speed-up |
|---|---|---|---|
| **score** | 5538.6, 5575.0, 5512.7 (median **5538.6**, spread 1.1 %) | 5863.0, 5810.8, 5795.3 (median **5810.8**, spread 1.2 %) | **×1.049** (per round 1.059, 1.042, 1.051) |
| b58 MSD-weak (whole field), n/s | 2.453e14 (2.429–2.472) | 2.662e14 (2.657–2.689) | ×1.085 |
| **b58 MSD-strong (whole 1e15 field, 0.74 s)** | 1.351e15 (1.333–1.355) | 1.212e15 (1.212–1.231) | **×0.897** |
| b60 MSD-weak (sampled) | 4.867e14 (4.840–4.921) | 5.492e14 (5.477–5.506) | ×1.128 |
| b62 MSD-weak (sampled) | 6.272e14 (6.259–6.288) | 6.866e14 (6.841–6.958) | ×1.095 |

- Whole-field counts identical on and off (b58 MSD-weak 33,590,315,220 / 1,894,592,860; MSD-strong 4,027,773,430 / 226,773,299). The sampled scenarios cover a time-dependent number of partitions, so their counts differ run to run on both sides.
- **b58 MSD-strong is 10 % slower with the switch on**, in all three rounds. It is the scenario with the smallest buckets (strong MSD pruning), the same regime as the 1e14 fields (§8).

## 7. Profile after: `FP` = `73cda4c` + the profile commits, switch off and on (`chain_post.sh`, after NiceMark; `fprof_*.log`)

Profiled device time is within 1 % of unprofiled: b62 1e17 off 143.93 s against the A/B's 143.17, on 136.57 against 134.73.

| phase | b62 1e17 off | b62 1e17 **on** | change | b60 1e16 off (2 fields) | b60 1e16 **on** | change |
|---|---|---|---|---|---|---|
| top | 48.88 s (34.4 %) | 50.67 (37.6 %) | +1.79 | 15.10 (27.9 %) | 15.29 (30.4 %) | +0.19 |
| bucket | 2.42 (1.7 %) | 2.42 (1.8 %) | 0 | 0.90 (1.7 %) | 0.89 (1.8 %) | −0.01 |
| **join** | **75.33 (53.0 %)** | **65.93 (48.9 %)** | **−9.40 (−12.5 %)** | **31.03 (57.3 %)** | **27.34 (54.3 %)** | **−3.69 (−11.9 %)** |
| check | 9.30 (6.5 %) | 9.63 (7.2 %) | +0.33 | 4.48 (8.3 %) | 4.53 (9.0 %) | +0.05 |
| other | 6.13 (4.3 %) | 6.05 (4.5 %) | −0.08 | 2.65 (4.9 %) | 2.29 (4.5 %) | −0.36 |
| device, profiled excl. probe | 142.06 | 134.70 | −7.36 | 54.17 | 50.33 | −3.84 |

- **Only the join phase moves, by 12 %.** The top kernel is untouched; its +1.8 s at b62 1e17 is one run each, and the on run's mean SM clock was 2.4 % lower (1449 against 1485 MHz, both at 178–179 W), which accounts for about 1.2 s of it. At b60 the top moved by +0.19 s.
- The join is still the largest phase (49 % at b62 1e17, 54 % at b60 1e16).

## 8. Why ×1.06–1.14 and not the brief's 10–18 %, and where it loses

- **The AND got about 1.3× cheaper, not 2–4×.** With the brief's split of the join (L1.7: 1.18 ps per real lane-pair, 0.49 ps per padding lane, 238 ps per top), the base's AND at b62 1e17 is 29.9 + 6.7 + 9.1 = 45.7 s of the 75.3 s join phase. The join phase lost 9.4 s (§7), so the transposed AND with its build costs about 36 s: ×1.26 (×1.35 if the per-top term is chunk overhead the change does not touch).
- **Likely reason: shared-memory traffic hardly drops.** This is inferred from instruction and load counts, not from a per-instruction profile (no Nsight on the box).
  - Per warp and chunk of 32 tops, the per-top AND issues 64 broadcast loads (`t_lo`/`t_hi` per top; both entry slots share them) and roughly 420 ALU instructions.
  - The transposed AND at G=4 (12 digits per entry, EPT 2) issues 24 loads per chunk, but each is a gather over the lanes' digits. A lane with digit d and one with d + 32 hit the same bank, and with 32 lanes drawing from ~62 digits a warp almost always has such a pair. So each load costs about 2 wavefronts: ~48 per chunk against 64.
  - ALU work drops about 3× (to ~130 per chunk); shared wavefronts drop about 25 %. A ×1.25–1.35 cheaper AND is what one would expect if the per-top AND was bound by shared-load throughput or latency rather than by ALU.
  - No layout avoids the conflicts: 64 digit words share 32 banks, and the lanes gather random digits. Walking all lanes' low digits before their high digits makes each load conflict-free, but the trip count becomes the warp's largest low count plus its largest high count (about 10 + 10 against 12), so by the same count it saves under 20 % of the wavefronts for more ALU work. Not tried.
- **Overheads on top of that:** the build and its barrier (+1.4 % of the field when measured alone, §3); 4 cubes per SM instead of 6 (§4); and partial groups. G=4 loads four chunks' words per digit pass even when the batch's last group has fewer tops, and live buckets hold 129–310 tops on average at 1e16, so many batches end in a partial group.
- **It loses on small buckets.** With a few tops per batch the per-top AND is a few dozen instructions, while the transposed path still builds `T`, waits on a barrier and walks 12 digits per entry:
  - **1e14 fields** (3.2 tops per live bucket at b62): the compare runs (one field each, §5) give b57 ×1.08 but b60 ×0.86, b62 ×0.81, b64 ×0.92. The hybrid screen's 3-field runs give b60 0.616 → 0.734 s (×0.84), b62 0.497 → 0.594 (×0.84), b64 0.711 → 0.807 (×0.88).
  - **NiceMark b58 MSD-strong** (a whole 1e15 field in 0.74 s): ×0.90 in all three rounds.
- b64 1e16 gains the most (×1.14). It was not profiled; larger top batches per bucket would explain it, but that is a guess.

## 9. The hybrid: per-top AND for batches below `NICE_EXP_JOIN_TRANSPOSE_MIN` tops (`fcd6581`)

- **Change** (one commit on `13b7ad9`): a comptime `tmin` from `NICE_EXP_JOIN_TRANSPOSE_MIN` (default 0, i.e. as `F`). A batch of `nt < tmin` tops skips the build, keeping the barrier, and runs the per-top AND; larger batches run the transposed AND. The per-top AND is duplicated in the source so the switch-off kernel keeps only the base's AND (39 registers, 784 SASS instructions). Registers 44 at MIN = 64/96/128 (5 cubes per SM), 52 at MIN = 0.
- **Screen** (§3, b62 1e16): MIN=128 10.906 / 11.116 s against `F` G=4 11.029 / 11.294 and off 11.960 / 12.067 in the same rounds; MIN=64 and 96 are noisier (10.79–12.07). At 1e14 (3 fields, b60/62/64): MIN=128 0.628 / 0.542 / 0.739 s against off 0.616 / 0.497 / 0.711 and `F` G=4 0.734 / 0.594 / 0.807.
- **Exactness with MIN=128, G=4** (`hx_*.log`, `hcmp_on_e14.log`, `hlvp_*.log`, `hwgsl_lint.log`): the CPU-reference parity incl. b50/b54 ok (72 s); dense b58 254,938,965 / 14,396,829 and dense b62 120,013,475 / 7,355,827, both asserted equal to the CPU join; whole b42 ok; 1e14 compare at b57/60/62/64 ok with the same counts as §5; lavapipe parity ok on naga (86 s) and direct SPIR-V (105 s); WGSL lint 15 shaders, 0 flagged.
- **Short A/B** (`chain_hx.sh`, after everything above, nothing else on the box; off and `F` G=4 from `F`, hybrid from `H`, interleaved per round, device s/field):

| field | off (rounds) | `F` G=4 (rounds) | **hybrid** G=4, MIN=128 (rounds) | `F` speed-up | **hybrid speed-up** |
|---|---|---|---|---|---|
| b62 1e17, 1 field | 141.339, 145.286 (143.31) | — | 134.858, 131.689 (133.27) | — | **×1.075** |
| b62 1e16, 2 fields | 12.240, 12.159 (12.20) | 11.148, 11.325 (11.24) | 11.412, 11.059 (11.24) | ×1.086 | **×1.086** |
| b60 1e16, 2 fields | 26.866, 26.969 (26.92) | 25.415, 25.210 (25.31) | 24.991, 25.556 (25.27) | ×1.063 | **×1.065** |
| b64 1e16, 2 fields | 38.472, 38.255 (38.36) | 33.686, 33.655 (33.67) | 34.000, 33.974 (33.99) | ×1.139 | **×1.129** |
| b60 1e14, 3 fields | 0.610, 0.620 | 0.729, 0.704 | 0.614, 0.641 | ×0.858 | **×0.980** |
| b62 1e14, 3 fields | 0.499, 0.495 | 0.608, 0.593 | 0.510, 0.525 | ×0.828 | **×0.960** |
| b64 1e14, 3 fields | 0.697, 0.722 | 0.787, 0.782 | 0.720, 0.721 | ×0.904 | **×0.985** |

(Medians of two rounds; at 1e14 the ratio is of means.) Counts identical across all three in every run (the A/B fields' exact counts above; 1e14: b60 8,995,820,166 / 602,561,220, b62 4,229,527,892 / 259,080,525, b64 13,236,144,651 / 805,128,380).

NiceMark (`client_H`, off/hybrid × 2, `hnm_*.json`): **score 5549.0, 5594.7 → 6000.2, 6085.7, ×1.085** (per round 1.081, 1.088). b58 MSD-weak ×1.122, **b58 MSD-strong ×0.980** (`F`: ×0.897), b60 MSD-weak ×1.148, b62 MSD-weak ×1.097. Whole-field counts identical.

- **The hybrid keeps `F`'s gain on the large fields** (within the two-round noise: b62 1e16 equal, b60 +0.2 %, b64 −0.9 %, b62 1e17 ×1.075 against `F`'s ×1.063 in §6) **and removes most of its loss on small buckets**: 1e14 ×0.96–0.99 instead of ×0.83–0.90, NiceMark MSD-strong ×0.98 instead of ×0.90, NiceMark score ×1.085 instead of ×1.049 (different sessions, two and three rounds).
- What remains at 1e14 (−1.5 to −4 %) is the price of carrying the path: 44 registers and 16.4 KiB of shared memory per cube, so 5 cubes per SM instead of 6 even when no batch uses the transposed AND. The 1e14 compare runs in `hcmp_on_e14.log` (one field per base) were at parity with §5's switch-off runs: b57 0.751 / 0.739 s, b60 0.536 / 0.537, b62 0.509 / 0.506, b64 0.761 / 0.752.
- MIN=128 was the only threshold A/B'd. MIN=64/96 were screened once (§3) and are not distinguishable from it at b62 1e16.






## 10. Files

- `raw/scripts/` (all run on the box from `/root/l34`):
  - Builds: `build.sh` (test binary), `buildclient.sh`, `chain_base.sh` → `chain_base2.sh` → `post_t.sh` (P, T, A; the chain was reordered while running, see the scripts' headers), `chain_final.sh` (F, client, lavapipe binaries; stopped at 07:02 to hold the A/B) → `chain_rest.sh` (the rest of its CPU steps).
  - Runs: `run.sh` (throughput harness + nvidia-smi), `test.sh` (one ignored test), `regs.sh` (CUDA source dump + ptxas registers).
  - Chains: `chain_prof.sh` (baseline profile), `chain_screen.sh`, `chain_tprof.sh`, `chain_screen2.sh`, `chain_screen3.sh`, `chain_screen4.sh`, `chain_h.sh` (screens), `chain_x.sh` (CUDA exactness), `chain_lvp.sh` (lavapipe), `chain_ab.sh` (A/B + NiceMark), `chain_post.sh` (profile after), `chain_hx.sh` (hybrid exactness, lavapipe, short A/B, NiceMark).
  - Analysis: `analyze.py` (output `raw/analysis.txt`), `prof.py` (GPU_PROFILE phase shares; output for every profile log in `raw/profiles.txt`), `blocks.py` (SPIR-V blocks, from L33).
  - Lint: `clippy.sh` (on `fcd6581`), `clippy2.sh` (on `432b795`).
  - Follow-up (§11–12): `chain_min.sh` (gate screen), `chain_prbuild.sh`, `chain_prcpu.sh` (P256 builds and checks, superseded), `chain_pr192.sh` (P192 builds, then `chain_prx.sh` checks and `chain_prab.sh` A/B), `chain_p192t.sh` → `chain_fix.sh` (top-id diagnostic build; SPIR-V rebuild after the `cargo clean` race), `chain_p0.sh` (parity with `TRANSPOSE_MIN = 0`), `analyze2.py` (output `raw/analysis2.txt`).
- `raw/box/`: every log, `.smi` trace and NiceMark JSON; `sass/` (CUDA sources of the join kernel per variant, the CubeCL logs they came from, and `registers.txt`); the lint's WGSL dumps (`wgsl_g4.log.gz`, `wgsl_h.log.gz`) and the SPIR-V parity dumps (`pardump_spv_*.log.gz`); `power.txt`, `nvidia-smi.txt`, `box-info.txt`.

## 11. Follow-up: a stricter gate, MIN = 192 and 256 (`chain_min.sh`, 08:49–09:27 box UTC, nothing else on the box but niced builds)

`H` (`fcd6581`) with G=4 and `NICE_EXP_JOIN_TRANSPOSE_MIN` = 192 or 256, and 128 on the cheap fields, against the switch off in the same binary. Two rounds, interleaved per round. Device s/field; the ratio is of medians (two rounds), and at 1e14 of means. `raw/analysis2.txt` (`analyze2.py`). Counts were identical across all configurations in every run. While the large fields ran, the PR builds of §12 ran at `nice -n 19` with 4 jobs. The harness ran at normal priority, so they only used idle CPU.

| field | off | MIN=128 | **MIN=192** | MIN=256 |
|---|---|---|---|---|
| b62 1e17, 1 field | 140.80, 144.32 | — | 132.59, 132.85: **×1.074** | 134.45, 133.28: ×1.065 |
| b62 1e16, 2 fields | 12.053, 12.105 | 11.028, 11.100: ×1.092 | 11.357, 11.362: ×1.063 | 11.243, 11.130: ×1.080 |
| b60 1e16, 2 fields | 27.302, 27.151 | — | 24.974, 25.540: **×1.078** | 25.445, 25.683: ×1.065 |
| b64 1e16, 2 fields | 38.913, 38.844 | — | 33.146, 33.145: **×1.173** | 34.013, 33.644: ×1.149 |
| b60 1e14, 3 fields | 0.635, 0.601 | 0.631, 0.619: ×0.989 | 0.624, 0.638: ×0.979 | 0.637, 0.647: ×0.963 |
| b62 1e14, 3 fields | 0.501, 0.491 | 0.527, 0.514: ×0.953 | 0.525, 0.537: **×0.934** | 0.524, 0.532: ×0.939 |
| b64 1e14, 3 fields | 0.692, 0.720 | 0.736, 0.719: ×0.970 | 0.754, 0.742: ×0.944 | 0.727, 0.728: ×0.970 |
| NiceMark score (`client_H`, 2 rounds, `mnm_*.json`) | 5486.4, 5582.3 | 5996.4, 6008.2: ×1.085 | 6151.8, 6104.0: **×1.107** | 5897.1, 6006.7: ×1.075 |
| NiceMark b58 MSD-strong | 1.310e15, 1.358e15 | ×0.992 | **×1.023** | ×0.999 |
| NiceMark b58 / b60 / b62 MSD-weak | | ×1.116 / ×1.138 / ×1.098 | ×1.161 / ×1.142 / ×1.108 | ×1.116 / ×1.103 / ×1.088 |

- **MIN=256 keeps most of the large-field gain** (×1.065–1.149), but MIN=192 keeps more at b62 1e17, b60 and b64, and in NiceMark. Between 128, 192 and 256 the large-field differences are 1–3 %, about the noise of two rounds (b62 1e16 put 128 first, b62 1e17 / b60 / b64 put 192 first).
- **NiceMark's small-bucket scenario is fixed by any gate:** b58 MSD-strong ×0.99–1.02 against ×0.90 ungated (§6).
- **No gate removes the 1e14 loss.** b62 1e14 is ×0.93–0.95 and b64 1e14 ×0.94–0.97 at every MIN, including 256, which transposes no batch at 1e14 (3.2 tops per bucket).
  - So the residual loss is a fixed cost of carrying the path, not of using it. The kernel has 44 registers (5 cubes per SM against the base's 6), 16.4 KiB of shared memory per cube (also 5), and one extra barrier per batch.
  - Closing it would need the base kernel's footprint for small fields. One option is a per-field choice between two compiled variants, from the host's estimate of tops per bucket (top-layer prefixes per slice over buckets); this was not tried.
  - Alternatively, ≤ 40 registers and 1 KiB less shared memory (survivors' top ids from `tl`, which the TID knob showed costs nothing) would give 6 cubes. That is not reachable from CubeCL without a register cap.
- **Chosen: MIN = 192.** It is the best large-field and NiceMark result of the three. The criterion "no scenario below ×0.99" is met by NiceMark (all scenarios ≥ ×1.02) but **not by the 1e14 fields** at any MIN.

## 12. Follow-up: the PR branch `pr/join-transpose-and` (fork, **`1298ce7`**, one commit on #236's head `fb05597`; PR not opened; body in `PR-BODY.md`)

- **Branch construction.**
  - The seven `exp/join-transpose` commits (`5814422` … `432b795`) cherry-picked onto `fb05597` without conflicts. Their diff equals `0f1a8a7..432b795` line for line, and every hunk is in `join_kernel`, the kernels' allow-list or the host's `JoinDevice` (`top_kernel` untouched).
  - They were then squashed and rewritten without the experiment switches:
    - `pub const TRANSPOSE_MIN: u32 = 192` and `const AND_GROUP: u32 = 4`, used in the kernel directly (no new kernel parameters, no host change).
    - No TID or diagnostic knobs.
    - `clippy::manual_is_multiple_of` joins the kernels' allow-list.
    - A const assert ties `JOIN_WG = TOP_CAP`, `TOP_CAP % (32·AND_GROUP) = 0` and `TRANSPOSE_MIN ≤ TOP_CAP`.
    - Kernel and module docs updated, and a CHANGELOG line under Unreleased ending `([#NNN](…/pull/NNN))`.
  - +132/−18 over 2 files. The commit also applies to `cubecl_join.rs` on `exp/join-all3` without conflict; only the CHANGELOG conflicts, as usual.
- **Binaries** (box, toolchain 1.99.1):

  | binary | md5 |
  |---|---|
  | `P192` (`1298ce7`, CUDA test) | 7ac6f472 |
  | `client_P192` | fb1d72eb |
  | `P192_naga` | 60bea832 |
  | `P192_spv` | fbb9ac6e |
  | `B236` (`fb05597`, the same md5 as L30's `p236`) | 4db573d2 |
  | `client_B236` | 24976c49 |
  | `P0` (`1298ce7` with `TRANSPOSE_MIN = 0`) | 45ac7ad5 |

  The first `P192_spv` was deleted by a concurrent build's `cargo clean` before its install, and was rebuilt alone (`chain_fix.sh`).
- **Checks at the head, all pass:**
  - CUDA (`prx192_*.log`): `cubecl_cuda_join_matches_the_cpu_reference` (incl. b50/b54); dense b58 254,938,965 / 14,396,829 and dense b62 120,013,475 / 7,355,827, both equal to the CPU join; whole b42 (417,789,835 / 16,879,877).
  - 1e14 compare at b57/60/62/64 (`prcmp192_e14.log`): identical to `B236`'s (`b236cmp_e14.log`).
  - The same CUDA tests with `TRANSPOSE_MIN = 0` (`p0_*.log`, every batch transposed, because the small test windows mostly stay below 192): all pass with the same counts.
  - Lavapipe join parity: naga (`pr192_lvp_par_naga.log`, 90 s) and direct SPIR-V (`pr192_lvp_par_spv.log`, 117 s); JoinKernel 133–136 SPIR-V blocks.
  - CI's WGSL lint: 15 shaders, 0 flagged (`pr192_wgsl_lint.log`).
  - `cargo fmt --check` and clippy default + `nice_client/gpu` `-D warnings` (`pr192_fmt.log`, `pr192_clippy_*.log`).
- **Registers:** 40 (= `fb05597`'s 40), 0 spills, 1,088 SASS instructions (784). Shared memory 16,392 B per cube against 14,344, so **5 cubes per SM by shared memory** against 6. The exp tree's `H` had 44 registers. With the knobs gone, ptxas allocates the same code in 40.
- **A/B on #236** (`chain_prab.sh`, 09:48–10:25 box UTC, nothing else on the box; `B236` vs `P192`, interleaved; 2 rounds at 1e17 and NiceMark, 3 at 1e16 and 1e14; `raw/analysis2.txt`):

  | field | #236 | PR | speed-up |
  |---|---|---|---|
  | b62 1e17 | 180.54, 187.32 | 174.02, 174.57 | **×1.055** (1.037, 1.073) |
  | b62 1e16 | 15.598, 15.742, 15.723 | 14.646, 14.973, 14.981 | **×1.050** |
  | b60 1e16 | 34.162, 34.431, 34.165 | 32.165, 32.022, 32.771 | **×1.062** |
  | b64 1e16 | 41.080, 41.136, 40.488 | 34.937, 35.023, 34.932 | **×1.176** |
  | b60 / b62 / b64 1e14 (3 fields, means) | 0.707 / 0.572 / 0.739 | 0.723 / 0.596 / 0.758 | ×0.978 / **×0.959** / ×0.975 |
  | NiceMark score | 4404.0, 4394.2 | 4692.7, 4764.2 | **×1.075** |
  | NiceMark b58 MSD-weak / MSD-strong / b60 / b62 | | | ×1.106 / **×1.017** / ×1.093 / ×1.085 |

  - Clocks within 1.3 % per field, all at 178–180 W.
  - Counts identical on every field and in NiceMark's whole-field scenarios.
  - The saving per b62 1e17 field is 9.6 s, about the same as on #235–#237 (§11: 9.8 s). The ratio is lower here only because the base is slower.
- **Top ids from the list (diagnostic, `exp/join-transpose-and-tid` `1252ea5`, local only; 1e14 only, `pab_prt_*`):**
  - It frees the 1 KiB `t_id` (15,368 B, under the 6-cube line), but ptxas then uses 45 registers, so it is still 5 cubes per SM.
  - At 1e14 (means of 3 rounds): ×0.994 / ×0.974 / ×0.991 against the PR's ×0.978 / ×0.959 / ×0.975. Its round 2 sat at the base's level, and rounds 1 and 3 at the PR's, so this is inconclusive.
  - Not taken.
