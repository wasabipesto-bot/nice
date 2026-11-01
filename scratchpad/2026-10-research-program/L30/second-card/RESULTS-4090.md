# Second card: #235, #236 and both on an RTX 4090 (300 W cap), 2026-11-01

Trees, all on upstream main `fae7398`: `main`; `#235` = `pr/join-top-cert-fast` `6e7475e`; `#236` = `pr/join-prefilter-in-walk` `dd4a0eb`; `both` = `exp/join-235-236` `e9cdac4` (main + #235 + #236). Raw logs: `raw/` (the box's `/root/sc`). Scripts: `scripts/`. Analysis: `analyze.py` (`python3 analyze.py raw`; output in `analysis.txt`).

## Summary

- **Each PR alone is faster on the 4090 too.** Device seconds per field, interleaved, medians of 3:
  - #235: ×1.101 (b62 1e17), ×1.116 (b62 1e16), ×1.084 (b60 1e16), ×1.002 (b64 1e16, extra rounds).
  - #236: ×1.181, ×1.182, ×1.235, ×1.309.
  - `both`: ×1.341, ×1.339, ×1.361, ×1.331 / ×1.320.
  - NiceMark nice-only: #235 ×1.076, #236 ×1.167, `both` ×1.260 (10,093 → 12,718).
- **The two compound fully.** In every scenario the time savings add. `both` lands within 1.2 % of main − (saving #235) − (saving #236): −0.71 s, +0.03 s, +0.04 s and −0.08 s. That puts it at **100.6-103.1 % of the product** of the single speed-ups. Disjoint savings give slightly more than the product, and this matches the 3080 (`combined-raw`: savings add, ×1.365 at b62 1e17).
- **On the 4090, #235 does nothing at b64.** At b64 1e16 it measured ×1.002 (−0.04 s of 18.2 s; the 3080 gave ×1.040). Everywhere else #235 gains slightly more on the 4090 than on the 3080, and #236 gains about the same (−3 % to +1 %).
- **Exactness on `both`:**
  - `cubecl_cuda_join_matches_the_cpu_reference` passes on the 4090.
  - At 1e14 (b57/60/62/64, `NICE_TEST_JOIN_COMPARE=1`), join = stride, and the survivor and checked counts equal main's to the last digit.
  - At 1e16/1e17, `both`'s counts are the same in every run, equal #236's, and equal the exact counts the 3080 produced in L30.
  - main and #235 come up short by the stage overrun (unchanged behaviour, see §3).
- **Card:** the power limit is set to 300 W (default and max 450 W). The card sits on that cap: 2,360-2,470 MHz, 288-300 W, at most 71 °C. The only throttle reason is the SW power cap; the thermal-slowdown counters read 0. So it is power-limited, not thermally limited.

## 0. Setup

- **Box:** Vast 58626188 (`nice-research-second-card`), machine m58187, created 06:19:59 UTC.
  - RTX 4090 24 GB, driver 580.178.04, PCIe gen3 ×16.
  - **Power limit 300 W** (default 450, min 150, max 450). Max SM clock 3,105 MHz. See `raw/power.txt` (idle), `raw/power_after.txt` (after the runs), `raw/gpu.csv`.
  - Xeon Gold 6133, cgroup quota 15.36 CPUs, 129 GB RAM.
  - Toolchain 1.99.1 (`rust-toolchain.toml`).
- **Sources and builds:**
  - Sources: `git archive` of the four commits on ivory, unpacked on the box (`raw/src_md5.txt`).
  - main's test binary was built first in `/root/tgt_main`. That target dir was then copied to `/root/tgt_{p235,p236,both}`, and the remaining seven builds ran as four parallel streams.
  - Each build did `cargo clean --release -p nice_common -p nice_client` first (`scripts/buildtree.sh`, `scripts/chain_build.sh`).
  - Commands: `cargo test --release -p nice_common --features gpu --no-run` and `cargo build --release -p nice_client --features gpu`.
- **Provenance** (`raw/provenance.txt`). Each test binary carries its own PR's test strings and not the other PR's.
  - Test binaries: main `105d68f4`, #235 `7718acc5`, #236 `4db573d2`, both `8f421599`.
  - Clients: main `600b0288`, #235 `26b48d0a`, #236 `ac061178`, both `9af4f2bd`.
  - main's two binaries are bit-identical to L30's 3080 builds (`105d68f4`, `600b0288`).
- **Fixed fields:**
  - Harness: `cubecl_cuda_join_throughput_fixed_fields` with `NICE_TEST_JOIN_FIELDS/SIZE/BASES/STARTS` (`scripts/run.sh`).
  - Starts: b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568.
  - Every process first runs one untimed 1e14 warm-up field.
  - Metric: the harness's `device=` (device wall seconds per field). `per_field` is reported alongside.
  - Rounds interleaved main → #235 → #236 → both (`scripts/chain_ff.sh`, 06:39:45-07:07:45 UTC).
  - Nothing else ran on the box.
  - "Clock" = mean SM MHz over the 5 s `nvidia-smi` samples at ≥ 90 % utilisation.
- **Timeline:**
  - Builds: 06:24-06:40.
  - Exactness: 06:33-06:38, during the client builds.
  - Fixed fields: 06:40-07:08.
  - NiceMark: 07:08-07:14.
  - Extra b64 four-way: 07:14-07:20.

## 1. Fixed fields (device s per field; speed-up = main / tree, from the medians)

Spread = (max − min) / median.

### b62 1e17, 1 field, 3 rounds

| tree | runs | median | spread | speed-up | per-round | saving | clock / W |
|---|---|---|---|---|---|---|---|
| main | 80.249, 80.483, 79.763 | 80.249 | 0.9 % | — | — | — | 2359 MHz / 295 W |
| #235 | 72.878, 72.181, 72.970 | 72.878 | 1.1 % | **×1.101** | 1.101, 1.115, 1.093 | −7.37 s | 2366 / 297 |
| #236 | 67.930, 67.828, 68.012 | 67.930 | 0.3 % | **×1.181** | 1.181, 1.187, 1.173 | −12.32 s | 2383 / 292 |
| both | 59.829, 60.941, 59.849 | 59.849 | 1.9 % | **×1.341** | 1.341, 1.321, 1.333 | −20.40 s | 2395 / 300 |

### b62 1e16, 2 fields, 3 rounds

| tree | runs | median | spread | speed-up | per-round | saving |
|---|---|---|---|---|---|---|
| main | 6.706, 6.647, 6.673 | 6.673 | 0.9 % | — | — | — |
| #235 | 6.067, 5.977, 5.973 | 5.977 | 1.6 % | **×1.116** | 1.105, 1.112, 1.117 | −0.70 s |
| #236 | 5.660, 5.644, 5.579 | 5.644 | 1.4 % | **×1.182** | 1.185, 1.178, 1.196 | −1.03 s |
| both | 5.014, 4.982, 4.967 | 4.982 | 0.9 % | **×1.339** | 1.337, 1.334, 1.343 | −1.69 s |

### b60 1e16, 2 fields, 3 rounds

| tree | runs | median | spread | speed-up | per-round | saving |
|---|---|---|---|---|---|---|
| main | 14.971, 15.240, 15.152 | 15.152 | 1.8 % | — | — | — |
| #235 | 13.988, 13.853, 13.973 | 13.973 | 1.0 % | **×1.084** | 1.070, 1.100, 1.084 | −1.18 s |
| #236 | 12.247, 12.271, 12.317 | 12.271 | 0.6 % | **×1.235** | 1.222, 1.242, 1.230 | −2.88 s |
| both | 11.121, 11.132, 11.223 | 11.132 | 0.9 % | **×1.361** | 1.346, 1.369, 1.350 | −4.02 s |

### b64 1e16, 2 fields

As requested: main vs both, 2 rounds.

| tree | runs | median | spread | speed-up | per-round | saving |
|---|---|---|---|---|---|---|
| main | 17.829, 18.352 | 18.090 | 2.9 % | — | — | — |
| both | 13.635, 13.557 | 13.596 | 0.6 % | **×1.331** | 1.308, 1.354 | −4.49 s |

**Extra rounds, not in the requested protocol.** b64 1e16, four-way, 2 rounds, run right after NiceMark (`scripts/chain_extra.sh`). They were added so the b64 compounding check uses single-PR numbers from this card.

| tree | runs | median | spread | speed-up | per-round | saving |
|---|---|---|---|---|---|---|
| main | 18.086, 18.319 | 18.203 | 1.3 % | — | — | — |
| #235 | 18.144, 18.188 | 18.166 | 0.2 % | **×1.002** | 0.997, 1.007 | −0.04 s |
| #236 | 13.966, 13.847 | 13.906 | 0.9 % | **×1.309** | 1.295, 1.323 | −4.30 s |
| both | 13.785, 13.795 | 13.790 | 0.1 % | **×1.320** | 1.312, 1.328 | −4.41 s |

Pooled main vs both at b64 (4 rounds each): medians 18.20 / 13.71 s, ×1.328.

### Notes on the fixed fields

- **Clocks.** Every tree sits at the 300 W cap: 2,361-2,468 MHz mean, 288-300 W.
  - Clock-normalised speed-ups differ from the raw ones by at most 2.1 % (`analysis.txt`). The largest case is both at b60: ×1.332 normalised vs ×1.361 raw, because its mean clock was 2 % higher than main's.
  - Under a power cap, a higher clock is partly the code's own doing (less power per unit of work), so the raw figures are the ones quoted.
- **`per_field` vs `device=`.** `per_field` includes ~1 s per field of host time outside the device wall. It gives slightly smaller ratios at 1e16: both ×1.285 (b62), ×1.321 (b60), ×1.303 (b64 extra); at b62 1e17, ×1.329. The ordering and the compounding are the same (`analysis.txt`).
- **Layouts** are identical across trees: slots 6 / 16 / 6 / 10. The plan grows +4 / +6 / +3 / +7 MiB for #236 and both (`ext_q`).
- **No regression anywhere.** The worst per-round ratio for any PR tree is #235's 0.997 at b64, against main's own spread of 1.3 %.

## 2. Do #235 and #236 compound?

Device seconds, medians. Two predictions are compared:
- **Product:** S235 × S236.
- **Additive:** main − (main − #235) − (main − #236) = #235 + #236 − main. This is what disjoint savings give, because #235 shrinks the top kernel and #236 the join kernel.

| field | S235 | S236 | product | additive prediction | measured both | both / product | interaction (measured − additive) |
|---|---|---|---|---|---|---|---|
| b62 1e17 | 1.101 | 1.181 | ×1.301 | 60.56 s (×1.325) | 59.85 s (**×1.341**) | **103.1 %** | −0.71 s (−1.2 %) |
| b62 1e16 | 1.116 | 1.182 | ×1.320 | 4.948 s (×1.349) | 4.982 s (**×1.339**) | **101.5 %** | +0.034 s (+0.7 %) |
| b60 1e16 | 1.084 | 1.235 | ×1.339 | 11.092 s (×1.366) | 11.132 s (**×1.361**) | **101.7 %** | +0.040 s (+0.4 %) |
| b64 1e16 (extra four-way) | 1.002 | 1.309 | ×1.312 | 13.870 s (×1.312) | 13.790 s (**×1.320**) | **100.6 %** | −0.08 s (−0.6 %) |
| NiceMark score | 1.076 | 1.167 | ×1.256 | — | **×1.260** | **100.4 %** | — |

- **Yes, they compound fully.** In every fixed field, `both` is within ±1.2 % of the additive prediction and at or above the product.
- **Why above the product.** When two changes cut disjoint parts of the time, the combined speed-up T / (T − s1 − s2) exceeds the product T² / ((T − s1)(T − s2)) by the s1·s2 term. Each PR keeps its full absolute saving on top of the other.
- **Same picture on the 3080.** `combined-raw`'s same-box run at b62 1e17 gave #235 ×1.100, #236 ×1.210, both ×1.365: additive prediction ×1.361, product ×1.332, interaction −0.49 s.
- **The b64 shortfall on the 3080 was a reference mismatch.** There, `both` came in at 96.5 % of the product. That product used L29/L30's single-PR numbers from other boxes (#235 ×1.040). On this card, with all four trees on one box, #235 is worth nothing at b64, and `both` = #236 + 0.1 s of extra saving.

### 4090 vs 3080 (speed-up = main / tree)

| field | #235 3080 (L29) → 4090 | #236 3080 (L30) → 4090 | both 3080 (`combined-raw`, device) → 4090 |
|---|---|---|---|
| b62 1e17 | ×1.075 → **×1.101** | ×1.215 → **×1.181** | ×1.365 → **×1.341** |
| b62 1e16 | ×1.089 → **×1.116** | ×1.182 → **×1.182** | ×1.350 → **×1.339** |
| b60 1e16 | ×1.053 → **×1.084** | ×1.241 → **×1.235** | ×1.379 → **×1.361** |
| b64 1e16 | ×1.040 → **×1.002** | ×1.300 → **×1.309** | ×1.305 → **×1.331** (requested) / ×1.320 (extra) |
| NiceMark | ×1.071 → **×1.076** | ×1.194 → **×1.167** | ×1.325 → **×1.260** |

- The 3080 references come from different metrics and boxes: L29 used `per_field` on its own box; L30 and `combined-raw` used `device=`, both at 180 W.
- **Absolute speed.** main's b62 1e17 field takes 80.2 s on the 4090 at 300 W, against 226 s on the 3080 at 180 W (×2.8).
- **The 4090's NiceMark ratio is the weakest number.** The 4090 runs each sweep in ~36 s, with single-repetition scenarios of 0.5-7 s each (b58 MSD-strong: 0.54 s). main's score spread is 3.8 %. The fixed fields are the better measure on this card.

## 3. Exactness (`both`, CUDA on the 4090)

| check | command | result | log |
|---|---|---|---|
| CPU reference, every test window | `scripts/test.sh x_ref both cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference` | ok (101.7 s); covers b10-b64, b50/b54, the b57 frontier, tight, refused and sliced layouts | `raw/x_ref.log` |
| 1e14 at b57/60/62/64, `NICE_TEST_JOIN_COMPARE=1` (asserts stride = join nice numbers) | `scripts/run.sh both_cmp_e14 both 57,60,62,64 1 1e14 1`, the same for main | both ok; counts identical, below | `raw/both_cmp_e14.log`, `raw/main_cmp_e14.log` |

**1e14 counts.** main = both, and both equal L30's 3080 table:

| base | join survivors | checked | hits | plan MiB main → both |
|---|---|---|---|---|
| 57 | 4,850,227,888 | 268,123,373 | 0 | 1592 → 1600 |
| 60 | 2,694,700,282 | 180,517,288 | 0 | 1599 → 1608 |
| 62 | 1,439,469,648 | 88,159,810 | 0 | 1765 → 1776 |
| 64 | 5,702,041,796 | 346,647,759 | 0 | 1809 → 1820 |

**1e16/1e17 counts.** #236 and both give one value per field across all their runs. It is identical to the exact count the 3080 produced in L30.

main and #235 vary run to run by the stage overrun (#235 does not touch the stage). Main's extra full checks are the overrun minus the field's keep rate, as on the 3080.

| field | both = #236 (survivors / checked) | main and #235 overrun (exact − survivors) | rate | main and #235 extra checks |
|---|---|---|---|---|
| b62 1e17 | 1,020,844,021,499 / 62,584,252,554 | 109.40-109.63 M | 1.07e-4 | 102.6-102.8 M (overrun × 0.938) |
| b62 1e16 ×2 | 163,513,599,082 / 10,027,698,695 | 2.67-2.69 M | 1.6e-5 | 2.50-2.53 M |
| b60 1e16 ×2 | 460,847,952,346 / 30,871,838,404 | 1,426.5-1,429.9 M | **3.1e-3** | 1,330.8-1,334.0 M (overrun × 0.933) |
| b64 1e16 ×2 | 787,584,956,227 / 47,900,853,327 | 17.24-17.30 M | 2.2e-5 | 16.18-16.24 M |

No hits anywhere. In NiceMark, the whole-field scenarios agree:
- b58 MSD-strong is identical in all four trees (4,027,773,430 / 226,773,299).
- b58 MSD-weak: #236 and both give 33,590,315,220 / 1,894,592,860 every run, the 3080's exact count; main and #235 come up 29-140 survivors short.
- The b60/b62 scenarios sample a time-dependent number of partitions, so their counts are not comparable.

## 4. NiceMark nice-only

`client_<tree> niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, run with `NICE_API_BASE=http://127.0.0.1:9` (no API traffic). Rounds interleaved main → #235 → #236 → both (`scripts/chain_nm.sh`). JSON in `raw/nm_*.json`.

| | main | #235 | #236 | both |
|---|---|---|---|---|
| **score** (runs) | 9989.1, 10372.4, 10093.0 | 10802.2, 10859.0, 10887.7 | 11720.4, 11857.4, 11778.5 | 12718.2, 12879.2, 12643.1 |
| median (spread) | 10093.0 (3.8 %) | 10859.0 (0.8 %) | 11778.5 (1.2 %) | 12718.2 (1.9 %) |
| **vs main** | — | **×1.076** | **×1.167** | **×1.260** |
| per-round | — | 1.081, 1.047, 1.079 | 1.173, 1.143, 1.167 | 1.273, 1.242, 1.253 |
| b58 MSD-weak, n/s (median) | 4.512e14 | 4.749e14 ×1.052 | 5.486e14 ×1.216 | 5.955e14 ×1.320 |
| b58 MSD-strong | 2.489e15 | 2.556e15 ×1.027 | 2.837e15 ×1.139 | 2.910e15 ×1.169 |
| b60 MSD-weak | 8.784e14 | 9.760e14 ×1.111 | 1.001e15 ×1.139 | 1.085e15 ×1.236 |
| b62 MSD-weak | 1.111e15 | 1.258e15 ×1.132 | 1.323e15 ×1.191 | 1.503e15 ×1.353 |

- Each sweep took ~36 s; the 150 s budget is not used up.
- The 5 s `nvidia-smi` trace catches 0-1 samples at ≥ 90 % utilisation per sweep, so there are no NiceMark clock numbers. The fixed-field runs show where the card sits under load.
- Scenario ranges are in `analysis.txt`. main's b62 MSD-weak has one high run (1.237e15 against 1.104-1.111e15).

## 5. Box

- The box is idle since 07:20 UTC. It self-destroys around 08:50 UTC (the onstart timer is 9,000 s), at $0.32/h.
- `vast.py destroy` was not run: it is outside this task's allowed commands.
