# L24 (b) results: the finite-difference detailed kernel on the browser GPU path (2026-10-31)

**Branch** `pr/web-detailed-fd` on the fork, head **5d4ce8a**, one commit on #230 (215952d). Pushed, not opened. The body is in `L24/PR-BODY-B.md`.

**Verdict.** The kernel was exact on the first build, on every layer.
- **Exactness.** Five layers, 0 differences:
  - native lavapipe, with both naga and CubeCL SPIR-V;
  - native naga → MSL on the M4;
  - SwiftShader;
  - headless Chromium on the M4;
  - the WGSL lint, clean at all 44 bases.
- **CUDA.** The native FD suite still passes.
- **M4 browser speed.**
  - Browser GPU NiceMark: 265 → **2170 (8.2×)**.
  - b40: 6.59e8 → 4.40e9 (6.7×). b50: 3.82e8 → 3.86e9 (10.1×).
  - Spreads are ≤ 0.4 % on the suite.
  - This is 1.8× the native wgpu FD kernel on the same M4 (2.435e9 / 2.187e9, PROPOSAL §4), far above the projection of 1.7–2.0e9 / 1.5–1.8e9.
- **Run length** stays 128:
  - 64 is 3.0–3.4 % slower at b40 and 5.3–5.5 % slower at b50;
  - 256 is +0.7 % at b40 and +2.4 % at b50.

Time: started 16:44 UTC, branch pushed ~17:35, write-up done 17:41 (about 1 h of the 6 h budget). mayalaran: 29 min wall (`raw-b/m4/machine-time.log`).

## 1. The change (5d4ce8a; 4 files, +878 −42)

| file | what |
|---|---|
| `common/src/cubecl_web.rs` | `fd_mask_u32`, `detailed_fd_kernel_u32`, `fd_seed_probe_kernel_u32` (+ `FD_SEED_STRIDE`/`FD_SEED_OFFSETS`); `WebKernel {Division, FiniteDifference{run_len, batch}}` + `DEFAULT`; `fd_launch_shape`; `process_range_detailed_web_kernel` (host split as `detailed_impl`; per-number closure; `ensure!` run>0, batch ≤ 32M, `u32::try_from(count + stride)`); `process_range_detailed_web_async` → `_kernel(DEFAULT)`; `fd_seed_probe_web_async`; module doc rewritten (two kernels, web-specific differences, Metal note). Tests: `web_fd_launch_bounds` (host), `web_fd_matches_cpu_detailed`, `web_fd_seed_matches_cpu` (ignored); `web_kernel_matches_cpu_detailed` now runs both `DEFAULT` and `Division`. |
| `common/src/cubecl_detailed_fd.rs` | test module only: `pub(crate) mod tests`, and `cpu_detailed_parallel`, `windows`, `SEED_STRIDE`, `SEED_FIELDS`, `seed_expected` → `pub(crate)` (reused by the web tests). No non-test line changed. |
| `wasm-client/src/lib.rs` | `#[doc(hidden)]` `process_chunk_gpu_shape(start, end, base, run_len, batch)` (run 0 = per-number; batch 0 = 32M) and `fd_seed_probe_gpu(start, count, base)` → `{"stride","offsets","words"}`; `gpu_build_info` + `"detailed_kernel":"fd"`; `process_chunk_gpu` doc. |
| `CHANGELOG.md` | one sentence |

**Kernel details.**
- **u32 throughout.** `stride = CUBE_COUNT_X*CUBE_DIM_X*run_len` and `off = ABSOLUTE_POS_X*run_len` are u32, and the host guarantees `count + stride ≤ u32::MAX`.
- **Run start.** n is four words `nw` built by a carry chain, then passed to `fd_seed_split16(&nw, …)`.
- **Mask.** A `(lo, hi)` tuple through `fd_mask_u32`. CubeCL 0.10 tuples worked first time, so no fallback array was needed.
- **Near-miss number.** `s + (off + i)` by carry chain, on the rare path only.
- **Steps and ripple branch.** Copied from the native kernel.

**Launch.**
- At 32M and R = 128: 977 cubes, with stride 32,014,336.
- The host test covers R ∈ {1, …, 4096} × counts up to 32M.

