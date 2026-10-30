# PROFILE-2: where the overlap join's GPU time goes on main d1ff798 (RTX 3080, 2026-10-30)

Re-measurement of GPU-RESULTS.md (85b5b4e) on current main, which since has #203 (closure), #205/#216 (2 entries per thread, 512-entry waves), #206 (memory budget) and #215 (field-certificate prune).

**Summary**
- **1e14 (production size): about half the device time is per-field fixed cost.** Fixed means it does not scale with the field's top-layer prefixes. The intercepts are 40–75 % of a field's time. The main parts:
  - the join kernel's floor of about 15.6 ns per (partition, bucket) work item, which comes to 0.16–0.26 s per field;
  - the bucket kernel, 11–16 %;
  - a measured **0.5 ms per launched batch**.

  **More partitions per launch is the largest lever measured.** Raising `SLOTS` from 16 to 32 gives ×0.92 / 0.90 / 0.83 / 0.87 on device time at b58/60/62/64; 64 gives ×0.88 / 0.86 / 0.78 / 0.83. Counters match to within the benign stage overrun, but one anomaly is open (section 5).
- **1e16: the join is 51–77 % of device time and top certification 15–41 %.** Inside the join, AND-survivor handling is the largest term: 47–77 % of the join, 25–59 % of device time. Top certification is the largest single phase at b62 (41 %).
- **Refit:** 0.62 ps per padded lane-pair + 64 ps per AND survivor, at 1e16 only; rms 5.7 %, max 11 % (it over-predicts b64). Adding tops (0.87 ps + 44.5 ps + 406 ps per top) gives rms 2.9 %, max 4.6 %. At 1e14 the two-term form fails (rms 33 %). It needs a per-work-item term: 0.36 ps + 43 ps + 15.6 ns, rms 5.9 %.
- **Wave padding is not a lever at 1e14.** EPT 1 halves the padded lanes there (padded/pairs 2.4–2.9 → 1.25–1.43) and the device time does not move (×0.99–1.00; b64 ×0.94 within its round spread). At 1e16 the empty lanes are modelled at 2–7 % of the field (b58–b62) and 9–15 % (b64). EPT 1 cannot recover them, since 280–420-entry buckets need two 256-entry waves, and it costs ×1.08–1.10. Only a bucket-sized tail wave could.
- **The stage overrun at b60 is worth about 0.3 %** at 1e16 (4.0e-3 of survivors, about 8.5e8 extra full checks at 130 ps). There is none at 1e14.
- **Card:** 320 W cap, not power-limited by the host. It sat at the cap under load (about 310 W, 1810–1830 MHz, 82 °C, SW power-cap and thermal flags). It is a **20 GB** RTX 3080, so its layouts differ from the 10 GB cards' (section 0).

## 0. Setup

- **Box:** Vast 58350591 (`nice-research-l1-profile2`).
  - RTX 3080 **20 GB** (nvidia-smi: 20480 MiB), driver 580.126.18, CUDA 13.0.
  - Power limit 320 W: current = default = max (`profile2-raw/box/power.txt`).
  - Xeon E5-2673 v4 host. `nproc` says 80, but the cgroup quota is 9.6 CPUs (`cpu.max 960000 100000`).
  - Under load (15 s `nvidia-smi` samples, `*.smi`):
    - 1e16: 1810–1825 MHz, 309–316 W, 82 °C, throttle flags 0x4 (SW power cap) and 0x20 (SW thermal);
    - 1e14: 1870–1930 MHz, 280–310 W.
- **Code:** fork branch `rp/gpu-profile-2` on upstream main `d1ff798`:
  - `65ff58b`: cfeb93d's `NICE_EXP_GPU_PROFILE` phase timers and probe. The conflicts were only in the harness's starts table and the size-knob comment; main's versions were kept, since #215's test commit had brought the same knobs. The kernel-side lines equal the earlier port onto the prune (`beaebf5`) line for line. The probe's wave is `ENTRIES_PER_THREAD · JOIN_WG` = 512.
  - `766eb68`: cherry-pick of `501a1b6`, the stage-overrun counter (`EXP_OVERRAN`) and `NICE_EXP_SURV_FLUSH`. With it unset, the flush level is 512 as on main, passed as a runtime argument instead of the constant.
  - Sections 1–4 ran this binary (md5 `17f20c74`).
