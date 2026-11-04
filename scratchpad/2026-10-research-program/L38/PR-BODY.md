## What

The top kernels write each certified top's eight words (P, its certificate mask, the range of bottom residues it covers, and P mod b^(k2 − f0) with the seed flag) to four arrays of two words per top: `top_p`, `top_m`, `top_r` and `top_x`. The join kernel loads a batch of up to 256 tops into shared memory before it tests a bucket's entries against them. Thread u reads the top id `t = tl[tc + u]` and gathers the top's mask, range and prefilter words from `top_m`, `top_r` and `top_x`.

This PR stores the eight words as one 32-byte record per top, `top_rec[8t .. 8t + 8]`: P (lo, hi), mask (lo, hi), range (lo, hi), then the two prefilter words. The batch load reads words 2–7 of the top's record, which lie in one 32-byte sector.

- `top_kernel` (both its launches) and `top_fd_kernel` write the record; the check kernel reads P from words 0–1.
- `top_b` stays a separate array, since the fill kernel reads only it.
- The shared-memory layout of the batch and everything after the batch load are unchanged.
- The join plan's footprint counts the record as one buffer of 32 bytes per top.

## Why

The tops' ids in a bucket's list are effectively random, so each lane of the batch load reads three different sectors from three different arrays for 24 bytes of payload. A top is loaded once for every bucket that lists it (one per digit-sum root, two at b62), about 7.6·10^10 top loads per b62 1e17 field.

An ablation of the join kernel on main at b62 1e17 (RTX 3080, 150 W cap) put the batches' top gathers at 18.6 s of the 72.4 s join: 26 % of the join, 14 % of the 129.7 s field. Reading `tl` alone cost 0.35 s and the `top_m` gather 2.5 s; the `top_r` and `top_x` gathers cost the other 15.7 s. Two more sectors per top from two more arrays cost six times the first one.

## Soundness

- **Same values, same tops, same order.** Every writer stores the same eight values for top `g` as before, at `8g + j` instead of word `2g + (j mod 2)` of array `j / 2`. Every reader reads word `8t + j` where it read word `2t + (j mod 2)` of that array, for the same `t`. Nothing else reads or writes the four arrays, so every kernel sees the values it saw before. The appends, the top ids, the bucket lists and the join's shared batch are the same.
- **Same bytes.** The record takes the four arrays' bytes together (32 per top and slot).
- **The plan does not move.**
  - The record is now the largest per-slot buffer that grows with the top layer: 32 bytes per prefix, against 8 per top array before (and 4 per digit-sum root in `tl`). It enters the binding bounds in `max_slice_prefixes` and `JoinPlan::new`.
  - It cannot bind before the survivor bounds next to them. The survivor list holds at most `budget / 32 ≤ max_binding / 16` entries. So `max_slice_prefixes`' survivor bound is at most `max_binding / 128`, against the record's `max_binding / 64`. And `JoinPlan::new`'s is at most `max_binding / (64 · ntl)` slots, against `max_binding / (32 · ntl)`.
  - Every field below ran with the same slots per launch and the same layout size on both sides.
- **Indices.** Every buffer of a layout fits its budget, which is at most 4 GiB, so `8t` stays below 2^30.

## Measurements

**Card:** RTX 3080 10 GB (driver 580.159.03) on a rented box whose host caps it at **180 W** (default 340 W). Every timed run sat at the cap (176–180 W, `SW power cap` throttling), at 66–70 °C.

**Method:**
- main (`6f060a9`) and this PR, same box, two binaries, rounds interleaved with the order alternating (main, PR; PR, main; main, PR), nothing else running.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, at the starts b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the mean device wall time per field (`device=`; two fields in flight at 1e16). Figures are medians of 3 rounds; spread = (max − min) / median; "per round" is main's time over the PR's in the same round. MHz is the mean SM clock per side; "cycles" is the ratio of device seconds × clock.

