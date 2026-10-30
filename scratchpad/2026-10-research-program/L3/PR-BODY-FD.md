# GPU detailed mode: digit arrays by finite differences instead of division

Stacked on "GPU detailed mode: read back only the near-misses that were written" (branch `pr/gpu-detailed-readback`); this PR is the one commit on top of it, and its measurements compare against that branch as well as `main`.

The `CubeCL` detailed kernel squares and cubes every candidate in u32 limbs and then divides both results down to base-b digits, a chunked long division whose length grows with limbs × chunks (about 20 division steps per number at base 40, 30 at base 50). Over a run of consecutive n none of that is needed: with dS = 2n + 1, dC = 3n² + 3n + 1 and ddC = 6n + 6, stepping to n + 1 is S += dS, dS += 2, C += dC, dC += ddC, ddC += 6. This is the same identity #221 uses on the CPU. This PR adds `common/src/cubecl_detailed_fd.rs`, a second detailed kernel built on it:

- **Runs.** Each thread takes a run of `FD_RUN_LEN` = 128 consecutive candidates (grid-stride over runs). It seeds the five values once per run from the run's first n, with the per-number kernel's own limb products and chunked division: u64 by a constant on CUDA and HIP, split16 (u32 division of 16-bit halves) on wgpu, chosen by the existing `wide_chunk_for`. The seed is about 5 % of a run's work at 128; on an RTX 3080 throughput was flat within 3 % from 64 to 512.
- **Digit arrays.** The five values live in registers as base-b digits, four per u32 (one byte lane each, little-endian). An addition is biased, as on the CPU: adding 256 − b to every byte makes a lane overflow into the next exactly when its digit sum reaches b, so one native add carries four digits, and `t − ((t >> 7) & 0x01010101) · (256 − b)` takes the bias back from the lanes that did not carry (bit 7 of a lane is clear exactly when it carried, for b ≤ 128). No compare or select per digit.
- **Cached high words.** Words of S and C above the addend's width change only when a carry ripples through four digits of b − 1. Their part of the digit mask is computed once per run, and each step's five additions return the raw sum of their last fast word; one AND of those sums guards a single, rare branch that does every ripple and refreshes the cached mask. The hot loop masks 36 digits per number at base 50 instead of 50, with one branch per step.
- **Mask, histogram, near-misses.** Unchanged from the per-number kernel: `m |= 1u64 << d` per digit, two `count_ones`, one shared-memory atomic into the 4-copy workgroup histogram, and the same near-miss records.
- **Where it runs.** `fd_plan(base)` computes, with exact integer roots, the interval where n² has exactly `ls` digits and n³ exactly `lc`, and the widths of the three addends at the interval's top. `detailed_impl` sends the part of each batch inside that interval to the new kernel and anything outside it to the per-number kernel. The interval is exactly the legal range at every base from 10 to 64 (the two digit counts sum to the base and neither can fall, so neither can rise), so production fields run entirely on the new kernel, except on Metal adapters (see Portability). The per-number kernel stays for bases above 64, whose mask needs two words, for candidates outside a base's range (tests only), and as the reference in the tests (`DetailedKernel::Division`).

Measured on an RTX 3080 at its default 320 W power limit, the new kernel is 3.0× (base 40) and 3.7× (base 50) faster than the readback branch on the benchmark's detailed GPU windows (3.3× and 4.0× faster than `main`), and a production field of 1e10 numbers at base 50 takes 0.32 s instead of 1.22 s.

## Why the results are identical

Everything is exact integer arithmetic. The seed is the per-number kernel's own square and cube, plus 2n + 1, 3n² + 3n + 1 and 6n + 6 from the same limbs, converted to digits once by the same division. Each step is an exact base-b addition, so after k steps the arrays hold exactly (n + k)², (n + k)³ and the three differences. The biased add needs every lane below b, which its own output keeps true, and b ≤ 64 here. The arrays are sized for the interval: n² and n³ have exactly `ls` and `lc` digits throughout it, and the addends are widest at its top, where `fd_plan` measures them. So no carry can leave an array except out of S or C after a run's last number, which is never read. The mask covers exactly the `ls` + `lc` significant digits, the digits the per-number kernel's scan emits, so `num_uniques`, the histogram and the near-miss list come out the same. The cached mask of the slow words is refreshed in the same branch that changes them: any carry out of the last fast word of S or C takes that branch.

## Measured

RTX 3080 (20 GB board), driver 580.126.18, CUDA 12.8 (NVRTC), PCIe 3.0 ×16, Xeon E5-2673 v4 host; Rust 1.99.1, release profile, `--features gpu`; `--gpu-backend auto` picked `CubeCL` CUDA. Three trees on the same box, interleaved A B C A B C A B C: A is `main` (46e4dc4), B the readback branch this is stacked on (6a1e396), C this branch. Rates in numbers per second; spread is the lowest and highest round relative to the median.