- **Lever experiments (section 5):** knob commits.
  - `455d4c0`: `NICE_EXP_JOIN_EPT`, `NICE_EXP_SLOTS`; binary `c49f3437`.
  - `31d95af`: `NICE_EXP_SURV_PER_PREFIX`, which overrides only the per-launch survivor bound, not the slice size; binary `2e7cd1d7`.
  - Unset, every knob leaves its constant.
  - Upstream main itself was also built on the box as a control (section 5d).
- **Fields:** the A/B starts, after one 1e14 warm-up per base:
  - b58 104400216587923470200;
  - b60 1366406074057412100454;
  - b62 7997740455941656911841 (field 2 of 1e16 is sparse: 1.51 M prefixes against 3.62 M);
  - b64 41242006262957161709568.

  1e14: 20 consecutive fields per base. 1e16: 2 per base.
- **Runs:** `profile2-raw/chain.sh` (round 1: e14 unprofiled, e14 profiled, e16 profiled, e16 unprofiled; round 2 in reverse). Then `chain2.sh`–`chain4.sh` for the levers.

  Commands are in `profile2-raw/run.sh`. The runs ran the version without the `BIN` variable; it is otherwise identical.

  ```
  [NICE_EXP_GPU_PROFILE=1] NICE_TEST_JOIN_FIELDS={20|2} NICE_TEST_JOIN_SIZE={1e14|1e16} NICE_TEST_JOIN_BASES=58,60,62,64 \
    NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
    nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1
  ```