| field | main s/field (rounds) | spread | this PR s/field (rounds) | spread | speed-up | per round | MHz main / PR | cycles |
|---|---|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | **120.37** (120.37, 120.57, 116.58) | 3.3 % | **109.46** (109.46, 109.64, 108.48) | 1.1 % | **×1.100** | 1.100, 1.100, 1.075 | 1427 / 1502 | ×1.034 |
| b62 1e16, 2 fields | **9.832** (9.83, 9.74, 10.04) | 3.0 % | **9.141** (9.15, 9.14, 9.11) | 0.4 % | **×1.076** | 1.075, 1.066, 1.102 | 1453 / 1488 | ×1.057 |
| **b60 1e16**, 2 fields | **23.122** (23.12, 22.94, 23.63) | 3.0 % | **21.823** (22.19, 21.78, 21.82) | 1.9 % | **×1.060** | 1.042, 1.053, 1.083 | 1451 / 1497 | ×1.029 |
| b64 1e16, 2 fields | **33.081** (33.34, 33.08, 33.06) | 0.8 % | **30.327** (30.48, 30.27, 30.33) | 0.7 % | **×1.091** | 1.094, 1.093, 1.090 | 1417 / 1475 | ×1.060 |
| b60 1e14, 3 fields | 0.593 (0.61, 0.59, 0.59) | 3.4 % | 0.607 (0.61, 0.58, 0.62) | 6.8 % | ×0.977 | 1.010, 1.015, 0.949 | | |
| b62 1e14, 3 fields | 0.486 (0.49, 0.49, 0.48) | 2.1 % | 0.491 (0.49, 0.51, 0.48) | 6.1 % | ×0.990 | 1.002, 0.951, 1.002 | | |
| b64 1e14, 3 fields | 0.737 (0.74, 0.75, 0.72) | 3.3 % | 0.722 (0.72, 0.72, 0.72) | 1.0 % | ×1.021 | 1.018, 1.033, 1.007 | | |

- At b62 1e17 that is 10.9 s saved per field. An earlier single round on the same box gave ×1.071 at b62 1e17, ×1.080 at b62 1e16 and ×1.061 at b60 1e16.
- **Part of it is clock.** The PR's side ran 35–75 MHz faster at the same cap: fewer sectors per top draw less power per cycle, and the cap turns that into clock. The clock-normalised ratios are ×1.03–1.06. On a card that is not power-limited I would expect a gain between the two columns; I could not measure that here (the container can neither lift the cap nor lock clocks).
- The 1e14 fields are neutral, within the spread of their runs (0.5–0.75 s per field).
- Every field ran with the same slots per launch and layout size on both sides.

NiceMark nice-only (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 2 rounds, alternating):

| | main | this PR | speed-up |
|---|---|---|---|
| **score** | 6075.4, 6066.3 | 6387.4, 6362.4 | **×1.050** (per round 1.051, 1.049) |
| b58 MSD-weak (whole field) | 2.819e14 n/s | 2.920e14 | ×1.036 |
| b58 MSD-strong (whole field) | 1.336e15 | 1.353e15 | ×1.012 |
| b60 MSD-weak (sampled) | 5.596e14 | 5.987e14 | ×1.070 |
| b62 MSD-weak (sampled) | 6.899e14 | 7.475e14 | ×1.083 |

