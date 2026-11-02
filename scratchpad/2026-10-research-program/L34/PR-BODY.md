## What

The GPU overlap join's `join_kernel` tests every bottom entry of a bucket against every top in the bucket's batch of up to 256 tops. A pair passes when the entry's 64-bit digit mask and the top's have no bit in common. Today each top costs every entry two ANDs, an OR, a compare and a select, plus two broadcast shared loads and loop overhead.

This PR transposes the batch instead, for batches of at least `TRANSPOSE_MIN` tops (192). After the batch is in shared memory, the kernel writes `t_tr[c·64 + d]`: one 32-bit word per (chunk `c` of 32 tops, digit `d`), with bit `i` set iff top `32c + i` has digit `d`. That is 2 KiB of shared memory, with one word per thread pair and a barrier.

An entry's pass mask for a chunk is then the complement of the OR of the words of the entry's own digits. An entry has 2k of them (12 at the production k = 6), so that is about 12 loads and ORs per chunk instead of 32 two-word tests. The kernel walks an entry's digits once per group of `AND_GROUP` = 4 chunks, with 4 accumulators per entry slot, and shifts the accumulators down one chunk at a time.

Batches below `TRANSPOSE_MIN` keep the per-top test. On small buckets the copy costs more than it saves.

The walk over the pass mask, the prefilter in the walk (#236), the stage and the flush are unchanged.

## Why

On top of #235–#237, the join kernel is 53 % of device time at b62 1e17 and 58 % at b60 1e16. The other phases: top 35 % / 28 %, check 7 % / 8 %, bucket and transfers 6 % / 7 %. These were measured with the device synchronised after each kernel group, on an RTX 3080. A fit of the join phase over fields puts about 60 % of it in the AND.

## Soundness

- **The test is the same set test.** Write `S_e` and `S_t` for the entry's and the top's digit sets, so the masks are their indicator words. The per-top test passes iff `S_e ∩ S_t = ∅`.
  - Bit `i` of `OR_{d ∈ S_e} t_tr[c·64 + d]` is `OR_{d ∈ S_e} [d ∈ S_{t_i}]`, where `t_i` is top `32c + i`.
  - That is 1 iff some digit of the entry is a digit of `t_i`, i.e. iff `S_e ∩ S_{t_i} ≠ ∅`.
  - So the complement's bit `i` is exactly the per-top test's bit `i`. The low and high mask words map to digits `0..32` and `32..64`, and `t_tr` holds both.
  - The OR runs over the entry's set bits, so the result does not depend on how many digits an entry has.
- **Tops past the batch's end never pass.**
  - The copy clears the bits past the batch's last top and writes zero words for chunks past it, so no stale word of an earlier batch is read.
  - The complement would set those bits, so it is ANDed with the chunk's valid-top bits (`cm`). The walk sees the same bits the per-top loop produced; that loop stopped at the batch's end.
- **Padding lanes never pass.**
  - An entry slot past the bucket's entries has `vv = 0`. Its digit set is taken as `mask & vv`, empty, so it runs no iterations. Its pass mask is then `cm`, and the walk takes `pm & vv = 0`, as before.
  - The per-top test gave these lanes an all-ones mask (fail every top), and `vv` killed them as well.
  - Dead bottom entries (`DEAD_MASK`) are never listed, as before.
- **Barriers.**
  - `t_tr` is written between the barrier after the batch load and a new barrier, so every thread sees the complete copy before any reads it.
  - It is rewritten only for the next batch, after the barrier that ends the batch loop.
  - `nt` (the batch's top count) is the same for the whole cube, so every thread takes the same path at every barrier.
- **Groups.** Accumulators are recomputed at the first chunk of each group of 4 (`cb % AND_GROUP == 0`), since 4 divides the 8 chunks of a full batch. Each chunk then takes the front accumulator and shifts the rest down.

## Measurements

RTX 3080 10 GB (driver 580.159.03) with a **power limit of 180 W** (default 340). Every timed run sat at the cap: 178–180 W, mean SM clock 1,406–1,491 MHz per side at ≥ 90 % utilisation. The metric is mean device seconds per field from `cubecl_cuda_join_throughput_fixed_fields`, at its fixed starts (b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568), with an untimed warm-up field per process. Runs are interleaved base/PR per round; numbers are medians. The change was measured on #236 alone (this branch) and on top of #235–#237.

**On #236 alone** (this branch `1298ce7` against #236's head `fb05597`; two binaries, interleaved; 3 rounds at 1e16, 2 at 1e17 and in NiceMark):

| field | #236 (rounds) | this PR (rounds) | speed-up | per round |
|---|---|---|---|---|
| **b62 1e17**, 1 field | 180.54, 187.32 | 174.02, 174.57 | **×1.055** | 1.037, 1.073 |
| b62 1e16, 2 fields | 15.598, 15.742, 15.723 | 14.646, 14.973, 14.981 | **×1.050** | 1.065, 1.051, 1.050 |
| b60 1e16, 2 fields | 34.162, 34.431, 34.165 | 32.165, 32.022, 32.771 | **×1.062** | 1.062, 1.075, 1.043 |
| b64 1e16, 2 fields | 41.080, 41.136, 40.488 | 34.937, 35.023, 34.932 | **×1.176** | 1.176, 1.175, 1.159 |
| b60 1e14, 3 fields | 0.705, 0.709, 0.707 | 0.731, 0.713, 0.725 | ×0.978 | |
| b62 1e14, 3 fields | 0.559, 0.563, 0.593 | 0.601, 0.591, 0.596 | ×0.959 | |
| b64 1e14, 3 fields | 0.727, 0.717, 0.773 | 0.762, 0.751, 0.762 | ×0.975 | |

The 1e14 ratios are of means. Mean SM clock per side: 1,438–1,491 MHz, within 1.3 % of each other on every field.

NiceMark (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 2 rounds):

| | #236 | this PR | speed-up |
|---|---|---|---|
| **score** | 4404.0, 4394.2 | 4692.7, 4764.2 | **×1.075** (per round 1.066, 1.084) |
| b58 MSD-weak (whole field) | 1.993e14, 2.012e14 n/s | 2.187e14, 2.244e14 | ×1.106 |
| b58 MSD-strong (whole field) | 1.135e15, 1.148e15 | 1.171e15, 1.149e15 | ×1.017 |
| b60 MSD-weak (sampled) | 3.676e14, 3.694e14 | 3.931e14, 4.128e14 | ×1.093 |
| b62 MSD-weak (sampled) | 4.841e14, 4.678e14 | 5.153e14, 5.178e14 | ×1.085 |

**On top of #235–#237** (the same kernel change, `TRANSPOSE_MIN = 192`, against the same tree without it; 2 rounds, interleaved):

| field | #235–#237 | with this change | speed-up |
|---|---|---|---|
| **b62 1e17** | 140.80, 144.32 | 132.59, 132.85 | **×1.074** |
| b62 1e16 | 12.053, 12.105 | 11.357, 11.362 | ×1.063 |
| b60 1e16 | 27.302, 27.151 | 24.974, 25.540 | ×1.078 |
| b64 1e16 | 38.913, 38.844 | 33.146, 33.145 | ×1.173 |
| b60 / b62 / b64 1e14 | | | ×0.979 / ×0.934 / ×0.944 |
| NiceMark score | 5486.4, 5582.3 | 6151.8, 6104.0 | **×1.107** (b58 MSD-strong ×1.023, MSD-weak ×1.161; b60 ×1.142; b62 ×1.108) |

- **The join phase loses about 12 %** at b62 1e17 and b60 1e16, and nothing else moves. This is from a per-phase profile on top of #235–#237 with every batch transposed.
- **The gate:**
  - Without it (every batch transposed), b58 MSD-strong was ×0.90 and the 1e14 fields ×0.83–0.92. At 3 tops per bucket the copy outweighs a handful of per-top tests.
  - 128, 192 and 256 were compared. 192 was best or within noise of the best on every large field and in NiceMark, and every gate brings MSD-strong to ×0.99–1.02.
- **The 1e14 fields still lose 2–7 % at every gate, including 256**, which transposes no batch there. So that cost is the kernel's footprint, not the copy: 5 cubes per SM instead of 6 (see below) and one barrier per batch. 1e14 is far below production field sizes. NiceMark's smallest-bucket scenario (b58 MSD-strong) is not slower.


## Exactness

All on the RTX 3080 (CUDA) at this branch's head, except where marked lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8).

- `cubecl_cuda_join_matches_the_cpu_reference`: ok. It covers b10's 69; windows b20–b64, including b50 and b54 after refused layouts; the b57 frontier partitions 0/1000/3248, tight and refused; windows whole and in slices; and the production shape.
- Dense fields, asserted equal to the CPU join:
  - b58 1e15, 32 partitions: 254,938,965 survivors / 14,396,829 checked.
  - b62 1e16, 4 partitions: 120,013,475 / 7,355,827.
- Whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): ok. 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference.
- `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64): join = stride. Counts identical to #236's head: 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759.
- **The transposed path on the tests' small windows.** With `TRANSPOSE_MIN = 192`, the tests' small windows mostly have batches below the gate and run the per-top test. The timed fields below run the transposed path on most batches (129–310 tops per live bucket at 1e16–1e17). So the reference, both dense fields and the whole b42 field were also run with `TRANSPOSE_MIN = 0` (a one-line edit; every batch transposed). All pass with the same counts.
- Every timed field below has the same survivors and full checks with this PR as with its base, in every run. Since #236 these counts are exact, so any difference would be a defect:
  - b62 1e17: 1,020,844,021,499 / 62,584,252,554.
  - b62 1e16: 163,513,599,082 / 10,027,698,695.
  - b60 1e16: 460,847,952,346 / 30,871,838,404.
  - b64 1e16: 787,584,956,227 / 47,900,853,327.
  - NiceMark's whole-field scenarios: identical.
- lavapipe, join parity (`cubecl_join_matches_the_cpu_reference`): ok with the naga (WGSL) compiler and with CubeCL's direct SPIR-V compiler. The SPIR-V JoinKernel has 136 blocks (133 at some bases), against 109–112 before, with no stack overflow.
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's 13 `--require`s): 15 shaders, 0 flagged (JoinKernel b57: 36 constant divisions).
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`, default and `--features nice_client/gpu` (rustc 1.99.1): clean.


## Registers and occupancy

From ptxas (`nvcc -cubin -arch=sm_86 -O3 -Xptxas -v` on CubeCL's CUDA for the b62 join kernel):

| | registers | spills | SASS instructions | shared memory per cube | cubes per SM (sm_86: 64 K registers, 100 KiB shared, 1 KiB reserved per cube) |
|---|---|---|---|---|---|
| #236's head | 40 | 0 | 784 | 14,344 B | 6 |
| this PR | 40 | 0 | 1,088 | 16,392 B | **5** (by shared memory; 6 by registers) |

- The 2 KiB copy costs one cube per SM. That is the main cost on fields where no batch reaches the gate: there the PR runs the same AND as before, with one more barrier per batch and 5 cubes per SM instead of 6.
- Freeing 1 KiB elsewhere (survivors' top ids from `tl` instead of a shared copy) brings the shared memory back under the 6-cube line, but raises the registers to 45. That only moves the limit to the registers, so it is not in this PR.


## Not in this PR

- The top-kernel PRs (#235, #237) are separate and independent. This change touches only `join_kernel` (and its constants, docs and the CHANGELOG). It applies to `cubecl_join.rs` on top of them without conflicts; only the CHANGELOG line needs the usual resolution. The measurements above include a run on top of them.
- No CPU change. The CPU join already tests 8 masks per AVX-512 instruction, so a transposed copy has little to win there.
- Closing the 1e14 cost (getting back to 6 cubes per SM, or choosing the per-top kernel per field from the host's estimate of tops per bucket) is left for later.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
