# L30 PR: the walk prefilter as production code (`pr/join-prefilter-in-walk`), RTX 3080 at 180 W, 2026-11-01

Branch `pr/join-prefilter-in-walk` on the fork, one commit on upstream main `fae7398`. PR text: `L30/PR-BODY.md`. Raw logs: `L30/pr-raw/box/`, scripts `L30/pr-raw/scripts/`, analysis `L30/pr-raw/analyze.py` (output `L30/pr-raw/analysis.txt`).

## Summary

TBD

## 0. Setup

- **Box:** Vast 58605134 (`nice-research-l30-pr`), machine m139250 (the prototype's and PROFILE-3's).
  - RTX 3080 10 GB, driver 580.159.03, CUDA 13.0 driver API; nvcc/ptxas 12.8 for the register counts.
  - **Power limit 180 W** (default 340, max 374; `box/power.txt`); max SM clock 2,115 MHz. Under load the card sits at the cap (clocks per run below).
  - Xeon E5-2630 v4, cgroup quota 9.6 CPUs (`box/nproc.txt`).
- **Binaries** (all from `git archive`/tar of ivory trees, built on the box with `scripts/build.sh`, toolchain 1.99.1 from `rust-toolchain.toml`, shared target dir with `cargo clean -p nice_common` before each build, one build at a time; each binary verified by md5 and, for the PR, by a string only it has):
  - `main` 105d68f4: `cargo test --release -p nice_common --features gpu --no-run` at `fae7398`.
  - `pr2` fdf70a5f: the same at the PR tree. (`pr1` was a build that raced the next one's `cargo clean` and was never used.) The committed tree differs from `pr2`'s only by one rustfmt line break (`b2k` in `walk_pf`).
  - `pr_wgpu` cbdfae99 (`--features cubecl`, naga) and `pr_spirv` a894a40c (`--features cubecl-spirv`), PR tree.
  - `client_main` 600b0288, `client_pr` 1e4daa2e: `cargo build --release -p nice_client --features gpu`.
- **Fields:** b62 7997740455941656911841, b60 1366406074057412100454, b64 41242006262957161709568 (the throughput harness's/PROFILE-3's starts), b57 frontier 28151599893042801193 for 1e14. Every run process starts with an untimed 1e14 warm-up field (JIT).
- **A/B protocol:** `scripts/chainC.sh`: per scenario A B A B A B (A = `main`, B = `pr2`), nothing else on the box meanwhile, `run.sh` = `cubecl_cuda_join_throughput_fixed_fields` with `NICE_TEST_JOIN_FIELDS/SIZE/BASES/STARTS`; the metric is the harness's `device=` (mean device wall seconds per field, unprofiled). `.smi` traces every 5 s; "clock" = mean SM MHz over samples at ≥ 90 % utilisation.

## 1. Exactness

All on `pr2` (CUDA) or `pr_wgpu`/`pr_spirv` (lavapipe); logs in `pr-raw/box/`.

| test | command (`scripts/test.sh NAME BIN TEST ENV`) | result | log |
|---|---|---|---|
| CPU reference, every window (b10-b64, k = 1..6, key level or not, b50/b54), b57 frontier partitions, tight layouts, slices, refused layouts | `cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference` | ok (87 s) | `pr2_ref.log` |
| dense b58 1e15, 32 partitions | `..._on_a_dense_field`, `NICE_TEST_JOIN_DENSE=32` | 254,938,965 / 14,396,829 = CPU join (asserted equal) | `pr2_dense58.log` |
| dense b62 1e16, 4 partitions | same + `NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16` | 120,013,475 / 7,355,827 = CPU join | `pr2_dense62.log` |
| main's kernel on the same two | `main` binary | b58: 254,938,965 / 14,396,829, 0 overran; b62: 120,011,463 / 7,357,700, **2,012 overran (1.7e-5)** | `main_dense58.log`, `main_dense62.log` |
| whole b42 1e13 field vs the threaded reference, and the stride pipeline | `..._reference_on_a_whole_field`, `NICE_TEST_JOIN_FULL_FIELD=1` | 1,764 partitions, 417,789,835 / 16,879,877, no hits; equal; stride agrees | `pr2_full42.log` |
| 1e14 at b57/60/62/64, `NICE_TEST_JOIN_COMPARE=1` | `scripts/run.sh NAME BIN 57,60,62,64 1 1e14 1` | table below; stride agrees | `pr2_cmp_e14.log`, `m_cmp_e14.log` |
| lavapipe, CubeCL direct SPIR-V | `pr_spirv --ignored cubecl_join:: --test-threads 1`, `RUST_MIN_STACK` unset | 5 passed (109 s); no stack overflow | `lvp_spirv.log` |
| lavapipe, naga WGSL | `pr_wgpu --ignored cubecl_join:: --test-threads 1` | 5 passed (86 s) | `lvp_naga.log` |
| WGSL lint | `CUBECL_DEBUG_LOG=... pr_wgpu --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint`; `scripts/wgsl-lint.py` with CI's 13 `--require`s | 15 shaders, 0 flagged; JoinKernel b57 34 constant divisions, BucketKernel b57 46 | `wgsl_lint.log`, `wgsl.log.gz` |
| fmt, clippy `-D warnings`: default, `nice_client/gpu`, `nice_client/gpu,nice_client/cubecl-spirv` (all `-p "*" --all-targets`) | `scripts/lint.sh` | clippy clean ×3; fmt flagged one line break (`b2k` in `walk_pf`), fixed in the commit (re-checked: see §5) | `lint_*.log` |
| host suite | `cargo test --release -p nice_common -p nice_client` (+ `--features nice_client/gpu`) | default: 180 + 22 passed; gpu: 221 + 23 passed | `host_default.log`, `host_gpu.log` |

1e14 (one field per base, the frontier/throughput starts), counts identical (main is deterministic here: no overrun):

| base | join survivors (main = PR) | checked (main = PR) | hits | plan MiB main → PR |
|---|---|---|---|---|
| 57 | 4,850,227,888 | 268,123,373 | 0 | 1185 → 1193 |
| 60 | 2,694,700,282 | 180,517,288 | 0 | 1192 → 1201 |
| 62 | 1,439,469,648 | 88,159,810 | 0 | 1359 → 1369 |
| 64 | 5,702,041,796 | 346,647,759 | 0 | 1402 → 1413 |

Registers (`scripts/regs.sh`: CubeCL's CUDA for b62 from `CUBECL_DEBUG_LOG`, `nvcc -cubin -arch=sm_86 -O3 -Xptxas -v`; `pr-raw/box/sass/`): join kernel 62 → **39** (SASS 1,672 → 784); bucket kernel 34 → 39 (296 → 344). The prototype (`xm = 256`) had 44 and 1,328: the production flush is a plain copy (one atomic per stage, no plane compaction), which the prototype kept.

## 2. A/B (`scripts/chainC.sh`, 03:06-03:50 UTC, nothing else on the box)

Device seconds per field (`device=`), A = main (`fae7398`), B = PR; rounds interleaved A B A B A B. Spread = (max − min) / median. Clock = mean SM MHz at ≥ 90 % utilisation; both kernels sit at the 180 W cap (178-180 W).

| field | A: main | B: PR | **B/A (medians)** | per-round B/A | saving per field | clock A / B (MHz) | clock-normalised |
|---|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | 222.52, 226.09, 225.87 (median 225.87, spread 1.6 %) | 184.29, 185.96, 186.01 (185.96, 0.9 %) | **×0.823** | 0.828, 0.823, 0.824 | **−39.9 s** | 1457 / 1468 | ×0.829 |
| b62 1e16, 2 fields | 17.986, 18.019, 18.482 (18.019, 2.8 %) | 15.158, 15.241, 15.380 (15.241, 1.5 %) | **×0.846** | 0.843, 0.846, 0.832 | −2.78 s | 1506 / 1483 | ×0.833 |
| b60 1e16, 2 fields | 42.111, 42.119, 42.909 (42.119, 1.9 %) | 33.794, 33.945, 34.079 (33.945, 0.8 %) | **×0.806** | 0.802, 0.806, 0.794 | −8.17 s | 1459 / 1476 | ×0.816 |
| b64 1e16, 2 fields | 51.884, 53.546, 52.998 (52.998, 3.1 %) | 40.735, 40.733, 40.078 (40.733, 1.6 %) | **×0.769** | 0.785, 0.761, 0.756 | −12.27 s | 1453 / 1456 | ×0.770 |

- Against the prototype (same machine, `xm = 0` control): b62 1e17 ×0.833 → ×0.823, b62 1e16 ×0.839 → ×0.846, b60 ×0.803 → ×0.806. b64 was not measured before.
- No scenario regresses: the worst per-round ratio is 0.846, against control spreads of at most 3.1 %.
- Layouts identical A/B: slots 5 (b62 1e17), 13 (b62 1e16), 4 (b60), 6 (b64); plan MiB +4, +9, +2, +4.

### Counts at 1e16/1e17

The PR's counts are the same in every run, and equal to the prototype's exact counts (and PROFILE-3's join survivors) at b62 1e16, b62 1e17 and b60 1e16. Main's vary run to run: the stage's overflow skipped the prefilter and the survivor count. (The order of a bucket's tops comes from the top-fill kernel's atomics, so which chunk a pair falls in, and how many overrun, changes between runs.)

| field | PR join survivors | PR checked (= prefilter survivors = full checks) | main: overrun (PR − main survivors), per run | main checked − PR checked | of which would have passed (overrun − difference) | hits |
|---|---|---|---|---|---|---|
| b62 1e17 | 1,020,844,021,499 | 62,584,252,554 | 115,730,119; 115,702,770; 115,686,592 (**1.13e-4**) | 108,548,196 (largest-overrun run) | 7,181,923 (6.2 %) | 0 |
| b62 1e16 ×2 | 163,513,599,082 | 10,027,698,695 | 3,393,617; 3,381,213; 3,370,311 (2.1e-5) | 3,183,152 | 210,465 (6.2 %) | 0 |
| b60 1e16 ×2 | 460,847,952,346 | 30,871,838,404 | 1,800,612,705; 1,800,528,749; 1,800,430,107 (**3.9e-3**) | 1,679,853,275 | 120,759,430 (6.7 %) | 0 |
| b64 1e16 ×2 | 787,584,956,227 | 47,900,853,327 | 22,677,365; 22,641,440; 22,625,753 (2.9e-5) | 21,281,689 | 1,395,676 (6.2 %) | 0 |

So main's list = the PR's list − (the overrun's own prefilter survivors) + the overrun, to the pair, and the keep rate of the overrun pairs is the field's keep rate (6.1-6.7 %). At b60 main ran 5.4 % more full checks than needed.

## 3. NiceMark nice-only

TBD

## 4. Code: what changed against the prototype (`exp/join-survivors` `xm = 256`)

- No switch: the walk prefilter is the only path. `mid_pass`, the flush-time prefilter, the flush's plane compaction (`plane_tot`) and `ext_pk` are deleted. The flush is one `fetch_add` for the whole stage and a coalesced copy.
- **Every shape, not only the production one.** The prototype refused anything but `f0 3, k 6, k2 8`, key level. The PR adds, under `comptime`, the terms that vanish there, mirroring `cpu_join`: `e1 = b^(k-1) mod M` (`d²` in t2, `3R'·d²·b^(k-1)` in t3), `e2 = b^(2k-2) mod M` (`d³`), `kb` (the key digit's part of `R mod b^mid`), and in `walk_pf` `bk = b^k mod b^mid`, `b2k` (the `D²` terms when `k < mid`, then `pc`'s low half holds `R mod b^mid`); `R' mod M` adds the slot's partition digits (read from the first top's `P mod b^(k2-f0)`) when `f0 < mid + 1`; non-key-level shapes store their carries and `2R`, `3R²` directly. All test windows (b10 k=1 through b64) now run the new code; they passed on CUDA, naga and SPIR-V.
- `ext_q` replaces `ext_pk` (the prototype allocated both); the key digit's output digits come from `t2 % b`, `t3 % b`. `key_at_zero` left the join kernel (the general formula covers k = 1).
- `2·r0` is not reduced mod M before the multiply (`Q2 + d·2σ < 2^26`).
- `Footprint.ext_q` = 8 B per entry (was `ext_pk` 4 B); `JoinDevice::new` refuses `b^(mid+1) > 2^18` (never at b ≤ 64).
- Counters: `and_count` (was `staged`) counts join survivors per thread in the walk, one atomic per plane; `JoinFieldStats` docs say both counts are exact. The dense-field test asserts equality with the CPU join (was: overrun ≤ 1e-4, checked within the overrun).
- Merge with #235 (`fork/pr/join-top-cert-fast` 3eb6e72): `git merge-tree` auto-merges `cubecl_join.rs`; CHANGELOG conflicts (both add the first Unreleased line).
