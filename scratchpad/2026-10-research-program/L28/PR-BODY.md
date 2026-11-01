# GPU detailed mode: a two-word digit mask on wgpu

## What and why

The finite-difference detailed kernel (#225, #230) builds a 64-bit digit-presence mask at every step: one bit per
distinct digit of n² and n³, then a popcount. Until now the mask was one u64 on every target: `1u64 << d`, a u64 OR, and
a popcount of each half.

On wgpu the mask is now a pair of u32 words. It is built by the browser kernel's branch-free `fd_mask_u32` (#233), which
moves into `cubecl_detailed_fd` so that both kernels share it. CUDA and HIP keep the u64 mask, through a comptime switch
on `wide_chunk` like the one the seed already has.

**Motivation.** On an Apple M4 (Metal), two kernels ran at very different speeds. Both are finite-difference kernels,
measured over 2e8-number windows:

| kernel | b40 (n/s) | b50 (n/s) |
|---|---|---|
| browser kernel, headless Chromium (WebGPU) | 4.40e9 | 3.86e9 |
| native kernel, the client's `detailed --gpu --benchmark` on wgpu | 2.44e9 | 2.19e9 |
| browser / native | 1.81× | 1.76× |

**Why the mask is the suspect.**
- The two kernels share the seed and every digit-array step.
- Per step, the only difference is the mask: a u64 in the native kernel, a u32 pair in the browser's.
- Apple GPUs have no 64-bit integer ALU, so Metal emulates every u64 shift and OR with 32-bit operations.

The two also reach Metal through different WGSL compilers: Chromium's, and naga for the native client. So part of the
gap may have another cause. This PR tests the mask hypothesis.

## The change

All in `common/src/cubecl_detailed_fd.rs` and `common/src/cubecl_web.rs`:

- **`fd_mask_u32`** moves unchanged from `cubecl_web.rs` and becomes `pub(crate)`. It sets bit `d & 31` in the low or
  high word using `sel = (d >> 5) - 1`, all ones below 32 and zero from 32. It has no branch, no u64 and no division.
- **New `fd_mask_sc`** ORs a range of S's digits and a range of C's digits into the mask `(lo, hi)`:
  - with `wide` (CUDA, HIP) it packs the pair into a u64 and runs the existing `fd_mask`;
  - otherwise it runs `fd_mask_u32` twice.
- **`detailed_fd_kernel`** holds its cached slow-word mask as `ms_lo`/`ms_hi`. It builds both the step mask and the
  refreshed cache with `fd_mask_sc`, and the popcount is `count_ones(lo) + count_ones(hi)`.
- **`cubecl_web.rs`** imports `fd_mask_u32`. Its docs no longer list the mask as a difference from the native kernel.
- **CHANGELOG:** one line.

## Exactness

**Bit-identical by construction.** Base ≤ 64, so every digit d is in 0..64:
- for d < 32, `sel` is all ones and only `lo` gets `1 << d`;
- for 32 ≤ d < 64, `sel` is 0 and only `hi` gets `1 << (d - 32)`.

The pair is therefore exactly the old u64's two halves, and the popcount, the histogram bin and every near-miss decision
are unchanged.

**Tests.** All on an RTX 3060, CubeCL 0.10.0, Rust 1.99.1. The lavapipe runs were Mesa llvmpipe (LLVM 20.1.2) through
wgpu's naga WGSL path.

| where | test | result |
|---|---|---|
| CUDA | `cubecl_cuda_fd_matches_cpu_detailed` | pass |
| CUDA | `cubecl_cuda_matches_cpu_detailed` | pass |
| CUDA | `cubecl_cuda_reads_back_every_near_miss` | pass, 73 near-misses |
| CUDA | extra sweep (not committed) | 132 windows exact, 9.56e8 numbers, 180 near-misses |
| lavapipe | `cubecl_fd_seed_matches_cpu` | pass |
| lavapipe | `cubecl_fd_matches_cpu_detailed` | pass |
| lavapipe | `cubecl_reads_back_every_near_miss` | pass |
| lavapipe | `cubecl_matches_cpu_detailed` | pass |
| lavapipe | `web_fd_matches_cpu_detailed` | pass |
| lavapipe | `web_fd_seed_matches_cpu` | pass |
| lavapipe | extra sweep (not committed) | 132 windows exact, 1.09e7 numbers, 28 near-misses |
| lavapipe, CubeCL SPIR-V compiler (`gpu,cubecl-spirv` build) | the four native FD tests above and the sweep | pass (5 of 5; sweep 132 windows exact) |
| host | `cargo test --release -p nice_common --features gpu --lib` | 221 passed, 47 ignored |
| lint | `cargo fmt --all --check` and the three clippy runs of `just lint` (default, `gpu`, `gpu,cubecl-spirv`) | clean |

- **The extra sweep.** It compares the start, middle and end window of every base 10-64 that has a plan (44 bases)
  against the CPU: distribution and near-misses. Windows are 1e7 numbers wide on CUDA and 1e5 on lavapipe, or the whole
  range where that is smaller.
- **What the tests ran on.** They ran on the PR's code. The final commit differs from the tested one only in
  `fd_mask_sc`'s doc comment.

**WGSL.** I ran `wgsl_dump_for_lint`, then `scripts/wgsl-lint.py` with CI's `--require` list:
- 15 shaders, 0 flagged sites, every requirement met, on both main and this branch.
- The browser kernels' WGSL (`DetailedFdKernelU32` at b40 and b50, `DetailedKernelU32` at b80) is byte-identical to
  main's.
- The native FD kernel's WGSL loses most of its u64:

| `DetailedFdKernel` lines naming u64 | b23 | b40 | b50 | b62 |
|---|---|---|---|---|
| main | 89 | 135 | 167 | 201 |
| this PR | 30 | 32 | 32 | 34 |

Some u64 remains, none of it per step. At b40:
- 3 declarations;
- 18 lines in each run's prologue (start, count, stride, offset and n);
- 4 in the seed's split of n into u32 words (6 at b62);
- 7 in the near-miss record, which runs only for a near miss.

So the native wgpu kernel still needs `shader-int64`. The step loop itself is now u32 only.

## Measured

**CUDA: unchanged.** RTX 3060, `nice_client detailed --gpu --gpu-backend cubecl-cuda --benchmark --benchmark-secs
60`. The runs were interleaved: main, PR, u32-on-CUDA, u32-on-CUDA, PR, main. Each figure is the median of 2 runs, in
numbers per second.

| build | b40 | b50 | NiceMark |
|---|---|---|---|
| main | 1.449e10 | 1.289e10 | 7203 |
| this PR | 1.438e10 (0.992) | 1.290e10 (1.001) | 7177 (0.996) |
| u32 pair forced on CUDA (not in this PR) | 1.109e10 (0.766) | 9.83e9 (0.763) | 5505 (0.764) |

- **The PR is within noise of main.** Main's own two b40 runs are 1.7 % apart.
- **Why CUDA and HIP keep the u64.** On NVIDIA, where u64 is native, the u32 pair costs about 24 %. That is the last
  row: this branch with the switch forced to the pair.

**Apple M4 and AMD: not yet measured.** The speed-up this PR is for has to be measured on an Apple M4, and on an AMD
card, before it can be claimed. Both runs are being arranged.

**A risk to check on AMD.** The CUDA result says the u32 pair is more work wherever u64 is native, and this PR sends
every wgpu device to the pair:
- that includes AMD and NVIDIA under Vulkan, and DirectX;
- lavapipe agrees in direction. Interleaved 40 s runs (main, PR, PR, main) gave 0.91× at b40, 0.94× at b50 and 0.93×
  NiceMark. That is a CPU rasterizer with native u64, on a shared host, and the runs were 4-6 % apart.

If the AMD card loses, the switch should key on Metal rather than on "not CUDA/HIP". The pair is meant for Apple, where
u64 is emulated.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
