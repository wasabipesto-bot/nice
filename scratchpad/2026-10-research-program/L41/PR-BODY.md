Stacked on #241: its commit is the base of this branch; the new work is the last commit.

## What

The join kernel runs the middle-digit prefilter on every pair that passes the AND and is in the top's residue range, as the walk over the pass bits reaches it. At mid = 2 (every production shape) it tests the two base-b digits of x2 = (A2 + P2·D) mod b² and x3 = (A3 + P3·D) mod b², where A and P (< b²) are the entry's carry and coefficient (2R, 3R²) and D (< b²) the top's next two digits: the four digits must be distinct and none of them in the entry's digits or, when the top's seed flag is set, its certificate.

This PR computes the same predicate with fewer instructions:

- **Digits by fixed point instead of division.** The entry keeps `A·C` and `P` for each power, with `C = ceil(2^32/b²)`, and the batch load writes `dh = ceil(D·2^32/b²)` for the top (as `D·Q + ceil(D·R/b²)`, `2^32 = Q·b² + R`). Per pair, `F = A·C + P·dh mod 2^32`; the digits are `h = hi32(F·b)` and `g = hi32((F·b mod 2^32)·b)`: three multiplies per power (`IMAD`, `IMAD.WIDE.U32`, `IMAD.HI.U32`), no reduction mod b² and no division.
- **Membership by shifts.** With the digit masks held bit-reversed (below), digit g is in `seen` iff bit 63 of `seen << g` is set: `hi32(seen << g)` is one funnel shift, the four OR into one sign test, and six compares check that the four digits are distinct. Before, the kernel built four 64-bit one-hot masks (two shifts each) and tested them.
- **Seed-gated top masks.** The batch load writes each top's certificate gated by its seed flag (`t_glo`, `t_ghi`: the mask, or 0), so a pair ORs it in without a select.
- **The residue range test per chunk, not per pair.** Only a clipped top (a block at the field's ends, whose range is not the whole `[0, w)`) can reject a residue. The batch load marks the clipped tops in one word per chunk of 32 (`s_cw`, `fetch_or` from the rare clipped tops), and a chunk with any clears their out-of-range pass bits before the walk. Every bit walked is then a join survivor, and they are counted by popcount per chunk.

Shapes with mid ≠ 2 or k < mid (small test windows, e.g. b10's k = 1) keep `walk_pf` and its packed words; the range test is per chunk for every shape.

**A representation change inside `join_kernel`.** Behind a comptime flag, `lean` (mid = 2, k ≥ 2: every production shape; the condition for the fixed-point digits, the shift membership and the gated masks), `join_kernel` holds every digit mask bit-reversed, digit d at bit 63 − d: the entries' `mlo`/`mhi` (reversed in the wave load), the tops' `t_lo`/`t_hi` and the gated `t_glo`/`t_ghi` (in the batch load), and so the digit-major `t_tr` built from them. The AND only tests disjointness, which does not depend on how the bits are labelled. Nothing outside the kernel reads these masks: the global buffers (`ext_m`, `top_rec`), every other kernel and the CPU join keep digit d at bit d. Shapes without `lean` (b10's k = 1) keep the natural order inside the kernel too.

## Why

The walk is the bulk of the join: 1.28·10^11 plane-rounds per b62 1e17 field (counted on the device), an estimated 70 % of the join's warp instructions (SASS counts per unit times measured and estimated unit counts). One round issues for the whole warp whatever the number of live lanes, and by that instruction model it is integer-ALU-bound (one warp ALU instruction per 2 cycles per SM sub-partition on sm_86); the measured gain in cycles below agrees. Its prefilter part was 51 SASS instructions, 36 of them on the ALU pipe: unpacking the entry's and top's halves (loop-invariant, redone each round), `x mod b²`, `x / b` and `x % b` by multiply-shift, the four 64-bit one-hot masks and their tests, the seed select. Before it came the range test, two shared loads and a branch on the round's dependency chain in every round, which rejects almost nothing (26 of 4.85·10^9 in-AND pairs on a b57 1e14 field, 5 on a b62 one, none on b60/b64 ones).

The round before the stage, at b62 (SASS of CubeCL's CUDA, ptxas 12.8, sm_86):

| | instructions | of them ALU pipe |
|---|---|---|
| base (#241) | 71 | 45 |
| digits by fixed point | 59 | 35 |
| + membership by shifts | 51 | 28 |
| + gated top masks | 47 | 24 |
| + range test per chunk (this PR) | **41** | **21** |

b60: 69 → 41; b64 (where `% 64` and `/ 64` were already shifts): 64 → 43. The digits now cost 6 instructions on the FMA pipe and none on the ALU pipe.

## Soundness

**The fixed-point digits are exact.** For a base b ≤ 64 and A, P, D < b²:

1. `C·b² = 2^32 + ε1` and `dh·b² = D·2^32 + ε2` with `0 ≤ ε1, ε2 < b²` (both are ceilings).
2. Write `x = A + P·D = q·b² + r` with `r = x mod b²`. Then `(A·C + P·dh)·b² = q·b²·2^32 + r·2^32 + Δ`, with `Δ = A·ε1 + P·ε2`, so `0 ≤ Δ < 2b⁴ ≤ 2^25`.
3. Hence `A·C + P·dh = q·2^32 + F0` with `F0 = (r·2^32 + Δ)/b²`. F0 is an integer (b² divides the left side of step 2 minus `q·b²·2^32`), and it is below 2^32 because `r ≤ b² − 1` and `Δ < 2^32`. So `F = (A·C + P·dh) mod 2^32 = F0`, and `F·b² = r·2^32 + Δ`.
4. The two multiplies split `F·b²` exactly: `F·b = h·2^32 + F′` and `F′·b = g·2^32 + F″` with `g < b`, so `⌊F·b²/2^32⌋ = h·b + g`. Since `Δ < 2^32`, that is r: (h, g) are r's two base-b digits.

`A·C` fits a word (`(b² − 1)·C < 2^32` for b < 256). The batch load forms `dh = D·Q + ceil(D·R/b²)`, which is `ceil(D·2^32/b²) ≤ ceil((b² − 1)·2^32/b²) < 2^32`, with `D·R + b² − 1 < 2^25` inside it. At b64, ε1 = ε2 = 0 and the same code runs. The only condition is Δ < 2^32; Δ < 2b⁴ ≤ 2^25 leaves a factor of 128 to spare (the exact maximum over A, P, D < b² is about 2^24.7, at b62).

The operands are in these ranges in the kernel, not only in the model: A is `(t2 mod b³) / b` at the key level and a digit pair of R² or R³ below b^mid otherwise; P is `2ρ` or `3ρ²` reduced mod b²; D is `⌊(P mod b^(k2 − f0)) / b^(k − f0)⌋ < b^mid`. (Δ stays below 2^32 even for A, P anywhere below 2^16, so the 16-bit packing of the non-key shapes could not break it either.)

**The membership test is the same predicate.** Before: `g2 ≠ g3 ∧ h2 ≠ h3 ∧ (seen ∩ {g2, g3} = ∅) ∧ ((seen ∪ {g2, g3}) ∩ {h2, h3} = ∅)`. Unrolled, that is: the four digits pairwise distinct (six inequalities) and none in `seen`, which is what the new test checks. Reversing the bits of every mask the kernel holds relabels the digits without changing any intersection: the AND, the digit-major copy and the small-batch test compute the same pass bits.

**The gated masks** are `seed ? mask : 0`, written once per top per batch: the same `seen`.

**The range test per chunk** clears exactly the pass bits the per-pair test rejected. A top's range is `[rlo, rhi)` from its record; `top_kernel` writes `[a − pw0, e − pw0 + 1)` for the block clipped to the field and `top_fd_kernel` `[0, w)`, and every bottom residue is below w = b^f0. So a top with `rlo = 0` and `rhi = w` passes every residue, and only the others are marked and tested. The walk sees the same in-range pairs, and the join survivor count is the popcount of the same bits.

**Host tests** (new, in `cubecl_join::tests`; the first, third and fourth run in CI):

- `fx_digits_match_the_division`: at every base 10–64, the constants and `dh` against exact ceilings for every D < b², the error bound, and the digits against `(A + P·D) mod b²` for every (P, D) at the largest A and every (A, D) at the largest P.
- `fx_digits_are_exact_everywhere` (ignored, and opt-in by `NICE_TEST_FX_EXHAUSTIVE=1` since the GPU jobs run every ignored test; 190 s on 9 threads): every triple A, P, D < b² at every base 10–64, 663,187,945,915 in all.
- `lean_membership_matches_the_masks`: the new membership test against the four one-hot masks for every digit 4-tuple at every base 10–64 against a random `seen`, and 10^7 random tuples against sets of every density.
- `lean_prefilter_matches_the_division_form`: the whole lean prefilter against a host model of the division form (the digits of `(A + P·D) mod b²` and the four one-hot masks) on 10^6 random pairs per base 10–64. The device tests below compare the kernel itself with the CPU join.

## Measurements

**Card:** RTX 3080 10 GB (driver 580.159.03) on a rented box whose host caps it at **180 W** (default 340 W). Every timed run sat at the cap (`SW power cap` throttling), at 64–65 °C.

**Method:**
- #241's head (`7832f89`) and this PR, same box, two binaries, rounds interleaved with the order alternating (base, PR; PR, base; base, PR), nothing else running.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, at the starts b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the mean device wall time per field (`device=`; two fields in flight at 1e16). Figures are medians of 3 rounds; spread = (max − min) / median; "per round" is the base's time over the PR's in the same round. MHz is the mean SM clock per side; "cycles" is the ratio of device seconds × clock.

| field | #241 s/field (rounds) | spread | this PR s/field (rounds) | spread | speed-up | per round | MHz #241 / PR | cycles |
|---|---|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | **108.97** (107.74, 109.05, 108.97) | 1.2 % | **100.38** (100.39, 100.38, 100.26) | 0.1 % | **×1.086** | 1.073, 1.086, 1.087 | 1501 / 1472 | ×1.103 |
| b62 1e16, 2 fields | **9.119** (9.10, 9.12, 9.15) | 0.6 % | **8.398** (8.39, 8.44, 8.40) | 0.5 % | **×1.086** | 1.084, 1.081, 1.090 | 1467 / 1482 | ×1.075 |
| **b60 1e16**, 2 fields | **22.039** (22.04, 21.80, 22.09) | 1.3 % | **19.649** (19.64, 19.75, 19.65) | 0.6 % | **×1.122** | 1.122, 1.104, 1.124 | 1480 / 1469 | ×1.126 |
| b64 1e16, 2 fields | **30.270** (30.22, 30.31, 30.27) | 0.3 % | **28.280** (28.29, 28.27, 28.28) | 0.1 % | **×1.070** | 1.068, 1.072, 1.070 | 1520 / 1472 | ×1.104 |
| b57 1e14, 3 fields | 0.658 (0.69, 0.66, 0.66) | 5.9 % | 0.641 (0.64, 0.62, 0.66) | 5.6 % | ×1.027 | 1.084, 1.058, 1.003 | | |
| b60 1e14, 3 fields | 0.599 (0.60, 0.60, 0.59) | 2.2 % | 0.589 (0.61, 0.59, 0.58) | 5.8 % | ×1.017 | 0.980, 1.019, 1.017 | | |
| b62 1e14, 3 fields | 0.513 (0.51, 0.50, 0.52) | 2.5 % | 0.510 (0.52, 0.50, 0.51) | 3.1 % | ×1.006 | 0.988, 1.000, 1.012 | | |
| b64 1e14, 3 fields | 0.721 (0.74, 0.72, 0.70) | 5.3 % | 0.723 (0.73, 0.72, 0.70) | 4.8 % | ×0.997 | 1.010, 0.997, 1.006 | | |

- At b62 1e17 that is **8.6 s saved per field**. An earlier two-round screen on the same box (one binary, the four parts switched on in turn against the base code) gave ×1.075 at b62 1e17 and ×1.111 at b60 1e16 for the whole change, ×1.028 / ×1.037 for the fixed-point digits alone.
- **The power cap takes part of it.** In cycles the gain is ×1.08–1.13. The PR's side ran 29–48 MHz slower at b62 1e17 and b64 under the same cap: the leaner round does the same memory and shared-memory work in fewer cycles, so it draws more power per cycle. On a card that is not power-limited I would expect the gain to be near the cycles column; I could not measure that here (the container can neither lift the cap nor lock clocks).
- The 1e14 fields are neutral, within the spread of their runs (0.5–0.7 s per field).
- Every field ran with the same slots per launch and layout size on both sides.

NiceMark nice-only (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 6 rounds, alternating):

| | #241 | this PR | speed-up |
|---|---|---|---|
| **score** (median of 6) | 6437.3 | 6828.7 | **×1.061** (per round 1.056–1.063) |
| b58 MSD-weak (whole field) | 2.953e14 n/s | 3.161e14 | ×1.070 (rounds 1.064–1.082) |
| b58 MSD-strong (whole field) | 1.340e15 | 1.395e15 | ×1.041 (rounds 1.007–1.049) |
| b60 MSD-weak (sampled) | 6.150e14 | 6.503e14 | ×1.058 (rounds 1.056–1.076) |
| b62 MSD-weak (sampled) | 7.581e14 | 8.099e14 | ×1.068 (rounds 1.061–1.082) |

MSD-strong (the smallest buckets, about 3 tops each) gains least: the change adds a little per batch and per wave (the top's `dh`, the masks' reversal, the gated stores, the clip words) and saves per round. No scenario lost in any round.

## Exactness

All on the RTX 3080 (CUDA) unless marked lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8, 8-lane subgroups). The timed runs used a build that differs from this head by:
- comments: the walk's comment moved below the range test, the `t_tr` comment and the kernel doc on the reversed masks, the wording of one comment in `walk_pf_lean`, and two test docs;
- two rustc warnings fixed: an unneeded `mut` on `s_cw`, and `let mut pass = false; if … { pass = … }` written as `let pass = if … { … }` (this changes CubeCL's CUDA text; the resulting join SASS is the timed build's instruction for instruction);
- the exhaustive test's opt-in, and lint fixes in the new tests (`div_ceil` in the host mirror, two `many_single_char_names` allows, one variable renamed).

The CUDA tests below ran on both the timed build and this head's kernels with the same results.

- `cubecl_cuda_join_matches_the_cpu_reference`: ok. It covers b10's 69 (k = 1: the division form, with the per-chunk range test); windows b20–b64, including b50 and b54 after refused layouts; the b57 frontier partitions 0/1000/3248, tight and refused; tight-layout and sliced windows; and the production shape. Its small windows are where clipped tops matter: a build without the per-chunk range test fails it at `b20 [58945, 160000) JoinParams { t: 2, k: 3, p: 1 }` (join survivors differ).
- `cubecl_cuda_top_fd_matches_the_top_kernel`: ok, 26 fields, 279 batches (23 with a clipped block), 237,907,266 tops.
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept, 203,413 powers above c0, 69,824 with the carry.
- Dense fields, asserted equal to the CPU join:
  - b58 1e15, 32 partitions: 254,938,965 survivors / 14,396,829 checked.
  - b62 1e16, 4 partitions: 120,013,475 / 7,355,827.
- Whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): ok. 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference.
- `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64): join = stride, found 0. Counts identical to #241's: 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759. (Without the range test, b57 would count 26 more join survivors and b62 5 more.)
- Every timed field above has #241's survivors and full checks in every round:
  - b62 1e17: 1,020,844,021,499 / 62,584,252,554.
  - b62 1e16: 163,513,599,082 / 10,027,698,695.
  - b60 1e16: 460,847,952,346 / 30,871,838,404.
  - b64 1e16: 787,584,956,227 / 47,900,853,327.
  - NiceMark's whole-field scenarios: identical (b58 MSD-weak 33,590,315,220 join survivors, MSD-strong 4,027,773,430).
- The walk's rounds are unchanged: 128,346,267,597 plane-rounds at b62 1e17 before, 128,350,614,206 after (+0.003 %, the run-to-run order of the bucket lists, which are filled with shared atomics).
- The host tests above, and the `join_plan` and `cubecl_join` unit tests: ok.
- lavapipe, every wgpu test in `cubecl_join` (join parity incl. b50/b54 and the b57 frontier, the FD-vs-top-kernel test on 21 fields / 142 batches / 1,018,088 tops, the certificate test, the production-field sample, the ticket test): ok with the naga (WGSL) compiler and with CubeCL's direct SPIR-V compiler. These run the digits' `mul_hi` (emulated in WGSL, `OpUMulExtended` in SPIR-V) and the 64-bit funnel shifts on 8-lane planes.
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's 13 `--require`s): 16 shaders, 0 flagged. The join kernel (b57) now has 26 constant divisions, down from 36.
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`, default, with `--features nice_client/gpu` and with `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1): clean.
- Not run on Metal or AMD hardware. CI's macOS job (paravirtual Metal) will be the first Metal run of the new path. It adds no constant division of a shifted or high word (the Apple compiler's known bug class): `mul_hi`'s results are not divided, and the one new constant division divides a sum.

## Registers

From ptxas (`nvcc -cubin -arch=sm_86 -O3 -Xptxas -v`, CUDA 12.8) on CubeCL's CUDA for 1e14 fields at b60, b62 and b64:

| kernel | #241 | this PR |
|---|---|---|
| `join_kernel` b60 / b62 / b64 | 40 / 40 / 47 | 45 / 45 / 45–47 (about half of compiles at b60/b62: 40 + 28–44 B of spills) |
| `top_fd_kernel` b60 / b62 | 108 / 110 | 108 / 110 |
| `top_kernel` b60 / b62 / b64 | 80 / 80 / 95 | 80 / 80 / 95 |
| `check_kernel` b60 / b62 / b64 | 38 / 38 / 34 | 38 / 38 / 34 |

- The join takes 45 registers at b60/b62 where it took 40: the entry keeps four words per slot (A·C and P for each power) instead of two packed ones. That is still ≤ 48, so the occupancy is unchanged: 5 cubes of 256 per SM, set by the shared memory (now ~18 KiB per cube: +2 KiB for the gated masks).
- **Spills, new with this PR.** In about half of the compiles ptxas takes 40 registers with 28–44 B of spills instead of 45: 14 of 26 offline compiles at b60/b62, all of them with the per-chunk range test; none of 18 at the intermediate steps without it (one more at b64).
  - Which variant a process gets depends on CubeCL's per-process order of the shared arrays: two compiles whose CUDA differs only in those offsets land on either side.
  - The likely reason, not tested: the shared memory is one dynamic array, so ptxas does not see the 5-cube limit and aims at 6 cubes (≤ 40 registers). A compile with a static array of the same size would settle it; none was tried.
  - The spilled values are per work item and per batch (the work index, the list base, four values around the digit-major copy), never in the walk; occupancy is 5 cubes per SM either way.
  - Which variant each timed process compiled was not recorded, and the offline `nvcc` pass above is not the runtime's NVRTC compile. The PR's three processes per field agree to 0.1–0.6 %.
  - The base sits at 40 registers without spills. Its codegen also varies by process (1080 or 1088 SASS for the b62 join), but it never spills.
- The other kernels are unchanged.

## Not in this PR

- **The CPU join** keeps its division-based prefilter (`cpu_join`'s `SmallDiv`); the GPU's form needs no change there.
- **ptxas's warp-convergence fallback.** With this change, ptxas no longer proves the walk's warp converged at its vote and plane barrier, and adds three issued instructions per round (a never-taken branch and a mask move at the loop head, and a branch over a dead WARPSYNC call at its tail). The CUDA around the vote is the same as before; dropping the plane barrier brings back a `YIELD` and costs more. Without the fallback the round before the stage would be 39 instead of 41.
- **A plain read of the clip words.** A chunk reads its clip word as a shared atomic load (`ATOMS.ADD 0`, CubeCL's `Atomic::load`). Copying the words to a plain shared array once per batch, so the chunks read them with an `LDS`, measured ×1.003 at b62 1e17 and ×1.012 at b60 1e16 in a two-round screen, inside the noise; not included.
- **Other parts of the join** (the transposed copy, the per-chunk bookkeeping, the AND's digit loop): each a few percent of its instructions, not touched here.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
