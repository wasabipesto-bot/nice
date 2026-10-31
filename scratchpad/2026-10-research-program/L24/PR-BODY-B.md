# Browser client: GPU detailed mode by finite differences

One commit on `main`, after #230 (the shared u32 seed), which is merged.

## What and why

The browser's GPU path still runs detailed mode with the per-number kernel. That kernel squares and cubes every n and divides both down to digits. #225 replaced this on the native client with finite differences: each thread seeds the digit arrays of n², n³ and the three differences once per run of 128 consecutive n, then steps through the run with digit-array additions. #230 moved that kernel's seed into a u32-only function so a browser kernel could share it.

This PR adds that browser kernel. On an Apple M4 in headless Chromium, the browser GPU NiceMark goes from 265 to 2170 (8.2×). Results are byte-identical to the CPU on every window tested.

## Design

**`detailed_fd_kernel_u32`** (`common/src/cubecl_web.rs`) is #225's `detailed_fd_kernel` with every u64 removed. WebGPU has no 64-bit integers, and Chrome's WGSL compiler rejects any shader that names one.

- **Shared with the native kernel, unchanged:**
  - `fd_seed_split16`, the seed;
  - `fd_add_top`, `fd_add_const_top`, `fd_ripple` and `NO_CARRY`, the steps;
  - `fd_plan` (the interval where n² and n³ have fixed digit counts) and `FD_RUN_LEN` (128);
  - the shared-memory histogram copies;
  - the 5-word near-miss record.
- **Web-specific:**
  - **Prologue.** The run start, count, offset and stride are u32. n is built as four u32 words by a carry chain, which is the shape `fd_seed_split16` takes. The host checks `count + stride < 2^32` for every dispatch.
  - **Mask.** A u32 pair instead of one u64 (`fd_mask_u32`), set branch-free per digit: `bit = 1 << (d & 31)`, `sel = (d >> 5) - 1`, `lo |= bit & sel`, `hi |= bit & !sel`. The popcount is the sum of the two words'.
  - **Near-miss record.** The number is rebuilt from the start words and `off + i` on the rare path, so no extra registers are held across the run.
- **Launch.** A 32M batch is 250,000 runs, which is 977 workgroups of 256, one run per thread. Shared memory is at most 1,040 B (at b64). No 64-bit atomics are used, and bins stay u32 under the existing drain bound.
- **Host split.** `process_range_detailed_web_kernel` splits each batch as the native `detailed_impl` does:
  - the part inside `fd_plan`'s interval goes to the finite-difference kernel;
  - anything outside it, and every base above 64 (which has no plan), goes to `detailed_kernel_u32`.

  The per-number kernel is unchanged. It also stays as the test reference.
- **Readback kept.** Both kernels write the same histogram, near-miss count and near-miss buffers within a batch's one flush. The slice therefore still ends in a single `read_async` of all three, and the conservation check, overflow check and host sort are unchanged.
- **Unchanged API.** `process_range_detailed_web_async` and `process_chunk_gpu` keep their signatures. `worker.js` and the page need no change.
- **`gpu_build_info`** gains `"detailed_kernel":"fd"`, so a console paste shows whether a cached wasm predates this.
- **Test hooks.** Two `#[doc(hidden)]` wasm exports exist for parity runs in a browser:
  - `process_chunk_gpu_shape(start, end, base, run_len, batch)` chooses the run length and batch, or the per-number kernel alone with `run_len = 0`;
  - `fd_seed_probe_gpu(start, count, base)` returns the seed's digit words for `count` consecutive n.

  `WebKernel` and `process_range_detailed_web_kernel` are `pub` but `#[doc(hidden)]` for the same reason.
- **Apple's Metal compiler.** It miscompiles a constant division whose dividend is a bare `x >> 16` (#225, #228). Every browser on a Mac compiles WGSL to Metal.
  - In this kernel only the seed divides by a constant that is not a power of two, and the seed never takes such a dividend.
  - The prologue, mask, steps and near-miss record do not divide at all. In the generated WGSL, the kernel has exactly one more constant division than the seed alone: `% HIST_COPIES`, a power of two.

## Exactness

