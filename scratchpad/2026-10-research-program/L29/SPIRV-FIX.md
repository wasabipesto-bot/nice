# L29 SPIR-V fix: the certificate test kernel overflowed the compiler thread's stack (2026-11-01)

PR #235 (`pr/join-top-cert-fast`), CI job "cubecl on lavapipe (Linux)", step "Run device parity tests (CubeCL direct SPIR-V compiler)": `thread 'DSD-4-0' has overflowed its stack`, SIGABRT. Raw logs in `spirv-raw/box/` (the box's `/root/logs`), scripts in `spirv-raw/`, the block counter `spirv-raw/scripts/blocks.py`, the CI log `spirv-raw/ci_job_124718159257.log`.

**Summary**
- **Cause:** `cubecl-spirv` 0.10's `SpirvCompiler::compile_block` compiles a block's successor from inside the block. Its recursion depth therefore grows with the kernel's basic-block count, at about 1.05–1.1 kB of stack a block. It runs on CubeCL's device-server thread `DSD-4-0`, which has Rust's default 2 MiB stack.
  - The PR's test kernel `cert_test_kernel` held two new scans, two lockstep scans and `top_cert` (two more scans) in one kernel: 1,800–2,100 blocks at 3 words.
  - It overflowed at **b47, 3 words** (cap 5, s2 27, s3 40; 1,993 blocks). b50 at 3 words (2,101 blocks) comes next and needs 2.26 MB.
  - naga's WGSL path walks the structured scope instead, so it passed.
