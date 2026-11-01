# L28: native FD kernel, u32-pair digit mask on wgpu (2026-10-31/11-01)

**Result.**
- **Branch.** `pr/fd-u32-mask` on the fork, head **`2b8d524`**. It is one commit on main 9bde4a8 and is pushed. The PR
  is not opened; its body is `PR-BODY.md`.
- **Exact.** Every requested test passes on CUDA and on lavapipe. So do the browser FD tests and a 132-window sweep of all
  44 FD bases, on CUDA, on lavapipe through naga and on lavapipe through CubeCL's SPIR-V compiler. The host suite and
  fmt and clippy (default, `gpu`, `gpu,cubecl-spirv`) are clean.
- **WGSL.** The lint finds 0 flagged sites. In `DetailedFdKernel`, the lines naming u64 drop from 135 to 32 at b40 and
  from 201 to 34 at b62.
  - The remaining u64 is the per-run prologue, the seed's split of n into words, and the near-miss record. None of it is
    per step.
  - The browser kernels' WGSL is byte-identical to main's.
- **CUDA speed is unchanged.** PR/main is 0.992 (b40), 1.001 (b50) and 0.996 (NiceMark), with main's own b40 runs 1.7 %
  apart.
- **The u32 pair on CUDA is 24 % slower.** With the switch forced to the pair on CUDA, the ratio is 0.766 / 0.763 /
  0.764. That is why CUDA and HIP keep the u64.
  - **Risk.** wgpu devices with native u64 (AMD and NVIDIA under Vulkan) may lose too. Lavapipe agrees in direction,
    at 0.91-0.94×, though noisily.
  - **Recommendation.** If the AMD run loses, key the switch on Metal.
- **Apple M4 and AMD speed: not measured here.** The PR body says so.

## Deviations and choices

- **The tested code is the final code.** The tests ran on 66dd23f (CUDA, lavapipe, host, dumps) and 4132024 (SPIR-V).
  fmt and clippy ran on the final 2b8d524. The three commits differ only in `fd_mask_sc`'s doc comment. The first lint
  pass failed `doc_markdown` on "ORed" (`raw/box/lint-old/`); the reworded doc passes.
- **Design.**
  - The kernel holds the mask as a u32 pair everywhere.
  - `fd_mask_sc(sd, cd, lo, hi, s_from, s_to, c_from, c_to, wide)` does both arrays in one call:
    - with `wide`, it packs the pair into a u64, runs the old `fd_mask` twice and unpacks;
    - otherwise it runs `fd_mask_u32` twice.
  - So the CUDA source changes. It gains pack and unpack lines and its variables are renumbered (`raw/cuda-source-diff.txt`,
    892 → 904 `uint64` lines at b40), but NVRTC folds these: the A/B is flat.
  - The browser kernel still calls `fd_mask_u32` directly, now imported. That kept its WGSL byte-identical.
- **CHANGELOG.** One line, following #230's precedent for internal changes. It makes no speed claim.
- **No divisions in the mask.** The mask code is shifts, masks, a subtract and ORs. All `/` and `%` in it are comptime
  (`j / 4`, `j % 4`).

## The box

- **Machine.** `nice-research-fd-u32mask`, Vast 58589776: an RTX 3060 (driver 580.126.09), Xeon E5-2698B v3, 64
  threads, 188 GiB. The host is shared, with a load average of 15-44 from other tenants.
- **Software.** Rust 1.99.1; lavapipe at `/usr/share/vulkan/icd.d/lvp_icd.json` (llvmpipe, LLVM 20.1.2).
- **Its trees.**
  - `/root/nice` is a clone of the fork with `upstream` (wasabipesto/nice) added for main.
  - `/root/nice-lint` and `/root/nice-spirv` are worktrees with their own target dirs.
  - The binaries are in `/root/bin/{main,fix,u32cuda}-{test,client}` and `/root/bin/spirv-test`.
- **CUDA.** It needed no `LD_LIBRARY_PATH`.
- **NVIDIA Vulkan is not usable here.** `nvidia_icd.json` exists, but the container has
  `NVIDIA_DRIVER_CAPABILITIES=compute,utility`. After `apt-get install libxext6`, `vulkaninfo` still fails with "Could
  not get 'vkCreateInstance'". So the wgpu path could not be timed on the 3060.
- **Times (UTC).**
  - First ssh at 23:25.
  - Builds ran 23:26-00:07: main 12 min cold (crates were already cached), then fix and u32cuda at about 10 min each.
  - Tests and benchmarks ran 23:45-00:30.
- **Self-destruct.** The box was not destroyed (only `list` and `ssh` are allowed). It was at age 1.16 h at 00:31 and
  self-destroys about 03:20.
- **Setup gotcha.** I overwrote `/root/build.sh` while bash was executing it. I killed that run by its process group and
  restarted it before any damage. After that, every changed script got a new name (`build2.sh`).

## Commands and outputs

