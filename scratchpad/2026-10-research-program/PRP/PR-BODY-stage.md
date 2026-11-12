## What

The join kernel stages the pairs that pass its prefilter in shared memory, two arrays of `SURV_SH_CAP` words per work
group, and writes the stage to the survivor list once it holds `SURV_FLUSH` entries. This PR halves both:
`SURV_SH_CAP` 1024 → 512 and `SURV_FLUSH` 512 → 256 (still half the stage). The constants' docs now say what the size
trades and why it is 512. No other code changes.

## Why

The stage is 8 KiB of the work group's shared memory with 1,024 entries, 4 KiB with 512. On AMD's RDNA4 the work
group's shared memory is what limits how many of them run at once: the join kernel uses 18.9 KiB per work group with
the 1,024-entry stage, which the compiler (Mesa's ACO, for the RX 9070 XT) puts at 12 waves per SIMD; with 512 entries
it is 14.8 KiB and 16 waves, a third more. The AND waits on several shared-memory loads per digit, and more waves in
flight hide more of that latency (that is the reading of the compiler's output; the card was not profiled at that
level).

On NVIDIA the kernel is bound by its registers, not its shared memory: at 46–48 registers a 256-thread block fits 5
times per SM on an RTX 3080 (sm_86), and the shared memory (18.1 KiB per block on CUDA, 14.1 KiB with this PR, plus 1 KiB
reserved per block, against 100 KiB per SM) allowed 5 before and allows 6 now. So NVIDIA should not move, and does
not (below).

## Soundness

The stage's size does not change which pairs reach the list, only how they get there:

- In the walk, a pair that passes the prefilter takes a slot with `at = s_cnt.fetch_add(1)`. If `at < SURV_SH_CAP` it
  is staged; otherwise it goes to the survivor list directly (its own `surv_count` reservation), as before. A pair
  that finds the stage full is never dropped.
- The flush, checked once per batch of tops after a barrier, writes `min(count, SURV_SH_CAP)` staged pairs (the rest
  went directly) and resets the count; the kernel flushes what is left at its end.
- Nothing else reads either constant: the shared arrays are sized by `SURV_SH_CAP`, and `flush_survivors` and the
  walk's test use it. The survivor list and its overflow re-runs (`run_field`) are sized and checked on the host
  independently of the stage.

A batch of up to 256 tops can add more pairs than the half stage left free, so with a smaller stage more pairs take
the direct path. To see that path carry real load, a throwaway build (not in this PR) counted the pairs written past a
full stage in the dense compare against the CPU join (`cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`, RTX
3080):

| stage / flush | b60 1e16, 48 partitions | b62 1e17, 32 partitions | b64 1e17, 32 partitions | counts |
|---|---|---|---|---|
| 16 / 8 (forced overflow) | 123,932,078 of 134,795,310 checked pairs | 37,554,910 of 41,427,678 | | equal to the CPU join's |
| **512 / 256 (this PR)** | 93,908 (0.07 %) | 0 | 79 | equal to the CPU join's |

With 1,024 / 512 the same count, taken on an earlier version of the kernel, was 0 at b60 1e16 and b62 1e17 (whole
fields). With a 16-entry stage over 90 % of the survivors went the direct path and the hits and both survivor counts
still matched the CPU join's exactly. How many pairs go direct depends on how the device schedules the work groups;
the RX 9070 XT's runs below had identical counts in every round.

## Measurements

**RX 9070 XT (RADV, Vulkan, CubeCL's SPIR-V compiler, 304 W cap)**, measured earlier on an experiment build: main's
join kernel with the two sizes switched by an environment variable (the switch compiles the same kernel this constant
change does), in a tree whose other stages are not exactly today's main. Three rotated rounds, each ratio against the
same round's run with the 1,024-entry stage, counts identical in every run, every run at the card's operating point
(3.03–3.19 GHz, 303–304 W):

| field | per round | median |
|---|---|---|
| b62 1e17 | ×1.055, ×1.056, ×1.060 | **×1.056** |
| b60 1e16 | ×1.057, ×1.056, ×1.056 | **×1.056** |

One round each, not repeated: b64 1e17 with a 256-entry stage ×1.062 (512 was not run alone at b64); a screen at b60
gave stages of 512 / 256 / 128 entries ×1.063 / ×1.048 / ×1.054.

**RTX 3080 (CUDA)**: an RTX 3080 10 GB (driver 595.91, 320 W cap). Main (`a7a59c1`) and this PR, same box, the
throughput harness on production-shaped fields after one untimed warm-up field per process, four rounds with the
order rotated, nothing else on the box. Every run started with the card at or below 60 °C: run back to back
it throttles on temperature, and the second run of a pair pays for the first's heat. Seconds are the timed fields' wall
time. Each process's `join_kernel` was replayed through the driver's JIT: 46–48 registers and no spill, except where
marked (*), which got the known 40-register variant with 24 B of spills. A median of four rounds is the mean of the
middle two.

| field | main (s) | this PR (s) | per round (main ÷ PR) | median |
|---|---|---|---|---|
| b62 1e17 | 66.43, 66.75, 66.77, 66.72 | 66.38*, 66.51, 66.86, 66.86 | ×1.001*, ×1.004, ×0.999, ×0.998 | **×1.000** |
| b60 1e16 | 12.17, 12.11, 12.13, 12.16 | 12.31, 12.18, 12.11, 12.07* | ×0.989, ×0.994, ×1.002, ×1.007* | **×0.998** |
| b64 1e17 | 144.95, 145.43, 146.15, 146.41 | 145.98, 141.28, 146.54, 146.87 | ×0.993, ×1.029, ×0.997, ×0.997 | **×0.997** |
| b64 1e16 × 2 | 30.08, 30.00, 30.06, 30.22 | 30.07, 30.20, 29.53, 30.20 | ×1.000, ×0.993, ×1.018, ×1.001 | **×1.000** |

Neutral, as the occupancy arithmetic above says; the lowest single round is ×0.989. Clocks and power per run: b62
1,725–1,785 MHz at 288–307 W, b60 1,800–1,830 MHz at 317–319 W, b64 1e16 1,785–1,808 MHz at 318–319 W; the b64 1e17
runs (145 s) heat the card into thermal slowdown and settle at 1,560–1,630 MHz and 245–256 W on both sides. Fields:
b62 1e17 at 7520566762397899821056, b60 1e16 at 1447429612114824200908, b64 1e17 at 58557331862957161709568, b64 1e16
at the same start (two consecutive fields). Every run of a field gave the same counts on both sides.

**NiceMark** (nice-only, `--gpu --benchmark --benchmark-secs 150`; client binaries of main and this PR, four rounds,
order rotated, each run started at ≤ 60 °C; 1,785–1,800 MHz, 318–319 W): score **×0.999** (per round ×0.994, ×0.998,
×1.001, ×1.000; medians 9,948 and 9,916). Per scenario, median (lowest round): b58 MSD-weak ×0.999 (0.994), b58
MSD-strong ×1.001 (0.987), b60 MSD-weak ×1.000 (0.991), b62 MSD-weak ×0.997 (0.996). Neutral; no scenario's median
below ×0.997, no single round below ×0.987.

No Apple GPU was measured.

## Exactness

- **CUDA (RTX 3080):** all pass.
  - Every CUDA device test of `cubecl_join` (7): CPU-reference parity over all windows (b20–b64, the b57 frontier
    field, tight layouts, slices, refused layouts, the production shape's re-runs), FD against the top kernel,
    top certificates against the lockstep scan and the CPU.
  - The dense compare against the CPU join (`cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`: hits and both
    survivor counts) on 48 partitions of the b60 1e16 field at 1447429612114824200908 (2,011,244,757 / 134,795,310)
    and 32 partitions of slice 0 of the b62 1e17 field at 7520566762397899821056 (679,431,359 / 41,427,678).
  - The same compare with the stage forced to overflow (the 16-entry build above): the same counts, with over 90 % of
    the survivors taking the direct path.
  - Every timed run gave the same counts on both sides (b62 1e17 1,097,114,812,011 / 66,862,268,894; b60 1e16
    190,770,281,868 / 12,786,993,080; b64 1e17 3,092,989,872,066 / 191,683,594,021; b64 1e16 × 2 674,468,878,644 /
    41,802,516,096).
- **lavapipe (Mesa, llvmpipe):** every wgpu test of `cubecl_join` passes with naga and with CubeCL's SPIR-V compiler
  (8 each), the 17 parity windows included.
- **Host:** every `nice_common` unit test (247). `cargo fmt --all --check` and `cargo clippy -p nice_common
  --all-targets --features gpu,cubecl-spirv -- -D warnings` with the pinned toolchain: clean.

## Not in this PR

- A smaller `TOP_CAP` (128 tops per pass): on the RX 9070 XT it adds ×1.01–1.03 on top of this stage, but costs 3–4 %
  on NVIDIA, so it would need a per-device value.
- A 256-entry stage: measured only in one-round screens (×1.048 at b60, ×1.062 at b64 1e17).
- Any change to how often the stage is checked.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