**Power.** The board's power limit is its default, 320 W, but both kernels run into it. Sampled during back-to-back 1e10-number fields at base 50, `nvidia-smi` reports "SW Power Cap: Active" for all three trees (no thermal or hardware slowdown), at 317–318 W; the SM clock settles at 1.76–1.77 GHz on the division kernel and 1.86 GHz on this one (max 2.1 GHz). During the benchmark below the division kernel ran at 1.76–1.79 GHz on the readback branch and this kernel at 1.88–1.89 GHz, both at 308–318 W. So about 1.07× of the gain on this card is clock, not instructions: under the same cap this kernel holds a higher clock, presumably because its shifts, logic ops and adds cost less energy than the division's multiply-high sequences. Per clock, this kernel is about 2.8× (base 40) and 3.5× (base 50) the readback branch on the benchmark windows.

`nice_client detailed --gpu --benchmark --benchmark-secs 150` (67.5 s timed per scenario, 2e8-number windows at the range start):

| scenario | A rounds | A median (spread) | B rounds | B median (spread) | C rounds | C median (spread) | C / B | C / A |
|---|---|---|---|---|---|---|---|---|
| b40_detailed | 1.039e10 1.018e10 1.013e10 | 1.018e10 (−0.5/+2.1 %) | 1.108e10 1.106e10 1.114e10 | 1.108e10 (−0.2/+0.5 %) | 3.337e10 3.352e10 3.358e10 | 3.352e10 (−0.4/+0.2 %) | **3.03×** | **3.29×** |
| b50_detailed | 7.521e9 7.512e9 7.483e9 | 7.512e9 (−0.4/+0.1 %) | 7.980e9 8.093e9 8.052e9 | 8.052e9 (−0.9/+0.5 %) | 2.978e10 2.968e10 2.984e10 | 2.978e10 (−0.3/+0.2 %) | **3.70×** | **3.96×** |
| detailed GPU score | 4660 4609 4590 | 4609 (−0.4/+1.1 %) | 4956 4986 4991 | 4986 (−0.6/+0.1 %) | 16615 16624 16682 | 16624 (−0.1/+0.3 %) | **3.33×** | **3.61×** |

Kernel-dominated windows, through `process_range_detailed_cubecl` (the call the client makes for a detailed field) on the same three trees, interleaved, three rounds, median of five windows per round:

| window | A | B | C | C / B |
|---|---|---|---|---|
| b40, 2e9 numbers from the range start | 1.126e10 (−1.3/+0.5 %) | 1.139e10 (−1.6/+0.3 %) | 3.520e10 (−6.9/+0.1 %) | **3.09×** |
| b50, 2e9 numbers from the range start | 8.252e9 (−0.6/+0.3 %) | 8.301e9 (−0.8/+0.2 %) | 2.988e10 (−1.5/+5.1 %) | **3.60×** |

