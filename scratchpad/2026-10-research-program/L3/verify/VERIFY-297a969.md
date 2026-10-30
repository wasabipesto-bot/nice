# 297a969 (`pr/gpu-detailed-fd-metalfix`) on an RTX 3080: CUDA and lavapipe (2026-10-30)

**Result: everything that ran passes.**
- Lint, build, host tests, CUDA FD tests, and the lavapipe tests including `cubecl_fd_seed_matches_cpu` all pass.
  The seed test found 132 of 132 windows exact.
- The production path takes the FD kernel on CUDA and on wgpu (lavapipe) at b40/b50.
- CUDA speed is unchanged against the PR before the fix (18cba8b) on the same card: 1.000× at b40 and 0.999× at b50.
- **This card is capped at 150 W, not 320 W**, so its absolute rates are about 15 % below the earlier 320 W numbers.

## Box

- Vast 58428313 `nice-research-fd-verify`, RTX 3080 **10 GB** (the earlier 3080 was the 20 GB variant), driver
  580.159.03 (CUDA 13.0), 20 vCPU, 15 GB RAM. Created 17:06:40 UTC. I used it from 17:08 to 17:41 UTC.
- **Power limit:** `nvidia-smi -q -d POWER` gives Current = Requested = **150.00 W**, Default = Max = 320.00 W and
  Min = 100 W. It was the same before and after the runs. Every loaded `dmon` sample read 149–150 W, with the SM clock
  at a median of **1545 MHz** (the earlier box ran at 317 W and 1860 MHz).
- Toolchain 1.99.1 (from `rust-toolchain.toml`). Mesa llvmpipe (LLVM 20.1.2), Vulkan 1.4.318.
- Tree: `git fetch origin pr/gpu-detailed-fd-metalfix && git checkout 297a969`, and `git status` was clean before and
  after. Raw logs are in `L3/verify/box/` and the box scripts are `L3/verify/box-v{1..4}.sh`.
- Added to the box: `libpq-dev` (for clippy over `nice_api`, as in the gate run) and `libxext6`.
  - `libxext6` was an attempt to load the NVIDIA Vulkan ICD. It did not work: "Could not get 'vkCreateInstance'". The
    container exposes `compute,utility` only.
  - **So NVIDIA-Vulkan was not available.** Every wgpu test ran on llvmpipe, and the default wgpu device is llvmpipe
    too (`GPU initialized: CubeCL wgpu device (llvmpipe ...)` without `VK_ICD_FILENAMES`).

## 1. Lint and build (`box/v1.log`)

| command | result |
|---|---|
| `cargo fmt --all --check` | **pass** |
| `cargo build --release -p nice_client --features gpu` | **pass** (4 m 15 s), sha256 `2512664025c0…` |
| `cargo clippy -p "*" --all-targets -- -D warnings` | **pass** |
| `cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings` | **pass** |
| `cargo clippy --all-targets --features gpu -- -D warnings` | **pass** |
| `cargo test --release -p nice_common --features gpu --no-run` | **pass** |

The justfile's `lint` recipe has `fmt` and **two** clippy lines. The third clippy line above is the extra one from the
gate script (`box-gate.sh`).

## 2. Host tests (`box/host.log`, `box/host-full.log`)

`cargo test --release -p nice_common --features gpu`: **pass**.
- lib: 209 passed, 0 failed, 40 ignored.
- The three integration-test binaries and the doctests have 0 tests each.

The gate run had 210 passed and 38 ignored. The new count is consistent with this branch:
- d9261a8 adds two ignored tests (the seed test and the reproducer);
- the revert removes the gate's `detailed_kernel_by_device`.

## 3. CUDA (CubeCL CUDA runtime; `box/tests-cuda.log`, `box/cuda-*-full.log`)

The ignored tests whose names contain `fd`, `seed` or `detailed` (`box/ignored.txt`) are listed below.
- On CUDA: `cubecl_cuda_fd_matches_cpu_detailed`, `cubecl_cuda_matches_cpu_detailed` and the hand-CUDA
  `gpu_matches_cpu_detailed_small`.