Every layer compares against the CPU's `process_range_detailed`. Browser comparisons are of the raw JSON strings from `process_chunk_gpu` and `process_chunk_wasm`, byte for byte, so near misses above 2^53 are compared as exact digits.

**New ignored tests** (`cubecl_web::tests`). CI's gpu-parity job runs these on lavapipe with both naga and CubeCL's SPIR-V compiler, and on the macOS runner.
- **`web_fd_matches_cpu_detailed`, 430 windows:**
  - b40 and b50: the native suite's windows (range start and end, straddling the start, eight seeded, every digit-gain point of an addend) under four run shapes: 128; 61; 1, which seeds every n; and 1000 with 333,333-number batches;
  - bases 10–25 in full under the same four shapes: 8.7e6 numbers, 45 near misses;
  - every other base from 27 to 64: the same windows plus the middle, at run lengths 128 and 61 (371 windows over 29 bases);
  - partial runs of 1–100,001 numbers at the b40 and b57 starts;
  - the b49 and b40 near-miss windows.
- **`web_fd_seed_matches_cpu`.** The seed's five digit arrays, word for word, for 1,024 n at the start, middle and end of all 44 bases: 132 of 132 windows exact.
- **`web_fd_launch_bounds`** (host). The u32 offset bound holds for run lengths 1–4096 and batch sizes up to 32M.
- **Existing `web_kernel_*` tests.** These now go through the finite-difference kernel at b≤64. `web_kernel_matches_cpu_detailed` also runs the per-number kernel alone.

