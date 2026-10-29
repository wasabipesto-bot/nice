# PR `pr/field-cert-prune` on an RTX 3080 against upstream main 2709d3f (2026-10-29)

**The PR wins at every base and size against new main, with identical counters.**
- **1e16, 3 interleaved rounds:** ×1.116 (b58), ×1.098 (b60), ×1.156 (b62), ×1.250 (b64). Spreads ≤ 1.5 %.
- **1e14 (production size), 20 fields per base, 3 rounds:** ×1.57 / ×1.71 / ×2.26 / ×2.17.
- **NiceMark nice-only:** 2451 → 3001 (×1.224). Every scenario took the join.
- **Where:** 90–97 % of the saving is in the join kernel. The bucket kernel halves. Top certification and the full check do not move.
- **With 2 entries per thread** (`pr/join-ept-2`, see EPT2-3080.md): ×1.218 / 1.163 / 1.349 / 1.577 at 1e16, ×1.69 / 1.77 / 2.53 / 2.65 at 1e14, and NiceMark 3310 (×1.350).
- **The flush fix is not in the PR.** On new main the prune does not change the stage overrun at any base (counted directly), and b64 is at 3.7e-5, under the 1e-4 limit. The candidate fix (flush at 256) removes main's own large b60 overrun (4.0e-3) but costs 1–2 % at b58/b64.
- **This card is power-capped at 150 W** (1260–1275 MHz). Absolute times are 15–30 % above yesterday's 3080.

## Setup

- **Box:** Vast 58197709 (South Korea), RTX 3080 10 GB, driver 580.159.03, Xeon E5-2630 v4 host (20 visible cores), PCIe 3 x16.
- **Power cap.** The host runs the card at a **150 W power limit** (default 320 W): it sat at 150 W with throttle reason `SW power cap` and 1260–1275 MHz SM clock throughout. Yesterday's 3080 (Vast 58056651) ran at 1830 MHz and about 231 W. Absolute seconds here are 15–30 % above yesterday's, and the ratios are those of a power-limited card. Nothing else ran during the timed runs.
- **Trees** (all on the fork `wasabipesto-bot/nice`; built with `cargo build --release -p nice_client --features gpu` and `cargo test --release -p nice_common --features gpu --no-run`, toolchain 1.99.1; binaries copied to `/root/bins/<tree>` and told apart by md5 and by strings):

| tree | branch | head | what |
|---|---|---|---|
| main (A) | `rp/pr-prune-a` | `6b4d383` | upstream main `2709d3f` + the PR's test-only harness commit |
| pr (B) | `pr/field-cert-prune` | `26a8b15` → `941e39e` | the PR. The 1e16 A/B ran `26a8b15` (`ff80db7` the prune + `26a8b15` harness). The 1e14 runs, NiceMark and the tests ran the head `941e39e` (`7efe289` + `941e39e`), which adds only the prune's empty-list fallback and its assertion |
| ept2 | `pr/join-ept-2` | `cb38b91` | the PR's head + 2 entries per thread at every base (EPT2-3080.md) |
| xmain | `rp/pr-prune-exp-main` | `be6e936` | A + `NICE_EXP_GPU_PROFILE`, `NICE_EXP_JOIN_EPT`, `NICE_EXP_SURV_FLUSH` and an overrun counter (throwaway) |
| xpr | `rp/pr-prune-exp-pr` | `501a1b6` | B + the same (throwaway); with `NICE_EXP_JOIN_EPT=2` it is tree C, "PR + EPT 2" |

  The experiment knobs, unset, leave the code paths as they are; the overrun counter is one atomic per flush, by one thread, only when the stage overran.
- **Fields:** the A/B fields of PRUNE.md / GPU-RESULTS.md, 1e16 each: b58 `104400216587923470200`, b60 `1366406074057412100454`, b62 `7997740455941656911841`, b64 `41242006262957161709568` (`NICE_TEST_JOIN_STARTS`), each base after a 1e14 warm-up.
- **Layout on new main.** #206's budget (2.5 GiB on this card) takes each 1e16 field in **one slice** (yesterday 5–8 slices): batches 1047 / 1350 / 769 / 683, 5 / 4 / 5 / 6 partitions per launch, at b58/60/62/64, the same on both trees.
- Raw logs: `L1/pr-raw/3080/ab/`; scripts: `L1/pr-raw/3080/*.sh`; tables: `L1/pr-raw/3080/analyze.py ab`.