**Not done, per brief:** no kill switch. The proposal's "lib.rs is unchanged" is superseded by the brief's build-info field and test hooks.

## 2. Native tests (Vast 58556641 `nice-research-l24b-kernel`, RTX 3080, driver 580.159.03, Rust 1.99.1, Mesa 25.2.8 lavapipe, 40 threads)

- **Box tree.** `/root/nice` at 215952d plus `git diff 215952d` applied by `raw-b/scripts/sync.sh`. Before t5–t7, the patch sha256 was 9a66951b…cc83, equal to `git diff 215952d 5d4ce8a`.
- **Scripts:** `raw-b/scripts/t2.sh` … `t7.sh`.
- **Logs:** `raw-b/box/`.

| run | tree | command | result |
|---|---|---|---|
| t1 | pre-clippy-fix | `VK_ICD_FILENAMES=lvp_icd.json cargo test --release -p nice_common --features gpu --lib -- --ignored --exact cubecl_web::tests::<t> --nocapture` × 5 | all ok; `web_fd_matches_cpu_detailed` **430 windows exact** (64 s); `web_fd_seed_matches_cpu` **132/132** (24 s) |
| t3 | pre-fix | CUDA `cubecl_cuda_fd_matches_cpu_detailed` / `_matches_cpu_detailed` / `_reads_back_every_near_miss` | ok 134 s / 4 s / 59 s (bases 10–28: 73 near-misses) |
| t3 | pre-fix | lavapipe native `cubecl_fd_seed_matches_cpu`, `cubecl_fd_matches_cpu_detailed`, `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed` | all ok |
| t3 | pre-fix | clippy | default ok. `gpu`, `gpu,cubecl-spirv` and wasm-client (host) failed: `many_single_char_names` (`l`/`h` in `fd_mask_u32`) and `checked_conversions` (×2). Fixed by renaming to `mask_lo`/`mask_hi` and using `u32::try_from(...).is_ok()`. |
| t4 | fixed | `cargo fmt --all --check`; `cargo clippy -p nice_common --all-targets [ \| --features gpu \| --features gpu,cubecl-spirv] -- -D warnings`; `cargo clippy -p nice-wasm-client --all-targets -- -D warnings` | all rc 0 |
| t5 | 5d4ce8a | the 5 web tests under `taskset -c 0-3 LP_NUM_THREADS=4` (CI runner size) | all ok: fd 59 s, seed 24 s, others 4 s + 1 s + 0 s |
| t6 | 5d4ce8a | the 5 web tests, `--features gpu,cubecl-spirv` (CubeCL's SPIR-V compiler, CI's second lavapipe pass) | all ok: fd 92 s, seed 44 s (+260 s build), kernel 7 s |
| t7 | 5d4ce8a | host `cargo test --release -p nice_common --features gpu --lib` | 221 passed, 43 ignored |
| t7 | 5d4ce8a | WGSL dumps + lint (below); lavapipe native FD suite; CUDA FD suite | all ok (CUDA FD 137 s) |

**`web_fd_matches_cpu_detailed`: the 430 windows.**
- b40 and b50: 13 windows each × 4 shapes (128 / 32M, 61 / 32M, 1 / 32M, 1000 / 333,333).
- Bases 10–25 in full: 13 bases × 4 shapes, 8,669,368 numbers, 45 near-misses.
- The other 29 bases from 27 to 64: 371 windows, which are `windows(b, 1e5)` plus the middle, × {128, 61}.
- Partial runs: 18, of lengths 1, 2, 61, 127, 128, 129, 255, 257 and 100,001 at the b40 and b57 starts, × {128, 61}.
- Near-miss windows: 2. The b49 window holds 20363742218601559; the b40 one holds 1917398732423, asserted present. Each runs × 4 shapes.

**Running the five new tests in CI.** About 85 s per lavapipe pass on 4 cores (naga), and about 140 s on the SPIR-V pass. On the M4 natively it is 22 s + 7 s. The macOS runner's paravirtual GPU was not measured.

**wasm32.** On ivory:
- `cargo clippy --target wasm32-unknown-unknown -p nice-wasm-client --no-deps -- -D warnings`: rc 0 (`raw-b/clippy-wasm32-nodeps.log`).
- Without `--no-deps` it stops at **one pre-existing** `doc_markdown` error, on `LibreWolf` in `cubecl_web.rs:93` (from 0338106e, 2026-08-28, a wasm-only `cfg`). CI does not lint wasm32. I left it alone (`raw-b/clippy-wasm32.log`).

