## What

In the join kernel's fixed-point middle-digit prefilter (`walk_pf_lean`), the two leading base-b digits of each pair's
32-bit fraction F (one fraction for the square's digits, one for the cube's) are taken as

```
h = mul_hi(F, b)          g = mul_hi(F * b, b)
```

At a power-of-two base b = 2^s these are bit fields of F:

```
h = F >> (32 - s)         g = (F << s) >> (32 - s)
```

The kernel now uses the shift form when its comptime base is a power of two and the multiply form otherwise. Base 64
is the only power-of-two base the join takes, so this changes the join kernel at b64 and nowhere else.

- `walk_pf_lean`: the four digits chosen at comptime (`base.is_power_of_two()`); its doc says so.
- A new host test, `fx_digits_are_bit_fields_at_powers_of_two`, checks the identity against the multiply form at
  b = 2, 4, …, 256: on 0, 1, 2, the extremes, the first 4,096 multiples of 2^(32 − s) and of 2^(32 − 2s) (where the
  two digits change) each ±1, and 10^6 random fractions.
- CHANGELOG line.

## Why

The prefilter runs on every pair that passes the AND, and at b64 it is the largest single part of a field. Measured
by executing it twice at full load: 30 % of a b64 1e17 field on an RX 9070 XT, 21 % on an RTX 3080. Each of the four
digits costs a 32-bit multiply-high, and the second digit of each fraction a low multiply before it; in the shift form
the first digit is one shift and the second two.

## Soundness

For 0 ≤ F < 2^32 and b = 2^s: F·b = F·2^s, so ⌊F·b / 2^32⌋ = ⌊F / 2^(32 − s)⌋ = F >> (32 − s). And F·b mod 2^32 is
what a 32-bit `F << s` gives, so the second digit, ⌊(F·b mod 2^32)·b / 2^32⌋, is the same step applied to `F << s`:
`(F << s) >> (32 − s)`. So the two forms give the same words for every F, not only for the fractions the join forms. Nothing else in the
prefilter changes: the fraction, the bit-reversed membership test and the six distinctness compares are the same.

The new host test checks the identity on the values above. On the device it is checked by the join tests below, all
of which compare against the CPU join or the CPU reference.

**Every other base compiles exactly the code it did before.** The choice is made at comptime, so at a base that is
not a power of two the kernel's source is main's. Checked on the CUDA source CubeCL generates (`CUBECL_DEBUG_LOG`, one
1e14 field each at b58, b60, b62 and b64, main against this branch): all 15 kernels at b58, b60 and b62 (five per
base) and the other four at b64 are identical. CubeCL emits the mutable locals' declarations and the shared arrays'
offsets in an order that changes from process to process; with those two put in a fixed order before comparing,
nothing else differs. At b64 the join kernel differs in exactly 12 lines (12 removed, 12 added): the six lines that
form the four digits, in each of the two copies the kernel unrolls (two entries per thread), `__umulhi(f, 64)` and
`f * 64` replaced by `f >> 26` and `f << 6`.

**The CPU join** (`cpu_join::Fx::digits`) holds the base as a runtime value, so the compiler cannot fold its multiplies
by 64. A throwaway build that takes the shift form there (behind a runtime flag) was **3.5 % slower** on a b64 1e16 field
(every 256th partition, one thread, 3 alternating rounds: 2.61–2.62 s against 2.70–2.72 s per partition; same counts):
presumably the branch on the base and the variable shifts cost more than the multiplies they replace, which are cheap
on x86. So the CPU join is not changed.

## Measurements

**RTX 3080 (CUDA)**: an RTX 3080 10 GB (driver 595.91, 320 W cap). Main (`a7a59c1`) and this PR, same box, the
throughput harness on production-shaped fields after one untimed warm-up field per process, four rounds with the
order rotated, nothing else on the box. Every run started with the card at or below 60 °C (run back to
back it throttles on temperature). Seconds are the timed fields' wall time. Each process's `join_kernel` was replayed
through the driver's JIT: 46–48 registers and no spill, except where marked (*), the known 40-register variant with
24 B of spills. A median of four rounds is the mean of the middle two.

| field | main (s) | this PR (s) | per round (main ÷ PR) | median |
|---|---|---|---|---|
| **b64 1e17** | 144.95, 145.43, 146.15, 146.41 | 143.23, 143.57, 142.67, 141.34 | ×1.012, ×1.013, ×1.024, ×1.036 | **×1.019** |
| **b64 1e16 × 2** | 30.08, 30.00, 30.06, 30.22 | 29.60, 29.67, 29.57, 29.64 | ×1.016, ×1.011, ×1.017, ×1.020 | **×1.016** |
| b62 1e17 (same code) | 66.43, 66.75, 66.77, 66.72 | 66.88, 67.40*, 66.67, 66.65 | ×0.993, ×0.990*, ×1.001, ×1.001 | ×0.997 |
| b60 1e16 (same code) | 12.17, 12.11, 12.13, 12.16 | 12.13, 12.13, 12.12, 12.26 | ×1.003, ×0.998, ×1.001, ×0.992 | ×1.000 |