## A/B against new main (PROPOSAL §5: fixed fields, A B C × 3)

Commands (`pr-raw/3080/ab.sh`, `x14.sh`; per tree, from its own directory):

```
NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 \
  NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
  /root/bins/<tree>/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1
# tree C ("ept2" in the 1e16 tables): /root/bins/xpr with NICE_EXP_JOIN_EPT=2 (the PR + 2 entries per thread)
# 1e14: NICE_TEST_JOIN_FIELDS=20 NICE_TEST_JOIN_SIZE=1e14, trees main / pr / ept2 (= pr/join-ept-2 cb38b91)
```

Order per round: main, pr, ept2. The figure is the harness's `per_field` (wall ÷ fields, two fields in flight); device seconds beside it. The 1e16 A/B ran the PR at `26a8b15`. Its head, `941e39e`, changes only the prune's empty-list fallback and its test; the 1e14 runs used `941e39e`.

#### Fixed-field throughput (s/field, two 1e16 fields in flight)

| base | tree | rounds | **median** | spread | device s/field (median) | batches | slots | survivors | checked |
|---|---|---|---|---|---|---|---|---|---|
| 58 | main | 80.51, 81.75, 81.11 | **81.115** | 1.5 % | 80.21 | 1028 | 5 | 6.0642e+11 | 3.4236e+10 |
| 58 | pr | 72.77, 72.69, 71.89 | **72.691** | 1.2 % | 71.78 | 1028 | 5 | 6.0642e+11 | 3.4236e+10 |
| 58 | ept2 | 65.69, 66.61, 66.65 | **66.614** | 1.4 % | 65.71 | 1028 | 5 | 6.0642e+11 | 3.4236e+10 |
| 60 | main | 56.88, 57.03, 56.97 | **56.966** | 0.3 % | 56.02 | 1350 | 4 | 4.5903e+11 | 3.2567e+10 |
| 60 | pr | 51.71, 52.17, 51.90 | **51.904** | 0.9 % | 50.95 | 1350 | 4 | 4.5904e+11 | 3.2561e+10 |
| 60 | ept2 | 49.13, 48.87, 49.00 | **48.999** | 0.5 % | 48.05 | 1350 | 4 | 4.5904e+11 | 3.2557e+10 |
| 62 | main | 29.19, 29.23, 29.14 | **29.190** | 0.3 % | 28.28 | 532 | 13 | 1.6351e+11 | 1.0031e+10 |
| 62 | pr | 25.14, 25.26, 25.25 | **25.249** | 0.5 % | 24.36 | 532 | 13 | 1.6351e+11 | 1.0031e+10 |
| 62 | ept2 | 21.58, 21.64, 21.93 | **21.645** | 1.6 % | 20.74 | 532 | 13 | 1.6351e+11 | 1.0031e+10 |
| 64 | main | 94.92, 94.97, 95.07 | **94.969** | 0.2 % | 94.12 | 683 | 6 | 7.8756e+11 | 4.7922e+10 |
| 64 | pr | 76.00, 76.51, 75.92 | **75.998** | 0.8 % | 75.17 | 683 | 6 | 7.8756e+11 | 4.7922e+10 |
| 64 | ept2 | 60.24, 59.24, 60.39 | **60.237** | 1.9 % | 59.42 | 683 | 6 | 7.8756e+11 | 4.7923e+10 |

| base | pr / main | ept2 / main | ept2 / pr |
|---|---|---|---|
| 58 | **×1.116** (10.4 % saved) | **×1.218** (17.9 % saved) | **×1.091** |
| 60 | **×1.098** (8.9 % saved) | **×1.163** (14.0 % saved) | **×1.059** |
| 62 | **×1.156** (13.5 % saved) | **×1.349** (25.8 % saved) | **×1.167** |
| 64 | **×1.250** (20.0 % saved) | **×1.577** (36.6 % saved) | **×1.262** |