- wgpu-only (run in section 4): `cubecl_fd_matches_cpu_detailed`, `cubecl_fd_seed_matches_cpu`, `cubecl_matches_cpu_detailed`,
  `web_kernel_matches_cpu_detailed` and `cubecl_detailed_survives_more_batches_than_the_task_cap`.
- **There is no CUDA form of the seed test.** `cubecl_fd_seed_matches_cpu` is hard-wired to wgpu (`new_default`, then
  `WgpuRuntime`).

All runs used `RUST_LOG=debug ... -- --ignored --nocapture --test-threads=1 --exact <name>`.

| test | result |
|---|---|
| `cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed` | **pass** (91.9 s) |
| `cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed` | **pass** |
| `cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss` | **pass**, 73 near-misses (b10–28 in full) |
| `client_process_cuda::tests::gpu_matches_cpu_detailed_small` (hand CUDA, not FD) | **pass** |

`cubecl_cuda_fd_matches_cpu_detailed` passed every window at b40 and b50:
- range start, range end, straddling the start, random 0–7, and the dS/dC digit-gain points;
- 1e6 numbers each, under every FD run shape;
- the 2e8 benchmark window, where "finite differences = division = CPU";
- b10–28 in full, 73 near-misses.

`cubecl_cuda_matches_cpu_detailed` matched the CPU exactly at base 10 (1e6), 40 (2e6), 62 (2e5) and 80 (1e5).

**Kernel per window.**
- **`RUST_LOG=debug` prints nothing in these tests.**
  - The CubeCL tests are plain `#[test]` with no logger, so the full logs hold no `debug!` lines.
  - Only the hand-CUDA tests use `#[test_log::test]`.
  - At 297a969 the per-window line no longer names the kernel either: the revert of d8038d6 removed `({kernel:?})`.
    It now reads `CubeCL detailed b40: 2.00e8 numbers in ...`.
- **The kernel served is therefore taken from the code, plus one diagnostic build:**
  - `cubecl_cuda_fd_matches_cpu_detailed` names its kernel explicitly. Every window runs under
    `FiniteDifference { run_len, batch }` for each of `SHAPES`, and the benchmark window runs under both `DEFAULT` (FD)
    and `Division`.
  - The production-path tests (`cubecl_cuda_matches_cpu_detailed`, `..._reads_back_every_near_miss`) call
    `process_range_detailed_cubecl`, which calls `DetailedKernel::for_base(base)`. That is FD wherever `fd_plan(base)` is
    `Some`: the 44 bases 10–64 that have a range (all but 11, 16, …, 61). Above `FD_MAX_BASE` = 64 it is `Division`.
    So b10, b40 and b62 ran FD, b80 ran the per-number kernel, and b10–28 in the readback test ran FD.
  - **The diagnostic build** (`box/bench.log`, `diag-*`) re-added `({kernel:?})` to that one `debug!` line by `sed`. It
    is a separate binary, and the file was restored afterwards. In it, the production benchmark path logged:

    | device | b40 | b50 |
    |---|---|---|
    | CUDA | 650 windows `FiniteDifference { run_len: 128, batch: 50000000 }` | 562 windows, the same |
    | llvmpipe | 14 windows, the same | 13 windows, the same |

    No window ran `Division`.

## 4. lavapipe (`box/tests-lvp.log`, `box/lvp-full.log`)

`VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json` (as in `box-gate2.sh`), `RUST_LOG=debug`,
`-- --ignored --nocapture` over the gate's five tests plus `cubecl_fd_seed_matches_cpu`. The six tests ran in 30.5 s.

| test | result |
|---|---|
| `cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu` | **pass**: 132 of 132 windows exact (1024 n at start, middle and end of all 44 bases 10–64), 0 "wrong n per array" lines |
| `cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed` | **pass**: b40/b50 windows at 1e5 under every shape, b10–24 in full (27 near-misses) |
| `cubecl_backend::tests::cubecl_reads_back_every_near_miss` | **pass**, 27 near-misses |
| `cubecl_backend::tests::cubecl_matches_cpu_detailed` | **pass** (b10, b40, b62, b80) |
| `cubecl_backend::tests::cubecl_finds_69_in_base_10` | **pass** |
| `cubecl_web::tests::web_kernel_near_miss_matches_cpu_at_base_49` | **pass** |