## 3. WGSL (`raw-b/wgsl/`)

- **Dumps.** `CUBECL_DEBUG_LOG` was set during `web_fd_matches_cpu_detailed`, `web_kernel_matches_cpu_detailed` and `web_fd_seed_matches_cpu` on lavapipe:
  - `wgsl-*.log.gz` is the pre-fix tree;
  - `wgsl7-*.log.gz` is 5d4ce8a.
- **Lint.** The lint is `scripts/wgsl-lint.py` from fork `pr/browser-parity-step` (0f87771), copied, not committed. It ran with `--require DetailedFdKernelU32@b --require FdSeedProbeKernelU32@b` for all 44 bases, plus `DetailedKernelU32@40/50/80/97`.
  - Both trees: **122 shaders, 0 flagged, rc 0** (`raw-b/box/t7-lint.log`, `raw-b/wgsl/lint*.txt`).
  - Those are 44 FD, 44 seed probe, and 34 per-number (b10, the 31 ranged bases 27–64, b80 and b97).
- **No division in the hot loop.** Each FD kernel has exactly one more constant division than the seed probe at the same base, the `% HIST_COPIES` (4):

  | base | FD kernel | seed probe |
  |---|---|---|
  | b23 | 103 | 102 |
  | b40 | 278 | 277 |
  | b50 | 465 | 464 |
  | b54 | 489 | 488 |
  | b64 | 824 | 823 |

  The prologue, mask, steps and near-miss path therefore have no division.
- **No 64-bit types.** `grep -c 'u64\|i64'` is 0 on every dump.
- **The five requested bases** are extracted with `raw-a/scripts/kdump.py` into `raw-b/wgsl/web-fd-5bases/DetailedFdKernelU32_b{23,40,50,54,64}.wgsl`: 1,861, 4,105, 5,951, 6,259 and 9,888 lines.

## 4. SwiftShader (ivory, rootless podman `--cgroup-manager=cgroupfs`, `mcr.microsoft.com/playwright:v1.62.0-noble`, Chromium 151.0.7922.34, `nice -n 19`)

- **Setup.**
  - Plain `podman run` fails with "crun: sd-bus call: Permission denied", hence the cgroupfs flag.
  - `run.sh` ran unmodified through a `docker` shim (`~/l24b-work/bin/docker` → `podman --cgroup-manager=cgroupfs`).
- **Harness.** `exp/browser-gpu-harness` `hw/`, copied to `~/l24b-work/harness`. My additions are `raw-b/scripts/{seedprobe,shapes,kshape}.mjs`, which import `./hw/lib.mjs`.
- **Sites.**
  - `site-old` is 215952d's `web/search` + vendor + pkg (wasm sha256 6b0826…3057, build 215952d).
  - `site-new` is the same with 5d4ce8a's pkg (2f357b…ae7d, build 5d4ce8a).

| run (final build) | result |
|---|---|
| `bash wasm-client/e2e/run.sh` | rc 0, 28 s. "CPU and GPU histograms agree exactly"; GPU 2.91e6 n/s (offline field); the b49 near miss 20363742218601559 exact in the GPU submission. |
| `parity.mjs --software --subset ci` | 13 windows, 1,106,584 numbers, 11 near misses, **0 differing**, 13.0 s |
| `parity.mjs --software --subset hw` | 199 windows, 25,471,443 numbers, 50 near misses, **0 differing**, 71.9 s |
| `seedprobe.mjs --software` | 132 windows, 125,448 n, **0 wrong**, 31 s |
| `shapes.mjs --software --subset ci --shapes 0,1,61,64,128,1000:333333` | 78 runs, **0 differing**, 25.7 s |
| control: old build, `parity.mjs --software --subset ci` | 13 windows, 0 differing |
| `adapter.mjs --software`, b40 2e6 warm, 3 rounds interleaved | old 7.36e5 / 7.54e5 / 7.73e5; new 1.06e7 / 1.21e7 / 8.48e6 n/s (ivory is shared, so noisy) |