| base | tree | Δ survivors vs main | Δ checked vs main | Δchecked/Δsurvivors |
|---|---|---|---|---|
| 58 | pr | -3.749e+03 (-6.18e-09) | +3.463e+03 (+1.01e-07) | -0.924 |
| 58 | ept2 | -2.415e+03 (-3.98e-09) | +2.210e+03 (+6.46e-08) | -0.915 |
| 60 | pr | +6.474e+06 (+1.41e-05) | -6.034e+06 (-1.85e-04) | -0.932 |
| 60 | ept2 | +1.031e+07 (+2.25e-05) | -9.628e+06 (-2.96e-04) | -0.934 |
| 62 | pr | -1.550e+04 (-9.48e-08) | +1.559e+04 (+1.55e-06) | -1.006 |
| 62 | ept2 | -4.177e+03 (-2.55e-08) | +4.414e+03 (+4.40e-07) | -1.057 |
| 64 | pr | -9.902e+04 (-1.26e-07) | +9.487e+04 (+1.98e-06) | -0.958 |
| 64 | ept2 | -2.684e+05 (-3.41e-07) | +2.538e+05 (+5.30e-06) | -0.945 |


#### Production size: 20 fields of 1e14 per base (s/field)

| base | tree | rounds | **median** | spread | device s/field (median) | batches | slots | survivors | checked |
|---|---|---|---|---|---|---|---|---|---|
| 58 | main | 1.489, 1.543, 1.552 | **1.543** | 4.1 % | 1.54 | 211 | 16 | 6.5277e+10 | 3.6820e+09 |
| 58 | pr | 0.982, 0.982, 0.984 | **0.982** | 0.2 % | 0.98 | 211 | 16 | 6.5277e+10 | 3.6820e+09 |
| 58 | ept2 | 0.904, 0.916, 0.913 | **0.913** | 1.3 % | 0.91 | 211 | 16 | 6.5277e+10 | 3.6820e+09 |
| 60 | main | 1.298, 1.336, 1.343 | **1.336** | 3.4 % | 1.33 | 214 | 16 | 4.5680e+10 | 3.0600e+09 |
| 60 | pr | 0.782, 0.787, 0.780 | **0.782** | 0.9 % | 0.78 | 214 | 16 | 4.5680e+10 | 3.0600e+09 |
| 60 | ept2 | 0.754, 0.759, 0.741 | **0.754** | 2.4 % | 0.75 | 214 | 16 | 4.5680e+10 | 3.0600e+09 |
| 62 | main | 1.769, 1.810, 1.830 | **1.810** | 3.4 % | 1.81 | 241 | 16 | 2.4395e+10 | 1.4950e+09 |
| 62 | pr | 0.795, 0.802, 0.800 | **0.800** | 0.9 % | 0.80 | 241 | 16 | 2.4395e+10 | 1.4950e+09 |
| 62 | ept2 | 0.716, 0.722, 0.702 | **0.716** | 2.8 % | 0.71 | 241 | 16 | 2.4395e+10 | 1.4950e+09 |
| 64 | main | 2.228, 2.268, 2.294 | **2.268** | 2.9 % | 2.27 | 256 | 16 | 6.5747e+10 | 4.0000e+09 |
| 64 | pr | 1.043, 1.025, 1.050 | **1.043** | 2.4 % | 1.04 | 256 | 16 | 6.5747e+10 | 4.0000e+09 |
| 64 | ept2 | 0.855, 0.848, 0.865 | **0.855** | 2.0 % | 0.85 | 256 | 16 | 6.5747e+10 | 4.0000e+09 |

| base | pr / main | ept2 / main | ept2 / pr |
|---|---|---|---|
| 58 | **×1.571** (36.4 % saved) | **×1.690** (40.8 % saved) | **×1.076** |
| 60 | **×1.708** (41.5 % saved) | **×1.772** (43.6 % saved) | **×1.037** |
| 62 | **×2.262** (55.8 % saved) | **×2.528** (60.4 % saved) | **×1.117** |
| 64 | **×2.174** (54.0 % saved) | **×2.653** (62.3 % saved) | **×1.220** |