- **The production path on wgpu takes FD.**
  - The gate is lifted at this head: `for_base` has no device argument.
  - The diagnostic build logged `FiniteDifference` for every b40/b50 window on llvmpipe (table above).
  - The unmodified 297a969 benchmark on llvmpipe (`--gpu-backend cubecl`, 10 s) gave b40 5.442e8, b50 5.129e8 and
    NiceMark 278. That is the FD level: the gate tree's FD on lavapipe, on the earlier box, gave 4.78e8 and 4.37e8.

## 5. Speed (CUDA, `--gpu` = CubeCL CUDA; `box/bench.log`, `box/ab.log`)

`RUST_LOG=info,nice_common::cubecl_backend=debug NICE_API_BASE=http://127.0.0.1:9 ./target/release/nice_client
detailed --gpu --benchmark --benchmark-secs 60`, twice. Then the same pair again, interleaved against 18cba8b (PR #225
before the fix) built on this box. The 18cba8b binary's sha256 is `4d5f9dfdf924…`, byte-identical to the earlier gate
box's "base" binary. Each run times 27 s per scenario.

| run | b40 (n/s) | b50 (n/s) | NiceMark |
|---|---|---|---|
| 297a969 #1 | 2.871e10 | 2.497e10 | 14113 |
| 297a969 #2 | 2.846e10 | 2.509e10 | 14086 |
| 18cba8b (A/B round 1) | 2.876e10 | 2.515e10 | 14173 |
| 297a969 (A/B round 2) | 2.861e10 | 2.521e10 | 14154 |
| 18cba8b (A/B round 3) | 2.845e10 | 2.495e10 | 14042 |
| 297a969 (A/B round 4) | 2.861e10 | 2.474e10 | 14022 |
| **297a969, median of 4** | **2.861e10** | **2.503e10** | 14100 |
| 18cba8b, mean of 2 | 2.861e10 | 2.505e10 | 14108 |
| **297a969 / 18cba8b** | **1.000** | **0.999** | 0.999 |

- **The numbers do not match the requested 3.3e10 / 3.0e10, because of the power cap.** The earlier figures are FD at
  320 W, from `PR-RESULTS-3080.md`: 3.35e10 / 2.98e10, at 317 W and 1860 MHz. This card is held at 150 W (149 W
  measured), with the SM clock at 1545 MHz.
  - The rate ratios to those figures are 0.854 (b40) and 0.840 (b50).
  - The clock ratio is 0.83, so the gap is the cap.
  - Against the same-box reference the fix costs nothing on CUDA, as expected: the CUDA wide seed path is unchanged code,
    only moved into `fd_seed`.

## 6. Metal reproducer (`box/repro-*-full.log`)

`NICE_METAL_DIV_REPRO=1 cargo test ... -- --ignored --nocapture --exact cubecl_detailed_fd::tests::metal_half_shift_div_repro`:
- **pass on llvmpipe**: all 36 (variant 0–5 × k) cases have 0 of 1024 wrong;
- **pass on the default wgpu device**, which here is also llvmpipe.

**It could not run "on CUDA".**
- The test is wgpu-only: it is `new_default` with a `WgpuRuntime` launch, and there is no CUDA form.
- NVIDIA Vulkan is not available in this container, so it did not run on the 3080 at all.

## Not run / caveats

- **The seed test and the reproducer did not run on NVIDIA hardware.** Both are wgpu-only, and NVIDIA-Vulkan is
  unavailable in the container. The CUDA wide seed is covered indirectly by `cubecl_cuda_fd_matches_cpu_detailed`.
- `web_kernel_matches_cpu_detailed` and `cubecl_detailed_survives_more_batches_than_the_task_cap` were not run: they
  are wgpu-only and outside the gate set. The batch-cap test skips on software rasterizers anyway.
- "Kernel per window" for the tests comes from the code and from the diagnostic benchmark, not from a test log, because
  the tests print no debug lines.
- No speed number at 320 W: the box's limit is 150 W, and I did not try to change it.
- The box is idle, with no processes left, and self-destroys at about 19:06 UTC. Nothing was pushed.
