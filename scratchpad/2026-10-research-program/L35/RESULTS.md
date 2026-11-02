# L35 RESULTS: the top kernel by finite differences (`exp/top-fd`), RTX 3080 at 180 W (2026-11-02)

Branch **`exp/top-fd`** on the fork (base `exp/join-all3` 0f1a8a7 = main 04693ac + #235 + #236 + #237).
Raw logs: `raw/box/` (the box's `/root/l35/logs`), scripts: `raw/scripts/`. Design: `DESIGN.md` (plan, then
"As built"). No PR.

__SUMMARY__

## 1. What was built

`NICE_EXP_TOP_FD` (read in `JoinDevice::new`; 0 or unset = today's `top_kernel`) switches the top stage to
`top_fd_kernel`. One binary does A/B.

- **State.** An unclipped block is a = P·w, w = b^f0, so a^k = P^k·b^(k·f0): the digits of a² and a³ are
  P²'s and P³'s shifted up by 2f0 and 3f0, with zeros below. Consecutive partition values are consecutive
  P. So the kernel keeps the detailed FD's five packed digit arrays for n = P (P², 2P+1, P³, 3P²+3P+1,
  6P+6; 4 digits per u32, `fd_add_top`'s biased add) and steps them with five additions per slot. They are
  short: P has t digits, not L (b62 1e17: 5 + 3 + 7 + 5 + 3 = 23 words).
- **Seed.** The first slot of a batch, after a gap in `vs`, and after a clipped or out-of-range slot: P,
  P², P³ in 16-bit limbs, then split16 long division with #237's limb trim and the Apple-safe first step
  (`fd_digits_trim`); 2P+1, 3P²+3P+1, 6P+6 from those digits by biased adds.
- **Certificate** (`cert_power_fd`). It has `cert_power`'s contract and produces the same outputs from the
  same digits. d = e^k − a^k and c0 = max(cap, `ndig_fast`(d)) are unchanged. The scan reads Q's packed
  words from position z = k·f0 up:
  - a word wholly below c0 only adds its value times b^pos to x mod b^c0 (u32 words, u64 products;
    nothing divides it);
  - the other words' digits go through `cert_power`'s scan step;
  - the repeat flags come from popcounts;
  - #235's carry test is unchanged.
  The zero digits at c0..z, if c0 < z (unreachable for P ≥ 1), are entered before the scan.
- **Mode 2** (`NICE_EXP_TOP_FD=2`, the A/B's side B) also steps d2 and d3 in binary:
  - d2 += 2wδ, d3 += Δ3, Δ3 += 6w²δ, with δ = w − 1;
  - Δ3 is seeded as 3wδ·(2a + 2w − 1);
  - so a stepped slot runs no `powers_diff`.
  Mode 1 keeps `powers_diff` every slot.
- **Clipped blocks.** Only P = plo and P = phi can clip, so at most two partition values per slice. The FD
  kernel skips them. `top_kernel` with a comptime `only_clipped` is launched beside it, only for batches
  that hold one of those two values (`clip_vs`, `top_fix`). The FD kernel has no division path at all.
- **Grid / append.** x runs over prefixes only, and each thread walks the batch's slots. `top_kernel`'s
  `top_count[slot]` atomic is warp-aggregated by nvcc (VOTEU.ANY + one ATOMG; its slot is `CUBE_POS_Y`).
  The FD kernel's slot is a loop counter, so every kept lane did its own same-address atomic. The kept
  tops are now appended per plane: plane_sum, plane_exclusive_sum, one `fetch_add`, plane_broadcast.
  Every unit runs the loop, using a `live` flag.
- `cube_done(ran, 0)` once per cube. `expect[0]` = top cubes, plus top cubes × slots when the
  `only_clipped` launch runs (`top_expect`).

Commits: `3574f0f` (the kernel, tests, timing test), `e702a85` (rustfmt), `5d93d35` (clippy: two unused
comptime parameters removed, a doc line), `3892d9c` (rustfmt), **`34e45c0`** (clippy: an allow on the
timing test). Every binary measured below was built from **`3574f0f`**. The later commits are
whitespace, an unused comptime parameter pair and lint attributes, with the same kernels.

**Host facts checked first** (as the brief asked):
- Production batches are consecutive. `run_field` passes `parts = 0..nparts` (`cubecl_join.rs` ~3529),
  and `run_pass` launches `parts.chunks(slots)` (~3800).
- Gaps come only from three sources: the overflow re-runs (`todo = left.overflowed`, re-chunked at half
  the size, which with an odd slot count can join two batches' ends), refusals (`not_run` + `overflowed`),
  and single-partition re-runs. The tests' thinned partitions and `join_sample` add their own. All of them
  re-seed.
- Clipping: `plo = s / w` and `phi = (e − 1) / w` (`overlap_join.rs` 1063), so a < s only for P = plo and
  e > e − 1 only for P = phi. That is one partition value each per slice (each slice has its own s, e).

## 2. Setup

- **Box.** Vast 58776353 (`nice-research-l35-topfd`), RTX 3080 10 GB, driver 580.159.03 (CUDA 13.0 driver
  API), power limit 180 W (as L29–L33's boxes), 40 host threads (cgroup ~9.6 CPUs), CUDA 12.8 toolkit for
  offline `nvcc`/`ptxas`. No GPU performance counters in the container (`ncu`: ERR_NVGPUCTRPERM), so the
  kernel was analysed by timing and ablation.
- **Trees.** A = `exp/join-all3` 0f1a8a7 (`/root/l35/src/A`); B = the work tree (`/root/l35/src/B`, at
  `3574f0f` for the final binaries); `Cfmt` = the pushed head for fmt/clippy.
- **Binaries** (pinned toolchain 1.99.1, `cargo clean -p nice_common` before each; `scripts/build.sh`):

  | binary | tree | features | md5 | used for |
  |---|---|---|---|---|
  | `A` | 0f1a8a7 | gpu | caf200d3 | base 1e14 compare, base b62 1e16 run, base registers |
  | `B`…`B8` | iterations (§4) | gpu | (logs) | kernel-level timings, FD test per iteration |
  | **`F`** | **3574f0f** | gpu | **8ea24743** | all CUDA exactness, **both sides of the A/B** (env), timings, registers |
  | `client_F` | 3574f0f | `nice_client --features gpu` | 723ed864 | NiceMark (both sides, env) |
  | `F_naga`, `F_spv` | 3574f0f | cubecl / cubecl-spirv | (build logs) | lavapipe |

- **Harness** as L30/L33: `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60
  1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568; b57 frontier for the
  1e14 compare), one untimed 1e14 warm-up field per process; metric `device=` (mean device seconds per
  field). New: `cubecl_cuda_top_fd_timing` (top kernels alone on the first slice of a production plan:
  the first 40 batches of consecutive partitions, and 40 batches of every other partition, where every FD
  slot seeds; each kernel in turn, three rounds, ns per (prefix, slot)).

## 3. Exactness

| check | result |
|---|---|
| **`cubecl_cuda_top_fd_matches_the_top_kernel`** (new; F, `xf_fd.log`): both kernels on the same `JoinDevice` and batch, per slot `top_count`, every `bucket_cnt`, and the sorted (top_p, top_m, top_r, top_x, top_b) entries equal, for **mode 1 and mode 2** | **ok**: 26 fields (17 test windows b20–b64, clipped at both ends, every partition; b57/b60/b62/b64 1e14 production plans; b60/b62/b64 1e16 first and last slices), **279 batches** (consecutive: first three, middle, last; the thinned live partitions = gaps; a batch [3, 2, 4, 5, 7, 8, …] stepping back and skipping), **23 with a clipped block**, **237,907,266 tops** |
| the same on every iteration binary (B, B3, B4, B6, B8) | ok each time (`x_fd*.log`) |
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` (F; `top_cert`'s end moved into `close_cert`) | ok: **102,365 intervals, 33,582 kept, 203,413 powers above c0, 69,824 with the carry** (#235's counts) |
| `cubecl_cuda_join_matches_the_cpu_reference` with **`NICE_EXP_TOP_FD=2`** and **`=1`** (b10's 69, windows b20–b64 incl. b50/b54, b57 frontier, tight layouts with re-runs and splits, refused layouts, production shape) | **ok / ok** (`xf_ref2.log`, `xf_ref1.log`) |
| dense b58 1e15, 32 partitions, FD=2 | ok: **254,938,965 / 14,396,829**, asserted equal to the CPU join (= L30/L33) |
| dense b62 1e16, 4 partitions, FD=2 | ok: **120,013,475 / 7,355,827**, asserted equal to the CPU join (= L30's on the #236 tree) |
| whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`), FD=2 | ok: 1764 partitions, **417,789,835** join survivors, **16,879,877** checked, no hits; join = stride = CPU reference (= L29/L33) |
| **1e14 COMPARE** (`NICE_TEST_JOIN_COMPARE=1`, stride pipeline too), b57/60/62/64: base binary A, F with FD=0, F with FD=2 | all pass (join = stride, found 0), **counts identical in all three**: b57 4,850,227,888 / 268,123,373; b60 2,694,700,282 / 180,517,288; b62 1,439,469,648 / 88,159,810; b64 5,702,041,796 / 346,647,759 (= L30/L33) |
| 1e16 / 1e17 whole fields (the A/B, §5): FD=0 and FD=2 sides | survivors / checked / found identical on every side and round (§5) |
| lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8), **naga**: `top_fd_matches_the_top_kernel` (light: windows + 1e14 plans, first/last/thinned/odd batches) | ok: 21 fields, 142 batches (20 with a clipped block), 1,018,088 tops, 81 s |
| lavapipe, **direct SPIR-V**: the same test | ok, 135 s, no stack overflow |
| lavapipe, direct SPIR-V: `cubecl_join_matches_the_cpu_reference` with FD=2 | ok, 125 s |
| CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe naga + `scripts/wgsl-lint.py` with CI's 13 `--require`s) with FD off | 15 shaders, **0 flagged**, rc 0; TopKernel b57: 270 constant divisions (= L33) |
| the same dump with `NICE_EXP_TOP_FD=2` (`--require TopFdKernel@57` instead of TopKernel@57) | 15 shaders, **0 flagged**, rc 0; **TopFdKernel b57: 196 constant divisions** (the seed's trimmed split16 division and digit extraction, and the buckets' `% (b − 1)` as in `top_kernel`; a stepped slot has no long division) |
| `cargo fmt --all --check` | on 3574f0f: reflows only (`fmt.log`), fixed in `e702a85`/`3892d9c`; **clean on the head 34e45c0** (`fmt_head.log`) |
| `cargo clippy -p "*" --all-targets --features nice_client/gpu -- -D warnings` (rustc 1.99.1) | **clean** on the head (`clippy_gpu.log`; the first run found two unused comptime parameters, a doc nit and a test's single-letter names, fixed in `5d93d35`, `34e45c0`) |

Coverage: the dense fields spread their partitions (i·total/n), so they exercise seeds and overflow
re-runs; stepping is exercised by the FD test's consecutive batches and by every whole-field run (1e14
compare, A/B), whose batches are consecutive chunks of `0..nparts`.

## 4. The kernel alone: iterations, ablation, registers

`cubecl_cuda_top_fd_timing`, b62 1e17's first slice: 3,620,628 prefixes, 5 slots per batch (the plan's),
40 batches. Values are ns per (prefix, slot), the median of 3 rounds, with the ratio to `top_kernel` in the
same round. "all-seed" uses every other partition, so every FD slot seeds. (The b62 1e16 plan's first
slice is the same layout and gives the same numbers; b60 1e16: 4,348,405 prefixes, 4 slots.)
`python3 raw/scripts/iter.py raw/box` prints all of them.

| binary | change | FD regs (mode 1 / 2) | top_kernel | FD, consecutive batches | FD, all-seed |
|---|---|---|---|---|---|
| B2 | first prototype: digit FD, `powers_diff` every slot, the division path in the kernel for clipped blocks and c0 < z | 128 | 0.359 | 0.268 (×1.34) | 0.364 (×0.97) |
| B3 | + d2, d3 stepped in binary (always) | 160 | 0.366 | 0.309 (×1.18) | 0.446 (×0.80) |
| B4 | clipped blocks to `top_kernel(only_clipped)`; c0 < z in `cert_power_fd`; remainder in u32 words; mode 1 / mode 2 switch | 95 / 115 | 0.360 | 0.262 / 0.264 (×1.38 / ×1.37) | 0.354 / 0.363 |
| B6 | the scan walks Q's packed words; repeat flags by popcount | 93 / 109 | 0.363 | 0.261 / 0.265 (×1.39 / ×1.37) | 0.334 / 0.341 |
| **B8 = F** | **one atomic per plane** for the kept tops | **80 / 109** | 0.357 | **0.244 / 0.2275 (×1.46 / ×1.57)** | 0.337 / 0.350 (×1.07 / ×1.03) |
| B8, b60 1e16 (4 slots) | | | 0.327 | 0.240 / **0.225 (×1.37 / ×1.46)** | 0.318 / 0.328 |

- `top_kernel`: 80 registers. The first FD prototype had 128 and B3 had 160 (one block of 256 per SM),
  from `top_cert`'s division path and then the binary state living beside it. Removing the division path
  (B4) gave 95.
- **What had been capping the FD kernel was the append, not arithmetic.** From B4 to B6 neither halving
  the scan's remainder updates, nor dropping `powers_diff` from stepped slots (mode 2), nor the cube size
  (256/128/64 threads, `wg_B7.log`: ±1 %) moved the consecutive time.
  - The SASS showed `top_kernel`'s `top_count[slot]` atomic warp-aggregated by the compiler
    (`VOTEU.ANY`, `@P0 ATOMG`), because its slot is the cube's y.
  - The FD kernel's slot is a loop counter, so each kept lane issued its own same-address ATOMG.
  - Aggregating per plane (B8) took mode 1 from ×1.38 to ×1.46 and mode 2 from ×1.37 to ×1.57.
  - After B8, mode 2 (no `powers_diff` in a stepped slot) is the faster mode, as the instruction count
    says it should be.
- **Ablation** (`NICE_EXP_TOP_FD_ABL`, B5 and B8, consecutive, mode 1 / mode 2; the tops are wrong when
  it is set):

  | left out | B5 (before the plane append) | B8 = F |
  |---|---|---|
  | nothing | 0.261 / 0.263 | 0.244 / 0.229 |
  | outputs (append, stores, bucket atomics) | 0.229 / 0.210 | 0.219 / 0.196 |
  | the cube's certificate scan | 0.151 / 0.126 | |
  | the square's certificate scan | 0.194 / 0.176 | |
  | the digit step | 0.269 / 0.265 (no change) | |

  The cube's scan was the largest single part (~40 % of B5's stepped cost), then the square's (~25 %).
  The digit step itself is lost in the noise. Leaving out both scans, d's digit counts, or `powers_diff`
  changes the control flow (fake c0s, all or nothing kept), so those rows (`abl_B5.log`: 6, 8, 32) say
  nothing and are not used.

## 5. A/B, whole fields: binary F, FD off (A) against `NICE_EXP_TOP_FD=2` (B)

Interleaved A B per round, nothing else on the box (`chain_ab.sh` 07:50–08:23, `extra.sh` rounds 4–5 of
b62 1e17 08:31–08:39). Metric `device=` in s/field; medians; spread = (max − min)/median. Every timed run
sat at the 180 W cap (throttle reason 0x4, SW power cap), ≤ 71 °C. `python3 raw/scripts/analyze.py raw/box`
gives `raw/analysis_F.txt`.

| field | A (FD off) s/field, rounds | spread | B (FD, mode 2) s/field, rounds | spread | **speed-up** | per round | mean SM clock A / B |
|---|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field, 5 slots | **146.08** (146.22, 146.21, 146.08, 146.03, 145.38) | 0.6 % | **127.77** (128.82, 126.70, 127.77, 128.80, 126.94) | 1.7 % | **×1.143** | 1.135, 1.154, 1.143, 1.134, 1.145 | 1432 / 1453 MHz |
| **b62 1e16**, 2 fields, 13 slots | **12.23** (12.25, 12.23, 12.19) | 0.6 % | **10.76** (10.76, 10.70, 10.81) | 1.1 % | **×1.136** | 1.139, 1.143, 1.127 | 1453 / 1450 |
| **b60 1e16**, 2 fields, 4 slots | **27.40** (27.60, 27.40, 27.33) | 1.0 % | **25.27** (25.41, 25.27, 24.96) | 1.8 % | **×1.084** | 1.086, 1.084, 1.095 | 1451 / 1468 |
| **b64 1e16**, 2 fields, 6 slots | **38.52** (38.49, 38.52, 39.23) | 1.9 % | **39.13** (39.13, 39.62, 38.80) | 2.1 % | **×0.985** | 0.984, 0.972, 1.011 | 1436 / 1473 |

- **Counts are identical on both sides in every round.**

  | field | survivors | checked | found |
  |---|---|---|---|
  | b62 1e17 | 1,020,844,021,499 | 62,584,252,554 | 0 |
  | b62 1e16 | 163,513,599,082 | 10,027,698,695 | 0 |
  | b60 1e16 | 460,847,952,346 | 30,871,838,404 | 0 |
  | b64 1e16 | 787,584,956,227 | 47,900,853,327 | 0 |

  The b62 1e17 counts equal L30's profile counts. On this tree (#236) the counts are deterministic,
  unlike L33's #235-only tree.
- **Seconds saved per field:** b62 1e17 18.3, b62 1e16 1.47, b60 1e16 2.13.
- **Share of the top kernel.** Using the kernel-level ratios (§4: ×1.59 at b62, ×1.47 at b60), the top
  kernel was ~34 % of b62 1e17's device time (49.7 s of 146) and ~24 % of b60 1e16's (6.6 s of 27.4).
  That is less than L30.3's 43 % / 37 %, because #237 already took ×1.10 out of it.
- **Clock-normalised ratios are lower** (b62 1e17 ×1.127, b60 ×1.072). Side B held a higher SM clock at
  the same 180 W, so it does less work per cycle (fewer multiplies, more adds and loads). Unlike L33, the
  plain ratio is the conservative one here.
- **The base binary against F with FD off**, b62 1e16, single runs: 11.90 against 12.09 s, identical
  counts. That is within one round's spread, and the FD-off kernel compiles to the same 80 registers at
  b62 (§7).
- **b64 is slower with FD** (×0.985; clock-normalised ×0.959).
  - At b64 = 2^6 `top_kernel`'s chunk divisor is 2^12, so its "division" is shifts and masks (L30 §4
    found #235 null there for the same reason). The FD kernel removes nothing there.
  - It adds a seed, which at b64 costs 0.51 ns per (prefix, slot) against `top_kernel`'s 0.31 slot.
  - At the kernel level FD is ×0.93 (mode 2) / ×0.79 (mode 1), and even its stepped slots cost about what
    `top_kernel`'s do.
  - Fixed in `2111f09`: FD stays off at power-of-two bases (§8).

## 6. NiceMark (binary `client_F`, A = FD off, B = FD=2, 3 rounds, ~33 s each)

Score: A 5478 (5363, 5478, 5496; spread 2.4 %), B 5097 (5130, 5084, 5097; spread 0.9 %) → **×0.930**. Per
round 0.957, 0.928, 0.927.

| scenario | A rate | B rate | B/A |
|---|---|---|---|
| b58 msd weak (1e15, 16 slots, one slice) | 2.419e14 | 1.739e14 | **×0.719** |
| b58 msd strong | 1.329e15 | 1.356e15 | ×1.020 |
| b60 msd weak | 4.772e14 | 4.846e14 | ×1.016 |
| b62 msd weak | 6.201e14 | 6.337e14 | ×1.022 |

- The b58 scenarios run every partition, and their survivors / checked are identical A = B. The b60/b62
  ones sample partitions within the time budget, so their counts vary in both A and B.
- **b58 msd weak is the regression.**
  - The FD grid is one unit per top-layer prefix, against prefixes × slots for `top_kernel`.
  - On a field with a small top layer and many slots (this one: 1e15, 16 slots) it underfills the GPU,
    and each unit walks 16 slots in series.
  - The b60/b62 scenarios measure only short samples (~2.6–3.2 s of run time), so their large-field gain
    shows up only partly.
- The fix is in `2111f09` (§8): when the top layer is below 2^17 prefixes, the FD kernel splits the
  batch's slots into groups along y (each group seeds once), so it always has at least 2^17 units.

## 7. Registers, SASS, occupancy

CubeCL's CUDA source from `CUBECL_DEBUG_LOG` (a 1e14 field per base), compiled offline with
`nvcc -cubin -arch=sm_86 -O3 -Xptxas -v` (CUDA 12.8; `raw/scripts/regs.sh`, `raw/box/regs_*.log`). The
JIT the driver runs may differ a little. 256 threads per cube; sm_86 has 64 K registers per SM.

| kernel | b57 | b60 | b62 | b64 | blocks of 256 per SM |
|---|---|---|---|---|---|
| `top_kernel` (base binary A, b62) | | | 80, SASS 4400 | | 3 |
| `top_kernel`, F, FD off | 80 / 4368 | 80 / 4032 | 80 / 4376 | **99** / 3488 | 3 (b64: 2) |
| `top_kernel(only_clipped)` | 80 | 80 | 80 | 80 | 3 |
| **`top_fd_kernel` mode 1** | 80 / 3768 | 80 / 3560 | 80 / 3744 | 93 / 3272 | 3 (b64: 2) |
| **`top_fd_kernel` mode 2** | 111 / 3904 | 109 / 3696 | 109 / 3888 | 111 / 3432 | 2 |

- No spills. Mode 1 reports a 24-byte stack frame at b57–b62, a small local array, not a spill.
- Mode 2 holds 24 more words (d2, d3, Δ3, b62: 6 + 9 + 9) and two constants, at 109–111 registers.
  That means 2 blocks per SM (16 warps), against `top_kernel`'s 3 (24 warps). It is still the faster mode
  at b60/b62 (§4).
- The cube size made no difference at 256, 128 or 64 threads (B7, mode 1 at 93 registers). So the FD
  kernel is not occupancy-bound at these sizes.
- Lavapipe direct SPIR-V blocks (`blocks_fd_spv.txt`): **TopFdKernel 304 (b57, b62), 310 (b58, b60),
  316 (b64)**, against TopKernel 368–386 on the same dump. The FD kernel is the smaller one, so it is not a
  stack risk for CubeCL's SPIR-V compiler (L29.2).

## 9. What a stepped partition costs, and what persistence would add

From F's kernel timings (`tm_e17_b62.log`, `tm_e16_b60.log`, `tm_e16_b64.log`). With k slots per batch,
c = consecutive and g = all-seed ns per (prefix, slot):
- a stepped slot costs s = (k·c − g)/(k − 1);
- a seeded slot costs about g.

| base (slots) | `top_kernel` per slot | FD mode 2: stepped s / seeded g / batch average c | mode 1: s / g / c |
|---|---|---|---|
| b62 1e17 (5) | 0.363 | **0.198** / 0.350 / 0.229 | 0.223 / 0.339 / 0.246 |
| b60 1e16 (4) | 0.333 | **0.192** / 0.329 / 0.226 | 0.213 / 0.319 / 0.240 |
| b64 1e16 (6) | 0.309 | 0.298 / 0.509 / 0.333 | 0.369 / 0.496 / 0.390 |

- **A stepped partition costs 0.198 ns of device time per top prefix at b62 against 0.363 for
  `top_kernel` (×1.83), and 0.192 against 0.333 at b60 (×1.73).**
  - In a batch of 5 (b62 1e17) the one seeded slot is 31 % of the FD kernel's time; in a batch of 4
    (b60) it is 36 %.
  - The appends (the plane append, stores and bucket atomics: `NICE_EXP_TOP_FD_ABL=1`) are 0.033 ns of
    the 0.229 at b62.
  - The step itself is five biased adds over the 23 digit words plus three multiword adds over the 24
    binary words (b62 1e17). At an estimated ~200 integer instructions it is too small to see:
    leaving the digit step out (ABL=16) changed nothing measurable.
  - What a stepped slot still pays for:
    - the two certificate scans over the digits from z up (cube ~40 %, square ~25 %, B5);
    - x mod b^c0 in binary;
    - the carry tests and `ndig_fast`, which read the power table;
    - the closure and the append.
- **Persistence across batches** (keep the state per prefix in device memory between batches;
  production batches are consecutive) would make every slot a stepped one except the first of a slice
  and those after re-runs.
  - Kernel at b62: 0.229 → 0.198 (×1.16 more; ×1.83 over `top_kernel` in all). At b60: 0.226 → 0.192.
  - Field, scaled by the top kernel's share above: **b62 1e17 ≈ ×1.18** instead of ×1.143 (146.1 →
    ~123.5 s); **b60 1e16 ≈ ×1.11** instead of ×1.084.
  - Memory: mode 2's state is 23 + 24 words plus a tag = 192 B per prefix, **≈ 695 MB for b62 1e17's
    3.62 M-prefix slice** (mode 1: 96 B, ≈ 348 MB). The plans here are 1.6–2.2 GB on a 10 GB card, so it
    fits, but it has to be budgeted in `JoinPlan`/`Footprint` and released with the layout. Not built,
    as the brief said.
  - The attempt to measure it directly with 20-slot batches (`tm_*_s20.log`) is void: `test_plan` fitted
    only one slot at those sizes.
- **More slots per batch** would do part of the same without new memory. The plan's slot count, which
  memory bounds, now also sets the seed share: one slot in 5 seeds at b62 1e17, one in 13 at b62 1e16.

__REST__