These windows take about 60 ms on the new kernel, so its spreads include the boost clock settling (the low b40 round's first three windows ran at 3.2e10, the last two at 3.5e10).

**What a production field costs.** One field of 1e10 numbers, the server's detailed cap, from the start of the range, interleaved, three rounds of two fields per tree, seconds per field:

| base | A median (range) | B median (range) | C median (range) | C / A |
|---|---|---|---|---|
| 50 | 1.218 s (1.213–1.224) | 1.214 s (1.206–1.224) | **0.325 s** (0.317–0.335) | **3.75×** |
| 52 | 1.288 s (1.282–1.296) | 1.287 s (1.270–1.296) | **0.333 s** (0.323–0.346) | **3.86×** |

Base 52 costs this kernel 2.5 % more per number than base 50 (two more digits to mask and add) and the per-number kernel 5.7 % more. This PR does not change the claim and submit round trips around each field, which are now a larger share of a field's wall time.

On every window above, all three trees returned identical results (the same hash of the distribution and near-miss list; one near-miss in the b40 2e9 window, none in the others). That includes base 52, which no test covers. No scenario regresses.

**A second card.** RTX 4090 (24 GB board), driver 580.126.18, CUDA 12.8, same three trees interleaved A B C over six rounds for the benchmark and three for the windows. This card is not power-limited (limit 480 W, default 450 W, never reached) but runs into its thermal target: 85–90 °C against 83 °C, fan at 100 %, thermal slowdown active in every snapshot, SM clock about 2.5–2.6 GHz on main and the readback branch and about 2.63 GHz on this branch (max 3.1 GHz). `auto` picked `CubeCL` CUDA every time. NiceMark detailed GPU: b40 3.459×, b50 3.922× over main (3.04× and 3.59× over the readback branch), score 11,493 → 42,296 (3.68×). 2e9-number windows through the per-field function: 3.02× and 3.63× over main. Production-size 1e10 fields through `nice_client --repeat` against a local mock API, three rounds of eight fields: 3.06× (b50) and 3.77× (b52) over main, about 0.11–0.12 s per field. Per clock this kernel is 2.87× (b40) and 3.31× (b50) the division kernel here, against 2.78× and 3.42× on the 3080 above, so the gain carries over between the cards; the clock bonus is only 1.03–1.09× on the thermally limited card against 1.07× under the 3080's power limit. Results were identical across all three trees on every window and on all 147 production-size fields (distributions and near-miss lists).

## Exactness

All on the RTX 3080 above unless noted.

- `cubecl_cuda_fd_matches_cpu_detailed` (CUDA runtime): whole `FieldResults` (distribution and near-miss list) against `process_range_detailed` at bases 40 and 50, on 1e6-number windows (2e6 at the range ends and across the range start):
  - the range start and the range end;
  - a window straddling the range start, where n³ gains a digit, so every batch splits between the two kernels;
  - eight seeded random windows;
  - a window centred on every point inside the range where an addend gains a digit: dS at 3,276,800,000,000 (b40) and 48,828,125,000,000,000 (b50), dC at 3,783,722,724,161 and 56,381,862,225,549,391 (ddC gains none inside either range).

  Each window runs at four run shapes: the default (128 per thread, 5e7 per dispatch); 61 per thread, leaving a partial run; 1 per thread, so every number is seeded by division; and 1000 per thread with 333,333 per dispatch, so every batch ends in a partial run. Then the `b40_detailed` and `b50_detailed` windows (2e8 numbers each) whole: new kernel = per-number kernel = CPU. Then the whole range of every base from 10 to 28 that has one (15 bases, 76 million numbers, 73 near-misses), all four shapes. Identical everywhere.
- `cubecl_fd_matches_cpu_detailed` (wgpu): the same windows at 1e5 numbers and bases 10 to 24 in full (27 near-misses), all four shapes; sized for software rasterizers.
- Against `main` (the per-number kernel) through `process_range_detailed_cubecl` on the CUDA runtime: the start, middle and end of the range of every base from 10 to 64 that has one, 1e8 numbers each or the whole range where it is smaller (100 distinct windows, 8.6e9 numbers, 261 near-misses at bases 10-35): the same hash of distribution and near-miss list from both trees on every window. This covers every base the new kernel serves, including the bases from 57 up, where n takes three u32 limbs.
- `plan_covers_exactly_the_legal_range` (normal suite, no GPU): the plan's interval equals the legal range at all 44 bases from 10 to 64 that have one, and there is no plan above 64.
- The existing parity tests pass through the new default: `cubecl_cuda_matches_cpu_detailed` (base 10 1e6 from the range start, which runs 53 numbers on the new kernel and the rest, past the range end, on the per-number kernel, with 556,846 near-misses; b40 2e6; b62 2e5 with a three-limb n; b80 on the per-number kernel), `cubecl_cuda_reads_back_every_near_miss`, and the whole `nice_common` lib suite (209 passed).
- On lavapipe (llvmpipe, LLVM 20.1.2): `cubecl_fd_matches_cpu_detailed`, `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed`, `cubecl_finds_69_in_base_10` and `web_kernel_near_miss_matches_cpu_at_base_49` (which compares the browser kernel with the native path, now this kernel, at base 49) pass through naga's WGSL path (wgpu's default compiler, as in a `--features cubecl` build; 15 s) and through `CubeCL`'s SPIR-V compiler (`--features cubecl-spirv`, 20 s; the device reports `wgpu<spirv>`). The first two pass again under SPIR-V with `NICE_CUBECL_WIDE=1`, which makes the seed divide in u64 (`wide_chunk: true` in the compile log). Every ignored test the lavapipe CI job runs (19, from the `--features gpu` test binary minus the CUDA, hand-CUDA and timing ones; the nice-only and join tests included) passes on this branch. Pinned to 4 cores (`taskset`, `LP_NUM_THREADS=4`, like a hosted runner) `cubecl_fd_matches_cpu_detailed` takes 7.4 s and `cubecl_reads_back_every_near_miss` 3.2 s.
- **With the Metal gate (the second commit).**
  - **CUDA** (RTX 3080, driver 595.91.07): `cubecl_cuda_fd_matches_cpu_detailed`, `cubecl_cuda_matches_cpu_detailed` and `cubecl_cuda_reads_back_every_near_miss` pass, and the client's debug log shows the new kernel serving every benchmark window.
  - **lavapipe:** `cubecl_fd_matches_cpu_detailed`, `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed`, `cubecl_finds_69_in_base_10` and `web_kernel_near_miss_matches_cpu_at_base_49` pass, and the client's production path still takes the new kernel.
  - **Lib suite:** 210 passed, including the new `detailed_kernel_by_device`.
  - **Speed is unchanged.** 60 s benchmarks, interleaved without the gate and with it:

    | | without the gate | with the gate |
    |---|---|---|
    | b40 | 3.331e10 to 3.467e10 | 3.339e10 |
    | b50 | 2.968e10 to 3.044e10 | 2.968e10 to 2.976e10 |
    | score | 16,571 to 17,121 | 16,591 to 16,614 |

    The highest run without the gate was the first, on a cold card.