The WIP build (pre-clippy-fix) gave the same results: CI subset, hw list, seed probe and shapes all had 0 differences (`raw-b/ivory/{parity,seedprobe,shapes}-*`).

## 5. Apple M4 (mayalaran, macOS 26.3 25D125, "Apple M4", 10-core GPU, Metal 4)

- **Work dir.** `~/claude-exp-2026-11-01-webfd` only.
- **Staging.**
  - Node v24.14.1, checked against SHASUMS256.
  - `npm i --omit=optional --ignore-scripts playwright@1.62.0` and `npx playwright install --no-shell chromium` (151.0.7922.34), with the npm cache, `PLAYWRIGHT_BROWSERS_PATH` and `TMPDIR` all inside the directory. That took 56 s.
- **Scripts.** All runs went through `raw-b/scripts/m4/run.sh`, which writes a PID file. The watchdog (3 h) was killed by PID at the end.
- **Logs.** Outputs are in `raw-b/m4/out/`, with logs in `raw-b/m4/logs/`.

**Adapter** (`adapter.mjs --expect-vendor apple`, new build):
- vendor `apple`, architecture `metal-3`, description "" ("Apple M4" with `--enable-webgpu-developer-features`), device 0x0000;
- `isFallbackAdapter` false (on `info`); subgroups 32/32; features include `shader-f16`, `subgroups` and `timestamp-query`;
- `gpu_init` " (BrowserWebGpu, wgpu<wgsl>)";
- build info `{"near_miss_capacity":8192,"batch_size":32000000,"miss_buffer_bytes":163840,"detailed_kernel":"fd"}`;
- warm b40 2e8 rate 4.396e9 n/s. The hardware assertion passed.

**Exactness** (new build, no flags, Tint → MSL):

| run | result |
|---|---|
| `seedprobe.mjs` | **132/132 windows**, 125,448 n word for word, 7.3 s |
| `parity.mjs --subset hw --extra --expect-vendor apple` | **201 windows, 425,471,443 numbers, 50 near misses, 0 differing**, 128 s. Per set: full 13, sme 93, m4fail 40, gain 27, boundary 4, partial 18, nearmiss 2, fallback 2, bench 2 × 2e8. |
| `shapes.mjs --subset hw --set partial,boundary,nearmiss,gain,fallback --shapes 0,1,61,64,128,1000:333333` | 53 windows × 6 = **318 runs, 0 differing** |
| `parity.mjs --set random --random 10` | **440 windows, 341,084,160 numbers, 320 near misses, 0 differing**, 104 s |
| native, naga → MSL: offline test build (`--features cubecl`, Rust 1.99.1, `-j 4`, 107 s) | see below |

**Native (naga → MSL) build.**
- `CARGO_HOME` was an APFS clone (`cp -c -R`) of `~/.cargo/registry/{cache,index}`, plus the 177 lockfile crates missing there and the sparse-index entries for all 515 lockfile names, from ivory (`crates-ship.tgz`, 66 MB).
- **Tests:** all 5 web tests ok:
  - `web_fd_matches_cpu_detailed`: 430 windows, 22 s;
  - seed probe: 132/132, 7 s;
  - `web_kernel_matches_cpu_detailed`, the b49 near miss and 69: ok.
- **Control.** `NICE_METAL_DIV_REPRO=1 metal_half_shift_div_repro` **fails as expected**:
  - variants 0–2 are wrong at every k except 32768;
  - variants 3–5 are exact.

  The compiler fault is still present, so these exact results are a live check.

**Speed.** `speed.sh`: `bench.mjs --rounds 1` per build, interleaved over 3 rounds (old/new, new/old, old/new). Each run is a kernel-only pass followed by a real-page suite (GPU worker, 60 s).
- `pmset -g therm` reported no warning before any run or at the end.
- Load averages were 0.9–1.7, with no other agent on the Mac (no other `claude-exp` dirs).

