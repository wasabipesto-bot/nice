# L36 RESULTS: the five open PRs together (`exp/join-all5`), RTX 3080 at 150 W (2026-11-03)

Branch **`exp/join-all5`** on the fork, head **`6ddab24`** (no PR) = `exp/join-all3` `0f1a8a7` (main `04693ac` + #235 +
#236 + #237) + `pr/top-fd` `c7ef3c8` (#240) + `pr/join-transpose-and` `775b6d9` (#239). Raw logs: `raw/box/` (the
box's `/root/l36/logs`). Scripts: `raw/scripts/`. Analysis: `python3 raw/scripts/analyze.py raw/box >
raw/analysis.txt`; profiles `python3 raw/scripts/prof.py raw/box/prof_*.log > raw/profiles.txt`. The top-kernel
scoping (step 5) is in `SCOPING.md`.

## Summary

- **The five PRs merge cleanly.** `exp/join-all5` = all3 + #240 + #239: only `CHANGELOG.md` conflicted (both
  merges; every line kept); `cubecl_join.rs` auto-merged and the merged diff is the union of the two PRs' diffs.
  Pushed to the fork (`6ddab24`).
- **Exact.** On CUDA: CPU-reference join parity incl. b50/b54, #240's FD device test (26 fields, 279 batches), #235's
  certificate test (#235's counts), both dense fields equal to the CPU join, the whole b42 field. The 1e14 compare at
  b57/60/62/64 gives main's counts to the last digit (= #239's and #240's PR bodies). Every A/B round's
  survivors / checked equal all3's exact counts, at all four fields. Lavapipe join parity passes on naga and the
  direct SPIR-V compiler; CI's WGSL lint: 16 shaders, 0 flagged.
- **Speed: ×1.88 at b62 1e17, at or above the product of the per-PR ratios everywhere but b64/NiceMark (within 1 %).**
  RTX 3080 capped at **150 W** (this box; L29–L35's was 180 W), main `04693ac` vs all5, 3 interleaved rounds,
  medians of device s/field:

  | field | main → all5 | speed-up | product of per-PR ratios |
  |---|---|---|---|
  | **b62 1e17** | 280.24 → **148.92 s** | **×1.882** | ×1.843 (brief's ×1.83) |
  | b62 1e16 | 23.01 → 11.77 | **×1.955** | ×1.790 |
  | b60 1e16 | 52.65 → 29.22 | **×1.802** | ×1.760 |
  | b64 1e16 | 64.93 → 41.85 | **×1.552** | ×1.560 |
  | **NiceMark** nice-only | 3108.8 → 4991.8 | **×1.606** | ×1.625 |

  - Every round is faster by ×1.55–1.97; spreads all5 0.1–0.6 % (b60 5.3 %), main 0.9–2.8 %.
  - Above the product at b62 mainly because #240 gains more at 150 W than at the 180 W it was measured at (top
    kernel alone ×1.70–1.74 here against ×1.585), most at b62 1e16 where 12 of 13 slots step.
  - all5 ran at a lower SM clock than main during the A/B (1074 against 1162 MHz at b62 1e17), so the plain ratios
    are conservative: clock-normalised ×2.04, and a late pair at matched clocks gave ×1.962 (140.1 against 274.9 s).
- **Profile after all five** (profiled device time, probe excluded; main on the same box in brackets):
  - b62 1e17: **top 29.7 %** (42.5), bucket 1.9 % (0.9), **join 56.1 %** (50.4), check 8.2 % (4.1), other 4.1 % (2.0).
    Top 116.5 → 40.6 s (×2.87), join 138.2 → 76.7 s (×1.80); nothing else moved by more than 0.3 s.
  - b60 1e16: **top 24.3 %** (34.7), **join 59.7 %** (56.6), check 9.8 % (5.5), bucket 1.7 %, other 4.4 %.
  - The FD kernel and its clipped-block launch are in "top" (the profile commit needed a two-hunk adaptation to
    #240's `launch_top`, ~10 min). The join's AND vs walk cannot be split with these timers (one launch).
- **The top kernel's residual** (`SCOPING.md`): a stepped FD slot costs 0.219 ns per prefix at b62 1e17; the digit
  scan is a third of it (mostly per-digit bookkeeping), the append 17 %, the carry test with x mod b^c0 ~14 %, the
  step 13 %, `ndig_fast` 6 %, a floor 30 %. No single change reaches 25 %; three exact prototypes together (c0
  carried across steps −14 %, a bookkeeping-free scan path −7 %, no a/e on steps −2 %) take 22–23 % off, ×1.04 on
  whole fields.
- **The box (58924168) can be destroyed** once this report is read: every log is in `raw/box/`.

## 0. Setup

- **Box:** Vast 58924168 (`nice-research-l36-stack`), machine **m137673** (not m139250, where L29–L35 ran).
  - RTX 3080 10 GB, driver 580.159.03 (CUDA 13.0 driver API), CUDA 12.8 toolkit for offline `nvcc`.
  - **Power limit 150 W** (default 320, max 320; `box/power.txt`). L29–L35's box was capped at 180 W, so absolute
    seconds here are not comparable with theirs; ratios are.
  - Xeon E5-2630 v4, cgroup quota 19.2 CPUs, **7 GB RAM**. No GPU performance counters (`ncu`: ERR_NVGPUCTRPERM).
- **Trees** (on the box, git worktrees of the fork clone; the profile trees shipped from ivory as `git archive`):

  | tree | source | binaries (md5) |
  |---|---|---|
  | `M` | upstream main `04693ac` | `M` (test, gpu), `client_M` |
  | `S` | `exp/join-all5` `6ddab24` | `S` (test, gpu), `client_S`, `S_naga` (cubecl), `S_spv` (cubecl-spirv) |
  | `PR` | `6ddab24` + `417dff9` + `6194a21` (= `2ab1694` and `32b84af`, adapted; local only) | `PR` (profile) |
  | `MP` | `04693ac` + `5f0a722` (= `2ab1694`, clean cherry-pick; local only) | `MPR` (main's profile) |
  | `X`, `X2`, `X3`, `X4` | `exp/top-fd-ablate` `db32f95`, `cd239e0`, `1036a4c`, `47c1b36` (fork) | ablation switches and the exact prototypes (`SCOPING.md`) |

  md5 (first 8): `M` **105d68f4** (the same binary as L30's main `fae7398`: the commits since are API-only), `client_M`
  8ddc5c62, `S` dee33bc6, `client_S` af121632, `S_naga` 9372e1b1, `S_spv` 579e6734, `PR` 66ebc37f, `MPR` **d22ece14**
  (= L30's `mprof`), `X` d9276234, `X2` e50f7762, `X3` fa3592ea, `X4` 96a200ee.

  Toolchain 1.99.1 (`rust-toolchain.toml`), one shared target dir with `cargo clean -p nice_common` before each
  build, one build at a time (`scripts/chain_build.sh`); the lavapipe binaries in their own target dir.
- **Order (box UTC):**
  - Builds 05:56–06:31 (`S` 06:01, `M` 06:04, `X` 06:07, clients 06:13/06:16, `PR` 06:20, lavapipe binaries
    06:24/06:28, `MPR` 06:31).
  - CUDA exactness 06:01–06:16 and the change diagnostic 06:08, beside the builds; a first ablation round (`pre`)
    06:16–06:22 beside the builds; lavapipe 06:28–06:32.
  - Quiet ablation rounds 06:32–06:44, then **the A/B 06:44–07:35 with nothing else on the box**, then the profiles
    07:35–07:44.
  - Scoping and prototypes 07:44–09:13 (`SCOPING.md`); two niced builds overlapped the third ablation round and the
    prototypes' device tests, none overlapped the A/B or the profiles.
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60 1366406074057412100454, b62
  7997740455941656911841, b64 41242006262957161709568), one untimed 1e14 warm-up field per process; metric
  `device=` (mean device seconds per field). nvidia-smi sampled every 5 s; clock = mean SM MHz over samples at
  ≥ 90 % utilisation.

## 1. The merge

- `git worktree add .worktrees/exp-join-all5 fork/exp/join-all3 -b exp/join-all5`, then
  `git merge fork/pr/top-fd` (`5adf6d0`) and `git merge fork/pr/join-transpose-and` (`6ddab24`).
- **Only `CHANGELOG.md` conflicted, both times** (each PR adds its line under Unreleased); resolved by keeping every
  line. **`common/src/cubecl_join.rs` auto-merged both times**: #240 touches the top stage and the host's launch,
  #239 only `join_kernel` and its constants.
- Union check: the sorted +/− lines of `git diff 0f1a8a7 6ddab24 -- common/` equal those of `git diff 51410e7
  c7ef3c8` (#240) plus `git diff fb05597 775b6d9` (#239), except one `pub fn top_kernel(` line that `diff` places
  as a −/+ pair in one and not the other. Against all3: 2 files, +1628 / −188.
- Pushed to the fork as `exp/join-all5`.

## 2. Exactness (all5, CUDA unless noted; `box/x_*.log`, `box/cmp_*_e14.log`, `box/wgsl_lint*.log`, `box/lvp_*.log`)

| check | result |
|---|---|
| `cubecl_cuda_join_matches_the_cpu_reference` (`x_ref.log`): b10's 69, windows b20–b64 incl. **b50 and b54**, the b57 frontier partitions 0/1000/3248 tight and refused, refused layouts (617–976 MiB), production shape | **ok**, 87 s, 22 windows agree |
| `cubecl_cuda_top_fd_matches_the_top_kernel` (#240's, `x_fd.log`) | **ok**, 213 s: 26 fields, 279 batches (23 with a clipped block), one slot group and several, **237,948,545 tops** (L35: 237,907,266; the b60 1e16 plan's first slice here has 4,347,381 prefixes against L35's 4,348,405, the slice boundary moved by 1,024 prefixes, so the test's batches differ; both kernels agree on every batch) |
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` (#235's, `x_cert.log`) | **ok**, 122 s: **102,365 intervals, 33,582 kept, 203,413 powers scanned above c0, 69,824 with the carry** (= #235's counts) |
| dense b58 1e15, 32 partitions (`NICE_TEST_JOIN_DENSE=32`, `x_dense58.log`) | **ok**: 254,938,965 survivors / 14,396,829 checked, asserted equal to the CPU join (= L30/L34/L35) |
| dense b62 1e16, 4 partitions (`NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16`, `x_dense62.log`) | **ok**: 120,013,475 / 7,355,827, asserted equal to the CPU join (= L30's #236 counts) |
| whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`, `x_whole.log`) | **ok**, 55 s: 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference |
| `NICE_TEST_JOIN_COMPARE=1`, 1e14 at b57/60/62/64, all5 and main (`cmp_S_e14.log`, `cmp_M_e14.log`) | both pass (join = stride, found 0). **Counts identical all5 = main**, and equal to #239's and #240's PR bodies: b57 4,850,227,888 / 268,123,373; b60 2,694,700,282 / 180,517,288; b62 1,439,469,648 / 88,159,810; b64 5,702,041,796 / 346,647,759. Plan MiB main → all5: 1185 → 1193, 1192 → 1201, 1358 → 1369, 1402 → 1413 (#236's `ext_q`) |
| the A/B's whole fields (§3), 3 rounds × 4 fields | survivors / checked / found **identical in every round and equal to all3's exact counts** (b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327; found 0) |
| lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8), **naga**: `cubecl_join_matches_the_cpu_reference` (`lvp_par_naga.log`) | **ok**, 101 s, all windows incl. b50/b54 and the b57 frontier |
| lavapipe, **direct SPIR-V** (`cubecl-spirv`): the same test (`lvp_par_spv.log`) | **ok**, 121 s, no stack overflow |
| CI's WGSL lint as the workflow runs it (`wgsl_dump_for_lint` on lavapipe naga, `scripts/wgsl-lint.py` with `gpu-parity.yml`'s 13 `--require`s; `wgsl_lint.log`; again with `--require TopFdKernel@57`, `wgsl_lint_fd.log`) | **16 shaders, 0 flagged**, rc 0 both. Constant divisions at b57: TopFdKernel 196, TopKernel 270, JoinKernel 36, BucketKernel 46, CheckKernel 10 (= L34/L35) |

- 1e14 device seconds in the compare runs (one field each, single runs, so indicative only): b57 1.285 → 0.801 s (×1.60), b60 0.860 → 0.623 (×1.38), b62 0.772 → 0.568 (×1.36), b64 1.171 → 0.910 (×1.29).

## 3. A/B: main (`04693ac`) vs all5 (`6ddab24`), interleaved (`chain_ab.sh`, 06:44–07:35 box UTC, nothing else on the box)

Device seconds per field (`device=`), medians of 3 rounds; spread = (max − min) / median; per round = main's time
over all5's in the same round; clock = mean SM MHz at ≥ 90 % utilisation. Every timed run sat at the **150 W cap**
(mean 149–150 W, throttle reason 0x4 SW power cap, ≤ 55 °C). "Product" multiplies the per-PR ratios measured on
their own bases at 180 W on machine m139250: #235 + #236 together (L30: ×1.365 / 1.350 / 1.379 / 1.305, NiceMark
×1.325), #237 (L33: ×1.100 / 1.098 / 1.092 / 1.019, ×1.108), #240 with #236 underneath (L35 §5: ×1.143 / 1.136 /
1.084; b64 ×1.000, FD is off there; NiceMark ×1.000), #239 on #235–#237 (L34 §11, MIN=192: ×1.074 / 1.063 / 1.078 /
1.173, ×1.107). The brief's round numbers (×1.365 × 1.10 × 1.14 × 1.07) give ×1.832 at b62 1e17.

| field | main s/field (rounds) | spread | all5 s/field (rounds) | spread | **speed-up** | per round | saving / field | product of per-PR ratios | clock main / all5 (MHz) | clock-normalised |
|---|---|---|---|---|---|---|---|---|---|---|
| b62 1e17, 1 field | **280.24** (272.72, 280.65, 280.24) | 2.8 % | **148.92** (149.01, 148.90, 148.92) | 0.1 % | **×1.882** | 1.830, 1.885, 1.882 | −131.33 s | ×1.843 | 1162 / 1074 | ×2.035 |
| b62 1e16, 2 fields | **23.01** (22.81, 23.15, 23.01) | 1.5 % | **11.77** (11.82, 11.75, 11.77) | 0.6 % | **×1.955** | 1.930, 1.971, 1.955 | −11.24 s | ×1.790 | 1162 / 1172 | ×1.938 |
| b60 1e16, 2 fields | **52.65** (52.24, 52.65, 52.71) | 0.9 % | **29.22** (27.75, 29.22, 29.29) | 5.3 % | **×1.802** | 1.882, 1.802, 1.799 | −23.43 s | ×1.760 | 1176 / 1138 | ×1.861 |
| b64 1e16, 2 fields | **64.93** (64.93, 64.88, 66.07) | 1.8 % | **41.85** (41.76, 41.85, 41.92) | 0.4 % | **×1.552** | 1.555, 1.550, 1.576 | −23.08 s | ×1.560 | 1125 / 1092 | ×1.599 |

**NiceMark nice-only** (`client_{M,S} niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json`, A B A B A B,
`NICE_API_BASE=http://127.0.0.1:9`; `nm_*.json`):

| | main | all5 | speed-up | product |
|---|---|---|---|---|
| **score** | 3091.0, 3108.8, 3126.5 (median **3108.8**, spread 1.1 %) | 4926.2, 4991.8, 5086.1 (median **4991.8**, spread 3.2 %) | **×1.606** (per round 1.594, 1.606, 1.627) | ×1.625 |
| b58 MSD-weak (whole 1e15 field), n/s | 1.367e14 | 2.418e14 (2.19–2.44) | ×1.769 | |
| b58 MSD-strong (whole field) | 8.439e14 | 1.067e15 | ×1.265 | |
| b60 MSD-weak (sampled) | 2.607e14 | 4.591e14 | ×1.761 | |
| b62 MSD-weak (sampled) | 3.322e14 | 5.872e14 | ×1.768 | |

- **Measured against predicted.** b62 1e17 **×1.882** against ×1.843 (per-field product) or ×1.832 (the brief's):
  2–3 % better. b62 1e16 ×1.955 against ×1.790 (+9 %), b60 1e16 ×1.802 against ×1.760 (+2 %), b64 1e16 ×1.552
  against ×1.560 (−0.5 %), NiceMark ×1.606 against ×1.625 (−1 %). So the five compound at least multiplicatively;
  nothing is lost in the stacking.
- **Why above the product at b62, and most at b62 1e16:** the per-PR ratios were measured at 180 W; this card is
  capped at 150 W, and the FD top kernel gains more there. Kernel alone (#240's timing test, `SCOPING.md`):
  `top_kernel` 0.449 against FD 0.258 ns per (prefix, slot) at b62 1e17, **×1.70–1.74** per round, against ×1.585
  at 180 W (L35 §12). b62 1e16 runs 13 slots a batch, so 12 of 13 FD slots step there (4 of 5 at b62 1e17, 3 of 4 at
  b60), and #240's share of the gain is largest. At b64 FD is off and #235 is null (L30), so the product is #236 and
  #239's, and it lands on it.
- **Absolute seconds at 150 W:** main b62 1e17 280.2 s (L30's main, the same binary md5, 226.8 s at 180 W on
  m139250: ×1.24); all5 148.9 s. Main's mean SM clock under load was 1162 MHz here (L30: 1432).
- **all5 ran at a lower clock than main at the same cap** during the A/B at b62 1e17 (1074 against 1162 MHz; b62
  1e16, b60 and b64 within 1–4 %), so the plain ratio is the conservative one; the clock-normalised ratios are
  ×2.04 / 1.94 / 1.86 / 1.60. That clock gap did not last: one more pair at the end of the session
  (`late_{S,M}_e17_b62.log`, 08:52–09:00) ran all5 at 1184 MHz in **140.14 s** and main at 1151 MHz in 274.91 s,
  **×1.962**, and the all5-equivalent `X4` with its switches off took 137.9–144.0 s at 1114–1180 MHz (`SCOPING.md`).
  The card's clock under the 150 W cap wanders by up to ~10 % for the same binary; the interleaved A/B above is the
  measurement, and ×1.88–1.96 brackets b62 1e17 on this card.
- **Spreads:** all5 0.1–0.6 % except b60 (5.3 %: its first round ran 27.75 s against 29.2–29.3 s); main 0.9–2.8 %
  (its first b62 1e17 round 272.7 against 280.2–280.7 s). Every round of every field is faster by ×1.55–1.97.
- **Counts:** all5's survivors / checked are identical in every round and equal all3's exact counts: b62 1e17
  1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 /
  30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327; found 0. Main's vary from run to run by its stage
  overrun (#236 removed that path), as in L30. NiceMark's whole-field b58 scenarios: all5 MSD-weak
  33,590,315,220 / 1,894,592,860 in every round (= L30's #236), main 155–229 lower (overrun); MSD-strong identical
  (4,027,773,430 / 226,773,299).
- Layouts: slots 5 / 13 / 4 / 6 on both sides; plan MiB +3 / +9 / +2 / +5 (#236's `ext_q`). Host setup per field the
  same on both sides (b62 1e17 16.1 against 15.7 s).

## 4. Profile of all5, and main's on the same box (`chain_prof.sh`, 07:35–07:44, after the A/B; `prof_*.log`, `raw/profiles.txt`)

- **The profile tree** (`PR`): all5 + `2ab1694` and `32b84af` (the `NICE_EXP_GPU_PROFILE` phase timers and the
  `spilled=` counter). `2ab1694` did not apply cleanly on #240; L34's adaptation of it (`36785cd`) conflicted in two
  places, both from #240's launch rework:
  - `JoinDevice::new` now builds `dev` and warms the clipped-block kernel before returning, so the profile's two
    fields (`profile`, `prof`) went into that struct literal;
  - `launch_batch` now calls `launch_top` (the FD kernel, plus `top_kernel(only_clipped)` on a batch with a clipped
    block). The inputs mark goes before it, and the existing top mark after `top_scan`/`top_fill` closes the phase,
    so **the FD kernel and the clipped-block launch are both in "top"**, with the scan and fill as before.
  - `32b84af` then applied cleanly. About 10 minutes; local commits `417dff9`, `6194a21` (not pushed).
- **Main's profile tree** (`MP`): main + `2ab1694`, clean (the same binary md5 as L30's `mprof`).
- One field at b62 1e17, two at b60 1e16. Shares are of profiled device time with the probe excluded; other =
  upload + inputs + read + unattributed.

| phase | b62 1e17 main | b62 1e17 **all5** | change | b60 1e16 main (2 fields) | b60 1e16 **all5** | change |
|---|---|---|---|---|---|---|
| **top** (FD kernel + clipped-block launch + top scan + top fill) | 116.52 s (42.5 %) | **40.57 s (29.7 %)** | **−75.95 s (×2.87)** | 36.16 (34.7 %) | **13.27 (24.3 %)** | **−22.89 (×2.72)** |
| bucket | 2.54 (0.9 %) | 2.56 (1.9 %) | +0.02 | 0.89 (0.9 %) | 0.93 (1.7 %) | +0.04 |
| **join** | 138.17 (50.4 %) | **76.66 (56.1 %)** | **−61.51 s (×1.80)** | 58.90 (56.6 %) | **32.62 (59.7 %)** | **−26.28 (×1.81)** |
| check | 11.36 (4.1 %) | 11.16 (8.2 %) | −0.20 | 5.68 (5.5 %) | 5.37 (9.8 %) | −0.31 |
| other | 5.55 (2.0 %) | 5.60 (4.1 %) | +0.05 | 2.46 (2.4 %) | 2.41 (4.4 %) | −0.05 |
| device, profiled, excl. probe | 274.14 | 136.55 | −137.59 (×2.01) | 104.09 | 54.60 | −49.49 (×1.91) |
| (unprofiled, the A/B's median) | (280.24) | (148.92) | | (105.29) | (58.43) | |
| host setup (CPU, overlapped) | 15.92 | 15.94 | | 4.80 | 4.99 | |

- **Only top and join moved.** Top lost 76 s at b62 1e17 (#235, #237, #240), the join 62 s (#236, #239); bucket,
  check and other moved by at most 0.3 s. The two profiles ran at 1155 (main) and 1213 MHz (all5) at b62 1e17, 1181
  and 1218 at b60; scaled to one clock the top phase is ×2.73 / ×2.64 and the join ×1.72 / ×1.75.
- **The new split: the join is the bulk** (56 % at b62 1e17, 60 % at b60 1e16), top 30 % / 24 %, check 8 % / 10 %.
  The check kernel (11.2 s at b62 1e17) is now larger than bucket + other together.
- **Profiled all5 ran faster than in the A/B** (136.6 + 1.8 s probe against 148.9 s at b62 1e17, −7 %) because it
  ran at a higher clock (mean 1213 MHz against 1074 in the A/B). Most of that is the card's clock wandering under the
  150 W cap, not the profile: the late unprofiled all5 run at 1184 MHz took 140.1 s (§3). Main's profiled run sat at
  its A/B clock (1155 against 1162 MHz) and is 2 % below its A/B time. Shares are within a run, so they stand; the
  seconds of the two sides are each at their own clock.
- **The join's AND vs walk split is not available**: the timers bracket the join kernel's launch as a whole. Its
  counts are unchanged from all3 (identical tops, listed entries, pairs): b62 1e17 2.53e13 AND pairs, 3.91e13
  wave-padded lanes (×1.54), 1.02e12 AND survivors, 6.26e10 checked, `spilled=0`.

## 5. Files

- `raw/scripts/` (run on the box from `/root/l36`):
  - Setup and builds: `setup.sh`, `build.sh` (test binary), `buildclient.sh`, `chain_build.sh`, `chain_mpr.sh`.
  - Wrappers: `run.sh` (throughput harness + nvidia-smi), `run_abl.sh` (the same, keeping `NICE_EXP_TOP_FD_ABL`),
    `test.sh` (one ignored test), `regs_abl.sh` (CubeCL's CUDA source of the FD kernel per switch, `nvcc -Xptxas -v`).
  - Exactness: `chain_x.sh` (CUDA), `chain_lvp.sh` (lavapipe: WGSL lint, naga and SPIR-V parity).
  - Measurement: `chain_ab.sh` (A/B + NiceMark), `chain_prof.sh` (profiles of all5 and main).
  - Scoping (`SCOPING.md`): `chain_abl.sh`, `chain_q.sh`, `chain_q3.sh`, `chain_x2.sh`, `chain_x3.sh`, `chain_x4.sh`,
    `chain_fx3.sh`, `chain_x4lvp.sh` (+ L35's `blocks.py`).
  - Analysis: `analyze.py` (→ `raw/analysis.txt`), `table.py` (the A/B table), `prof.py` (→ `raw/profiles.txt`),
    `abl.py`, `abl_table.py` (→ `raw/abl_*.txt`, `raw/abl_*_table.md`), `pull.sh` (copies the box's logs).
- `raw/box/`: every log and `.smi` trace, the NiceMark JSON, `power.txt`, `nvidia-smi.txt`, `box-info.txt`,
  `trees.txt`, `lvp_device.txt`, the lint's WGSL dump (`wgsl.log.gz`), and `sass.tgz` (CubeCL's CUDA sources of the
  FD kernel under each switch, with `sass/registers.txt`).
