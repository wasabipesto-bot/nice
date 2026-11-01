# L29 RESULTS: GPU top certificate from one endpoint's digits and a carry test (2026-11-01)

Branch `pr/join-top-cert-fast` on the fork, one commit `d6cc9da` on upstream main `9bde4a8`. PR body: `PR-BODY.md`. Raw logs: `raw/box/` (the box's `/root/logs`), scripts `raw/*.sh`, analysis `raw/scripts/analyze.py` (`python3 raw/scripts/analyze.py raw/box`).

**Summary**
- **The port is bit-identical.**
  - The new `cert_power` divides only a^j into digits and decides the carry from a^j mod b^c0, built from the digits below c0. It equals the lockstep scan it replaces word for word: mask, repeat flag, digit interval at the first disagreement, and c0, for the square and the cube.
  - `top_cert` equals the CPU's `Base::cert` and `cert_floor`.
  - Checked on 102,365 intervals: 33,582 kept, 203,413 powers scanned above c0, 69,824 of them with the carry. Real tops at b58–64, plus 32 arbitrary-interval shapes at b10–57 with n of 1–3 words. Passes on CUDA and on lavapipe.
- **The rest of the exactness checks also pass:**
  - CUDA join parity: windows b10/b20–b64 including b50/b54, the b57 frontier, tight, sliced and refused layouts, and the production shape.
  - Dense b58 1e15 and b64 1e16.
  - The whole b42 field, and join = stride on 2 × 1e14 per base.
  - Certified-top counts are identical to main's at 1e16. 1e14 survivor and full-check counts are identical to the last digit.
  - Host suite: 221 passed.
  - The WGSL lint flags 0 sites, both with CI's requirements and on the test kernel at every base.
  - fmt is clean, and clippy is clean in all three configurations.
- **Speed** (RTX 3080 capped at 180 W, interleaved, medians of 3; spreads ≤ 2.7 %; every PR round faster than the main round before it):
  - b62 1e17: **×1.075** (229.3 → 213.3 s).
  - 1e16: **×1.089** (b62), **×1.053** (b60), **×1.040** (b64).
  - NiceMark nice-only: score 3711 → 3976 (**×1.071**). Scenarios ×1.049–1.106, none slower.
  - 1e14, 2 rounds, not in the protocol: ×1.055 / 1.015 / 1.045 / 1.007 at b58 / 60 / 62 / 64.
- **Top kernel** (per-phase profile, 1e16): ×1.24 (b62), ×1.22 (b60), ×1.08 (b64). Its share of device time went 41.8 → 36.4 %, 34.3 → 29.9 % and 16.3 → 14.9 %.
  - That is less than the CPU's ×1.31–1.42 per top. Presumably the remainder's assembly and the second set of run masks cost back part of the saved division (not measured separately).
  - At b64 the chunk divisor is 2^12, so the dropped division was shifts and masks.

## 0. Setup

- **Box:** Vast 58589691 (`nice-research-topcert`), RTX 3080 **10 GB**, driver 580.159.03, CUDA 12.8 toolkit. Host Xeon E5-2630 v4, cgroup quota 9.6 CPUs (`cpu.max 960000 100000`), 62 GB RAM. The Vast machine (m139250) also hosted another research box (`nice-research-profile-1e17`, a different GPU) during the runs, so the host CPU was shared.
- **Power: capped by the host at 180 W** (default 340 W, max 374 W; `raw/box-info.txt`). Under the join it sat at the cap the whole time: median 1410–1470 MHz, 179.5–179.6 W, at most 66 °C, throttle flag 0x4 (SW power cap). Absolute seconds are a 180 W 3080's; the A/B is same box, same cap.
- **Trees and binaries** (`raw/box/md5_bins.txt`), `cargo test --release -p nice_common --features gpu --no-run` and `cargo build --release -p nice_client --features gpu` (`raw/build.sh`):
  - **main** = `9bde4a8` (`git archive`): test `105d68f4`, client `600b0288`.
  - **pr** = the branch's non-test code (identical to `d6cc9da`; the A/B test binary was built before the certificate test was moved into a lint-allowed module, a test-only change): test `95797b9e`, client `2bc20778`. `raw/box/final.log` has the rebuild from `d6cc9da` itself and the certificate test rerun on it.
  - **mprof / pprof** = main / the PR with `65ff58b` (`rp/gpu-profile-2`'s `NICE_EXP_GPU_PROFILE` per-phase profile) merged in by `git merge-tree` (clean), test binaries only, for the phase shares.
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at the A/B starts (b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568), one 1e14 warm-up field per base (`raw/run.sh`). "s/field" is the harness's `per_field` (wall per field, two fields in flight).
- **Order** (box clock, UTC): builds 23:35–23:46 (main), 23:39–23:55 (pr); exactness 23:55–00:07 (CUDA tests, lavapipe test and lint, fmt/clippy beside them); builds of mprof/pprof 23:57–00:10; **A/B 00:10:42–** (`raw/ab.sh`): b62 1e17 × 3 rounds, then b62/b60/b64 1e16 × 3 rounds, then NiceMark × 3, each round main then pr; then the profile, dense b64 on main, the host suite, the 1e14 count check and the final rebuild (`raw/box/after*.log`, `final.log`). No builds or other jobs on the box during the A/B.

## 1. Exactness

All on the RTX 3080 (CUDA) unless marked; logs `raw/box/x_pr_*.log`, `l_pr_*.log`.

| check | result |
|---|---|
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` (new) | ok, 102,365 intervals, 33,582 kept, 203,413 powers scanned above c0, 69,824 with the carry (`x_pr_cert_cuda.log`; 135 s) |
| `top_certificates_match_the_lockstep_scan_and_the_cpu` on **lavapipe** (new) | ok, the same counts (`l_pr_cert.log`; 116 s) |
| `cubecl_cuda_join_matches_the_cpu_reference` | ok: base 10's 69, every window b20–b64 incl. b50/b54, b57 frontier partitions, tight layouts, slices, refused layouts, production shape (`x_pr_parity_cuda.log`) |
| dense field b58 1e15 (`NICE_TEST_JOIN_DENSE=64`) | ok, 0 overran (`x_pr_dense58.log`) |
| dense field b64 1e16 (8 partitions) | ok, 20,889 overran (2.7e-5); **main: 21,899 (2.9e-5)**; survivors + overrun = 763,743,660 in both (`x_main_dense64.log`) |
| whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`) | ok: 417,789,835 survivors, 16,879,877 checked, no hits (`x_pr_whole_cuda.log`) |
| join = stride, 2 × 1e14 at b58–64 (`NICE_TEST_JOIN_COMPARE=1`) | ok, found 0 = 0 (`x_pr_compare.log`) |
| 1e14 counts main vs PR (2 rounds each) | identical to the last digit at b58/60/62/64 (section 2) |
| certified tops at 1e16 (profile counters) | identical: 4,508,762,994 / 6,869,484,234 / 3,866,773,495 (b62/60/64) |
| the new test again on a test binary rebuilt from `d6cc9da` itself (`dfbea0e6`), CUDA and lavapipe | ok, same counts (`x_final_cert_cuda.log`, `x_final_cert_lvp.log`) |
| host suite (`nice_common_test`, no `--ignored`) | 221 passed, 0 failed, 46 ignored (`host_pr.log`) |
| WGSL lint, CI's command and require list (lavapipe dump) | 15 shaders, 0 flagged (`l_pr_lint.log`; dump `wgsl_pr.log.gz`) |
| WGSL lint of the test kernel's dump (`top_cert` + both scans at b10–64, 1–3 words; 35 compilations, `NICE_TEST_CERT_SAMPLES=2000`) | 0 flagged (`l_pr_certkernel_lint.txt`) |
| `cargo fmt --all --check`; clippy `-p "*" --all-targets -D warnings` default, `--features nice_client/gpu`, `--features nice_client/gpu,nice_client/cubecl-spirv` | all clean (`fmt.log`, `clippy_*.log`) |

The first clippy run flagged the test module's cube code (single-letter names, long functions, `manual_midpoint`, `collapsible_if`, one cast). That code now sits in `mod cert_kernels` under `kernels`' allow list, and the reruns are clean.

## 2. A/B tables (`raw/analysis.txt`)


#### 1e17, 1 field

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | speed-up | per launch main / PR |
|---|---|---|---|---|---|---|---|
| 62 | **229.269** (226.812, 229.531, 229.269) | 1.2 % | **213.282** (213.282, 212.893, 213.330) | 0.2 % | **×0.930** | ×1.075 | 5 / 5 |

- b62 main: 1020728374812 / 62692716764 / 0; 1020728401804 / 62692691355 / 0; 1020728359809 / 62692730640 / 0
- b62 pr: 1020728386597 / 62692709293 / 0; 1020728401724 / 62692689542 / 0; 1020728374167 / 62692715229 / 0

#### 1e16, 2 fields

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | speed-up | per launch main / PR |
|---|---|---|---|---|---|---|---|
| 60 | **43.710** (43.710, 44.118, 43.649) | 1.1 % | **41.524** (40.943, 41.524, 41.639) | 1.7 % | **×0.950** | ×1.053 | 4 / 4 |
| 62 | **19.754** (19.664, 19.936, 19.754) | 1.4 % | **18.140** (18.140, 17.951, 18.290) | 1.9 % | **×0.918** | ×1.089 | 13 / 13 |
| 64 | **54.847** (54.847, 54.916, 53.447) | 2.7 % | **52.741** (53.837, 52.689, 52.741) | 2.2 % | **×0.962** | ×1.040 | 6 / 6 |

- b60 main: 459052137756 / 32547202260 / 0; 459052499914 / 32546878200 / 0; 459052769520 / 32546646123 / 0
- b60 pr: 459052303612 / 32547058406 / 0; 459052340129 / 32547045037 / 0; 459052636988 / 32546767214 / 0
- b62 main: 163510229678 / 10030858412 / 0; 163510219261 / 10030868350 / 0; 163510235912 / 10030852545 / 0
- b62 pr: 163510215810 / 10030871692 / 0; 163510233888 / 10030853874 / 0; 163510222596 / 10030865370 / 0
- b64 main: 787562318203 / 47922098907 / 0; 787562297616 / 47922117333 / 0; 787562304915 / 47922110266 / 0
- b64 pr: 787562320636 / 47922096619 / 0; 787562322548 / 47922093325 / 0; 787562304878 / 47922111241 / 0

#### 1e14, 2 fields (counts check)

| base | main s/field (rounds) | spread | PR s/field (rounds) | spread | **PR / main** | speed-up | per launch main / PR |
|---|---|---|---|---|---|---|---|
| 58 | **0.925** (0.921, 0.928) | 0.8 % | **0.877** (0.881, 0.872) | 1.0 % | **×0.948** | ×1.055 | 16 / 16 |
| 60 | **0.796** (0.788, 0.804) | 2.0 % | **0.784** (0.786, 0.783) | 0.4 % | **×0.986** | ×1.015 | 16 / 16 |
| 62 | **0.691** (0.696, 0.685) | 1.6 % | **0.661** (0.668, 0.653) | 2.3 % | **×0.957** | ×1.045 | 16 / 16 |
| 64 | **1.047** (1.044, 1.051) | 0.7 % | **1.040** (1.035, 1.046) | 1.1 % | **×0.993** | ×1.007 | 16 / 16 |

- b58 main: 7621203662 / 429530619 / 0; 7621203662 / 429530619 / 0
- b58 pr: 7621203662 / 429530619 / 0; 7621203662 / 429530619 / 0
- b60 main: 5634417625 / 377421465 / 0; 5634417625 / 377421465 / 0
- b60 pr: 5634417625 / 377421465 / 0; 5634417625 / 377421465 / 0
- b62 main: 2723010177 / 166801084 / 0; 2723010177 / 166801084 / 0
- b62 pr: 2723010177 / 166801084 / 0; 2723010177 / 166801084 / 0
- b64 main: 11007394280 / 669464864 / 0; 11007394280 / 669464864 / 0
- b64 pr: 11007394280 / 669464864 / 0; 11007394280 / 669464864 / 0

#### NiceMark nice-only

| scenario | main rate (rounds) | spread | PR rate (rounds) | spread | **PR / main** |
|---|---|---|---|---|---|
| b58_msd_weak | **1.597e+14** (1.578e+14, 1.627e+14, 1.597e+14) | 3.1 % | **1.711e+14** (1.691e+14, 1.711e+14, 1.749e+14) | 3.4 % | **×1.071** |
| b58_msd_strong | **9.704e+14** (9.580e+14, 9.881e+14, 9.704e+14) | 3.1 % | **1.018e+15** (1.001e+15, 1.018e+15, 1.033e+15) | 3.2 % | **×1.049** |
| b60_msd_weak | **3.190e+14** (3.190e+14, 3.158e+14, 3.204e+14) | 1.4 % | **3.508e+14** (3.508e+14, 3.467e+14, 3.564e+14) | 2.8 % | **×1.100** |
| b62_msd_weak | **4.022e+14** (4.022e+14, 4.021e+14, 4.087e+14) | 1.7 % | **4.449e+14** (4.449e+14, 4.426e+14, 4.489e+14) | 1.4 % | **×1.106** |

score main: [3669.1326449640796, 3716.3810208595687, 3711.131838109583]

score pr: [3963.445543759338, 3976.0429753430244, 4054.5663516145946]

#### nvidia-smi under load (samples > 100 W)

| run | samples | median SM MHz | median W | max °C | throttle flags |
|---|---|---|---|---|---|
| e14_main_r1 | 3 | 1620 | 113.8 | 50 | 0x0000000000000000, 0x0000000000000004 |
| e14_main_r2 | 5 | 1545 | 134.8 | 53 | 0x0000000000000004 |
| e14_pr_r1 | 5 | 1620 | 159.8 | 52 | 0x0000000000000004 |
| e14_pr_r2 | 5 | 1545 | 166.4 | 54 | 0x0000000000000004 |
| e16_main_r1 | 50 | 1425 | 179.6 | 65 | 0x0000000000000000, 0x0000000000000004 |
| e16_main_r2 | 50 | 1425 | 179.6 | 65 | 0x0000000000000000, 0x0000000000000004 |
| e16_main_r3 | 50 | 1425 | 179.6 | 65 | 0x0000000000000000, 0x0000000000000004 |
| e16_pr_r1 | 48 | 1425 | 179.6 | 65 | 0x0000000000000004 |
| e16_pr_r2 | 48 | 1425 | 179.6 | 65 | 0x0000000000000000, 0x0000000000000004 |
| e16_pr_r3 | 48 | 1425 | 179.6 | 65 | 0x0000000000000000, 0x0000000000000004 |
| e17_main_r1 | 45 | 1470 | 179.5 | 63 | 0x0000000000000004 |
| e17_main_r2 | 47 | 1410 | 179.5 | 66 | 0x0000000000000004 |
| e17_main_r3 | 47 | 1425 | 179.5 | 66 | 0x0000000000000004 |
| e17_pr_r1 | 44 | 1425 | 179.6 | 66 | 0x0000000000000004 |
| e17_pr_r2 | 44 | 1425 | 179.5 | 65 | 0x0000000000000004 |
| e17_pr_r3 | 44 | 1425 | 179.5 | 65 | 0x0000000000000000, 0x0000000000000004 |
| nm_r1_main | 10 | 1770 | 122.2 | 65 | 0x0000000000000000, 0x0000000000000004 |
| nm_r1_pr | 9 | 1770 | 124.2 | 62 | 0x0000000000000000, 0x0000000000000004 |
| nm_r2_main | 9 | 1770 | 117.5 | 61 | 0x0000000000000000, 0x0000000000000004 |
| nm_r2_pr | 9 | 1770 | 131.4 | 59 | 0x0000000000000000, 0x0000000000000004 |
| nm_r3_main | 9 | 1770 | 121.6 | 59 | 0x0000000000000000, 0x0000000000000004 |
| nm_r3_pr | 5 | 1500 | 133.7 | 58 | 0x0000000000000000, 0x0000000000000004 |
| prof_mprof_r1 | 27 | 1440 | 179.5 | 62 | 0x0000000000000000, 0x0000000000000004 |
| prof_mprof_r2 | 29 | 1440 | 179.6 | 64 | 0x0000000000000000, 0x0000000000000004 |
| prof_pprof_r1 | 28 | 1440 | 179.5 | 64 | 0x0000000000000000, 0x0000000000000004 |
| prof_pprof_r2 | 28 | 1425 | 179.6 | 64 | 0x0000000000000000, 0x0000000000000004 |
| t16_pr_r1 | 46 | 1485 | 179.6 | 61 | 0x0000000000000000, 0x0000000000000004 |
| t16_pr_r2 | 49 | 1425 | 179.6 | 66 | 0x0000000000000000, 0x0000000000000004 |
| t16_trim_r1 | 47 | 1425 | 179.6 | 65 | 0x0000000000000000, 0x0000000000000004 |
| t16_trim_r2 | 48 | 1410 | 179.6 | 67 | 0x0000000000000000, 0x0000000000000004 |

#### Per-phase profile, 1e16 (2 rounds each; medians of 2 = means)

| base | main: device s / top s (share) | PR: device s / top s (share) | top phase PR / main | certified tops (both) |
|---|---|---|---|---|
| 62 | 26.59 / 11.11 (41.8 %; rounds 10.97, 11.24) | 24.56 / 8.95 (36.4 %; rounds 8.90, 8.99) | **×0.806** (×1.24 faster) | [4508762994] |
| 60 | 43.18 / 14.80 (34.3 %; rounds 14.69, 14.91) | 40.40 / 12.09 (29.9 %; rounds 11.97, 12.21) | **×0.817** (×1.22 faster) | [6869484234] |
| 64 | 53.17 / 8.65 (16.3 %; rounds 8.62, 8.68) | 53.51 / 7.98 (14.9 %; rounds 7.98, 7.98) | **×0.923** (×1.08 faster) | [3866773495] |

#### Experiment: PR + division trim against the PR, 1e16 (2 rounds)

| base | PR s/field (rounds) | PR + trim s/field (rounds) | trim / PR | speed-up |
|---|---|---|---|---|
| 60 | 40.919 (40.487, 41.350) | 39.576 (39.236, 39.916) | ×0.967 | ×1.034 |
| 62 | 18.085 (17.627, 18.544) | 17.698 (17.691, 17.705) | ×0.979 | ×1.022 |
| 64 | 53.270 (52.205, 54.336) | 54.170 (54.266, 54.074) | ×1.017 | ×0.983 |

Notes:
- The 1e16 and 1e17 counts differ run to run within main as well: this is the stage overrun, which depends on timing. The PR's counts vary by the same amount, though not always inside main's three-run range: b62 1e16 survivors were 163,510,219,261–163,510,235,912 on main and 163,510,215,810–163,510,233,888 on the PR.
- NiceMark runs took about 45 s each; the 150 s is a budget the scenarios did not need. Their nvidia-smi samples are few, and some fall between scenarios.
- The per-phase profile (`prof_*` logs) is a separate run of the mprof/pprof binaries, 2 rounds per tree, b62/b60/b64 with one 1e16 field each after the 1e14 warm-up. The warm-up's profile line includes kernel compilation, so it is not used. The device is synchronised after each kernel group. The profiled device seconds are 35 % above the unprofiled s/field at b62, and within 3 % at b60 and b64, so use the shares, not the absolute seconds.
- Commands:
  - A/B: `raw/ab.sh`, which calls `raw/run.sh TREE TAG SIZE FIELDS BASES`, i.e. `NICE_TEST_JOIN_FIELDS=.. NICE_TEST_JOIN_SIZE=.. NICE_TEST_JOIN_BASES=.. NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1`.
  - NiceMark: `nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`.
  - Exactness: `raw/exact.sh`, `raw/lvp.sh`, `raw/whole.sh`, `raw/final.sh`.
  - Follow-ups: `raw/after.sh` (profile, main dense b64, host suite) and `raw/after2.sh` (1e14 counts).
  - Lint and clippy: `raw/clippy.sh`.

## 3. Experiment, not in the PR: bounding the long division to the live limbs

The scan divides all 2·nl limbs of the power in every pass, but x / B^pass < b^(sp − pass·cd), so only that power's 16-bit limbs can be non-zero. Example: the cube at b62 has 18 limbs, 14 of them live at pass 0 and 7.7 on average over its 19 passes; for the square, 12 limbs and 5.5 on average. The patch (`raw/trim-experiment.patch`, on top of the PR) makes the loop bound a compile-time constant per pass. It keeps the #228 first step on the top two live limbs.
- **Exact:** the certificate test passes on CUDA with it (`x_trim_cert_cuda.log`).
- **Speed:** 1e16, PR vs PR + trim, 2 interleaved rounds (`raw/trim.sh`): ×1.034 (b60), ×1.022 (b62), ×0.983 (b64). That is within this box's round-to-round noise; the PR's own b62 rounds were 17.63 and 18.54 s.
- **Conclusion:** no clear gain, so it was not pursued and it is not in the PR. Why was not investigated. Candidates: the dead limbs' steps were already cheap after NVRTC's optimisation, or the top kernel is bound by something other than the division steps (registers or occupancy, memory, the closure and bucket atomics).
- The binary was built in `/root/src/pr` with the patched file swapped in and then restored (`trim.log`: "restored" check). It ran after all PR measurements.