| layer | where | result |
|---|---|---|
| native tests, naga WGSL → lavapipe (Mesa 25.2.8) | Linux x86, 40 threads | all 5 web tests pass; the native FD suite and the near-miss test still pass |
| the same, CubeCL's SPIR-V compiler (`gpu,cubecl-spirv`) | same | all 5 pass |
| native tests, naga → MSL on an Apple M4 (macOS 26.3; Firefox's compiler path on a Mac) | M4 | all 5 pass: 430 windows, seed 132/132. The `metal_half_shift_div_repro` control still fails there, so the compiler fault is present and the tests are a live check. |
| CUDA regression (`gpu`) | RTX 3080 | `cubecl_cuda_fd_matches_cpu_detailed`, `cubecl_cuda_matches_cpu_detailed` and `cubecl_cuda_reads_back_every_near_miss` pass. The native kernel is untouched; `cubecl_detailed_fd.rs` changes only in test-helper visibility. |
| SwiftShader in the CI Playwright image (Chromium 151, Tint → SPIR-V) | Linux | `wasm-client/e2e/run.sh` passes (offline field CPU = GPU, submit shape, the b49 near miss 20363742218601559 exact). Parity: 199 windows, 2.55e7 numbers, 50 near misses, 0 differing. Seed probe 132/132. 13 windows × 6 run shapes (per-number, 1, 61, 64, 128, 1000/333,333): 0 differing. |
| headless Chromium 151 on an Apple M4, no flags (Tint → MSL) | M4 | Parity: 201 windows, 4.25e8 numbers including both 2e8 benchmark windows whole, 50 near misses, 0 differing. Seeded sweep: 440 windows, 3.41e8 numbers, 320 near misses, 0 differing. Seed probe 132/132. 53 boundary, partial-run, near-miss, gain-point and fallback windows × 6 run shapes: 0 differing. |
| WGSL check | the `CUBECL_DEBUG_LOG` dump on lavapipe | No `u64` or `i64` anywhere. No constant division or remainder of a half-width shift in 122 shaders: the finite-difference kernel and the seed probe at all 44 bases, and the per-number kernel at 34 bases (10, the 31 bases from 27 to 64 that have a range, 80 and 97). |

The M4 parity windows, per set:

| set | windows | numbers | near misses | differing |
|---|---|---|---|---|
| bases 10–25 in full | 13 | 8,669,368 | 45 | 0 |
| bases 27–64: start, middle, end | 93 | 9.3e6 | 0 | 0 |
| bases 27–30, 49, 50, 52–55: four seeded windows each | 40 | 4.0e6 | 0 | 0 |
| digit-gain points of dS, dC and ddC, 1e5 centred | 27 | 2.7e6 | 1 | 0 |
| straddling the plan's interval (b40, b50 start; b40 end; b10 `[47, 200)`) | 4 | 300,153 | 2 | 0 |
| partial runs at the b40 and b57 starts, 1 to 100,001 | 18 | 201,922 | 0 | 0 |
| near-miss windows at b49 and b40 | 2 | 2e5 | 2 | 0 |
| per-number only: b80 and b97 | 2 | 1e5 | 0 | 0 |
| b40 and b50 benchmark windows, 2e8 each | 2 | 4e8 | 0 | 0 |

**CI time.** On lavapipe, with the test pinned to 4 cores, `web_fd_matches_cpu_detailed` takes 59 s and `web_fd_seed_matches_cpu` 24 s; most of that is shader compiles at 44 bases. The SPIR-V pass took 92 s and 44 s on a 40-thread box. On the M4 the two take 22 s and 7 s.

## Measured

Apple M4 (10-core GPU, macOS 26.3 25D125), headless Chromium 151.0.7922.34 with no flags.
- **Adapter.** `apple` / `metal-3`, `isFallbackAdapter` false, subgroups 32. With `--enable-webgpu-developer-features` the description is "Apple M4".
- **Method.** This PR and its base were built and served side by side, three rounds, interleaved, alternating which went first.
- **Thermal state.** `pmset -g therm` recorded no thermal, performance or CPU-power warning before or after any round.
- **Rates.** Each cell is the median of 3 rounds; the spread (max − min over the median) follows in brackets.

| n/s | before | this PR | speed-up |
|---|---|---|---|
| b40, real page, suite mode, GPU worker, 60 s | 6.59e8 (0.05 %) | 4.40e9 (0.4 %) | 6.7× |
| b50, same | 3.82e8 (0.2 %) | 3.86e9 (0.1 %) | 10.1× |
| browser GPU NiceMark | 265 (0 %) | 2170 (0.2 %) | 8.2× |
| b40, `process_chunk_gpu` over 2e8 only (median of 3 calls after 2 untimed) | 6.50e8 (1.5 %) | 4.39e9 (2.4 %) | 6.7× |
| b50, same | 3.82e8 (0.1 %) | 3.86e9 (0 %) | 10.1× |
| suite `warmup_seconds`, b40 / b50 | 0.34 / 0.53 | 0.11 / 0.08 | — |

- **Compile cost.** A first call costs about 0.05 s more than a steady one.
- **Run length.** These are `process_chunk_gpu_shape` calls over the same 2e8 windows, 3 rounds. 128 stays.

  | run length | b40 | b50 |
  |---|---|---|
  | 64 | −3.0 % to −3.4 % | −5.3 % to −5.5 % |
  | 256 | +0.7 % | +2.4 % |

- **Against the native client.** On the same M4, the native client's wgpu finite-difference kernel runs at about 2.4e9 (b40) and 2.2e9 (b50) n/s, so the browser now outruns it by about 1.8×. One candidate cause, not tested: the native kernel's digit mask is a u64, and Apple GPUs have no native 64-bit integer operations.
- **SwiftShader** in the CI image, as a sanity row only: b40 over 2e6 numbers, warm, 3 rounds, went from 7.4–7.7e5 to 0.85–1.2e7 n/s.

## Not in this PR

- **AMD and Linux browser speed** (RX 9070 XT): parity is done there (Exactness above); the benchmark suite before and after, and run length 64 against 128, are not measured on that card.
- **Run-length tuning on AMD.** On the M4, 64 is slower and 256 is within 2.4 %, so the default stays 128 unless the 9070 XT shows a tail effect.
- **Safari (WebKit's own WGSL compiler) and Windows (D3D12)** are untested.
- **Firefox on a Mac** is covered only through the native tests' naga → MSL run above, not in the browser itself.
- **The native wgpu kernel's mask.** Whether a u32 mask pair also speeds up the native client on Apple GPUs is a separate change.
- **The parity step's WGSL lint, once both are in.** Its shader dump calls `process_range_detailed_web` at b40 and b50 inside the plan's interval. On top of this PR those calls compile the finite-difference kernel, not the per-number one. Its `--require` list (`DetailedKernelU32@40/50`) then needs `DetailedFdKernelU32@40/50` added, and a per-number call kept, for example `WebKernel::Division` or a window straddling the range start.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
