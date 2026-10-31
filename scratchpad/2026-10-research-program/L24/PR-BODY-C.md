Browser client: GPU-versus-CPU parity step, adapter check and a WGSL lint

## Why

- **The browser's GPU kernel has no real exactness check.** Each browser compiles the client's WGSL with its own compiler (Tint in Chrome, naga in Firefox, WebKit's in Safari) for whatever GPU the visitor has. The e2e compared GPU and CPU histograms on one base-40 field, the offline benchmark. Nothing compared near misses, other bases or the edges of a GPU thread's run. The native tests run the same kernel through wgpu on lavapipe, but not through a browser's compiler.
- **The browser kernel is about to change.** It is next in line for the finite-difference digit stepping that #225 gave the native GPU kernel. That change needs a check, in CI and on real GPUs, that the browser's results still match the CPU path byte for byte.
- **Apple's GPU compiler has a known miscompile, and no CI runner has that compiler.** It gets an unsigned division or remainder wrong when the divisor is a constant that is not a power of two and the dividend is a right shift by half the word (`x >> 16`, or a u64's high word). #225, #228 and #229 removed such sites by hand. The macOS runner's paravirtual GPU does not reproduce the bug. A lint over the generated WGSL keeps new sites out.

## What changes

### `web/search/parity.html` and `parity.js`

The page runs `process_chunk_gpu` and `process_chunk_wasm` over the same windows. It compares the two results as raw JSON strings, byte for byte. Nothing is parsed first, so near misses above 2^53 are compared as exact digits. The CPU histogram must also count every number in the window, so two empty results cannot pass as agreement.

- **Opens in any browser with WebGPU.** For example, Firefox Nightly on Linux or Safari.
- **Shows the adapter:** vendor, architecture, device, description, fallback flag, the name `gpu_init()` reports, and the build.
- **Shows each window's result**, the first differing field of any window that fails, and both raw results.
- **"Copy report"** copies all of it as JSON.
- **Deployment.** The page sits next to the client, so `just deploy-site` publishes it, but nothing links to it.
- **Locally:** `just wasm-build && just dev`, then open `http://localhost:8000/search/parity.html`.

Window lists (`parity.js`):

| list | windows | what |
|---|---|---|
| CI subset | 13 windows, 1.1e6 numbers | b10 `[47, 200)` (69 and 128), b23 whole, b40 start, straddling the start and a digit-gain point, run lengths 1, 61 and 129, a b49 near miss above 2^53, a b50 digit-gain point, and 2e4 at the b57, b64 and b80 starts |
| full (`--parity hw`) | 199 windows, 2.5e7 numbers, 50 near misses | bases 10-25 whole; the start, middle and end of every base 27-64; four fixed pseudo-random windows at each base where Apple's compiler broke #225's seed; every digit-gain point at 27-64; range-start and range-end straddles; nine run lengths at b40 and b57; two near-miss windows; b80 and b97 |

`--parity-random N` adds N fixed pseudo-random 1e6 windows at every base from 10 to 64. The windows' range starts are checked against the wasm build's own `benchmark_plan()`.

### `wasm-client/e2e/e2e.mjs`

The e2e drives the same page.

- **Adapter check, first.** It prints the adapter's vendor, architecture, description and fallback flag.
  - **CI's pinned adapter** must be the software one, so the run cannot come to depend on a host's GPU drivers.
  - **With `--hw`, the run fails unless:**
    - the browser returns an adapter;
    - it is not the fallback adapter;
    - no field names a software rasterizer (SwiftShader, llvmpipe, lavapipe, ...);
    - the vendor is the one given with `--expect-vendor`, if given;
    - a warm 2e8-number base-40 `process_chunk_gpu` call runs faster than `--min-rate` (default 1e8 numbers/s). SwiftShader manages about 1e6. This check does not rely on the strings the browser chooses to report.
- **Parity step, last.** It runs the CI subset by default, or the full list with `--parity hw`.
  - **A difference** fails the run. The output names the window, its range and base, and the first differing field, for example `distribution[num_uniques=44].count: gpu 1, cpu 0`.
  - **A window that hangs** fails after `--parity-timeout-secs` (default 300), and the run carries on in a fresh page.
  - **No adapter:** the step prints `PARITY SKIPPED: ...` instead of passing silently, and `--hw` has already failed on the adapter check.