- **Production was not overflowing, but the PR cost margin:** the top kernel at b64 went from 580 blocks (main) to 778. Stack high-water across the join parity test was 620 kB on main and 868 kB on the PR (42 % of 2 MiB).
- **Fix** (one commit `6e7475e` on top of the PR's `3eb6e72`, pushed to `pr/join-top-cert-fast`):
  - In `cert_power`, a chunk that lies wholly below c0 is taken as its value. Otherwise its digits are folded in with `select`s, without a branch per digit.
  - The test launches its kernel once per part.
  - Result: the top kernel at b64 has 496 blocks (below main's), with a 512 kB high-water mark. The largest test kernel has 548 blocks, with a 584 kB high-water mark.
- **Same certificates:** the PR's certificate test passes on lavapipe (both compilers) and on CUDA. Counts are identical to L29's: 102,365 intervals, 33,582 kept, 203,413 scanned above c0, 69,824 with the carry. Both lavapipe CI steps, the WGSL lint, CUDA join parity, fmt and three clippy configurations all pass.
- **Speed** (RTX 3060, b62 1e16, 2 rounds interleaved): main 35.18 s/field, PR 32.84 (×1.071), fix 32.09 (**×1.096 over main, ×1.024 over the PR**).

## 1. Reproduction

Box: Vast 58604278 (`nice-research-topcert-spirv`), RTX 3060 12 GB at its 170 W limit, 64 host threads, driver 580.126.09, CUDA 12.8. The lavapipe setup matches CI's: Ubuntu 24.04 `mesa-vulkan-drivers` 25.2.8-0ubuntu0.24.04.4 (llvmpipe, LLVM 20.1.2). The toolchain is the pinned rustc 1.99.1.

The spirv test binary has CI's file name (`nice_common-6773f06445c05522`). The CUDA test binaries reproduce L29's md5s: main `105d68f4`, PR `dfbea0e6`.

| run | result |
|---|---|
| CI step as CI runs it, PR binary (`pr_ci_spirv.log`) | `thread 'DSD-4-0' (7274) has overflowed its stack`, exit 134 |
| `top_certificates_match_the_lockstep_scan_and_the_cpu` alone, default stack (`pr_cert_alone.log`) | the same overflow |
| the same test under gdb, default stack (`pr_segv_gdb.log`) | SIGSEGV on `DSD-4-0`. 1,093 frames: frames #2–#1080 are `SpirvCompiler::compile_block` (1,079 deep), above `compile_kernel` ← `AutoCompiler::compile` ← `KernelTask<…cert_kernels…>` ← `WgpuServer::launch`. Innermost: `compile_operation` → `compile_arithmetic`. That is 2 MiB / 1,079 ≈ 1.9 kB a frame |
| which kernel | the last kernel logged before the abort (`pr_segv_spv.log.gz`) is CertTestKernel b47, 2 words, cap 4. A run with `RUST_MIN_STACK=256MiB` (`pr_cert_spv.log.gz`) compiles next **b47, 3 words, cap 5 (s2 27, s3 40): 1,993 blocks**, then b50 at 3 words (2,101). The rng is seeded, so CI's order is the same |
| stack high-water, that 256 MiB run (`pr_cert_live_rss.txt`) | after b47/b50 at 3 words, the compile thread's 256 MiB stack mapping held **2,256 kB** resident (2 MiB = 2,048 kB) |

- **`DSD-4-0`** is CubeCL's device server (cubecl-common 0.10, `device/handle/channel.rs`: `DS{U|D}-{type}-{index}`). It is spawned with `std::thread::Builder` and no stack size, so it gets 2 MiB. Every kernel the process launches is compiled on it.
- **Why depth follows block count:** in `cubecl-spirv` 0.10, `compile_block` (compiler.rs:339) ends with `compile_control_flow`. That calls `compile_block` on the successor (`ControlFlow::None`), or on then, else and merge (`compile_if_else`, branch.rs). Every block the scan reaches therefore adds a frame until it returns: about one frame per two blocks in these kernels.
- **The PR's earlier lavapipe pass:** L29 ran the new test on lavapipe through naga only. The spirv step was not run, so this was missed.

### Blocks per kernel (OpLabel in the SPIR-V dumps; `scripts/blocks.py`)

Top kernel, from the join parity test's dump (`{main,pr,fix}_parity_spv.log.gz`):

| base | main | PR | fix |
|---|---|---|---|
| 10 | 160 | 199 | 154 |
| 20 | 220 | 271 | 178 |
| 30 | 280 | 340 | 196 |
| 40 | 388 | 496 | 304 |
| 50 | 448 | 589 | 370 |
| 54 | 472 | 619 | 382 |
| 57 | 538 | 727 | 478 |
| 58 | 544 | 736 | 484 |
| 60 | 556 | 748 | 484 |
| 64 | 580 | 778 | 496 |

- The other join kernels are unchanged: join 135, top scan 88, check 84, bucket 28.
- **Test kernel, PR (one kernel):** 1,807 (b58), 1,843 (b60), 1,891 (b62), 1,927 (b64), 1,993 (b47, 3 words), 2,101 (b50, 3 words).
- **Test kernel, fix (three parts):** at most 548 blocks (lockstep part, b50/b57 at 3 words). `top_cert` part: 485. New-scan part: below that.

### Stack high-water (gdb at exit, `RUST_MIN_STACK=256MiB`, resident pages of the compile thread's stack mapping; `stack.sh`, `stackhw.py`)

| run | high-water | of 2 MiB |
|---|---|---|
| join parity test, main | 620 kB | 30 % |
| join parity test, PR | 868 kB | 42 % |
| join parity test, fix | 512 kB | 25 % |
| certificate test, fix (`NICE_TEST_CERT_SAMPLES=200`) | 584 kB | 29 % |
| certificate test, PR (live, after b47/b50 at 3 words) | 2,256 kB | 110 % |

- Each high-water mark divided by its largest kernel's blocks comes to 1.03–1.12 kB a block.
- On the PR, 2 MiB runs out at about 1,900–1,950 blocks: b64's 1,927 compiled and b47's 1,993 did not. That is consistent, since depth depends on shape, not only on count.

## 2. The fix

`common/src/cubecl_join.rs`, one commit on top of the PR's commit (not squashed, so the delta can be reviewed; squash at will).

**`cert_power`, the digit step.**
- The PR had a branch per digit: `if pos >= c0 { … if in_run { … } else { … } } else { low += … }`. That is about six blocks a digit, for 54–58 digits per top at b58–64.
- Now each pass branches once:
  - **A chunk wholly below c0** is all low digits, so `low = rx` (the chunk is below B = b^cd). This also skips that chunk's digit divisions.
  - **The last pass** can reach past sp, so it always takes the digit path. That keeps the result identical even without relying on x < b^sp. It uses a comptime threshold of `u32::MAX`.
  - **Any other chunk** extracts its digits as before, and updates `run`/`dup`, `runc`/`dupc`, `dlo`, `in_run` and `low` with `select`. A digit below c0 gives `bit = 0`, so it changes nothing but `low`.
- The `start < c0` branch for the remainder is unchanged. It is the same arithmetic in the same order, so the result is word for word the same as the PR's. The test below checks this against the lockstep scan.
- No division was added or moved: the chunk division is the #228 construction, untouched. `rx % base` and `rx / base` act on a remainder, not a shift, so the Metal half-shift rule is unaffected.

**The certificate test.** `cert_test_kernel` takes `#[comptime] part`:
- 0: both new scans.
- 1: both lockstep scans.
- 2: `top_cert`.

`check_cert_group` launches it three times into the same output buffer. Each part recomputes the powers from the interval, so the copies x2/y2/x3/y3 went away.

**Considered, not done:**
- Runtime loops for the passes. These would need B^pass as runtime limbs and would lose the constant limb bounds. The per-pass branch already took the block count below main's.
- Raising the thread's stack in CI (`RUST_MIN_STACK`). This hides the problem, and production's `-gpu` image compiles the same way on the same thread.

## 3. Verification (fix tree = the pushed commit, built on the box; `spirv-raw/box/v/`)

Source md5 `9ab62cee` = `git show 6e7475e:common/src/cubecl_join.rs`. Binaries: spirv `b885d548`, naga `04080ea8`, CUDA `7718acc5` (`md5_bins.txt`; `verify.sh`).

| check | result |
|---|---|
| CI step "Run device parity tests (CubeCL direct SPIR-V compiler)" (`ci_spirv.log`) | **24 passed**, 641 s. The certificate test on `wgpu<spirv>`: 102,365 intervals, 33,582 kept, 203,413 scanned above c0, 69,824 with the carry (L29's counts) |
| CI step "Run device parity tests" (naga), via `cargo test` as CI runs it (`ci_naga.log`) | 29 passed, 432 s; the certificate test on `wgpu<wgsl>` has the same counts |
| CI step "Lint the kernels' WGSL", CI's command and require list (`lint_dump.log`, `lint.log`, `wgsl.log.gz`) | 15 shaders, 0 flagged sites |
| WGSL lint of the certificate test's three parts at every shape (`NICE_TEST_CERT_SAMPLES=2000`; `cert_naga_dump.log`, `lint_cert.log`) | 12 CertTestKernel shaders (one per base as the lint counts them), 0 flagged |
| `cubecl_cuda_join_matches_the_cpu_reference` (`cuda_parity.log`) | ok, 182 s |
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` (`cuda_cert.log`) | ok, same counts, 187 s |
| `cargo fmt --all --check` (`fmt.log`) | clean |
| clippy `-p "*" --all-targets -D warnings`: default, `--features nice_client/gpu`, `--features nice_client/gpu,nice_client/cubecl-spirv` (`clippy_*.log`) | all three clean |

An earlier build of the fix (before two comment edits; same code) also passed the CI spirv step: 24 passed, 613 s (`fix_ci_spirv.log`).

GitHub CI on `6e7475e` is green: "cubecl on lavapipe (Linux)" passed in 16m56s, "cubecl (Metal) on macOS" (MSL compiler) in 12m35s, and Format and clippy, the GPU host tests and the builds also passed.

## 4. Speed (`spirv-raw/box/ab/`)

**Setup**
- RTX 3060 at its 170 W limit. It sat at the cap in every run: median 1890–1905 MHz, 165–169 W, at most 80 °C, throttle 0x4.
- The L29 harness (`cubecl_cuda_join_throughput_fixed_fields`) at b62 7997740455941656911841, 2 × 1e16 after the 1e14 warm-up (`ab.sh`).
- Rounds interleaved main, PR, fix, twice. The box was otherwise idle.

| tree | s/field (rounds) | mean | / main | speed-up |
|---|---|---|---|---|
| main (`105d68f4`) | 35.110, 35.241 | 35.176 | 1 | |
| PR (`dfbea0e6`) | 32.812, 32.876 | 32.844 | ×0.934 | ×1.071 |
| fix (`4534b29e`, the pre-comment-edit build) | 31.878, 32.291 | 32.085 | ×0.912 | **×1.096** |

- **Fix against PR: ×0.977, i.e. ×1.024 faster.** The rounds do not overlap, and spreads are ≤ 1.3 %.
- On L29's 180 W RTX 3080 the PR's gain at b62 1e16 was ×1.089. This card shows ×1.071 for the PR and ×1.096 for the fix.
- **Likely source of the extra 2 %:** chunks wholly below c0 skip their two constant digit divisions. This was not separately measured.
- **Counts:** survivors/checked vary run to run in every tree by the stage overrun's timing, as in L29. For example, main 163,509,936,802 / 163,509,951,029, PR 163,509,925,867 / …845, fix 163,509,945,109 / …936,674. found = 0 everywhere. The exactness evidence is the certificate test, not these counts.