| base | tree | Δ survivors vs main | Δ checked vs main | Δchecked/Δsurvivors |
|---|---|---|---|---|
| 58 | pr | +0.000e+00 (+0.00e+00) | +0.000e+00 (+0.00e+00) | nan |
| 58 | ept2 | +0.000e+00 (+0.00e+00) | +0.000e+00 (+0.00e+00) | nan |
| 60 | pr | +0.000e+00 (+0.00e+00) | +0.000e+00 (+0.00e+00) | nan |
| 60 | ept2 | +0.000e+00 (+0.00e+00) | +0.000e+00 (+0.00e+00) | nan |
| 62 | pr | +0.000e+00 (+0.00e+00) | +0.000e+00 (+0.00e+00) | nan |
| 62 | ept2 | +0.000e+00 (+0.00e+00) | +0.000e+00 (+0.00e+00) | nan |
| 64 | pr | +0.000e+00 (+0.00e+00) | +0.000e+00 (+0.00e+00) | nan |
| 64 | ept2 | +0.000e+00 (+0.00e+00) | +0.000e+00 (+0.00e+00) | nan |


- **Survivors and full checks:** at 1e14 they are identical to the last digit across all three trees, every base and every round. At 1e16 they differ by at most 2e-5 relative (b60), with Δchecked/Δsurvivors ≈ −0.93. That is the timing-dependent stage overrun (the overrun table below), present on both trees alike.
- **Layouts are identical** between trees: batches and partitions per launch are equal at every base and size.


## NiceMark nice-only

`nicemark.sh`: `RUST_LOG=info nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, main / pr / ept2 (`pr/join-ept-2`) interleaved × 3 (`ab/nm_r*_{main,pr,ept2}.{json,err}`). Not uploaded.

#### NiceMark nice-only

| scenario | main rates (median) | pr rates (median) | ept2 rates (median) | pr / main | ept2 / main | routes |
|---|---|---|---|---|---|---|
| b58_msd_weak | 1.088e+14, 1.097e+14, 1.096e+14 (**1.096e+14**) | 1.309e+14, 1.302e+14, 1.322e+14 (**1.309e+14**) | 1.455e+14, 1.432e+14, 1.441e+14 (**1.441e+14**) | **1.193** | **1.314** | join |
| b58_msd_strong | 5.861e+14, 5.894e+14, 5.974e+14 (**5.894e+14**) | 8.369e+14, 8.186e+14, 8.176e+14 (**8.186e+14**) | 8.675e+14, 8.707e+14, 8.700e+14 (**8.700e+14**) | **1.389** | **1.476** | join |
| b60_msd_weak | 2.262e+14, 2.272e+14, 2.281e+14 (**2.272e+14**) | 2.610e+14, 2.614e+14, 2.622e+14 (**2.614e+14**) | 2.827e+14, 2.886e+14, 2.853e+14 (**2.853e+14**) | **1.151** | **1.256** | join |
| b62_msd_weak | 2.631e+14, 2.629e+14, 2.646e+14 (**2.631e+14**) | 3.093e+14, 3.098e+14, 3.066e+14 (**3.093e+14**) | 3.583e+14, 3.585e+14, 3.593e+14 (**3.585e+14**) | **1.176** | **1.362** | join |
| **score** | 2440, 2451, 2465 (**2451**) | 3015, 2997, 3001 (**3001**) | 3306, 3314, 3310 (**3310**) | **1.224** | **1.350** | |


- Every scenario took `route: join` on every tree. The samples cover all 3364 partitions of the b58 scenarios (1 slice, 16 per launch), and 565–585 of 3600 (b60) and 774–816 of 3844 (b62) partitions of the first of 2 slices.
- The references in `bench_defs.rs` were pinned on main; on the PR they read about 22 % high on this card (17 % on the 4090), 35 % with EPT 2.


## Phase split (profiled)

`prof.sh`: the experiment trees with `NICE_EXP_GPU_PROFILE=1`, one 1e16 field per base after the warm-up (`ab/prof_{xmain,xpr}.log`):

```
NICE_EXP_GPU_PROFILE=1 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=... \
  /root/bins/{xmain,xpr}/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1
