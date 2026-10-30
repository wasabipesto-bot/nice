# L3 on Apple Metal: PR #225 (GPU detailed by finite differences) on the M4 "mayalaran" (2026-10-30)

**Result. The finite-difference kernel gives wrong answers on Metal.**
- `cubecl_fd_matches_cpu_detailed` fails. All 13 b40 windows pass under all four run shapes. The first b50 window
  (range start, production shape) then fails on the distribution.
- `cubecl_reads_back_every_near_miss` fails at base 23. Bases 10–22 pass.
- `cubecl_matches_cpu_detailed` passes.
- On main, the per-number kernel passes both backend tests on the same device.
- A per-base sweep finds the FD kernel wrong at b23, b27–b30, b49 (mid-range), b50, b52 (mid-range) and b53–b55. The
  per-number kernel is exact in every one of those windows.
- Checked one number at a time, the FD kernel returns the wrong unique count for **77 % of n at the start of b23 and
  87 % at the start of b50**.

**Speed.** On the b40/b50 NiceMark windows the PR is **3.00× and 4.54×** over main, and the detailed GPU NiceMark goes
from 329 to 1,216 (3.70×). Three rounds stayed within 0.3 % of each other, and a 60 s rerun showed no thermal decline.
The b50 rate, though, comes from a kernel that is wrong on this device.

**Backend.** `auto` picked CubeCL wgpu on every run: `GPU initialized: CubeCL wgpu device (Apple M4 (Metal,
wgpu<wgsl>)), batch size 50000000`. That is WGSL → naga 29.0.4 → MSL → Apple's compiler. `cubecl-metal` was not
enabled.

## Machine