| | old (215952d) r1 / r2 / r3 | new (5d4ce8a) r1 / r2 / r3 | ratio of medians |
|---|---|---|---|
| suite b40 | 6.594e8 / 6.591e8 / 6.591e8 (89–90 × 2e8) | 4.397e9 / 4.397e9 / 4.379e9 (592–594 × 2e8) | 6.67× |
| suite b50 | 3.820e8 / 3.829e8 / 3.822e8 (52 ×) | 3.859e9 / 3.856e9 / 3.856e9 (521–522 ×) | 10.09× |
| NiceMark | 265 / 265 / 265 | 2171 / 2170 / 2166 | 8.19× |
| kernel b40 (median of 3 after 2 untimed) | 6.560e8 / 6.464e8 / 6.502e8 | 4.386e9 / 4.292e9 / 4.396e9 | 6.75× |
| kernel b50 | 3.815e8 / 3.813e8 / 3.815e8 | 3.861e9 / 3.861e9 / 3.861e9 | 10.12× |
| suite `warmup_seconds` b40 / b50 | 0.33–0.38 / 0.53 | 0.105–0.110 / 0.080–0.084 | — |
| first call − steady (kernel pass) | 0.03–0.04 s | 0.05–0.06 s | — |

**Run length** (`kshape.mjs`, new build, `process_chunk_gpu_shape`, 2e8 windows, 3 rounds, medians):

| R | b40 | b50 |
|---|---|---|
| 0 (per-number) | 6.60e8 | 3.83e8 |
| 64 | 4.255e9 / 4.264e9 (−3.4 % / −3.0 %) | 3.643e9 / 3.650e9 (−5.5 % / −5.3 %) |
| 128 | 4.405e9 / 4.396e9 | 3.854e9 / 3.854e9 |
| 256 | 4.425e9 (+0.7 %) | 3.945e9 (+2.4 %) |

- **Per-number baseline.** The kernel-only R = 0 row reproduces the old build's rates within 1 %, so the per-number kernel is unchanged in speed.
- **Decision rule.** Switch only if ≥ 3 % better on both the M4 and the 9070 XT. 64 is worse and 256 is below the bar on the M4, so 128 stays (9070 XT pending).
- **Why the browser beats native here.** Browser FD (4.40e9 / 3.86e9) is 1.8× the native wgpu FD on this M4 (2.435e9 / 2.187e9). **H (untested):** the native kernel's u64 mask (`1u64 << d`, u64 OR, cast popcount) is emulated on Apple GPUs; the u32 pair is not. A u32 mask in the native wgpu kernel would be a separate, measurable change.

**Machine time.**
- Directory created 17:04:32, removed 17:33:50: **29 min** wall. Processes ran about 15 min of that.
- The first read-only probe was at 17:03:41.

**Cleanup.**
- Watchdog 95323 killed first, then its sleep 98143.
- No processes left.
- `com.google.chrome.for.testing` plist (`LastRunAppBundlePath` into the exp dir) removed with `defaults delete`, then the file.
- Crashpad `settings.dat` (pre-existing since 08-26) left. The Crashpad report dirs are empty.
- No node-gyp or python caches were written (`--ignore-scripts`).

## 6. Interactions and notes for the director

- **Interaction with PR (c)'s WGSL lint step.** `wgsl_dump_for_lint` calls `process_range_detailed_web` at b40/b50 inside the interval. After (b), those calls compile `DetailedFdKernelU32`, not `DetailedKernelU32`, so `--require DetailedKernelU32@40 --require DetailedKernelU32@50` will **fail** once both are in.
  - When (b) is rebased onto (c), add `--require DetailedFdKernelU32@40/50`.
  - Keep a per-number call, for example `process_range_detailed_web_kernel(…, WebKernel::Division)` or a window straddling the range start.
  - `git merge-tree` of (b) with `fork/pr/browser-parity-step` is otherwise clean.
- **Rebase onto main.** (b) is on #230 (7362e18 + 215952d). Against current upstream main (2a1caf2: #227, #229), `git merge-tree` reports only a CHANGELOG conflict.
- **The harness's CI subset** (`ciWindows`) passes on SwiftShader against this build (§4), so (c)'s CI parity step should stay green once (b) lands. It adds no time: the GPU is faster.
- **Worktree litter.** `wasm-client/LICENSE` (wasm-pack's copy) and `wasm-client/e2e/oom` are untracked in `.worktrees/pr-web-fd` and were not committed. `web/search/{pkg,vendor}` are ignored.
- **Vast box 58556641** is idle, at $0.113/h, and self-destroys 6 h after creation (created ~16:44, so ~22:44 UTC). I did not destroy it.