**Worktree (ivory).** `git worktree add .worktrees/pr-fd-mask origin/main -b pr/fd-u32-mask` (9bde4a8). The edits,
rustfmt and git ran on ivory; `git push -f fork pr/fd-u32-mask` → `2b8d524`.

**Builds.** `scripts/build.sh <label> <rev>` (logs `raw/box/build-*.log`):
- It checks out the rev and appends `scripts/l28_local.rs`, labelled `L28TREE-<label>`.
- It runs `cargo test --release -p nice_common --features gpu --no-run` and `cargo build --release -p nice_client
  --features gpu`, then restores the file.
- The trees and their binaries:

| label | rev | test sha256 | client sha256 |
|---|---|---|---|
| main | 9bde4a8 | 010b14be… | 88fbf547… |
| fix | 66dd23f | 049a081b… | b11c9517… |
| u32cuda | 66dd23f + the patch below | de6693fc… | 3d2fce1f… |

- **The u32cuda patch.** `build2.sh` with `PATCH='sed -i "s/, wide_chunk);$/, false);/; s/0u32, kc_dig, wide_chunk,/0u32, kc_dig,
  false,/"'`. The three `fd_mask_sc` calls get `wide=false` and the seed keeps `wide_chunk`. The diff is in the build
  log.
- Every binary carries its own label (2 hits) and no other.

**Box-local tests** (`scripts/l28_local.rs`, never committed):
- `l28_{cuda,wgpu}_fd_sweep` takes the start, middle and end windows of every base 10-64 with an `fd_plan`, clipped to
  the plan interval. It compares `process_range_detailed_cubecl` against `cpu_detailed_parallel` on distribution and
  near-misses. The width is 1e7 on CUDA and 1e5 on wgpu.
- `l28_dump` is one 1e4 window at `L28_BASE`, used for CUDA source dumps.

**Tests.** `scripts/tests.sh <label> cuda|lvp|dump|cudadump|host` runs `<bin> --ignored --nocapture --test-threads 1
--exact …` from `common/`, with `NICE_API_BASE=http://127.0.0.1:9`.

| run | tests | result | log |
|---|---|---|---|
| fix cuda | `cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed`, `cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed`, `cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss`, `l28_cuda_fd_sweep` | **4 passed**, 519 s | `raw/box/fix/cuda.log` |
| fix lvp | `cubecl_fd_seed_matches_cpu`, `cubecl_fd_matches_cpu_detailed`, `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed`, `cubecl_web::tests::web_fd_matches_cpu_detailed`, `web_fd_seed_matches_cpu`, `l28_wgpu_fd_sweep` | **7 passed**, 200 s | `raw/box/fix/lvp.log` |
| spirv lvp (`scripts/spirv.sh`, `--features gpu,cubecl-spirv`, device `(Vulkan, wgpu<spirv>)`) | the four native FD tests and `l28_wgpu_fd_sweep` | **5 passed**, 142 s | `raw/box/spirv/lvp-spirv.log` |
| fix host | `<bin>` with no args (= `cargo test --release -p nice_common --features gpu --lib`) | **221 passed, 0 failed, 47 ignored**, 99 s | `raw/box/fix/host.log` |

Detail from those logs:
- **CUDA.**
  - The b40 and b50 benchmark windows (2e8) give "finite differences = division = CPU".
  - Bases 10-28 in full: 73 near-misses.
  - `cubecl_cuda_matches_cpu_detailed` b10/40/62/80: exact.
  - Sweep: "132 windows, 956008104 numbers, 180 near-misses, all exact".
- **Lavapipe, naga.** Bases 10-24: 27 near-misses. Sweep: "132 windows, 10916946 numbers, 28 near-misses, all exact".
- **Lavapipe, SPIR-V.** The sweep line is the same.

**Lint** (`scripts/lint.sh` on 2b8d524, `CARGO_TARGET_DIR=/root/target-lint`):
- `cargo fmt --all --check`: rc 0.
- `cargo clippy -p "*" --all-targets -- -D warnings`: rc 0.
- The same with `--features nice_client/gpu`: rc 0.
- The same with `--features nice_client/gpu,nice_client/cubecl-spirv`: rc 0.
- Logs are in `raw/box/lint/`.

