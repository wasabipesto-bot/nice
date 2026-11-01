# L30 COMBINED: #235 + #236 merged on main, A/B against main, RTX 3080 at 180 W (2026-11-01)

Branch `exp/join-235-236` = `e9cdac4` on the fork (no PR). Raw logs: `combined-raw/box/` (the box's `/root/cmb`). Scripts: `combined-raw/scripts/`. Analysis: `combined-raw/analyze.py box` (output in `combined-raw/analysis.txt`).

## Summary

- **The PRs merge cleanly.** `cubecl_join.rs` and `join_plan.rs` auto-merge. The only conflict is the expected one-line CHANGELOG conflict, resolved by keeping both lines. The merged diff is exactly the union of the two PRs' diffs.
- **The combined tree is exact.**
  - Every CUDA exactness test passes: certificates, join parity including the b50/b54 windows, and both dense fields equal to the CPU join.
  - 1e14 counts are identical to main's at b57/60/62/64, and join = stride.
  - The 1e16/1e17 counts equal #236's exact counts in every run.
  - fmt, clippy with `--features nice_client/gpu` and default, and the WGSL lint (CI's 13 requires) are all clean: 15 shaders, 0 flagged.
- **Speed (device s per field, medians):**

  | field | speed-up |
  |---|---|
  | **b62 1e17** | **×1.365** (226.8 → 166.2 s, −60.6 s) |
  | b62 1e16 | ×1.350 |
  | b60 1e16 | ×1.379 |
  | b64 1e16 | ×1.305 |
  | **NiceMark nice-only** | **×1.325** (3676 → 4871) |

  - Every round is faster than the main round next to it: per-round ratios ×1.30–1.40.
  - Spreads: main 1.4–2.2 %, combined 0.2–1.3 %.
- **They compound, and slightly better than multiplicatively: the seconds each PR saves add up.**
  - Each PR alone on this box at b62 1e17: #235 saves 20.7 s (×1.100), #236 saves 39.4 s (×1.210).
  - Product of the ratios: ×1.332. Sum of the savings: 60.1 s, which predicts 166.65 s (×1.361).
  - Measured: 166.16 s (×1.365). The interaction is −0.5 s, inside the spreads.
  - The profile confirms why: each PR shortens its own kernel. #235 shortens the top kernel and #236 the join kernel, and neither moves the other's phase.
  - At b64 1e16, #235 alone is ×0.996, so it has nothing to give there. The combined ×1.305–1.327 is #236's ×1.299 plus ~1 s. L29's ×1.040 at b64 was within main's noise.
- **Profile after both** (b62 1e17): top **43.3 %**, join **45.9 %**, check 5.7 %, bucket 1.5 %, other 3.7 %.
  - On main, on the same box: top 41.3 %, join 50.7 %. The top kernel lost 20.6 s and the join 37.3 s; everything else moved by at most 0.2 s.
  - b60 1e16: top 36.6 %, join 50.4 % (main 34.5 / 56.0).
  - The stage never spilled (`spilled=0`).

## 0. Setup

- **Box:** Vast 58618524 (`nice-research-combined2`), machine **m139250**. That is the same machine as L29's and L30's A/Bs.
  - RTX 3080 10 GB, driver 580.159.03 (CUDA 13.0 driver API).
  - **Power limit 180 W** (default 340, max 374; `box/power.txt`). Under load the card sat at the cap: 179–180 W, mean SM clock 1419–1449 MHz at ≥ 90 % utilisation, at most 67 °C, throttle flag 0x4.
  - Xeon E5-2630 v4, cgroup quota 9.6 CPUs.
  - The host also ran another research box (`nice-research-topcert2`, another GPU) the whole time, so host CPU was shared. Host setup per 1e17 field was 15.4–16.4 s in every tree. The metric is device time.
  - The first box (58613559, m146575) never left `created` (03:58–04:54) and was replaced.
- **Binaries.** Each was built on the box from a `git archive` of an ivory tree, with toolchain 1.99.1 (`rust-toolchain.toml`). They share one target dir, with `cargo clean -p nice_common` before each build and one build at a time (`scripts/build.sh`, `buildclient.sh`, `box/chain_build.out`). Test binaries are `cargo test --release -p nice_common --features gpu --no-run`; clients are `cargo build --release -p nice_client --features gpu`:

  | binary | source | md5 | notes |
  |---|---|---|---|
  | `main` | `fae7398` | **105d68f4** | same md5 as L29's/L30's main |
  | `both` | `e9cdac4` | 8f421599 | strings check: has #235's certificate test and #236's exact dense-field assertion; main has neither |
  | `p235` | `6e7475e` | 7718acc5 | |
  | `p236` | `dd4a0eb` | 4db573d2 | |
  | `client_main` | `fae7398` | **600b0288** | = L30's |
  | `client_both` | `e9cdac4` | 9af4f2bd | |
  | `both_wgpu` | `e9cdac4`, `--features cubecl` | cc443839 | for the WGSL lint |
  | `prof` | `e9cdac4` + `2ab1694` + `32b84af` | 4e7b568c | §5 |
  | `mprof` | `fae7398` + `2ab1694` | d22ece14 | §6 |

- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at the A/B starts used before (b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568). Each process starts with an untimed 1e14 warm-up field. The metric is `device=`, the mean device wall seconds per field; `per_field` is in `analysis.txt` and agrees to ±0.01 in the ratios.
- **Order (box UTC):**
  - Builds 04:58–05:28.
  - Exactness 05:06–05:16 and fmt/clippy 05:06–05:09, beside the later builds.
  - WGSL lint 05:18–05:19.
  - **A/B 05:28–06:07** (`chain_ab.sh`): b62 1e17 ×3, b62 1e16 ×3, b60 1e16 ×3, b64 1e16 ×2, each round main then both. Then NiceMark ×3 (06:07–06:11).
  - Each PR alone at b62 1e17 06:11–06:31 (`chain_single.sh`), profile of both 06:31–06:35, b64 four-way 06:35–06:48, then the build of `mprof` and main's profile 06:48–06:56.
  - Nothing else ran on the box from 05:28 to 06:48. The `mprof` build ran after the last timed A/B run.

## 1. Merge

- `git worktree add .worktrees/exp-235-236 origin/main -b exp/join-235-236`, then `git merge fork/pr/join-top-cert-fast`. This fast-forwarded to `6e7475e`: `3eb6e72` plus the SPIR-V fix.
- Then `git merge fork/pr/join-prefilter-in-walk` (`dd4a0eb`):
  - `common/src/cubecl_join.rs`: auto-merged.
  - `common/src/join_plan.rs`: only #236 touches it.
  - **`CHANGELOG.md`: the one conflict.** Both PRs add the first line under Unreleased. Resolved by keeping both lines, #235's first.
  - **No other conflict.**
- Merge commit `e9cdac4`, parents `6e7475e` and `dd4a0eb`. It was first pushed as `0971c6e` with git's default message, then amended to `e9cdac4` for the message (same tree `66a18ac`) and force-pushed with a lease.
- Union check:
  - `git diff 6e7475e e9cdac4` has the same +/− lines as `git diff fae7398 dd4a0eb` (#236 applied on #235).
  - `git diff dd4a0eb e9cdac4` has the same +/− lines as `git diff fae7398 6e7475e` (#235 applied on #236).
  - The only difference is where `diff` places one closing `}` within a hunk.
  - Against main: 3 files, +1262 / −408.

## 2. Exactness (combined tree, CUDA unless noted; logs `box/x_*.log`, `box/*_cmp_e14.log`, `box/lint_*.log`, `box/wgsl_*.log`)

| check | result |
|---|---|
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` | ok (173 s): 102,365 intervals, 33,582 kept, 203,413 powers scanned above c0, 69,824 with the carry. Identical to L29's counts |
| `cubecl_cuda_join_matches_the_cpu_reference` | ok (76 s). Covers: base 10's 69; windows b20, b25, b30, b34, b40, **b50, b54**, b57, b58, b60, b64; b57 frontier partitions 0/1000/3248; tight layouts; 5 windows whole and in slices; refused layouts (b50 852 MiB → ceiling 426, b54 976 → 488, and others); production shape |
| dense b58 1e15, 32 partitions (`NICE_TEST_JOIN_DENSE=32`) | ok: 254,938,965 survivors / 14,396,829 checked, asserted equal to the CPU join (= L30's #236) |
| dense b62 1e16, 4 partitions (`NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16`) | ok: 120,013,475 / 7,355,827, asserted equal to the CPU join (= L30's #236) |
| `NICE_TEST_JOIN_COMPARE=1`, 1e14 at b57/60/62/64 (one field each), combined and main | both pass (join = stride, found 0 = 0). **Counts identical to main's**: table below |
| `cargo fmt --all --check` | clean |
| clippy `-p "*" --all-targets -D warnings`: `--features nice_client/gpu`; default | both clean (rustc 1.99.1) |
| WGSL lint as CI runs it: `wgsl_dump_for_lint` on lavapipe (llvmpipe, Mesa 25.2.8), `scripts/wgsl-lint.py` with CI's 13 `--require`s | 15 shaders, **0 flagged**, rc 0. TopKernel b57 has 539 constant divisions, JoinKernel b57 34, BucketKernel b57 46 |

1e14 (`box/main_cmp_e14.log`, `box/both_cmp_e14.log`; main = combined, and equal to L30's table):

| base | join survivors | checked | hits | plan MiB main → combined |
|---|---|---|---|---|
| 57 | 4,850,227,888 | 268,123,373 | 0 | 1185 → 1193 |
| 60 | 2,694,700,282 | 180,517,288 | 0 | 1192 → 1201 |
| 62 | 1,439,469,648 | 88,159,810 | 0 | 1359 → 1369 |
| 64 | 5,702,041,796 | 346,647,759 | 0 | 1402 → 1413 |

**Counts at 1e16/1e17:**
- The combined tree's counts are the same in every run.
- They equal #236's exact counts (L30, and #236 alone on this box): b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327.
- Main and #235 alone vary from run to run by the stage overrun only:
  - b62 1e17: 1.13e-4 of survivors.
  - b62 1e16: 2.1e-5.
  - b60 1e16: 3.9e-3.
  - b64 1e16: 2.9e-5.
- Their extra full checks are that overrun minus 6.15–6.71 %, which is each field's keep rate, as in L30 §2.
- No hits anywhere.

## 3. A/B: main (`fae7398`) vs combined (`e9cdac4`), interleaved

Device seconds per field. Spread = (max − min) / median. Clock = mean SM MHz over nvidia-smi samples at ≥ 90 % utilisation.

| field | A: main (rounds) | B: combined (rounds) | **speed-up (medians)** | per-round | saving per field | clock A / B | clock-normalised |
|---|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | 223.99, 226.75, 228.97 (226.75, 2.2 %) | 167.36, 166.00, 166.16 (166.16, 0.8 %) | **×1.365** | 1.338, 1.366, 1.378 | **−60.6 s** | 1432 / 1449 | ×1.349 |
| b62 1e16, 2 fields | 18.789, 18.964, 19.048 (18.964, 1.4 %) | 14.041, 14.051, 14.070 (14.051, 0.2 %) | **×1.350** | 1.338, 1.350, 1.354 | −4.91 s | 1422 / 1429 | ×1.343 |
| b60 1e16, 2 fields | 43.589, 42.862, 42.791 (42.862, 1.9 %) | 31.090, 30.872, 31.249 (31.090, 1.2 %) | **×1.379** | 1.402, 1.388, 1.369 | −11.77 s | 1428 / 1442 | ×1.366 |
| b64 1e16, 2 fields | 53.681, 52.555 (53.118, 2.1 %) | 40.963, 40.439 (40.701, 1.3 %) | **×1.305** | 1.310, 1.300 | −12.42 s | 1419 / 1431 | ×1.295 |

- Layouts are identical A/B: slots 5 / 13 / 4 / 6. Plan MiB +4, +9, +2, +4, which is #236's `ext_q`.
- Main's absolute seconds are close to L30's main on this machine: b62 1e17 226.75 against 225.87, b60 42.86 against 42.12, b64 53.12 against 53.00. b62 1e16 is the exception at 18.96 against 18.02 (+5 %).

### NiceMark nice-only

`client_{main,both} niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, A B A B A B, run with `NICE_API_BASE=http://127.0.0.1:9`. With that setting the /ping latency samples are skipped and no server is contacted. Each sweep took 36–41 s. JSON in `box/nm_*.json`.

| | main | combined | speed-up | #235 (L29) × #236 (L30) |
|---|---|---|---|---|
| **score** | 3676.4, 3672.4, 3741.1 (median 3676.4, spread 1.9 %) | 4871.2, 4854.4, 4929.5 (4871.2, 1.5 %) | **×1.325** (per round 1.325, 1.322, 1.318) | ×1.071 × ×1.194 = ×1.279 |
| b58 MSD-weak (whole field), n/s | 1.585e14 (1.582–1.625) | 2.182e14 (2.179–2.220) | ×1.377 | ×1.071 × ×1.256 = ×1.345 |
| b58 MSD-strong (whole field) | 9.677e14 (9.496–9.839) | 1.239e15 (1.215–1.241) | ×1.280 | ×1.049 × ×1.193 = ×1.251 |
| b60 MSD-weak (sampled) | 3.211e14 (3.168–3.230) | 4.148e14 (4.127–4.193) | ×1.292 | ×1.100 × ×1.145 = ×1.260 |
| b62 MSD-weak (sampled) | 4.045e14 (4.014–4.058) | 5.409e14 (5.401–5.468) | ×1.337 | ×1.106 × ×1.183 = ×1.308 |

Counts in the whole-field scenarios:
- b58 MSD-strong: identical (4,027,773,430 / 226,773,299).
- b58 MSD-weak: combined 33,590,315,220 / 1,894,592,860 in every run (= L30's #236). Main is 49–101 survivors lower, its overrun.

## 4. Do they compound? Each PR alone on the same box

`chain_single.sh`, right after the A/B: b62 1e17, rounds #235, #236 interleaved, 3 each. Main and both are the A/B's rounds above, 20–60 min earlier on the same box.

| b62 1e17 | device s (rounds) | median | spread | speed-up | saving |
|---|---|---|---|---|---|
| main | 223.99, 226.75, 228.97 | 226.75 | 2.2 % | — | — |
| **#235 alone** (`6e7475e`) | 205.32, 206.37, 206.05 | 206.05 | 0.5 % | **×1.100** | 20.7 s |
| **#236 alone** (`dd4a0eb`) | 188.69, 187.08, 187.36 | 187.36 | 0.9 % | **×1.210** | 39.4 s |
| **both** | 167.36, 166.00, 166.16 | 166.16 | 0.8 % | **×1.365** | 60.6 s |

- **Multiplicative model** (independent fractions of time): ×1.100 × ×1.210 = ×1.332, which predicts 170.3 s.
- **Additive model** (each PR removes its own seconds): 226.75 − 20.7 − 39.4 = 166.65 s, which is ×1.361.
- **Measured: 166.16 s (×1.365).** That is 0.5 s better than additive and 4.1 s better than multiplicative. The residual is well inside main's 2.2 % spread.
- **So they compound, with no measurable overlap or interaction: the savings add.**
  - This is what two cuts in different serial kernels should do. #235 cuts the top kernel (and its division), #236 the join kernel and its flush.
  - Removing a fixed number of seconds from a shorter total gives a larger ratio. That is why the combined ratio beats the product of the individual ratios.
- **Against the numbers in the brief** (×1.075 × ×1.215 ≈ ×1.31): the combined ×1.365 is 4.5 % above.
  - Almost all of that is #235 itself. At its head `6e7475e`, with the SPIR-V fix that folds the low chunks with `select`s, it measures ×1.100 here, against ×1.075 for `d6cc9da` in L29. SPIRV-FIX.md had seen +2.4 % on a 3060.
  - #236 alone reproduces: ×1.210 here, ×1.215 in L30.
- **b64 1e16 four-way** (`chain_extra.sh`, 2 rounds, main / #235 / #236 / both per round; `box/x4_*`). This was run because b64 was the one A/B field below the product of the brief's numbers:

  | b64 1e16 | device s (rounds) | mean | speed-up |
  |---|---|---|---|
  | main | 52.43, 54.09 | 53.26 | — |
  | #235 alone | 53.16, 53.74 | 53.45 | ×0.996 |
  | #236 alone | 41.26, 40.76 | 41.01 | ×1.299 |
  | both | 40.10, 40.19 | 40.15 | ×1.327 |

  - **#235 does nothing measurable at b64.** Main's own two rounds differ by 3 %. At b64 the top kernel is ~15 % of device time, and its chunk divisor is 2^12, so the division #235 removes was shifts and masks (L29 §0).
  - So the A/B's ×1.305 at b64 is #236's ×1.30 plus ~1 s, not a negative interaction. The brief's ×1.040 for #235 at b64 (L29) was within main's spread there.
- At b62/b60 1e16 only the A/B was run: ×1.350 and ×1.379, against products ×1.287 and ×1.307 of the brief's numbers. The same pattern holds as at 1e17.

## 5. Profile after both

Throwaway tree: the combined tree + `2ab1694` (`rp/gpu-profile-3`'s `NICE_EXP_GPU_PROFILE`, cherry-picked cleanly) + `32b84af`. Worktree `nice/.worktrees/exp-235-236-prof`, local only.
- **The overrun counter `406ca28` was not taken.** It counts survivors that overran main's stage and went to the list unprefiltered, and #236 deleted that path, so it conflicts in `flush_survivors` and the survivor buffer.
- `32b84af` adds its analogue for the new code instead: `spilled=` counts prefiltered survivors the walk wrote straight to the list because its cube's stage was full.

One field each (`chain_prof.sh`). The device is synchronised after each kernel group. Profiled device time is within 1 % of unprofiled: 168.04 against 166.16 s, and 31.34 against 31.09.

**Conventions (as in PROFILE-3):**
- Shares are of profiled device time with the probe excluded.
- "Other" = upload + inputs + read + unattributed.
- Host setup is CPU time per field, overlapped with device work except the first slice.

| field | device s (profiled) | host setup s | **top** | bucket | **join** | check | other |
|---|---|---|---|---|---|---|---|
| **b62 1e17** | 168.04 (probe 1.89) | 15.69 | **43.3 %** (71.87 s) | 1.5 % (2.41) | **45.9 %** (76.24) | 5.7 % (9.48) | 3.7 % (6.14: upload 2.57, inputs 2.04, read 0.68, unattributed 0.85) |
| b60 1e16 | 31.34 (probe 0.38) | 2.28 | **36.6 %** (11.34) | 1.4 % (0.43) | **50.4 %** (15.61) | 7.2 % (2.23) | 4.4 % (1.35: 0.55, 0.47, 0.17, 0.16) |

Counts (`box/prof_*.log`):

| field | top-layer prefixes | slices | partitions | batches | certified tops | listed entries | AND pairs | wave-padded pairs | live buckets | survivors | checked | spilled | hits |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| b62 1e17 | 30,636,533 | 11 | 3,844 | 6,439 | 38,155,658,259 | 53,672,786,098 | 2.532e13 | 3.907e13 (×1.54) | 159,918,088 (all) | 1,020,844,021,499 | 62,584,252,554 | **0** | 0 |
| b60 1e16 | 5,281,726 | 2 | 3,600 | 1,350 | 6,869,484,234 | 8,835,185,993 | 5.437e12 | 7.034e12 (×1.29) | 25,488,000 (all) | 227,399,051,187 | 15,233,090,013 | **0** | 0 |

(The b60 profile is one field; the A/B's b60 counts are for two.)

## 6. Main's split on the same box, and what moved

`mprof` = main `fae7398` + `2ab1694` (clean cherry-pick). It ran after the four-way (`chain_mprof.sh`, `box/mprof_*.log`) on the same fields. Profiled device time is 225.71 s against unprofiled 226.75 at b62 1e17, and 43.21 against 42.86 at b60.

| phase | b62 1e17 main | b62 1e17 both | change | b60 1e16 main | b60 1e16 both | change |
|---|---|---|---|---|---|---|
| top | 92.48 s (41.3 %) | 71.87 s (**43.3 %**) | **−20.61 s** (×1.29) | 14.81 (34.5 %) | 11.34 (**36.6 %**) | **−3.46** (×1.31) |
| bucket | 2.32 (1.0 %) | 2.41 (1.5 %) | +0.09 | 0.41 (1.0 %) | 0.43 (1.4 %) | +0.02 |
| join | 113.58 (50.7 %) | 76.24 (**45.9 %**) | **−37.34 s** (×1.49) | 24.03 (56.0 %) | 15.61 (**50.4 %**) | **−8.43** (×1.54) |
| check | 9.32 (4.2 %) | 9.48 (5.7 %) | +0.16 | 2.34 (5.5 %) | 2.23 (7.2 %) | −0.11 |
| other | 6.20 (2.8 %) | 6.14 (3.7 %) | −0.06 | 1.29 (3.0 %) | 1.35 (4.4 %) | +0.06 |
| device, profiled excl. probe | 223.90 | 166.15 | −57.75 | 42.89 | 30.96 | −11.93 |
| host setup (CPU, overlapped) | 15.41 | 15.69 | | 2.37 | 2.28 | |

What moved:
- **Each PR moves only its own kernel.** The top phase lost 20.6 s at b62 1e17. That is #235's 20.7 s alone, measured unprofiled in §4. The join phase lost 37.3 s, against #236's 39.4 s alone. The profile synchronises after each kernel group, which removes the overlap between batches, so phase seconds and unprofiled seconds differ by a few seconds. Bucket, check and other changed by at most 0.2 s.
- **The new split.**
  - At b62 1e17, top and join are now nearly even: 43 % / 46 %, from 41 % / 51 %.
  - At b60 1e16 the join still leads: 50 % / 37 %, from 56 % / 35 %.
  - Check is 6–7 %. Bucket, uploads and reads are 5 % together.
  - Host setup (15.7 s per 1e17 field on this shared CPU) runs beside the device. At 166 s per field it is still 9 % of device time, so it is not yet a bottleneck.
- Counts for choosing the next lever (both trees, identical):

  | field | certified tops | top-layer prefixes | tops per prefix | AND pairs tested | wave-padded lanes |
  |---|---|---|---|---|---|
  | b62 1e17 | 3.82e10 | 3.06e7 | 1,245 | 2.53e13 | 3.91e13 |
  | b60 1e16 | 6.87e9 | 5.28e6 | 1,301 | 5.44e12 | 7.03e12 |

  - The wave padding is ×1.54 at b62 1e17 and ×1.29 at b60. So **35 % of the join's lanes at b62 (23 % at b60) are padding** that tests no pair. This is a count of lanes, not a measured time.
  - The top kernel's cost is about 1.9 ns per certified top at b62 1e17 (71.9 s / 3.82e10), against 2.4 ns on main.
- **`spilled=0` on both fields.** After #236 no cube's stage overflowed, so the walk's direct-write fallback never ran here.

## 7. Files

- `combined-raw/scripts/`:
  - Builds: `chain_build.sh`, `build.sh`, `buildclient.sh`.
  - Checks: `chain_x.sh` (CUDA exactness and 1e14 counts), `lint.sh` (fmt and clippy), `wgsl.sh` (CI's WGSL lint).
  - Measurement: `chain_ab.sh` (A/B and NiceMark), `chain_single.sh`, `chain_prof.sh`, `chain_extra.sh` (b64 four-way), `chain_mprof.sh`.
  - Wrappers: `run.sh`, `test.sh` (L30's), and `master.sh` (the order).
- `combined-raw/analyze.py`; its output is `combined-raw/analysis.txt`. `combined-raw/pull.sh` copied the logs back.
- `combined-raw/box/`: every log, `.smi` trace and NiceMark JSON; `power.txt`, `nproc.txt`, `nvidia-smi.txt`; `wgsl.log.gz`, the lint's WGSL dump.