**The top stage alone** (`cubecl_cuda_top_fd_timing`, the first 40 batches of a production plan's first slice, ns per top prefix and partition, medians of 6 rounds per side): unchanged.

| field | `top_kernel` main / PR | `top_fd_kernel` main / PR |
|---|---|---|
| b62 1e17, consecutive partitions | 0.3574 / 0.3584 | 0.2272 / 0.2264 |
| b62 1e17, every other partition | 0.3543 / 0.3515 | 0.3544 / 0.3526 |
| b60 1e16, consecutive partitions | 0.3401 / 0.3393 | 0.2257 / 0.2260 |
| b60 1e16, every other partition | 0.3256 / 0.3257 | 0.3290 / 0.3271 |

The record's stores are the same nine 32-bit stores per kept top as before (the eight words and `top_b`).

**Loads:** six scalar loads from the record were compared with one 16-byte and one 8-byte load (binding the record as `Array<Vector<u32, Const<4>>>` in the join). They tied on every field (b62 1e17 108.6 against 107.4 s, b62 1e16 8.95 against 8.92 s, b60 1e16 21.7 against 21.5 s, each within its rounds' spread), so this PR keeps the scalar loads. The L1 serves the repeat loads from the same sector; the vector form needed 4 more registers and a vector binding on every backend.

## Exactness

All on the RTX 3080 (CUDA) unless marked lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8, 8-lane subgroups). The timed runs used a build that differs from this head only by one rustfmt line join; the tests below ran on both builds.

- `cubecl_cuda_join_matches_the_cpu_reference`: ok. It covers b10's 69; windows b20–b64, including b50 and b54 after refused layouts; the b57 frontier partitions 0/1000/3248, tight and refused; sliced windows; and the production shape.
- `cubecl_cuda_top_fd_matches_the_top_kernel`, now reading the record: ok, 26 fields, 279 batches (23 with a clipped block), 237,907,266 tops. Both top kernels give the same count, bucket counts and sorted (P, mask, r, x, b) entries per slot.
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept, 203,413 powers above c0, 69,824 with the carry.
- Dense fields, asserted equal to the CPU join:
  - b58 1e15, 32 partitions: 254,938,965 survivors / 14,396,829 checked.
  - b62 1e16, 4 partitions: 120,013,475 / 7,355,827.
- Whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): ok. 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference.
- `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64): join = stride, found 0. Counts identical to main's: 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759.
- Every timed field above has main's survivors and full checks in every round:
  - b62 1e17: 1,020,844,021,499 / 62,584,252,554.
  - b62 1e16: 163,513,599,082 / 10,027,698,695.
  - b60 1e16: 460,847,952,346 / 30,871,838,404.
  - b64 1e16: 787,584,956,227 / 47,900,853,327.
  - NiceMark's whole-field scenarios: identical (b58 MSD-weak 33,590,315,220 join survivors, MSD-strong 4,027,773,430).
- `join_plan` unit tests (production layouts and slice cuts): ok.
- lavapipe, every wgpu test in `cubecl_join` (join parity, the FD-vs-top-kernel test on 21 fields / 142 batches / 1,018,088 tops, the certificate test, the production-field sample, the ticket test): ok with the naga (WGSL) compiler and with CubeCL's direct SPIR-V compiler.
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's 13 `--require`s): 16 shaders, 0 flagged (JoinKernel b57: 36 constant divisions, as before).
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`, default, with `--features nice_client/gpu` and with `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1): clean.

## Registers

From ptxas (`nvcc -cubin -arch=sm_86 -O3 -Xptxas -v`, CUDA 12.8) on CubeCL's CUDA for 1e14 fields at b60, b62 and b64, two or three passes per side:

| kernel | main | this PR |
|---|---|---|
| `join_kernel` b60 / b62 / b64 | 40 / 40 / 44–47 | 40 / 40 / 44–47 |
| `top_fd_kernel` b60 / b62 | 108 / 110 | 108 / 110 |
| `top_kernel` b60 / b62 (clipped blocks) / b64 | 80 / 80 / 95 | 80 / 80 / 95–99 |
| `check_kernel` b60 / b62 / b64 | 38 / 38 / 34 | 38 / 38 / 34 |

- No spills on either side.
- The ranges come from passes of the same binary: CubeCL does not emit identical CUDA source from process to process, and the allocation moves with it, on both sides.
- Occupancy is unchanged: the join stays at 5 cubes of 256 per SM, set by its shared memory.
- The batch load is the same six 32-bit loads, now off one base address instead of three.

## Not in this PR

- **The vector loads** (above): no measurable gain, so not taken.
- **`top_b` in the record.** Only the fill kernel reads it, consecutive threads on consecutive tops (coalesced), so it stays a separate array; a 36-byte record would also lose the 32-byte alignment.
- **No CPU change.** The CPU join keeps its tops in host structs.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