At b62 and b60 this PR compiles main's kernels (above), so those rows are an A/A test of the method: single rounds
within ±1 %. On NVIDIA the gain is small, about what the generated machine code suggested (×1.01–1.02): the prefilter
is a smaller share of the field there than on the RX 9070 XT. The b64 1e17 runs (145 s) heat the card into thermal slowdown and settle at
1,560–1,630 MHz and 245–256 W on both sides; the others run at 1,725–1,830 MHz and 288–319 W. Fields: b64 1e17 at
58557331862957161709568, b64 1e16 at the same start (two consecutive fields), b62 1e17 at 7520566762397899821056, b60
1e16 at 1447429612114824200908. Every run of a field gave the same counts on both sides.

**NiceMark** (nice-only, `--gpu --benchmark --benchmark-secs 150`; four rounds, order rotated, each run started at
≤ 60 °C; 1,785–1,800 MHz, 318–319 W): its nice-only scenarios are b58, b60 and b62, where this PR compiles main's code,
so this is an A/A check: score ×1.002 (per round ×0.993, ×1.003, ×1.002, ×1.002); per scenario, median (lowest round):
b58 MSD-weak ×1.003 (0.997), b58 MSD-strong ×1.005 (0.989), b60 MSD-weak ×0.999 (0.990), b62 MSD-weak ×0.998 (0.995).
NiceMark has no b64 scenario, so it cannot show this change.

**RX 9070 XT (RADV, Vulkan, CubeCL's SPIR-V compiler, 304 W cap)**, measured earlier on an experiment build with the
same change behind an environment variable (the switch picks the form at comptime, so the shift form compiles to the
kernel this PR compiles at b64): b64 1e17, **150.16 → 142.90 s, ×1.051**, counts identical, at the card's operating
point. **One round only**; base runs of the same field spread 0.0–0.8 % in that hour. That build did not include #254,
so its b64 field took 150 s where today's main takes about 135 s on that card; if the 7.3 s saving carries over, that
is about ×1.05–1.06 on today's main (an estimate, not measured).

No Apple GPU was measured (on Metal the kernel's code at b64 changes the same way).

## Exactness

- **CUDA (RTX 3080):** all pass.
  - Every CUDA device test of `cubecl_join` (7): CPU-reference parity over all windows (b20–b64, the b57 frontier
    field, tight layouts, slices, refused layouts, the production shape's re-runs), FD against the top kernel (26
    fields, 279 batches), top certificates against the lockstep scan and the CPU.
  - The dense compare against the CPU join (`cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`: hits and both
    survivor counts) on b64 production shapes: 48 partitions of a b64 1e16 field at 39667831862957161709568
    (2,836,249,711 / 172,308,464) and 32 partitions of slice 0 of the b64 1e17 field at 58557331862957161709568
    (2,803,067,823 / 173,796,394), the counts these fields gave in earlier runs of main.
  - Every timed run gave the same counts on both sides (b64 1e17 3,092,989,872,066 / 191,683,594,021; b64 1e16 × 2
    674,468,878,644 / 41,802,516,096; b62 and b60 likewise).
- **lavapipe (Mesa, llvmpipe):** every wgpu test of `cubecl_join` passes with naga and with CubeCL's SPIR-V compiler
  (8 each).
- **What covers the b64 prefilter on the device:** the parity test's b64 window ([52125117810081128433988, +300,000),
  t = 11, k = 4, p = 2) has a prefilter depth of 2, so it runs `walk_pf_lean` and with this PR its shift form, on
  CUDA and on both lavapipe compilers. Batch by batch it asserts that the join-survivor count equals the CPU
  reference's, that the prefilter's survivors (as numbers, sorted) equal the CPU reference's pairs filtered by the
  prefilter's definition (`mid_mirror`, digits of n² and n³ computed directly), and at the end that the hits agree.
  The dense compares above run the production shape (k = 6) through the same kernel.
- **Host:** every `nice_common` unit test, the new one included (248). `cargo fmt --all --check` and `cargo clippy -p
  nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings` with the pinned toolchain: clean.

## Not in this PR

- The CPU join's prefilter (above: the shift form measured slower there).
- A second round on the RX 9070 XT.
- Any other base: the identity needs b = 2^s.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