- **New options:**
  - `--chromium-arg FLAG` (repeatable) passes a flag to Chromium, for experiments. `--hw` adds no flags of its own.
  - `--parity-only` runs only the adapter check and the parity step.
  - `--parity-out FILE` writes every record as JSON lines.

### WGSL lint (`scripts/wgsl-lint.py`, a step in the lavapipe job)

- **The dump.** `cubecl_backend::tests::wgsl_dump_for_lint` is ignored, and does nothing unless `CUBECL_DEBUG_LOG` is set. It compiles each kernel once:
  - the browser kernel at b40 and b50;
  - the native finite-difference kernel at b23, b40, b50 and b62;
  - the native per-number kernel at b80;
  - the stride kernel with its prefilter at b40;
  - the overlap join's kernels on the b57 frontier field.

  CubeCL writes their WGSL to the file `CUBECL_DEBUG_LOG` names.
- **The lint.** The script fails on any `/`, `%`, `naga_div` or `naga_mod` by a literal non-power-of-two constant whose dividend is a bare `>> 16` or a 64-bit `>> 32`. It reads CubeCL's WGSL and naga's MSL.
  - **Zero folding.** Before matching, it folds literal zeros the way unrolled code produces them, so `(0 << 16) | (x >> 16)` counts as `x >> 16`. That is the exact shape of the #225 seed bug.
  - **Coverage check.** `--require Kernel@base` fails the step if a kernel goes missing from the dump, or if none of its divisions are recognised (a sign that the WGSL format changed).
  - **Self-test.** 18 built-in cases run before every scan.
- **What it cannot see.** The script's header lists the patterns and their limits:
  - dividends built by other operations (`a * 65536 + (x >> 16)`);
  - values passed through arrays;
  - shifts other than exactly half the width;
  - run-time divisors;
  - anything a downstream compiler folds into the bad form after the WGSL, such as a loop it peels so that a carried remainder becomes a literal 0.

  A run on Apple hardware still settles the question.
- **Checked against WGSL from before each fix:**
  - on #225's finite-difference seed before its Metal fix, it flags 7, 26 and 59 sites at b10, b40 and b62;
  - before #228, it flags the join's top kernel (58 sites at b57);
  - before #229, it flags the stride prefilter (6 sites at b40);
  - it flags the minimal reproducers in both WGSL and naga MSL;
  - it flags nothing in the per-number kernels, whose remainder is carried through a run-time loop.
- **On current main** it reads 14 shaders and flags 0 sites.

## CI time

Measured on this branch's CI, on the fork:

- **Browser Client:** the e2e step took 64 s, against 50-53 s on main. The parity step itself took 9.3 s and the adapter check 0.2 s.
- **GPU Device Parity, lavapipe job:** the lint step took 8 s (dump 7.2 s, lint 0.2 s). It reuses the test binary the step before it builds.
- Both workflows passed, including the macOS job.

## On an Apple M4

Headless Chromium 151 over SSH, with no flags, on macOS 26.3:

| run | result |
|---|---|
| adapter | `apple` / `metal-3`, not the fallback adapter; warm b40 call 6.58e8 numbers/s |
| `e2e.mjs --hw --expect-vendor apple --parity hw` | passed in 26 s overall. Every existing step passed, and the parity step took 5.8 s: 199 windows, 2.5e7 numbers, 50 near misses, all identical. |
| `--parity-random 10` added | 639 windows, 3.7e8 numbers, 370 near misses, all identical, 53.8 s |
| `--expect-vendor amd` | failed as it should: `vendor "apple", expected "amd"` |
| `parity.html?subset=hw&run=1` | PASS, 199 windows in 4.4 s |

## Not covered

- **Firefox, Safari, Windows (D3D12) and AMD/NVIDIA/Intel GPUs** were not run here. `parity.html` is the way to check them.
- **Headless Chromium on Linux** offers no hardware adapter without flags, which is what `--chromium-arg` is for.

No CHANGELOG entry: the change is test infrastructure only.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
