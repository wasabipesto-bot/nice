## What

The join kernel's fixed-point prefilter (`walk_pf_lean`) passes a pair when its four middle digits (g2, h2 of the
square, g3, h3 of the cube) are distinct and none is in `seen`, the pair's digit mask (held bit-reversed in this
kernel: digit d at bit 63 − d). Today that is four 64-bit shifts with a sign test and six compares. This PR asks the
same question as one population count,

```
A = (2^63 >> g2) | (2^63 >> g3) | (2^63 >> h2) | (2^63 >> h3)
pass  <=>  popcount(A & !seen) == 4        (one 32-bit count per word, summed)
```

on every runtime except CUDA. The choice is a new comptime argument of `join_kernel`, `pf_count`, which `JoinDevice`
sets to `!R::name(client).contains("cuda")`; on CUDA the comptime branch expands to today's code.

Also a host model of the count form in the two existing lean prefilter tests, and a CHANGELOG line.

## Why

On AMD's RDNA (wave64) each compare and the sign test is a vector compare into a 64-bit lane mask plus a scalar OR.
For the count, Mesa's compiler (ACO) emits 8 fewer ALU instructions per walk round (below); the RX 9070 XT
does most of the project's nice-only work.

## Soundness

Let D = {g2, g3, h2, h3} as a set. Every digit is below b ≤ 64 (`mul_hi(F, b) ≤ ⌊(2^32 − 1)·b / 2^32⌋ < b`), so
`2^63 >> d` is one bit, at 63 − d, where the bit-reversed masks hold digit d. So A has one bit per element of D,
`A & !seen` one bit per element of D \ seen, and

popcount(A & !seen) = |D \ seen| ≤ |D| ≤ 4,

with equality iff |D| = 4 (the digits are distinct) and D ∩ seen = ∅ (none is seen): exactly today's six inequalities
and four non-memberships, for any four values below 64 and any `seen`. Per 32-bit word: A's low word against
`mlo | tlo` (digits 32–63), its high word against `mhi | thi` (digits 0–31), the words today's code joins into `seen`.

## Measurements

**RX 9070 XT (RADV, Vulkan, CubeCL's SPIR-V compiler, 304 W cap)**, on an experiment build of main with #255 and #256
applied and this change behind an environment variable. Throughput harness, one untimed warm-up field per process,
order rotated per round, every run at the power cap (302–305 W; median clocks 3.09–3.13 GHz at b62 on both sides,
3.04 GHz base and 3.01 GHz count at b64), counts identical in every run of a field.

| field | base (s) | count (s) | base ÷ count |
|---|---|---|---|
| b62 1e17, 3 rounds | 68.34, 68.58, 68.71 | 65.69, 66.31, 66.23 | ×1.040, ×1.034, ×1.037 → **×1.037** |
| b64 1e17, **one round** | 117.80 (a later base run: 117.66) | 109.08 | **×1.080** |

b60 was not timed, and nothing was timed on main without #255 (which changes b64's digits) and #256.

**RTX 3080 (CUDA, 180 W cap)**: the count form was 1–2 % slower, timed together with a change to the walk's bit pop
whose NVIDIA machine code has today's instruction mix: ×0.989 at b62 1e17 (4 rounds), ×0.981 at b64 1e17 and ×0.987
at b60 1e16 (3 rounds each), counts identical. In the driver's SASS the walk loop grows from 78 to 82 instructions (each
64-bit one-hot is two funnel shifts; each compare removed was one `ISETP`). So CUDA keeps the compares.

**What ACO emits** (Mesa 25.2.7, GFX1201, wave64; the experiment build's SPIR-V at production field shapes; a walk round
in which no lane passes). Instruction counts, not timings:

| | b62 base | b62 count | b64 base | b64 count |
|---|---|---|---|---|
| VALU / SALU / LDS | 35 / 14 / 3 | 32 / 9 / 3 | 35 / 14 / 3 | 32 / 9 / 3 |
| **ALU total** | **52** | **44** | **52** | **44** |
| waits (`s_delay_alu`, `s_wait_*`) | 7 | 11 | 7 | 12 |

The pass path (16 ALU), 96 VGPRs, 14,848 B of shared memory and 16 waves per SIMD are unchanged.

## Exactness

- **Host:** the count form is asserted in `lean_membership_matches_the_masks` (every digit 4-tuple at every base 10–64
  against random seen sets, plus 10^7 random tuples) and `lean_prefilter_matches_the_division_form` (10^6 random
  entries and tops per base 10–64 against the division form). All non-ignored `nice_common` tests, `cargo fmt` and
  `cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings` (1.99.1) pass.
- **lavapipe (llvmpipe), which runs the count form:** every wgpu test of `cubecl_join` passes with CubeCL's SPIR-V
  compiler and with naga (8 each; three are opt-in and return early). The parity test's b64 window runs
  `walk_pf_lean` and compares its survivors batch by batch with the CPU reference.
- **CUDA (RTX 3080), count form forced on in experiment builds:** the dense compare against the CPU join
  (`cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`: hits and both survivor counts) is equal on b60 1e16, b62
  1e17 and b64 1e17, and a build with the count form on every runtime passes the 7 CUDA device tests of `cubecl_join`.
- **RX 9070 XT:** every timed run above gave the base's counts.

This branch's own CUDA kernel was not run on a device.

## Not in this PR

- A cheaper pop in the walk (`find_first_set − 1` instead of `trailing_zeros`): about ×1.01–1.02 more on the RX
  9070 XT on top of this; a ready follow-up.
- Apple GPUs, HIP and DX12 get the count form; none was measured.
- A second b64 round on the RX 9070 XT.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