- **Layout on this card** (#206 budget = 4 GiB, the maximum; the list gets 1 GiB):
  - 1e14: 16 partitions per launch (the `SLOTS` cap), 211–256 batches per field, plan 1.6–1.8 GiB.
  - 1e16: one slice per field, and 5 / 6 / 9–16 / 10 partitions per launch. These are bound by the survivor rule (`SURV_PER_PREFIX` = 2 prefilter survivors per prefix and partition), **not by memory**: the plans are 2.7–3.5 GiB of 4.
  - The 10 GB 3080 (PR-RESULTS-3080) ran 5 / 4 / 5 / 6 at 1e16, so absolute 1e16 seconds are not comparable card to card.
- **Profiling overhead:**
  - 1e16: −1.3 … +1.9 % (noise level).
  - 1e14: **+22–35 % including the profiler's own probe readback**, and +6.5–10 % with the probe excluded.

  Every phase share below is of device time **with the probe excluded**. At 1e14 the remaining sync overhead inflates the short kernels by a few percent. The two profiled 1e14 rounds differ by 5–9 %, while the unprofiled ones agree within 2 %.
- **Exactness:**
  - 1e14 survivors and full checks are identical to the last digit in every main-binary run, and equal PR-RESULTS-3080's (b58 65,276,511,454 / 3,681,958,634; b64 65,747,036,999 / 3,999,993,450).
  - 1e16 runs differ by up to 2e-5, the timing-dependent stage overrun (section 3). No hits anywhere.
- **Incident:** a duplicate `chain2.sh` (a waiter I thought had died) ran concurrently for about 40 s at 05:29. Both were killed. Their partial logs are discarded (not in `profile2-raw/`), and the experiment chain was restarted from scratch. The main runs (chain.sh, 05:01–05:27) were before it and unaffected.

## 1. Device seconds per field and phase shares

Device seconds per field (unprofiled) are the median of 2 rounds. Shares are from the profiled runs (2 rounds), of device time excluding the probe. "Other" is upload + small-buffer inputs + readbacks + unattributed. Host setup is CPU time per field, overlapped with the previous field's device work.

| size | base | **device s/field** (rounds) | host setup s | top | bucket | **join** | check | other | batches | partitions/launch |
|---|---|---|---|---|---|---|---|---|---|---|
| 1e14 | 58 | **0.689** (0.683, 0.695) | 0.059 | 21.7 % | 11.3 % | **52.0 %** | 6.6 % | 8.5 % | 211 | 16 |
| 1e14 | 60 | **0.585** (0.585, 0.585) | 0.048 | 19.1 % | 14.1 % | **50.0 %** | 6.7 % | 10.2 % | 214 | 16 |
| 1e14 | 62 | **0.569** (0.570, 0.568) | 0.053 | 16.6 % | 16.3 % | **49.3 %** | 6.0 % | 11.7 % | 241 | 16 |
| 1e14 | 64 | **0.679** (0.684, 0.675) | 0.048 | 9.3 % | 13.9 % | **58.2 %** | 6.7 % | 11.9 % | 256 | 16 |
| 1e16 | 58 | **46.34** (46.19, 46.49) | 2.66 | 30.2 % | 0.4 % | **62.1 %** | 5.1 % | 2.1 % | 673 | 5 |
| 1e16 | 60 | **33.94** (34.12, 33.76) | 2.20 | 33.7 % | 0.6 % | **57.1 %** | 6.3 % | 2.2 % | 600 | 6 |
| 1e16 | 62 | **14.62** (14.61, 14.64) | 1.31 | 40.8 % | 1.2 % | **50.7 %** | 4.5 % | 2.8 % | 334 | 9 / 16 |
| 1e16 | 64 | **42.87** (42.80, 42.93) | 1.65 | 14.9 % | 0.4 % | **76.5 %** | 7.1 % | 1.2 % | 410 | 10 |

At 1e14, "other" is mostly `inputs`, the per-batch small-buffer creation (0.040–0.063 s per field profiled). At 1e16 it is mostly `upload` (`JoinDevice::new`, 0.26–0.54 s).

**Per-field fixed cost at 1e14.** Per base, I regressed each phase on the field's prefixes over its 40 profiled fields (probe excluded, so sync overhead is included). The intercept is the cost a field pays with no top-layer prefixes (`profile2-raw/analysis.txt`, last table):

| base | device: fixed s (share of mean) | µs per extra prefix | join fixed | bucket fixed | other fixed | check fixed | top fixed |
|---|---|---|---|---|---|---|---|
| 58 | 0.319 (43 %) | 6.3 | 0.160 | 0.087 | 0.045 | 0.010 | 0.016 |
| 60 | 0.353 (53 %) | 5.7 | 0.187 | 0.063 | 0.062 | 0.025 | 0.016 |
| 62 | 0.481 (77 %) | 3.7 | 0.260 | 0.105 | 0.063 | 0.037 | 0.017 |
| 64 | 0.437 (59 %) | 11.0 | 0.230 | 0.064 | 0.084 | 0.039 | 0.020 |

Subtracting the 0.045–0.06 s of profiling sync gives about 0.27 / 0.31 / 0.42 / 0.38 s, which is **40 / 53 / 74 / 56 % of the unprofiled 1e14 field**. The sparse fields confirm it directly:
- b64's field with 1,937 prefixes (7 % of the mean) still took 0.48 s of the mean 0.74 (profiled, probe excluded);
- b60's field with 5,507 prefixes took 0.40 s of 0.66.

## 2. µs per top-layer prefix

| size | base | prefixes/field | **µs/prefix, unprofiled** | top | bucket | join | check | other |
|---|---|---|---|---|---|---|---|---|
| 1e14 | 58 | 65.5 k | **10.52** | 2.43 | 1.26 | 5.83 | 0.74 | 0.95 |
| 1e14 | 60 | 52.0 k | **11.25** | 2.32 | 1.70 | 6.05 | 0.81 | 1.23 |
| 1e14 | 62 | 38.7 k | **14.70** | 2.68 | 2.64 | 7.98 | 0.98 | 1.89 |
| 1e14 | 64 | 27.3 k | **24.88** | 2.50 | 3.76 | 15.69 | 1.82 | 3.21 |
| 1e16 | 58 | 5.81 M | **7.98** | 2.42 | 0.04 | 4.97 | 0.41 | 0.17 |
| 1e16 | 60 | 5.30 M | **6.41** | 2.17 | 0.04 | 3.68 | 0.41 | 0.14 |
| 1e16 | 62 | 2.56 M | **5.70** | 2.37 | 0.07 | 2.95 | 0.26 | 0.16 |
| 1e16 | 64 | 3.06 M | **14.01** | 2.06 | 0.06 | 10.58 | 0.98 | 0.16 |

(Phase columns are profiled, probe excluded.)

- **Against 85b5b4e's 1e16:** 11.44 / 8.51 / 9.96 / 26.84 µs then (a different 3080 at the same 1830 MHz). That is ×1.43 / 1.33 / 1.75 / 1.92 per prefix.
- **Top certification is unchanged** at 2.1–2.7 µs per prefix at both sizes, as before. It is about 0.5–0.7 ns per (prefix, partition) certification.
- **1e14 costs 1.3–2.6× more per prefix than 1e16.** The difference is the fixed cost above, plus a 1e14 field's smaller buckets (more work items per pair).

## 3. Counts per field

| size | base | tops/field | tops/prefix | bottoms (bpre) per slice | listed entries/field | AND pairs/field | wave-padded lane-pairs/field | padded/pairs | entries per probed bucket | AND survivors/field | prefilter survivors (= full checks)/field | AND pass/pair | prefilter keeps | overran the stage/field (share) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1e14 | 58 | 7.41e7 | 1131 | 7.13e4 | 2.41e9 | 6.39e10 | 1.52e11 | 2.37 | 216 | 3.26e9 | 1.84e8 | 5.1 % | 5.6 % | 0 |
| 1e14 | 60 | 6.77e7 | 1301 | 7.13e4 | 2.63e9 | 2.99e10 | 6.93e10 | 2.32 | 221 | 2.28e9 | 1.53e8 | 7.6 % | 6.7 % | 0 |
| 1e14 | 62 | 4.82e7 | 1245 | 7.58e4 | 2.90e9 | 1.90e10 | 4.94e10 | 2.60 | 197 | 1.22e9 | 7.48e7 | 6.4 % | 6.1 % | 0 |
| 1e14 | 64 | 3.46e7 | 1266 | 7.43e4 | 2.92e9 | 4.97e10 | 1.42e11 | 2.85 | 180 | 3.29e9 | 2.00e8 | 6.6 % | 6.1 % | 0 |
| 1e16 | 58 | 6.57e9 | 1132 | 9.64e4 | 4.37e9 | 1.03e13 | 1.35e13 | 1.30 | 393 | 3.03e11 | 1.71e10 | 2.9 % | 5.6 % | 2.4e4 (8e-8) |
| 1e16 | 60 | 6.89e9 | 1301 | 1.01e5 | 5.39e9 | 5.82e12 | 7.06e12 | 1.21 | 423 | 2.30e11 | 1.63e10 | 3.9 % | 7.1 % | **9.16e8 (4.0e-3)** |
| 1e16 | 62 | 3.19e9 | 1246 | 1.02e5 | 5.22e9 | 2.17e12 | 3.27e12 | 1.50 | 340 | 8.18e10 | 5.02e9 | 3.8 % | 6.1 % | 1.69e6 (2.1e-5) |
| 1e16 | 64 | 3.87e9 | 1266 | 9.39e4 | 4.64e9 | 8.71e12 | 1.59e13 | 1.82 | 281 | 3.94e11 | 2.40e10 | 4.5 % | 6.1 % | 1.13e7 (2.9e-5) |

The overrun counts are identical (to within 0.5 %) in all four 1e16 runs per base, and zero in all four 1e14 runs per base on this binary.

- **Work items** per field, (partition, bucket) pairs = partitions × b × (b−1): 11.1 M / 12.7 M / 14.5 M / 16.5 M.
  - At 1e16 a work item holds 440–2,360 tops.
  - At 1e14 it holds **7–27** tops: 26.7 / 10.6 / 6.6 / 16.8. That is why the per-work-item cost dominates there.
- **The prune's bucket sizes:**
  - 180–220 entries at 1e14 (padded/pairs 2.3–2.9 in 512-lane waves);
  - 280–420 at 1e16 (1.2–1.8).

  Against GPU-RESULTS' 930–1,210 unpruned.

## 4. The join cost model, refitted (512-entry waves)

Fits are weighted least squares on relative error over the profiled fields (`profile2-raw/fit_summary.py`, output in `fit_summary.txt`). There are 16 fields at 1e16: 4 bases × 2 fields × 2 rounds, so 8 distinct fields. At 1e14 there are 158 (fields with an empty top layer are dropped).

**The requested form, 1e16 only:** `join = 0.617 ps × padded lane-pairs + 64.4 ps × AND survivors`, rms 5.7 %, max 11.4 %.

| base | mean residual | range | padded term (share of join) | survivor term (share of join) |
|---|---|---|---|---|
| 58 | −3.6 % | −4.2 … −3.3 % | 30 % | 70 % |
| 60 | −1.7 % | −3.7 … +0.1 % | 23 % | 77 % |
| 62 | −4.7 % | −7.5 … −1.9 % | 28 % | 72 % |
| 64 | **+8.7 %** | +5.9 … +11.4 % | 28 % | 72 % |

The residuals have a pattern: the model over-predicts b64, the most padded base (1.82). An empty lane costs less than a filled one, as PR-RESULTS-3080 inferred from the prune. Better fits:

| fields | model | coefficients | rms | max |
|---|---|---|---|---|
| 1e16 | padded + surv + **tops** | 0.874 ps, 44.5 ps, **406 ps per top** | 2.9 % | 4.6 % |
| 1e16 | **pairs** + surv | 1.11 ps per real pair, 58.4 ps | 2.9 % | 6.1 % |
| 1e14 | padded + surv | (−0.47 ps, 152 ps: fails) | 33 % | 87 % |
| 1e14 | padded + surv + **work items** | 0.36 ps, 43.1 ps, **15.6 ns per (partition, bucket)** | 5.9 % | 16 % |
| 1e14 | pairs + surv + work items | 1.45 ps, 32.9 ps, 15.9 ns | 5.1 % | 14 % |
| both | pairs + surv + work items | 2.02 ps, 27.6 ps, 15.4 ns | 5.8 % | 15 % (biased −6 … −11 % at 1e16) |

Notes:
- The tops term (about 400 ps per top, 5–17 % of the join at 1e16) is the per-32-top-chunk cost: the shared-memory load of the tops, `sync_cube`, the walk-loop entry and the flush check.
- The work-item term is the join kernel's floor: one 256-thread cube per (partition, bucket), with its syncs, its bucket's entry gathers and the end-of-cube flush. At 1e14 it is 47–77 % of the join (0.17–0.26 s per field). Part of it is per launch, measured in section 5a.
- No single linear model fits both sizes well. The per-pair and per-survivor coefficients drift between 1e14 and 1e16 by about 1.5×, and with four bases at 1e16 the AND-lane and survivor terms are nearly collinear (survivors ≈ 3–5 % of pairs).
- **Survivor cost:** the survivor coefficient is 33–64 ps against 74 ps on 85b5b4e. Per survivor the walk/stage/prefilter is about as expensive as before or cheaper; what changed is that the AND lanes around it shrank 3–4× with the prune.

## 5. Lever experiments

### 5a. Partitions per launch at 1e14 (`NICE_EXP_SLOTS`, unprofiled, 2–4 interleaved rounds)

| base | 8 | **16 (main)** | 32 | 64 | 32 vs 16 | **64 vs 16** | batches 8/16/32/64 |
|---|---|---|---|---|---|---|---|
| 58 | 0.804 | 0.698 | 0.643 | 0.617 | ×0.922 | **×0.884** | 421 / 211 / 106 / 53 |
| 60 | 0.697 | 0.591 | 0.533 | 0.506 | ×0.903 | **×0.857** | 428 / 214 / 107 / 54 |
| 62 | 0.700 | 0.579 | 0.481 | 0.450 | ×0.831 | **×0.776** | 481 / 241 / 121 / 61 |
| 64 | 0.800 | 0.685 | 0.597 | 0.565 | ×0.872 | **×0.826** | 512 / 256 / 128 / 65 |

The control (16) is the median of 4 rounds, 32 of 3, and 8 and 64 of 2, interleaved. Spreads are ≤ 5 % (all rounds in `profile2-raw/analysis_x.txt`).

- **The cost per launched batch** is a flat **0.50 ± 0.03 ms** on this card for 8→16 and 32→64 at every base. For 16→32 it is 0.81 ms at b62 and 0.69 ms at b64. There, 16 partitions already fill the 65,535-cube grid cap (16 × b(b−1) = 60.5 k / 64.5 k cubes), and 32 makes the cubes grid-stride over work items, so the cube setup is amortised as well.
- **Where it goes** (profiled 32-slot run against the 16-slot profile, probe excluded). The saving is spread over every kernel, as a fixed cost per launch would be:
  - device 0.734 → 0.674 (b58), 0.630 → 0.565 (b60), 0.626 → 0.514 (b62), 0.737 → 0.633 (b64);
  - join 0.382 → 0.373, 0.315 → 0.295, 0.309 → 0.259, 0.428 → 0.390;
  - inputs/other −0.02 s;
  - check −0.01 s;
  - bucket −0.01 … −0.02 s;
  - top −0.01 s.
- **Memory:** the plan grows by 37–49 MB per partition at 1e14, almost all of it the bucket lists. These are sized for the *unpruned* bottom list, `nbp_all · b · 4` bytes, about 130–175 k entries (estimated from the per-partition growth) against the pruned slice's 71–76 k. 32 partitions need 2.2–2.6 GiB on this card, and 64 need 3.4–4.1 GiB (b64 hit 4,088 MiB of the 4,096 budget). On a 10 GB card (2.5 GiB budget, 640 MiB list) the room allows about 39–51 partitions, so 32 fits but 64 does not. Lists sized by the pruned slice (about 2× smaller) would let 64 fit there. That is the "size buffers by pruned lists" lever: on its own it buys nothing, but it is what lets SLOTS go past about 40 on 8–10 GB cards.
- **Counters:** with grid-striding cubes the stage carries survivors from one work item into the next, so a few more survivors overrun it: 10–35 k per 20 fields at b58/b64, up to 5.4e-7 of the survivors. That is benign (`mid_pass` depends only on (top, r0)), and far under the dense test's 1e-4.

  **Anomaly:** one of the two 64-slot b64 runs counted **16.5 M (0.4 %) more full checks** than every other run, with survivors equal to within 247 and an overrun of 35 k. Nothing I counted explains it. It needs a look before SLOTS goes past 16. No hits in any run, so there is no exactness evidence either way.

### 5b. Wave size (`NICE_EXP_JOIN_EPT=1`, 256-entry waves)

| size | base | EPT 2 (main) s | EPT 1 s | ratio | padded/pairs EPT 2 → 1 | join (profiled) EPT 2 → 1 |
|---|---|---|---|---|---|---|
| 1e14 | 58 | 0.698 | 0.691 | ×0.990 | 2.37 → 1.25 | 0.382 → 0.412 |
| 1e14 | 60 | 0.591 | 0.591 | ×1.002 | 2.32 → 1.41 | 0.315 → 0.333 |
| 1e14 | 62 | 0.579 | 0.572 | ×0.988 | 2.60 → 1.39 | 0.309 → 0.310 |
| 1e14 | 64 | 0.685 | 0.645 | ×0.942 (rounds ×0.98, ×0.90) | 2.85 → 1.43 | 0.428 → 0.426 |
| 1e16 | 62 | 14.81 | 16.03 | **×1.082** | 1.50 → 1.50 | 7.56 → 8.23 |
| 1e16 | 64 | 42.01 | 46.41 | **×1.105** | 1.82 → 1.77 | 32.4 → 34.3 |

- **At 1e14, halving the padded lanes does not change the device time** (unprofiled, ×0.99–1.00; b64's ×0.94 has a 7 % round spread). Empty lanes cost close to nothing next to the per-work-item and per-chunk costs. The profiled join column is a single EPT 1 round, and profiled 1e14 rounds vary by 5–9 %.
- **At 1e16, 280–340-entry buckets need two 256-lane waves.** EPT 1 pays a second pass of the 32-top chunk loop (walk, `sync_cube`, flush check) for the same padded lanes. Side effect: EPT 1 stages half as many survivors per chunk, so the overrun vanishes and the counts become exact (b62 163,513,599,082 against EPT 2's 163,510.2 M).
- **What is left of padding** is the 1e16 empty lanes beyond real pairs: 0.6–1.0 ps × (padded − pairs) by the 1e16 fits, i.e. 2–7 % at b58–b62 and 9–15 % at b64. The 5-term fit puts an empty lane at 0.51 ps against 0.65 ps for a filled one, which gives 3.7 s = 8.6 % at b64. Recovering that needs a tail wave sized to the bucket, not a smaller EPT. That test is not run.

### 5c. The survivor bound at 1e16 (`NICE_EXP_SURV_PER_PREFIX=1`, bases 58/60/62)

Here the batch's partitions per launch are bound by expected survivors, not memory (section 0). Halving the bound gives:
- b58: 5 → 9 partitions, then memory-bound (plan 4,085 MiB);
- b60: 6 → 11;
- b62: field 1 goes 9 → 16.

Batches fall 44 % / 45 % / 25 %. No overflow or re-run.

| base | control (1 round) | bound 1 (2 rounds) | ratio | batches control → bound 1 |
|---|---|---|---|---|
| 58 | 45.29 | 46.01 (45.97, 46.04) | ×1.016 | 673 → 374 |
| 60 | 33.62 | 33.57 (33.36, 33.79) | ×0.998 | 600 → 328 |
| 62 | 14.85 | 14.68 (14.79, 14.58) | ×0.989 | 334 → 249 |

**No gain at 1e16.** About 300 fewer batches × 0.5 ms is about 0.15 s, i.e. 0.3–1 %, inside the noise. b58 is slightly worse, at a plan 0.3 % under the budget. b64 (1.91 measured prefilter survivors per prefix and partition, against the bound's 2) was not run, since it would overflow. More partitions per launch is a 1e14 lever only.

### 5d. Upstream main against the instrumented binary (1e14)

Upstream main `d1ff798` built on the box (binary `0fcfc766`, no instrumentation, no knobs), 2 rounds, interleaved with the knob binary unset (`x14_ctl_r4`, binary `2e7cd1d7`):

| base | main (rounds) | knob binary, unset (median of 4) | main / knob |
|---|---|---|---|
| 58 | 0.687 (0.676, 0.698) | 0.698 | ×0.985 |
| 60 | 0.589 (0.584, 0.593) | 0.591 | ×0.997 |
| 62 | 0.577 (0.578, 0.576) | 0.579 | ×0.997 |
| 64 | 0.688 (0.688, 0.688) | 0.685 | ×1.005 |

**The instrumented binary, unset, runs at main's speed** (within 1.5 %), and its counters equal main's to the last digit. One of main's own b64 rounds counted 3 survivors fewer (a 3-survivor overrun), so main has the timing-dependent overrun at 1e14 too. The unprofiled figures in sections 1–2 stand for production.

## 6. What is left

Ranked by the share of device time each lever addresses. "5 %" is what a 5 % device-time win would need.

1. **Per-launch and per-work-item fixed cost at 1e14 (production size): 40–74 % of the field.** This is the biggest remaining term.
   - Per launch, 0.50 ms × 211–256 batches = 15–21 % at 16 partitions per launch. **Measured: 64 partitions per launch saves 11.6 / 14.3 / 22.4 / 17.4 %.** Several times the 5 % target, at the cost of a plan of 3.4–4.1 GiB. 32 partitions (×0.83–0.92) fits 10 GB cards as is; 64 needs the lists sized by the pruned slice. Either way, the b64 check-count anomaly needs understanding first.
   - The rest is the join's per-(partition, bucket) floor (15.6 ns × 11–16.5 M = 25–40 % of the field; it overlaps the per-launch cost) and the bucket kernel (11–16 %). A 5 % win there needs either:
     - the per-work-item cost down by 12–20 %, for example a plane per work item instead of a 256-thread cube when a bucket has fewer than 32 tops, which is the 1e14 case (7–27 tops per work item); or
     - the bucket kernel down by a third to a half.
2. **AND-survivor handling at 1e16: 25–59 % of the field** (47–77 % of the join, depending on the model: 29–43 % at b58, 30–44 % at b60, 25–36 % at b62, 41–59 % at b64). At 1e14 it is 7–16 %.
   - 5 % needs 8–20 % off the per-survivor cost (the set-bit walk, the shared stage, `mid_pass`, the flush), or that many fewer AND survivors per pair (pass rate 3–5 % at 1e16, 5–8 % at 1e14).
   - This is the largest lever at b64 and b58 1e16.
3. **Top certification: 15–41 % at 1e16, 9–22 % at 1e14.** Flat at 2.1–2.7 µs per prefix and about 0.5–0.7 ns per (prefix, partition), with only 31–36 % of the b² pairs certifying.
   - 5 % needs the top kernel 12 % faster at b62 1e16 (where it is the largest phase, 41 %), 15–17 % at b58/b60 1e16, 23–30 % at 1e14 b58–b62, and 33–54 % at b64.
4. **AND lanes (real pairs) at 1e16: 13–26 % of the field.** 5 % needs about 20–40 % off per lane-pair.
5. **Wave padding: ≤ 1 % at 1e14 (measured); 2–7 % at b58–b62 and 9–15 % at b64 1e16 (modelled).** The 1e16 empty lanes are cheaper than filled ones (0.51 against 0.65 ps). A 5 % win exists only at b64 1e16, and would need most of its 7.2e12 empty lane-pairs removed by an occupancy-sized tail wave. EPT 1 is worse (×1.08–1.10).
6. **Bucket build: 11–16 % at 1e14, ≤ 1.2 % at 1e16.** At 1e14 it is all per-field cost (partitions × bpre); covered under 1.
7. **The stage overrun at b60: about 0.3 % at 1e16, 0 at 1e14.** Too small to be the 5 %, as PR-RESULTS-3080's flush-at-256 test also found (break-even at b60, −1–2 % elsewhere).
8. **More partitions per launch at 1e16: nothing** (measured ×0.99–1.02 with batches cut 25–45 %, 5c). The survivor bound, not memory, sets them there, and per-launch cost is under 1 % of a 1e16 field.

**Per base and size, the biggest term:**

| size | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| 1e14 | fixed cost (join floor + launches), about 40 % | fixed cost, about 53 % | fixed cost, about 74 % | fixed cost, about 56 % |
| 1e16 | survivor handling (29–43 %), then top (30 %) | survivor handling (30–44 %) ≈ top (34 %) | **top certification (41 %)** | survivor handling (41–59 %) |

## Raw data and scripts

All in `L1/profile2-raw/`:

- **Main runs:** `box/{e14,e16}_{prof,noprof}_r{1,2}.log`, with `.smi` clock/power traces.
- **Lever runs:**
  - `box/x14_{ctl,slots8,slots32,slots64,ept1}_r*.log`, `x14_*_prof_r1.log`;
  - `box/x16_{ctl,ept1}_r*.log`;
  - `box/y16_*.log`;
  - `box/x14_main_r*.log`.
- **Box metadata:** `box/power.txt`, `nvidia-smi.txt`, `nproc.txt`, and the build logs (`testbuild*.log`).
- **Scripts:**
  - `setup.sh`, `run.sh` / `run2.sh` / `run3.sh`, `chain.sh`, `chain2.sh`, `chain3.sh`, `chain4.sh`;
  - `analyze.py` (sections 1–3 and fits; output `analysis.txt`);
  - `fit_summary.py` (section 4; `fit_summary.txt`);
  - `analyze_x.py` (section 5; `analysis_x.txt`).
  - Run them with `uv run --with numpy python3 <script> profile2-raw/box`.