**WGSL** (`tests.sh <label> dump`, which is `wgsl_dump_for_lint` with `CUBECL_DEBUG_LOG`, then `scripts/wgsl-lint.py`
with CI's 13 `--require`):
- Main and fix both give "15 shaders (...), 0 flagged sites", lint rc 0 (`raw/box/{main,fix}/wgsl-lint.out`).
- Lines naming u64 per kernel (`scripts/u64count.py`, `raw/u64count.txt`):

| kernel@base | main | fix | WGSL identical |
|---|---|---|---|
| DetailedFdKernel@23 | 89 | 30 | no |
| DetailedFdKernel@40 | 135 | 32 | no |
| DetailedFdKernel@50 | 167 | 32 | no |
| DetailedFdKernel@62 | 201 | 34 | no |
| DetailedFdKernelU32@40 / @50 | 0 | 0 | **yes** |
| DetailedKernelU32@80, TopFillKernel@57, TopScanKernel | 0 | 0 | yes |
| DetailedKernel@80, NiceonlyKernel@40, Bucket/Check/Join/Top@57 | unchanged counts | | no, but only the order of `var` declarations differs (checked for NiceonlyKernel@40 and DetailedKernel@80) |

- **Lines naming u64 that remain at b40 (32).**
  - 3 `var` declarations: the offset, n_hi and the near-miss x_hi.
  - 18 prologue lines: start_lo/hi, count, stride, offset, `len = u32(count - off)` and `n_hi += 1`.
  - 4 seed lines: `n_lo >> 0`, `>> 32` and their casts to u32. At b62 there are 6, adding `n_hi >> 0`.
  - 7 near-miss record lines: `n_lo + u64(i)`, the carry, and the 4 words.
- **The kernels this PR does not touch.** Their WGSL is the same up to the order of the `var` declarations at the top
  (`l_mut_*`), which CubeCL does not emit deterministically.

**CUDA A/B** (`scripts/bench.sh 60 main fix u32cuda u32cuda fix main`):
- Each run is `/root/bin/<label>-client detailed --benchmark --benchmark-secs 60 --benchmark-json --gpu --gpu-backend
  cubecl-cuda`, with `NICE_API_BASE=http://127.0.0.1:9`. The pings fail and nothing is uploaded ("Not uploading
  (non-interactive …)").
- Each GPU scenario is timed for 27 s. Data: `raw/box/bench/*.json`, `raw/bench-cuda.md`.

| run | build | b40 n/s | b50 n/s | NiceMark |
|---|---|---|---|---|
| 01-main | 9bde4a8 | 1.4617e10 | 1.2932e10 | 7246 |
| 02-fix | 66dd23f | 1.4391e10 | 1.2855e10 | 7169 |
| 03-u32cuda | 66dd23f+patch | 1.1088e10 | 9.8237e9 | 5501 |
| 04-u32cuda | 66dd23f+patch | 1.1101e10 | 9.8433e9 | 5509 |
| 05-fix | 66dd23f | 1.4365e10 | 1.2937e10 | 7185 |
| 06-main | 9bde4a8 | 1.4365e10 | 1.2844e10 | 7159 |

| ratio of medians to main | b40 | b50 | NiceMark |
|---|---|---|---|
| fix | 0.9922 | 1.0006 | 0.9964 |
| u32cuda | 0.7656 | 0.7630 | 0.7643 |

- **Spreads.** Main b40 1.74 %, fix 0.18 %, u32cuda 0.12 %.
- **GPU state.** The SM clock held at 1890-1897 MHz and the temperature at 63-75 °C (`*.smi-*`).

**Lavapipe A/B, a weak proxy** (`scripts/benchlvp.sh 40 main fix fix main`, `--gpu-backend cubecl`, device "llvmpipe
(Vulkan, wgpu<wgsl>)"; `raw/bench-lvp.md`):

| run | b40 n/s | b50 n/s | NiceMark |
|---|---|---|---|
| 01-main | 2.7948e8 | 2.5790e8 | 141 |
| 02-fix | 2.6498e8 | 2.3308e8 | 131 |
| 03-fix | 2.5526e8 | 2.4729e8 | 132 |
| 04-main | 2.9054e8 | 2.5412e8 | 143 |
| fix/main (medians) | 0.913 | 0.938 | 0.925 |

The host's load average ran 6-44 during these runs (other tenants), and the spreads are 1.5-6 %. It is a CPU
rasterizer: u64 is native and its SIMD lanes are wider for u32. Read it only as "same direction as CUDA".

## What is not verified

- **Apple M4 (the motivation) and AMD speed.** Both are pending, as the brief says.
  - The CUDA and lavapipe numbers both say the pair costs more where u64 is native.
  - So on the AMD card, test Vulkan through naga and through SPIR-V, and HIP: HIP keeps the u64 and should be
    unchanged.
- **HIP exactness and speed.** HIP takes the `wide` branch, the same code CUDA runs, but it was not run (no AMD here).
- **Metal exactness.** The mask has no division, so the Apple half-shift miscompile cannot apply to it, and the lint is
  clean. The FD tests and the browser kernel's identical code have passed on an M4 before. This exact build has not.

## Files

- `PR-BODY.md`: the PR description.
- `scripts/`: build.sh, tests.sh, bench.sh, benchlvp.sh, lint.sh, spirv.sh, l28_local.rs, u64count.py, benchtab.py.
- `raw/box/`: every box log: builds, tests, WGSL and CUDA dumps, bench JSON, lint, spirv.
- `raw/u64count.txt`, `raw/bench-cuda.md`, `raw/bench-lvp.md` and `raw/cuda-source-diff.txt` (main → fix CUDA source
  at b40 and b62).
