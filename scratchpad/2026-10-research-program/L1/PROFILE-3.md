# PROFILE-3: the overlap join at the live field sizes (b62 1e17, b60 1e16) on main 9bde4a8 (RTX 3080 10 GB at 180 W, 2026-10-31/11-01)

PROFILE-2 profiled d1ff798 at 1e14 and 1e16. Production now runs base 60 at 1e16 and base 62 at **1e17** (`data.nicenumbers.net/fields`). This is the first profile at 1e17, on current upstream main (with #228's 16-bit-limb top kernel and #222's stage-count barrier).

**Summary**
- **b62 1e17: 223 s of device time per field** (220.9, 225.3), **7.28 µs per top-layer prefix**: the same as b62 1e16 on this card (7.28). Nothing new switches on at 1e17. The phase shares are those of b62 1e16 to within a point:
  - top certification **38 %**, join **46 %**, check **8 %** (3–4 % unprofiled: most of its profiled time is per-batch sync latency), bucket **3 %**, other 5 %.
  - Inside the join, AND-survivor handling is **26 %** of the field, real AND lanes 12 %, the per-top chunk cost 4 %, wave padding 3 %.
- **What 1e17 adds is count, not kind.** On a 10 GB card the field is cut into **11 slices** (3,844 partitions each), run in **6,439 batches** of 5–8 partitions. Per-slice work (the bucket build's per-partition part, the join's per-work-item floor) and per-batch work look like a few percent each in the profile, but **measured unprofiled neither is a lever**: 38 % fewer batches gave ×0.994, and 11 → 4 slices on top ×0.991, inside the ±2.5 % run-to-run spread. Slices are cut by prefix *blocks*, of which only 28 % are top-layer prefixes, so there are 3–4× more of them than memory needs; but the field-certificate prune works per slice, and 4 wide slices carry 9.4 % more real AND pairs, which repays the fixed work saved.
- **Refit** (6 distinct fields, 12 profiled runs, 1e16 + 1e17): `join = 1.18 ps × real lane-pair + 0.49 ps × empty lane-pair + 60.8 ps × AND survivor + 238 ps × top`, rms 1.6 %, max 3.2 %. Fitted on 1e16 alone it predicts the 1e17 join to −4.0 % / −0.4 % (the two 1e17 rounds differ by 3.7 %). The two-term form `0.654 ps × padded + 79.2 ps × survivor` has rms 4.4 % and again over-predicts b64 (+7–8 %).
- **Top certification is the largest phase at b62 (38 %) and b60 (32 %)**: 0.77 ns per (prefix, partition), only 32 % of which certify. A 5 % win at b62 1e17 needs the top kernel 12 % faster, or survivor handling 18 % cheaper; 10 % needs both.
- **The stage overrun is 5× more frequent at 1e17 (1.1e-4 of survivors) than at b62 1e16 (2.1e-5) and still worth 0.01 % of the field**: 1.1e8 extra full checks at 300 ps. b60 1e16 is unchanged at 3.9e-3 (0.4 %).
- **This card is power-capped at 180 W** (default 340 W): 1,460–1,510 MHz under load against PROFILE-2's 1,810–1,830 MHz at 320 W. 1e16 device times are ×1.25–1.28 PROFILE-2's (×1.22 from the clock, the rest from the 10 GB card's layouts). Shares, counts and the fit's relative terms carry over; absolute seconds do not.

## 0. Setup

- **Box:** Vast 58589649 (`nice-research-profile-1e17`), machine m139250.
  - RTX 3080 **10 GB** (10,240 MiB), driver 580.159.03, CUDA 13.0, PCIe gen 3 x16.
  - **Power limit 180 W** (requested = current; default 340 W, max 374 W; `profile3-raw/box/power.txt`). Under load (5 s `nvidia-smi` samples, `*.smi`): 1,460–1,510 MHz, 171–179 W, 68–70 °C, throttle flag 0x4 (SW power cap) throughout. Not thermally limited.
  - Xeon E5-2630 v4 host, cgroup quota 9.6 CPUs (`cpu.max 960000 100000`); host load average 13–27 during the runs (other tenants). A second research box (`nice-research-topcert`, also an RTX 3080) ran on the same machine at the same time.
- **Code:** fork branch `rp/gpu-profile-3` on upstream main `9bde4a8`:
  - `2ab1694`: cherry-pick of `65ff58b`, the `NICE_EXP_GPU_PROFILE` phase timers and probe, and the harness knobs. Applied cleanly; #228 changed the top kernel's body, not its launch or the phase boundaries.
  - `406ca28`: cherry-pick of `766eb68`, the stage-overrun counter (`EXP_OVERRAN`) and `NICE_EXP_SURV_FLUSH`. One conflict, against #222's second `sync_cube()` after the stage-count read: kept #222's barrier, with the runtime `flush_at` in place of `SURV_FLUSH`.
  - Sections 1–5 ran this binary (md5 `7330147f`).
  - Levers (section 6), binary `b81cd953`: `1315b65` and `f4f0eeb` (cherry-picks of `455d4c0`, `31d95af`: `NICE_EXP_SLOTS`, `NICE_EXP_JOIN_EPT`, `NICE_EXP_SURV_PER_PREFIX`), and `bddf20f`, new: `NICE_EXP_SLICE_MULT` multiplies `max_slice_prefixes`. Unset, every knob keeps its constant.
- **Fields** (the starts of PROFILE-2):
  - b62 1e17: [7997740455941656911841, +1e17). It contains PROFILE-2's two b62 1e16 fields and eight more; 30.6 M top-layer prefixes, denser than the two 1e16 fields' mean (2.56 M per 1e16).
  - b62 1e16 × 2, b60 1e16 × 2 (1366406074057412100454), b64 1e16 × 1 (41242006262957161709568).
  - **The b62 fields at the start of the live list are empty.** The first unchecked b62 field, [3226266762397899821056, +1e17), has no top-layer prefixes: 0.07 s of host setup and no device work (`e17f_*`). So b62's live fields range from empty to at least this dense; the field profiled here is a dense mid-range one.
- **Runs:** `profile3-raw/chain.sh`, one test process per (size, base): round 1 is 1e17 unprofiled, 1e17 profiled, then per base 1e16 profiled and unprofiled (b62, b60, b64); round 2 is the reverse. Each process starts with one 1e14 warm-up field, which holds the kernels' JIT compile (left out of everything below).

  ```
  [NICE_EXP_GPU_PROFILE=1] NICE_TEST_JOIN_FIELDS={1|2} NICE_TEST_JOIN_SIZE={1e17|1e16} NICE_TEST_JOIN_BASES={62|60|64} \
    NICE_TEST_JOIN_STARTS=60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
    nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1
  ```

  The knob binary was built (niced, `-j 4`) during round 2's b60 runs and b62's unprofiled 1e16 run; those agree with round 1 to within 0.5 % (b60) and 2 % (b62, faster).
- **Layout on this card:** CubeCL reports a quarter of the 10 GB as the largest buffer, so the budget is 2.5 GiB and the survivor list 640 MiB (83.9 M entries).
  - **Slices** are cut at `max_slice_prefixes` prefix *blocks* (`b^(l−(t−p))` numbers each); its binding term is the survivor bound at `SLICE_SLOTS` = 2, list/8 ≈ 10.5 M blocks. Only about 28 % of b62's blocks here are top-layer prefixes. So:
    - 1e17 b62: **11 slices** of about 2.8 M prefixes each;
    - 1e16 b60: 2 slices, both with prefixes;
    - 1e16 b62: 2 slices, the second one empty (no device work);
    - 1e16 b64: 1 slice.
  - **Partitions per launch** are then set by the survivor bound (`SURV_PER_PREFIX` = 2 prefilter survivors per prefix and partition, against 0.53 measured at b62 1e17): 5–8 at 1e17 (mean 6.57), 4 at b60, 5 and 13 at b62, 6 at b64. Plans are 1.5–2.1 GiB of 2.5. PROFILE-2's 20 GB card ran 6 / 9–16 / 10 at 1e16 with one slice each.
- **Profiling overhead.** Profiled device time (probe excluded) over unprofiled:
  - b62 1e17 **+7.2 %**, b60 +5.2 %, b62 1e16 +5.2 %, b64 −1.0 %. Including the probe: +13.6 / +11.6 / +11.9 / +1.4 %.
  - It is about **2.5 ms per batch** (16.1 s over 6,439 batches at 1e17; 1.7 ms at b60, 1.8 ms at b62 1e16), against under 0.5 ms on PROFILE-2's box (−1.3 … +1.9 % at 1e16). This box's host is slower (E5-2630 v4 at 2.2 GHz) and loaded, and the profile serialises the host's launch work with the device at every sync. b64's batches are the longest (78 ms) and its overhead vanishes.
  - The profiled runs also clock 1–9 % higher (1,456–1,598 MHz against 1,432–1,478 unprofiled): the syncs leave the card idle, under its power cap. Clock-normalised, the overhead is a few points larger at 1e16 (b60 +11 %).
  - So the per-batch phases (inputs, unattributed, the check's and the bucket's fixed parts) are inflated in the profile. Shares below are of profiled time with the probe excluded, as in PROFILE-2. Section 5 says which terms the 7 % sits in.
- **Exactness.** Counted AND survivors plus stage overruns are identical to the last digit in every run of a field, and equal PROFILE-2's where it ran the same field: b60 1e16 (2 fields) 460,847,952,346 (PROFILE-2: 459,016,303,009 + 1,831,649,337, the same sum); b62 1e16 (2 fields) 163,513,599,082 (PROFILE-2's exact EPT-1 count); b64 1e16 394,062,910,661; **b62 1e17 1,020,844,021,499**. The split between the two moves with timing (the stage overrun), so counted survivors and full checks differ between runs by up to 2e-6 (1e17) and 5e-5 (b60). No hits anywhere.

## 1. Device seconds per field and phase shares

Device seconds are the median of 2 unprofiled rounds. Shares are of profiled device time with the probe excluded (2 rounds). "Other" is upload + inputs + read + unattributed. Host setup is CPU time per field: the first slice's runs before the device starts, the later slices' each beside the previous slice's device work.

| size | base | **device s/field** (rounds) | profiled, probe excl. | host setup s | top | bucket | **join** | check | other | slices (with prefixes) | batches | partitions/launch: mean (first plan) | plan MiB |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **1e17** | **62** | **223.11** (220.90, 225.31) | 239.25 | 18.96 | **37.8 %** | 3.3 % | **45.7 %** | 7.9 % | 5.3 % | 11 (11) | 6,439 | 6.57 (5) | 1,667 |
| 1e16 | 60 | **42.97** (42.87, 43.07) | 45.22 | 2.85 | 31.6 % | 3.3 % | **50.5 %** | 8.3 % | 6.2 % | 2 (2) | 1,350 | 5.33 (4) | 1,564 |
| 1e16 | 62 | **18.66** (18.85, 18.48) | 19.63 | 1.53 | 38.3 % | 3.5 % | **44.7 %** | 7.8 % | 5.8 % | 2 (1) | 532 | 7.22 (5; 13) | 2,041 |
| 1e16 | 64 | **53.55** (53.57, 53.53) | 53.03 | 1.92 | 16.2 % | 1.5 % | **72.8 %** | 6.6 % | 2.8 % | 1 (1) | 683 | 6.00 (6) | 2,142 |

Other, split (s per field): 1e17 b62: upload 2.84, inputs 2.72, read 0.59, unattributed 6.60. 1e16: b60 0.50 / 0.73 / 0.14 / 1.45; b62 0.24 / 0.25 / 0.05 / 0.60; b64 0.27 / 0.32 / 0.06 / 0.85.

- **The 1e17 field's shares are the 1e16 field's** at the same base: top 37.8 against 38.3 %, join 45.7 against 44.7 %, check 7.9 against 7.8 %, bucket 3.3 against 3.5 %.
- **Against PROFILE-2 (20 GB card at 320 W, d1ff798):** b60 33.94 → 42.97 s (×1.27), b62 14.62 → 18.66 (×1.28), b64 42.87 → 53.55 (×1.25). The clock accounts for ×1.22. The top share is down 2–3 points at b60/b62 and up 1 at b64; the bucket share is up 1–3 points, from more batches on the smaller card and this box's slower per-batch host work (section 5).

## 2. µs per top-layer prefix

| size | base | prefixes/field | **µs/prefix, unprofiled** | top | bucket | join | check | other |
|---|---|---|---|---|---|---|---|---|
| **1e17** | **62** | 30.64 M | **7.28** | 2.95 | 0.26 | 3.57 | 0.62 | 0.42 |
| 1e16 | 60 | 5.30 M | **8.11** | 2.70 | 0.28 | 4.31 | 0.71 | 0.53 |
| 1e16 | 62 | 2.56 M | **7.28** | 2.93 | 0.27 | 3.42 | 0.60 | 0.45 |
| 1e16 | 64 | 3.05 M | **17.54** | 2.82 | 0.27 | 12.65 | 1.14 | 0.49 |

(Phase columns are profiled, probe excluded.)

- **Per prefix, 1e17 costs what 1e16 does** (7.28 against 7.28 µs at b62). A b62 1e17 field is about 12 dense b62 1e16 fields' work (30.6 M prefixes against 2.56 M).
- **Top certification: 0.69–0.77 ns per (prefix, partition)** (0.767 at b62 1e17). Against PROFILE-2's (0.603 / 0.617 / 0.504 ns at b60 / b62 / b64, d1ff798 at 1,815 MHz) that is ×1.24 at b60 and b62, the clock ratio (×1.22) to 2 %: #228's 16-bit-limb kernel costs what the old one did there. **At b64 it is ×1.37, 12 % over the clock**: #228 looks slower at b64 (not a live base), which this profile cannot separate from the card.

## 3. Counts per field

| size | base | tops/field | tops/prefix | bpre per slice | listed entries/field | AND pairs/field | wave-padded lane-pairs/field | padded/pairs | entries per probed bucket | work items | AND survivors/field | prefilter survivors (= full checks)/field | AND pass/pair | prefilter keeps | overran the stage/field (share) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **1e17** | **62** | 3.82e10 | 1245 | 9.90e4 | 5.37e10 | 2.53e13 | 3.91e13 | 1.54 | 332 | 1.60e8 | 1.02e12 | 6.27e10 | 4.0 % | 6.1 % | **1.16e8 (1.1e-4)** |
| 1e16 | 60 | 6.89e9 | 1301 | 9.49e4 | 9.28e9 | 5.52e12 | 7.06e12 | 1.28 | 401 | 2.55e7 | 2.30e11 | 1.63e10 | 4.2 % | 7.1 % | 9.0e8 (3.9e-3) |
| 1e16 | 62 | 3.19e9 | 1246 | 1.02e5 | 5.22e9 | 2.17e12 | 3.27e12 | 1.50 | 340 | 1.45e7 | 8.18e10 | 5.02e9 | 3.8 % | 6.1 % | 1.7e6 (2.1e-5) |
| 1e16 | 64 | 3.87e9 | 1266 | 9.39e4 | 4.64e9 | 8.69e12 | 1.58e13 | 1.82 | 281 | 1.65e7 | 3.94e11 | 2.40e10 | 4.5 % | 6.1 % | 1.4e7 (3.6e-5) |

- The overrun counts are identical (to within 0.5 %) in all four runs per field, profiled or not.
- **Work items** (slice, partition, bucket) are slices × partitions × b(b−1): 1.60e8 at 1e17 is 11 × 3,844 × 3,782.
- **Certification:** 1.18e11 (prefix, partition) pairs at b62 1e17, of which 32.4 % certify (3.82e10 tops).
- **bpre** (bottom entries after the field-certificate prune) is the same per slice at 1e17 as at 1e16 (99 k against 95–108 k). The bucket build and the listed entries are per slice: 11 × 4.9e9 listed entries at 1e17.
- The 1e17 field's bucket occupancy (332 entries per probed bucket, padded/pairs 1.54) and its pass rates equal b62 1e16's.

## 4. The join cost model, refitted

Weighted least squares on relative error over the 12 profiled field-runs: 6 distinct fields (b60 ×2, b62 ×2 at 1e16; b64 at 1e16; b62 at 1e17), 2 rounds each (`profile3-raw/analyze.py`, output `analysis.txt` section 4).

| fit on | model | coefficients | rms | max | 1e17 when left out |
|---|---|---|---|---|---|
| 1e16 + 1e17 | padded + surv (PROFILE-2's form) | 0.654 ps, 79.2 ps | 4.4 % | 8.0 % (b64 +7–8 %) | |
| 1e16 + 1e17 | padded + surv + tops | 0.664 ps, 67.7 ps, **368 ps per top** | 2.3 % | 3.8 % | −1.9 / +1.7 % |
| 1e16 + 1e17 | pairs + surv | 1.38 ps per real pair, 68.5 ps | 2.8 % | 5.7 % | −6.4 / −2.9 % |
| **1e16 + 1e17** | **pairs + empty + surv + tops** | **1.176 ps per real pair, 0.490 ps per empty lane, 60.8 ps per survivor, 238 ps per top** | **1.6 %** | **3.2 %** | **−4.0 / −0.4 %** (1e16-only fit: 1.24, 0.43, 61.0, 190) |
| 1e16 + 1e17 | padded + surv + tops + work items | 0.463 ps, 76.3 ps, 172 ps, 35 ns | 1.6 % | 3.0 % | −3.3 / +0.3 % |

- **The coefficients agree with PROFILE-2's once the clock is divided out** (×1.22): its 1e16 fits were 0.874 ps per padded lane-pair + 44.5 ps per survivor + 406 ps per top, and 1.11 ps per real pair + 58.4 ps per survivor. As there, an empty lane costs less than a filled one (0.49 against 1.18 ps), and the AND-lane and survivor terms are nearly collinear (survivors are 4.0–4.5 % of pairs at every base), so individual coefficients move by ±20 % between forms while the predicted totals do not.
- **The 1e17 join fits the 1e16 model.** A per-work-item term (the join's per-(partition, bucket) cube floor, 15.6 ns at 1e14 in PROFILE-2, ×1.22 = 19 ns) would be 3.0 s at 1e17. That is about the 4-term fit's residual on the first 1e17 round (+3.5 s) but not the second (−0.4 s), so it is not resolved here; the 5-term fit puts it at 35 ns with the other coefficients shifting to match.
- **Per-field fixed cost** at 1e16–1e17 is per slice and per batch, not per field (section 5): the bucket build's per-partition part (0.20 s per slice) and the join's per-work-item floor per slice, plus the floors per batch. The upload is per prefix (93 ns), not per slice.

## 5. Where the time goes

Model terms on the profiled means (probe excluded; the join split by the 4-term fit, the check and bucket by fits with a per-batch term: `check = 86.5 ps × full check + 1.92 ms × batch`, rms 9 %; `bucket = 514 ps × (bpre × partition × slice) + 0.86 ms × batch`, rms 10 %). Shares are of the profiled device time.

| size | base | device s, profiled (unprofiled) | **top cert.** | AND lanes (real pairs) | padding (empty lanes) | **survivor handling** | per-top chunk cost | join residual | **check kernel** (its per-batch part) | overrun's extra full checks | bucket | upload | inputs + read + unattributed |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **1e17** | **62** | 239.3 (223.1) | **90.4 s (37.8 %)** | 29.8 s (12.4 %) | 6.7 s (2.8 %) | **62.1 s (26.0 %)** | 9.1 s (3.8 %) | 1.6 s (0.6 %) | **18.9 s (7.9 %)** (12.3 s, 5.2 %) | 0.03 s (0.014 %) | 8.0 s (3.3 %) | 2.8 s (1.2 %) | 9.9 s (4.1 %) |
| 1e16 | 60 | 45.2 (43.0) | 14.3 s (31.6 %) | 6.5 s (14.4 %) | 0.8 s (1.7 %) | 14.0 s (30.9 %) | 1.6 s (3.6 %) | 0.0 | 3.8 s (8.3 %) (2.6 s, 5.7 %) | 0.19 s (0.43 %) | 1.5 s (3.3 %) | 0.5 s (1.1 %) | 2.3 s (5.1 %) |
| 1e16 | 62 | 19.6 (18.7) | 7.5 s (38.3 %) | 2.6 s (13.0 %) | 0.5 s (2.7 %) | 5.0 s (25.3 %) | 0.8 s (3.9 %) | −0.1 s | 1.5 s (7.8 %) (1.0 s, 5.2 %) | 0.0004 s | 0.7 s (3.5 %) | 0.2 s (1.2 %) | 0.9 s (4.6 %) |
| 1e16 | 64 | 53.0 (53.6) | 8.6 s (16.2 %) | 10.2 s (19.3 %) | 3.5 s (6.6 %) | 24.0 s (45.2 %) | 0.9 s (1.7 %) | 0.0 | 3.5 s (6.6 %) (1.3 s, 2.5 %) | 0.002 s | 0.8 s (1.5 %) | 0.3 s (0.5 %) | 1.2 s (2.3 %) |

With the 3-term join fit (padded + surv + tops) instead, b62 1e17 reads padded lanes 10.8 %, survivors 28.9 %, tops 5.9 %: the split between lanes and survivors is the uncertain part, ±3 points.

- **Survivor handling** (the set-bit walk, the shared stage, `mid_pass`, the flush): 61 ps per AND survivor, 1.02e12 survivors at b62 1e17. Against PROFILE-2's 44.5–64 ps (×1.22 for the clock: 54–78), unchanged.
- **The check phase has a fixed part per batch in the profile:** about 1.9 ms, whatever the base (b64's 35 M checks per batch take 5.1 ms, b62's 9.7 M take 2.9 ms); per check, 86.5 ps. At b62 1e17 that is two thirds of the profiled check phase. **Unprofiled it mostly vanishes:** 38 % fewer batches saved 0.6 % (section 6), i.e. about 0.5 ms per batch for everything per batch together. So unprofiled the check kernel is about 5.4 s + a share of the 3 s per-batch total, 3–4 % of the field, not 8 %.
- **The stage overrun's extra full checks** (overrun × (1 − prefilter keep) × per-check cost) are 0.014 % at b62 1e17 and 0.43 % at b60 1e16. At 1e17 the overrun is 5× more frequent per survivor than at b62 1e16, but survivors there are still almost all staged.
- **Where the 7 % profiling excess sits** (16.1 s at b62 1e17, 2.5 ms per batch): mostly inputs + unattributed (9.3 s, which are host-side gaps between synchronised kernels) and the check's and bucket's per-batch intercepts. The kernel-throughput terms (top, the join's four terms, per-check, per-bpre) are not inflated: the top phase is 0.767 ns per certification profiled at 14 ms per batch, where a 0.5 ms sync is 3 %.

## 6. Levers measured at b62 1e17

Unprofiled, knob binary `b81cd953`, interleaved with knob-unset controls (`chain3.sh`–`chain5.sh`). The card's clock drifts 1,430–1,470 MHz with temperature under its power cap, so device seconds are also given clock-normalised (× SM MHz under load / 1,500). **Even so, the controls spread 5 %** (212.7–223.7 s normalised over 6 runs; 220.9–229.5 s raw, 4 %), so ±2.5 % is the resolution of this section.

| configuration | slices | batches | partitions/launch (first plan) | plan MiB | runs: device s (clock-normalised) | median, normalised | vs control | median, raw | vs control |
|---|---|---|---|---|---|---|---|---|---|
| control (knob unset ×4, main-profile binary ×2) | 11 | 6,439 | 5 | 1,667 | 228.6 (223.7), 229.5 (219.7), 224.2 (212.7), 224.6 (213.2); 220.9 (215.6), 225.3 (216.9) | 216.3 | 1 | 224.9 | 1 |
| `SURV_PER_PREFIX=1` | 11 | 3,974 | 9 | 2,451 | 223.6 (213.5), 226.7 (215.0), 226.3 (216.1) | 215.0 | **×0.994** | 226.3 | ×1.006 |
| `SLICE_MULT=3` + `SURV_PER_PREFIX=1` | 4 | 3,652 | 4 | 2,183 | 224.5 (214.2), 227.0 (214.9), 224.1 (213.7) | 214.2 | **×0.991** | 224.5 | ×0.998 |
| `SLICE_MULT=2` | 6 | 7,178 | 3 | 1,494 | 226.0 (220.3) | 220.3 | ×1.018 | 226.0 | ×1.005 |

Counted AND survivors plus overruns are 1,020,844,021,499 in every run of every configuration; no hits.

- **Partitions per launch (`NICE_EXP_SURV_PER_PREFIX=1`)**: the survivor bound halves, partitions per launch go 5–8 → 9 (first plan), plan 1,667 → 2,451 MiB of 2,560, batches 6,439 → 3,974 (−38 %). **×0.994 normalised, ×1.006 raw: no gain outside the noise.** Unprofiled, a batch's fixed cost is therefore about 0.5 ms (at most about 1.8 ms, the controls' spread over the 2,465 batches saved), not the 2.8 ms that the profile's per-batch intercepts (check 1.9 ms, bucket 0.86 ms) suggest: most of those are the profile's own host latency at each sync.
- **Fewer slices (`NICE_EXP_SLICE_MULT=3`, with the bound at 1 so that batches stay few)**: 11 → 4 slices, 3,652 batches at 4 partitions per launch. **×0.991 normalised, ×0.998 raw: nothing either.**
  - **Wider slices prune less.** The field-certificate prune (#215) is per slice: at 4 slices bpre is 102.8 k per slice against 99.0 k, listed entries +8 % per slice, and **real AND pairs +9.4 %** (2.77e13 against 2.53e13). The wave-padded lane-pairs are identical to the last digit (3.907e13): every bucket still fits the same 512-lane waves, so the extra real pairs fill lanes that were empty. At the 4-term fit's 1.18 − 0.49 ps that costs +1.6 s, against the 7 slices' fixed work saved (bucket per-slice part 7 × 0.20 s, the join's per-work-item floor on 1.0e8 fewer work items, 2–5 s).
  - Its profile (`x17_mult3spp1_prof_r1`, 231.4 s against the control's 239.3 s profiled): check −5.1 s and bucket −2.4 s (1.8 and 0.85 ms per batch fewer, the per-batch intercepts of section 5), inputs + read + unattributed −5.8 s (profiling gaps), top +4.2 s (+4.6 %, of which 2.2 points are the run's lower clock), join +1.2 s (the extra real pairs).
- **`NICE_EXP_SLICE_MULT=2` alone** (6 slices) keeps the bound at 2, so a 5.1 M-prefix slice gets 3 partitions per launch: batches rise to 7,178 and the run is no faster (×1.018 normalised, one run).
- **What the per-batch cost is, unprofiled:** about 0.5 ms (≤ 1.8 ms) × 6,439 batches = about 3 s (≤ 12 s), 1.5 % (≤ 5 %) of the field; and the per-slice saving is repaid by the prune. **At b62 1e17 on a 10 GB card the batch and slice structure is not a lever.**


## 7. What a 5 % and a 10 % win at b62 1e17 would need

Target: 5 % of 223 s is **11.2 s**, 10 % is **22.3 s**. Terms in seconds from section 5 (profiled; the throughput terms are not inflated by the profile, so as shares of the unprofiled field they are about 1.07× the table's).

| term at b62 1e17 | s | share of the field | for 5 % | for 10 % |
|---|---|---|---|---|
| **top certification** (0.77 ns per (prefix, partition), 1.18e11 of them, 32 % certify) | 90 | 38–40 % | **−12 %** of the top kernel | −25 % |
| **survivor handling** (61 ps per AND survivor, 1.02e12) | 62 | 26–28 % (±3 by fit form) | **−18 %** per survivor, or 18 % fewer AND survivors at equal lanes | −36 % |
| AND lanes, real pairs (1.18 ps, 2.53e13) | 30 | 12–13 % | −37 % per lane-pair | −75 % |
| per-batch fixed cost (6,439 batches) | about 3 unprofiled (≤ 12) | about 1.5 % (≤ 5 %); −38 % batches measured ×0.994 | not reachable | — |
| per-top chunk cost in the join (238 ps per top) | 9 | 4 % | not reachable alone | — |
| wave padding (0.49 ps per empty lane, 1.37e13) | 7 | 3 % | not reachable | — |
| check kernel, per check (86 ps, 6.27e10) | 5 | 2.4 % | not reachable | — |
| per-slice fixed work (11 slices) | 3–5, mostly repaid by the per-slice prune | ≤ 1 % net (measured) | not reachable | — |
| stage overrun's extra full checks | 0.03 | 0.014 % | — | — |

- **A 5 % win needs one of the two big terms:** the top kernel 12 % faster, or survivor handling 18 % cheaper (the set-bit walk, the shared stage, `mid_pass`, the flush; or an AND filter that passes 18 % fewer survivors without adding that much in lanes: the AND passes 4.0 % of pairs, and `mid_pass` then rejects 94 % of what it passed). A split works too, e.g. top −7 % and survivors −8 %.
- **A 10 % win needs both, or one of them twice over:** top −25 %, survivors −36 %, or top −12 % with survivors −18 %. Nothing else is large enough to contribute more than a point or two.
- **The top kernel is the single biggest lever at b62.** It certifies every (prefix, partition) pair, and two thirds of them fail. What it would take: rejecting most failures before the full digit scan of n² and n³, or a digit scan that does not divide per pair (the detailed mode's #221/#225 replaced division with finite differences over consecutive n; the certificate's n differ by partition, so whether that carries over is untested).
- **Batch and slice structure is not a lever here.** Measured on this card: 38 % fewer batches ×0.994, and 11 → 4 slices on top of that ×0.991, both inside the controls' ±2.5 %. The profile's per-batch intercepts are mostly its own sync latency, and narrow slices prune the bottom list better, which repays most of their fixed work. (A 10 GB card is also at its memory budget at 9 partitions per launch: 2,451 of 2,560 MiB.)
- **At b60 1e16** (the other live size) the order is the same with survivor handling first: survivors 31 %, top 32 %, lanes 14 %, check 8 % in the profile (most of it per-batch profile latency), overrun 0.4 %. 5 % there needs the top kernel −15 % or survivor handling −15 %.

## 8. What differs from the 1e16 picture

- **Per prefix, nothing changes.** b62 costs 7.28 µs per top-layer prefix at 1e16 and at 1e17; every phase share is within a point; top certification is the largest phase at both sizes. A 1e17 field is about 12 dense 1e16 fields.
- **Batches per prefix are the same at both sizes** (2.10e-4 at 1e17, 2.07e-4 at 1e16). Partitions per launch are bound by expected survivors everywhere, so a slice with more prefixes gets fewer partitions per launch; the per-batch costs are a fixed share of the work at any field size.
- **What 1e17 adds is slices.** 11 on a 10 GB card (1 for b62 1e16, 2 for b60 1e16), because a slice is cut by prefix blocks (28 % of which are prefixes) rather than by prefixes. Each slice repeats the bucket build's per-partition part (0.20 s) and the join's per-work-item floor (14.5 M work items). That is 2–3 % of the field, but narrow slices also prune the bottom list better (real AND pairs +9.4 % at 4 slices), and measured, 11 → 4 slices saves nothing. On a 16 GB+ card (4 GiB budget, 1 GiB list) a 1e17 b62 field would be about 7 slices.
- **Upload is not per slice:** 2.84 s at 1e17 against 0.24 s for b62 1e16, i.e. per prefix the same (93 ns per prefix).
- **The stage overrun is 5× more frequent** (1.1e-4 of AND survivors against 2.1e-5 at b62 1e16), still 0.014 % of the time. b60 1e16's 3.9e-3 (0.4 %) remains the largest.
- **Host setup:** 19 s of CPU per field (11 slices × 1.7 s). Only the first slice's precedes the device; each later slice is prepared during the previous one, and the field's wall time equals its device time to 0.1 s, so no slice waited for its setup on this 9.6-CPU box. In production the first slice's 1.7 s also overlaps the previous field.
- **Live b62 fields vary from empty to this dense.** The first unchecked field of the list has no top-layer prefixes at all, so a mean b62 1e17 field costs less than this one; this profile is per prefix, which is what carries over.

## Raw data and scripts

All in `L1/profile3-raw/`:

- **Main runs:** `box/e17_b62_{prof,noprof}_r{1,2}.log`, `box/e16_b{60,62,64}_{prof,noprof}_r{1,2}.log`, each with a `.smi` clock/power trace (5 s).
- **Frontier field:** `box/e17f_b62_{prof,noprof}_r1.log` (empty top layer).
- **Lever runs:** `box/x17_*.log`.
- **Box metadata:** `box/power.txt`, `clocks.txt`, `nvidia-smi.txt`, `nproc.txt`; build logs `testbuild.log`, `testbuild_x.log`; `setup.log`.
- **Scripts:** `setup.sh`, `setup_x.sh` (builds), `run.sh` / `run2.sh` (one pass), `chain.sh` (main runs), `chain2.sh` (frontier field), `chain3.sh`–`chain5.sh` (levers; `box/wait*.sh` queued them); `analyze.py` (all tables and fits; output `analysis.txt`, sections 1–9). Run it with `uv run --with numpy python3 analyze.py box`.