```

#### Profiled phase split (NICE_EXP_GPU_PROFILE=1), seconds per field (mean of the fields)

| base | tree | ept | device (profiled) | top | bucket | join | check | other | listed/field | pairs/field | padded/pairs | survivors/field | checked/field |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 58 | xmain | 4 | 81.83 | 20.00 (24.4 %) | 0.70 (0.9 %) | 56.77 (69.4 %) | 3.00 (3.7 %) | 1.36 (1.7 %) | 2.138e+10 | 2.581e+13 | 1.07 | 3.087e+11 | 1.743e+10 |
| 58 | xpr | 4 | 73.37 | 20.20 (27.5 %) | 0.36 (0.5 %) | 48.53 (66.1 %) | 3.03 (4.1 %) | 1.25 (1.7 %) | 7.836e+09 | 9.782e+12 | 2.81 | 3.087e+11 | 1.743e+10 |
| 60 | xmain | 4 | 56.54 | 15.68 (27.7 %) | 0.76 (1.4 %) | 35.92 (63.5 %) | 2.62 (4.6 %) | 1.55 (2.7 %) | 2.373e+10 | 1.279e+13 | 1.10 | 2.265e+11 | 1.609e+10 |
| 60 | xpr | 4 | 50.70 | 15.78 (31.1 %) | 0.41 (0.8 %) | 30.26 (59.7 %) | 2.60 (5.1 %) | 1.64 (3.2 %) | 8.835e+09 | 5.437e+12 | 2.59 | 2.265e+11 | 1.608e+10 |
| 62 | xmain | 6 | 40.02 | 12.12 (30.3 %) | 0.55 (1.4 %) | 25.12 (62.8 %) | 1.23 (3.1 %) | 1.00 (2.5 %) | 1.733e+10 | 1.075e+13 | 1.29 | 1.171e+11 | 7.184e+09 |
| 62 | xpr | 6 | 34.36 | 11.88 (34.6 %) | 0.23 (0.7 %) | 20.04 (58.3 %) | 1.19 (3.5 %) | 1.01 (3.0 %) | 4.551e+09 | 2.823e+12 | 4.91 | 1.171e+11 | 7.184e+09 |
| 64 | xmain | 6 | 94.50 | 8.24 (8.7 %) | 0.62 (0.7 %) | 81.92 (86.7 %) | 2.92 (3.1 %) | 0.79 (0.8 %) | 2.001e+10 | 3.748e+13 | 1.27 | 3.940e+11 | 2.398e+10 |
| 64 | xpr | 6 | 75.93 | 8.07 (10.6 %) | 0.22 (0.3 %) | 63.99 (84.3 %) | 2.88 (3.8 %) | 0.78 (1.0 %) | 4.641e+09 | 8.694e+12 | 5.47 | 3.940e+11 | 2.398e+10 |

| base | phase | main s | PR s | saved s | share of the saving |
|---|---|---|---|---|---|
| 58 | top | 20.00 | 20.20 | -0.20 | -2 % |
| 58 | bucket | 0.70 | 0.36 | +0.34 | 4 % |
| 58 | join | 56.77 | 48.53 | +8.24 | 97 % |
| 58 | check | 3.00 | 3.03 | -0.02 | -0 % |
| 58 | other | 1.36 | 1.25 | +0.11 | 1 % |
| 58 | **device** | 81.83 | 73.37 | +8.46 | 100 % |
| 60 | top | 15.68 | 15.78 | -0.09 | -2 % |
| 60 | bucket | 0.76 | 0.41 | +0.35 | 6 % |
| 60 | join | 35.92 | 30.26 | +5.66 | 97 % |
| 60 | check | 2.62 | 2.60 | +0.01 | 0 % |
| 60 | other | 1.55 | 1.64 | -0.09 | -2 % |
| 60 | **device** | 56.54 | 50.70 | +5.84 | 100 % |
| 62 | top | 12.12 | 11.88 | +0.23 | 4 % |
| 62 | bucket | 0.55 | 0.23 | +0.31 | 6 % |
| 62 | join | 25.12 | 20.04 | +5.08 | 90 % |
| 62 | check | 1.23 | 1.19 | +0.04 | 1 % |
| 62 | other | 1.00 | 1.01 | -0.01 | -0 % |
| 62 | **device** | 40.02 | 34.36 | +5.66 | 100 % |
| 64 | top | 8.24 | 8.07 | +0.18 | 1 % |
| 64 | bucket | 0.62 | 0.22 | +0.40 | 2 % |
| 64 | join | 81.92 | 63.99 | +17.93 | 97 % |
| 64 | check | 2.92 | 2.88 | +0.05 | 0 % |
| 64 | other | 0.79 | 0.78 | +0.01 | 0 % |
| 64 | **device** | 94.50 | 75.93 | +18.56 | 100 % |


- **The saving is the join kernel's** (90–97 % of it). The bucket kernel halves (−0.3–0.4 s), but with one slice per field it is under 1.5 % of the time. top, check and other do not move.
- **Pairs fall 57–77 %, the join 14–22 %.** Padded lane-pairs (each bucket rounded up to whole waves) are equal on both trees at every base: b58 2.76e13, b60 1.41e13, b62 1.39e13, b64 4.76e13. Every bucket is one wave on either tree (1,024 entries at EPT 4, 1,536 at EPT 6, against about 280–420 pruned entries). GPU-RESULTS' cost model (0.58 ps per padded lane-pair plus 74 ps per survivor) would predict no saving at all, so a lane without an entry must cost much less than one with an entry: it skips the `lists`/`ext_m`/`bp_r` gathers. The prune saves the entries' loads and ANDs, and two entries per thread recover the empty lanes (EPT2-3080.md).
- Profiling overhead against the unprofiled A/B (device seconds, one field against the 2-field median): main +2.0 % (b58), +0.9 % (b60), +0.4 % (b64); b62's A/B median mixes a dense and a sparse field, so it is not comparable.
- The overrun counts in these runs match the flush experiment's (b60 4.0e-3 on both trees).


## The survivor stage (the flush fix that is not in the PR)

`join_kernel` stages each chunk's survivors (32 tops × one wave of entries) in a 1,024-entry shared stage and flushes it through the prefilter after a chunk once it holds 512 or more (`SURV_FLUSH`). A survivor that finds the stage full goes to the list unprefiltered and uncounted. The experiment trees count those directly: at each flush the overrun is `sc − SURV_SH_CAP`, read back per batch (`EXP_OVERRAN`).

One 1e16 field per base, `flush.sh`, logs `ab/fl_*.log`:

| base | main, flush at 512 | PR, flush at 512 (2 rounds) | PR, flush at 256 (2 rounds) | PR, flush at 128 |
|---|---|---|---|---|
| 58 | 35,231 (1.1e-7) | 36,684 / 36,329 (1.2e-7) | 0 | 0 |
| 60 | 916,729,535 (**4.0e-3**) | 913,105,429 / 910,565,270 (**4.0e-3**) | 0 | 0 |
| 62 | 3,247,108 (2.8e-5) | 3,232,150 / 3,234,745 (2.8e-5) | 0 | 0 |
| 64 | 14,543,863 (3.7e-5) | 14,654,113 / 14,657,063 (3.7e-5) | 0 | 0 |

- **On new main the prune does not raise the overrun.** The PR's share equals main's at every base (within 1 % of the count, which is timing-dependent). Yesterday's rise came from EPT 4: an unpruned b62/b64 bucket (about 1,200 entries) spread its survivors over two waves, a pruned one put them in one. #205 (EPT 6 from base 62) already puts every unpruned bucket in one wave, so main stages the same survivors per chunk as the prune.
- **b64 is under the dense test's 1e-4 limit on both trees** (3.7e-5); the dense-field test at b64 1e16 passes on the PR (tests below).
- **b60 is main's own problem:** 0.4 % of the survivors (9.1e8 per field) skip the prefilter, which is 5.3 % more full checks (16.08e9 against 15.23e9 with no overrun). A b60 chunk stages about 540 survivors on average (32 tops × 931 entries × 1.8 % AND pass), more than the 512 left after a half-full stage. The kernel comment's "about 2e-5 ... and no more on larger fields" no longer holds.
- **Flushing at a quarter (256) removes every overrun** at all four bases; the counted survivors become exact (b60 2.2740e11 against 2.2649e11) and b60's full checks fall 5.3 %. 128 gives the same counts.
- **But it costs 1–2 % at b58/b64** on this card (device seconds, PR tree, the two rounds in opposite order):

| base | flush 512: r1, r2 (mean) | flush 256: r1, r2 (mean) | 256 vs 512 | flush 128 (r1) |
|---|---|---|---|---|
| 58 | 72.53, 72.91 (72.72) | 74.78, 73.64 (74.21) | +2.0 % | 74.70 |
| 60 | 50.25, 50.53 (50.39) | 50.60, 50.17 (50.39) | 0.0 % | 50.52 |
| 62 | 34.46, 33.87 (34.17) | 34.50, 34.53 (34.52) | +1.0 % | 34.64 |
| 64 | 75.16, 75.05 (75.11) | 76.71, 76.57 (76.64) | +2.0 % | 76.60 |

  At 256 and at 128 a chunk at b58/b64 (about 430 survivors on average) almost always triggers a flush, against about every 1.5 chunks at 512: the cost is the per-flush barriers and the partly filled last round. b60 breaks even (the 5 % fewer full checks pay for it).
- **Decision: the PR keeps 512.** The prune's ripple that the fix was meant for does not exist on new main, and the candidate fix is not free. The draft is in `pr-raw/3080/flush-quarter.diff`. Untested alternatives that keep the flush rate: a 2,048-entry stage at 512 (8 KiB more shared memory per cube, 22 KiB in all, which needs checking against wgpu/Metal limits), or prefiltering the overflow inline.

## Exactness and lint (the PR's head, `941e39e`)

`lint.sh` (`lint_final.log`), `chain3.sh`'s host tests (`hosttests.log`), `tests2.sh` (`tests2.log`), all on `941e39e` (binary md5 `5549f33c`):

| check | command | result |
|---|---|---|
| fmt | `cargo fmt --all --check` | clean |
| clippy, default features | `cargo clippy -p nice_common -p nice_client --all-targets -- -D warnings` | clean |
| clippy, gpu | `... --features nice_client/gpu -- -D warnings` | clean |
| clippy, gpu + spirv | `... --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings` | clean |
| host tests | `nice_common_test --test-threads 8` (gpu features) | **207 passed**, 33 ignored |
| the prune's unit test | `cpu_join::tests::the_field_prune_drops_exactly_the_bottoms_that_meet_the_certificate --nocapture` | passes; listed bottoms per partition at 1e14: b42 0 % (empty certificate), b50 39.7 %, b57 81.5 %, b60 82.3 %, b62 86.3 %, b64 85.0 % pruned (6–9 certificate digits from b57) |
| CUDA parity | `cubecl_cuda_join_matches_the_cpu_reference` | passes (also on `26a8b15` before the A/B, `early_ref.log`) |
| dense field, b58 1e15 | `NICE_TEST_JOIN_DENSE=32 ... on_a_dense_field` | passes; **0** survivors overran the stage |
| dense field, b64 1e16 (the A/B field) | `NICE_TEST_JOIN_DENSE=8 NICE_TEST_JOIN_DENSE_FIELD=64:41242006262957161709568:1e16 ...` | passes; 19,069 overran, **2.5e-5**, under the 1e-4 limit |
| CPU join vs the unpruned reference | `NICE_TEST_CPU_JOIN_REF=2 cpu_join_matches_the_reference_on_production_fields` | passes (b42–b64) |
| join vs stride | `NICE_TEST_JOIN_COMPARE=1`, 2 fields of 1e14 per base at the A/B starts | found 0 = 0 at b58/60/62/64 (stride 17–49 s per field against 0.9–1.4 s) |

- The whole-field b42 test was not rerun: its certificate is empty, so the prune is a no-op there. It passed on the 4090 on `26a8b15`.
- The 1e14 timing runs are a stronger exactness check at production size: survivors and full checks are identical to the last digit across main, the PR and `pr/join-ept-2`, at every base and in every round.
- `941e39e` against the timed `26a8b15`: when a range's certificate meets every residue of `bpre`, the prune now keeps the unpruned list (the AND still rejects every pair) instead of failing the field setup with an error. A later slice failing that way would have failed the whole field. The unit test asserts it. No timed field reaches that path, so the 1e16 A/B stands for the head.

## Not done

- The whole-field b42 test (see above), and the dense test on main at b64 (main's overrun there is counted directly: 3.7e-5).
- The flush-level exact-counter comparison on main (`exact256.sh`, flush at 256 on both trees for exact counts at 1e16). Time went to the EPT branch. The 1e14 runs give exact equality instead.