- **Hardware.** Apple M4, 10 CPU cores, 16 GiB, on AC power. Load average was about 1.0 before I started.
- **OS.** macOS 26.3 (25D125), the same build as the 10-06 MSL root-cause session. The Metal GPUCompiler is
  32023.864 (from the compiler's error path).
- **Toolchain.** Rust 1.99.1, pinned by rust-toolchain.toml and already installed. No `RUSTUP_TOOLCHAIN` override.
- **GPU stack.** wgpu 29.0.4 and naga 29.0.4. The adapter is `Apple M4`, IntegratedGpu, backend Metal, subgroup sizes
  4–64.

## Trees and builds

- **Source.** Shallow clone of the fork at `pr/gpu-detailed-fd` (`18cba8b`), from GitHub, which was reachable. main is
  a clone of it checked out at `946ec15`.
- **Offline build.** `CARGO_HOME` was inside the experiment directory, as an APFS clone of `~/.cargo/registry`.
  - The Mac's cache lacked 179 lockfile crates, among them `rustls 0.23.46`. I copied the `.crate` files from ivory's
    cache (65 MB tar).
  - After that, `cargo build --offline` and `cargo test --offline` worked with no network.
- **Shared target dir.** Both trees used one target dir, with `cargo clean -p nice_common -p nice_client` before each
  tree's build. Each binary was copied out after its build.
- **Binaries verified by string.** The PR-only error text `detailed run length` appears once in the pr client and test
  binaries and zero times in main's.
- **Build times.** Release `nice_client --features cubecl` took 103 s for pr from cold dependencies and 61 s for main.
  `nice_common` test `--no-run` took 81 s for pr and 56 s for main.

## 1. Exactness on Metal

The test binary is `cargo test --release -p nice_common --features cubecl`, run directly with `--test-threads=1
--nocapture`.

| tree | test | result | time |
|---|---|---|---|
| pr | `fd` filter, non-ignored (`plan_covers_exactly_the_legal_range`) | pass | 0.00 s |
| pr | `cubecl_fd_matches_cpu_detailed` (`--ignored`) | **FAIL** at `b50 range start, run 128, batch 50000000: distribution` | 1.48 s to failure |
| pr | `cubecl_matches_cpu_detailed` | pass (b10 1e6, b40 2e6, b62 2e5, b80 1e5) | 1.22 s |
| pr | `cubecl_reads_back_every_near_miss` | **FAIL** at `base 23: distribution mismatch` | 0.97 s to failure |
| main | `cubecl_matches_cpu_detailed` | pass | 0.83 s |
| main | `cubecl_reads_back_every_near_miss` | pass (bases 10–24 in full) | 0.91 s |

**Reproducible.** A second run with `CUBECL_DEBUG_LOG` set failed at the same two points.

**What passed before each failure.**
- In the FD test, all 13 b40 windows passed under all four shapes. They are the range start, the range end, the window
  straddling the range start, eight random windows, and the two addend digit-gain points.
- The b50 range-start window then failed on its first shape. In left = GPU and right = CPU, both sum to 200,000. The
  GPU histogram is shifted about one bin towards more unique digits.
- At base 23 (546,240 numbers) the GPU histogram is likewise shifted. Bases 10–22 had all passed first.

**Why `cubecl_matches_cpu_detailed` passes.** Its windows avoid the failing bases:
- b10 runs 53 numbers on the FD kernel and the rest on the per-number kernel;
- b40 is a base where FD is exact here;
- b62 and b80 are exact or not served by FD.

### Diagnostics

I added three ad-hoc `#[ignore]` tests to the pr clone on the Mac, all deleted with it. Their sources are in
`pr-raw/m4/scripts/diag*_body.rs`.

**Which run shapes fail (`zz_metal_diag`).**
- At b23 (full range) and at the b50 range start (2e5), all four shapes fail, including `run 1`, where every n is
  seeded by division and never stepped. So the stepping is not to blame. The seed, the digit packing, or the mask
  build is.
- At b24 (full range) and at the b40 range start (2e5), all four shapes are exact.
- The per-number kernel (`DetailedKernel::Division`) is exact on all four windows.

**`NICE_CUBECL_WIDE=1` does not compile.** naga's MSL hits `call to 'select' is ambiguous` (`lhs /
metal::select(rhs, 1u, rhs == 0u)` with u64 operands), so the u64 seed could not be tried on this path. The code
already warns that this is expected for naga.

**Per-base sweep (`zz_metal_sweep`).**
- It covered every base 10–64 that has a range: 1e5 numbers at the range start and 1e5 mid-range (79 windows in 44
  bases), production shape, each against the CPU.
- The per-number kernel is exact in all 79 windows.
- The FD kernel fails in these windows:

| base | range start | mid-range |
|---|---|---|
| b23 | fail | fail |
| b27 | fail | fail |
| b28 | fail | exact |
| b29, b30 | fail | fail |
| b49 | exact | fail |
| b50 | fail | fail |
| b52 | exact | fail |
| b53, b54, b55 | fail | fail |

- Every other window is exact: b10–b22, b24, b25, b32–b48, b57–b64 (where n has three limbs), and the cells marked
  exact above.
- Whether a window fails is not a simple function of n's size. b28 fails at its start but not mid-range, between two
  failing magnitudes.
- **Production relevance.** b49–b55 fields run on this kernel on any Apple GPU.

**Wrong unique counts, one n at a time (`zz_metal_wrong_n`).** This runs one launch per n with run length 1, against
`process_range_detailed` on the same n.
- **b23:** 2,297 of the first 3,000 n wrong.
- **b50:** 349 of the first 400 n wrong.
- The errors are ±1–4 unique digits, symmetric. That is why the window histograms differ by only a few percent: wrong
  digit strings have nearly the random-digit distribution.
- **Distribution tests barely see it.** A prefix bisection on distributions reported the "first wrong n" as 795,835.
  795,831 is already wrong, but the first four errors are a permutation of the right counts.
- The `nice_numbers` (near-miss) comparison catches what the histogram misses only where the cutoff is reached.
- **No simple corruption explains the counts.** I tried these models against the 3,400 counts
  (`scripts/hyp.py`); none fits better than "correct":
  - a limb of n² or n³ zeroed or replaced by another limb;
  - n off by 1–3;
  - S or C taken from n+1.

**Root cause: not found.**
- The same WGSL passes on lavapipe (PR body) and on CUDA. So it is either naga's MSL translation or Apple's compiler.
- The 10-06 M4 finding (Apple's compiler divides the low half in `uint(ulong(a)*ulong(b) >> 32) / K`) is the obvious
  suspect, on the same OS build. I did not show that this pattern is the trigger.
- In naga's MSL every constant division in this kernel goes through `naga_div(x, K)`. The 10-06 notes found that
  guarded form correct in the join.
- **Next step for a root cause:** a debug buffer of the seeded S/C digit words for one failing n (b23 n = 795,831),
  compared with the Python model, then the 10-06 Swift harness on naga's MSL.

**Shaders.**
- `pr-raw/m4/shaders/fd_b{22,23,40,50}.wgsl` are the FD kernels CubeCL compiled on the Mac, from the
  `CUBECL_DEBUG_LOG` dumps. b22 and b40 pass; b23 and b50 fail.
- `fd_b*.metal` is the same WGSL translated on ivory by naga 29.0.4 to MSL 2.4 (`scripts/naga-msl`, default options).
  This is a reconstruction; wgpu's own options may differ, e.g. in bounds-check policy.
- The full compile logs, which include the per-number kernel at b40, are `shader-*.log.gz`.

## 2. Speed: `nice_client detailed --gpu --benchmark --benchmark-secs 90`

- **Setup.** Three interleaved rounds, A B A B A B, with `RUST_LOG=info`, `NICE_API_BASE=http://127.0.0.1:9` and stdin
  `/dev/null`.
- **Timing.** About 40.5–40.7 s timed per scenario. The GPU sweep skips the single-thread scenario.
- **Units.** Rates are numbers per second.

| tree | b40_detailed r1 r2 r3 | median | spread | b50_detailed r1 r2 r3 | median | spread | NiceMark |
|---|---|---|---|---|---|---|---|
| main | 8.109 8.116 8.118 e8 | **8.116e8** | 0.11 % | 4.812 4.810 4.814 e8 | **4.812e8** | 0.08 % | 329 329 329 |
| pr | 2.437 2.433 2.440 e9 | **2.437e9** | 0.29 % | 2.182 2.184 2.183 e9 | **2.183e9** | 0.09 % | 1216 1215 1216 |

| ratio pr / main | b40 | b50 | NiceMark |
|---|---|---|---|
| medians | **3.003×** | **4.537×** | **3.696×** |
| per round | 3.005, 2.998, 3.006 | 4.534, 4.541, 4.535 | 3.70 each |

- **Comparison.** On the 4090 the same windows gave 3.46× and 3.92×. The M4 gains less at b40 and more at b50.
  - The M4 takes the split16 seed, by the PR body's count about 4 divisions per number at 128 per run, against about 200 per number for
    main's split16 scan. So main's b50 is especially slow here.
  - The b50 figure is a work rate only: on this device that kernel is wrong at b50.
- **No warnings or fallbacks.** No run logged a warning, an error or a fallback.
- **API latency** reads "unavailable" by design (dead API base). No uploads.

## 3. Stability: pr, `--benchmark-secs 60`, right after the six runs

b40 **2.444e9**, b50 **2.193e9**, NiceMark **1,220**. These are 0.3 % and 0.5 % above the 90 s medians, so there is no
thermal or throttling decline over about 9.5 minutes of back-to-back GPU load.

## Odd things

- **The window tests nearly miss this bug.** On Metal, 77–87 % of numbers are wrong, yet window histograms move only a
  few percent and can match exactly over short prefixes.
  - An FD bug that is rarer, or confined to fewer digits, could pass `assert_shapes_match` on a 1e5 window.
  - A per-number check, such as a hash of (n, unique count) over a small window, would be far stronger than histogram
    equality.
- **CI had not run the Metal tests.** The "cubecl (Metal) on macOS" job on PR #225 was still **pending** when I checked
  (about 15:10 UTC). It runs these wgpu tests through naga's MSL. On a paravirtual Metal device it may or may not
  reproduce this.
- **Offline cache gap.** The Mac's cargo cache lacked 179 lockfile crates. The next offline session needs ivory's
  `.crate` files again.

## Cleanup

- **Machine time.** About 29 minutes in total: first ssh 14:59:46 UTC, last 15:28:37 UTC.
- **Watchdog.** A 3,450 s watchdog ran throughout. Every job ran under a wrapper that registered its PID and
  deregistered it on exit. At the end the PID file was empty.
- **Processes.** I killed the watchdog (PID 50406) and then its `sleep` (50408), parent first, and confirmed both gone.
- **Directory.** I removed `~/claude-exp-2026-10-30-fd`. `test -e` reports it gone, and `~/claude-exp-*` matches
  nothing.
- **Final check.** A `ps` filter for `nice_client`, `nice_common`, `watchdog.sh`, `cargo`, `rustc` and `claude-exp`
  matched only the check's own login shell.
- Nothing outside that directory was touched, and nothing was pushed.

## Raw files (`pr-raw/m4/`)

- `tests-pr.log`: pr tests.
- `dump-pr.log`: the rerun with the shader dump.
- `maintests.log`: main tests.
- `diag.log`: shapes, plus the `NICE_CUBECL_WIDE=1` compile error.
- `diag2.log`: the per-base sweep.
- `diag3.log`: per-n results.
- `bench-r{1..6}-{main,pr}.log`: the A/B runs.
- `bench-s1-pr.log`: the 60 s rerun.
- `build-*.log` and `testbuild-*.err`: the builds.
- `shader-*.log.gz` and `shaders/`: the shader dumps and MSL translations.
- `scripts/`: the scripts and diagnostic test bodies.