## Portability

The kernel needs nothing the per-number kernel does not already need on every backend: u32 arithmetic in the hot loop; u64 add, multiply and shift for the start, the seed's limb products and the digit mask (`shader-int64` on wgpu, which the native per-number kernel already requires; the browser keeps its u32-only kernel); and a u64 division only in the seed, only on CUDA and HIP. On wgpu the seed uses the split16 division, so no u64 division reaches WGSL, SPIR-V or MSL unless `NICE_CUBECL_WIDE=1` asks for it, exactly as with the per-number kernel. In the WGSL `CubeCL` generates for it (dumped on lavapipe at bases 10, 40 and 62), every division is by a u32 constant; naga 29.0.4, the version wgpu uses here, validates that WGSL and translates it to MSL (default and `--metal-version 2.4`) and to SPIR-V, as it does the per-number kernel's.

- CUDA: run on the RTX 3080 (NVRTC 12.8).
- Vulkan: run on lavapipe through both compilers, as above.
- **Metal: off.** The new kernel gives wrong results on an Apple M4, so detailed fields on any Metal adapter keep the per-number kernel, exactly as on `main`.
  - **Device.** Apple M4, macOS 26.3, through wgpu with naga's MSL.
  - **Failures.** `cubecl_fd_matches_cpu_detailed` fails at the base 50 range start, and `cubecl_reads_back_every_near_miss` fails at base 23.
  - **Sweep.** 1e5 numbers at the start and middle of every base from 10 to 64. The new kernel is wrong at bases 23, 27–30, 49 (mid-range), 50, 52 (mid-range) and 53–55, with most unique counts off by 1 to 4; the per-number kernel is exact in every window.
  - **The fault is in the seed or the mask build.** The kernel fails even at one number per run, so the stepping is not to blame.
  - **Elsewhere it is exact.** The same code passes on CUDA, on lavapipe, and on the macOS CI runner's paravirtual Metal device (macOS 26.6.2), through naga's MSL and through `CubeCL`'s own MSL compiler.
  - **Suspected cause (not yet shown on the device).** In the seed's digit conversion, the division `(x >> 16) / K` of the top word x of n² and n³ is computed from the low 16 bits of x. Modelling that reproduces the M4's histograms exactly in every window except base 23's. It is the 16-bit form of a Metal miscompilation seen before on the same machine, where `hi(a·b) / K` divides the low word.
  - **The gate.** `DetailedKernel::for_device` checks the adapter's wgpu backend. CUDA, HIP and the other wgpu backends keep the new kernel.
  - **Before lifting it,** `cubecl_fd_matches_cpu_detailed` (which runs the new kernel on any wgpu device) has to pass on Apple hardware.
- HIP: the same code path as CUDA (`wide_chunk_for` picks the u64 seed there); not built or run (no ROCm here).
- Speed is not measured on AMD GPUs. Through wgpu they take the split16 seed: by count about 530 u32 divisions per run at base 50, about 4 per number at 128 per run, against about 200 per number in the per-number kernel's split16 scan. On the M4, before the gate, the new kernel ran 3.0× (base 40) and 4.5× (base 50) faster than `main` on the benchmark windows. That is the speed a fix would recover; the base 50 figure came from wrong results.

## Not in this PR

- The hand-CUDA backend (`--gpu-backend cuda`) and the browser kernel (`cubecl_web.rs`, u32 only): both still divide per number.
- Bases above 64: the per-number kernel, as before.
- **Apple GPUs.** The new kernel stays off on Metal until the miscompilation is understood and worked around.
  - The likely fix is to convert the seed to digits the way the per-number kernel does: through shared memory, in a runtime loop. That code is exact on the M4 in every window.
  - The seed is about 5 % of a run, so a slower conversion costs little.
- Measurements on AMD GPUs.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
