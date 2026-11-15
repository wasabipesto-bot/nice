# T2.8 early audit of base 62, and what the release is worth on NVIDIA at base 62 (2026-11-15)

Agent run 05:56–09:30 UTC. Box: Vast 60746721, RTX 3080 **power-capped at 150 W** (max 320 W; `nvidia-smi -pl`
refused in the container), Xeon E5-2630 v4, 8 GB RAM, driver 580.159.03; clients `--threads 8`, GPU backend auto
(CubeCL CUDA). Labels: **[measured]**, **[derived]**, **[assumed]**. Everything under `raw/`.

## Answers

1. **Instant fields: every one is empty.** All **8,665** base-62 fields with a submission of zero survivors and zero
   checked (census to 09:01 UTC) are proved empty from `range_start`/`range_end` alone by an independent exact
   big-integer check [measured]. **No instant field that cannot be shown empty.** By argument: 8,385 leading digits
   1 and 1 (x < 2^(1/3)); 263 another collision of the top digits the range fixes; 14 Hall on the two
   first-disagreement positions; 3 by subdivision (≤ 195 nodes). Reverse: of the 329 run fields in the 06:00 census,
   my field-level check rejects **0**; with subdivision deeper than the client's (to a 200k-node budget) **1**
   (207072495, run by the fleet and both builds on the box: 193 survivors, 32 checked, no nice number); 328 undecided.
2. **Re-verification: no mismatch in 156 comparisons** on 112 fields (91 exact equalities, 65 bounds). All 48
   sampled submissions (32 demoux a7a59c1, 16 fleet v3.4.7, RTX 4060 = the only fleet GPU model at b62) were re-run
   with upstream main 54d0aac4 against a local stub, plus every other census submission on a re-run field and the
   box's own v3.4.7 runs. demoux and main-repeat comparisons are **exact equalities** of survivors and checked (and of
   the nice-number list, empty everywhere); v3.4.7 comparisons are **bounds** (the overrun model of `T2/AUDIT.md` §4
   rule 3), all inside, max |d|/tol 0.49, max overrun x/T 3.2e-6.
3. **Release ratio on the RTX 3080 at 150 W:** v3.4.7 / main = **×3.13 join run_secs (geomean, range 2.99–3.21),
   ×3.08 whole-field wall (2.95–3.17)** over 5 real fields × 2 interleaved rounds [measured]; counts identical
   between rounds for main, within the overrun bound for v3.4.7. Implied for the fleet [derived, assuming the ratio
   carries from a power-capped 3080 to an RTX 4060]: 338 s → ≈ 110 s per real field, ≈ 3.1× fields per dollar-hour
   (10.7 → ≈ 33 real fields per box-hour at the same price).
4. **Base 62 ends ≈ 2027-01-06 at the present rate** [derived]: 76,762 fields past the processed frontier need a real
   run (field-level predictor), at 61.7 *new* real fields/h (03–08 UTC) = 1,245 h. If the duplicate submissions
   (≈ 19 % of real submissions are a second search of a field, see §4) stopped: ≈ 78 fields/h → ≈ 2026-12-26. If the
   fleet ran main (×3.1): ≈ 38 days → ≈ 2026-12-23. Assumptions: per-field cost constant across the base (only
   0.9 % of it has been seen), demoux and the fleet as now, no deploy. **Base 60 is complete**: all 162,076 fields at
   check_level ≥ 1 [measured].

## 1. Instant fields (ivory, CPU, exact)

**The client's certificate** (54d0aac4 = a7a59c1 + CI/toolchain/cc bumps; `common/src/overlap_join.rs`,
`cubecl_join.rs`). At b62, n has L = 13 digits; `JoinParams::for_length` gives t = 10, k = 6, p = 2. The field is cut
into slices (`join_slices`, granularity 62^5); per slice `FieldSetup::top_side` builds `Base::top_layer(s, e−1,
depth t−p = 8, cap k = 6)`: breadth first over n's top 1..8 digits, a prefix interval [a, e] survives iff
`Base::cert(a, e, 6)` is `Some`, and a failing prefix's children are skipped. `cert_parts`: for j = 2, 3, start at
c0 = max(6, ndig(e^j − a^j)); the digits of ⌊a^j / 62^c0⌋ are common to every n^j (after a trailing run of 61s and
the d/d+1 digit above it when ⌊e^j/62^c0⌋ is one more); any repeated digit among the common digits of n² and n³ →
`None`; then `close_certificate` on the two d/d+1 domains (empty free set → `None`, a single free digit is forced
into the mask). If every slice's top layer is empty, `run_slice` launches nothing: `run_secs` 0, survivors = checked
= 0, `launches` 0 (what every instant submission shows: setup ≈ 0.02 s, slices 14, partitions 3,844).

**My independent check** (`raw/instant_check.py`, written from the definitions, not from the code): for [a, e] and
j = 2, 3, the lowest c with ⌊a^j/62^c⌋ = ⌊e^j/62^c⌋ (found directly, no c0 shortcut) gives digits common to every n^j
at positions ≥ c, and at c − 1 a digit in [lo, hi] (the digits of a^j, e^j there). Fail if the lengths of n², n³ do
not sum to 62, if the common digits repeat, or by Hall on the two domains (X, Y = domains minus common digits; need X,
Y ≠ ∅ and |X ∪ Y| ≥ 2). No cap (positions ≥ 0), general [lo, hi] domains, full two-set Hall: at least as strong as the
client's cert. A passing interval is split at multiples of the largest power of 62 that cuts it and recursed.
Soundness checks (`raw/soundness.txt`): brute force at bases 5–24 (only base 10 has a nice number there: 200
intervals around 69, none wrongly rejected — a weak test); 132,000 checks at base 62 that random n in random
sub-intervals of real fields have the claimed common and domain digits (0 violations).

| argument (instant fields, census to 09:01 UTC) | fields |
|---|---|
| leading digits of n², n³ both 1 over the field (x < 2^(1/3); ids 207064110–207072494) | 8,385 |
| other collision of the top digits the range fixes | 263 |
| Hall on the first-disagreement positions, field level | 14 |
| subdivision (depths 1, 2, 4; 9, 72, 195 nodes) | 3 |
| **not shown empty** | **0** |

The boundary: the first field past x = 2^(1/3) is 207072495 (index 8,385) [measured: every field below it is instant
and leading digits (1,1)]. The (2,2) block at x ∈ [√2, 3^(1/3)) starts near id 207077474, not reached yet.
Agreement with the client past the boundary: of 798 submitted fields, the client found 280 instant; my field-level
check rejects 277 of those and none of the 518 run fields; the other 3 instant ones need subdivision (`raw/telemetry.txt`).

## 2. Sampled exact re-verification (box, real client vs local stub)

Mechanism as `T2/AUDIT.md` §2: production hosts (`api.`, `data.`, `www.nicenumbers.net`, `nicenumbers.net`) mapped
to 127.0.0.1 and ::1 at 05:57 UTC before any build or client run; `curl` exit 7 for each, github.com 200
(`raw/proof_hosts_block.txt`); `raw/run_queue.sh` refuses to start if a production host answers or the block is
missing, and every client gets `--api-base http://127.0.0.1:<port>`; the only nicenumbers host in both binaries'
strings is `api.nicenumbers.net` (the default). No census query from the box. Stub `raw/stub_api.py` (T2's, plus
claim/submit timestamps). Builds on the box from exact commits (`raw/box_build.sh`, `--features gpu,cubecl-cuda`):
54d0aac4 (rustc 1.100.0) and v3.4.7 = 8bd154bc (rustc 1.99.1).

Sample (`raw/make_sample.py` → `raw/sample.json`, drawn before any run from the 06:00 census): demoux 32 (first 5 past
the boundary, latest 5, min run_secs 2.5 s and max 73.3 s, rest spread in time); fleet 16 (first, last, min 3.9 s,
max 400.8 s, rest spread); 6 fleet fields doubled as the timing fields. Extension (`raw/make_ext.py`): the other 36
fleet fields and 30 random demoux fields (seed 20261115), run as far as time allowed.

Rules (`raw/compare.py`): a7a59c11 and main repeats: **exact** (survivors, checked and nice list equal to main's
re-run). v3.4.7 (#222 without #236, counters timing dependent): **bound**, T, P = main's counts, p = P/T, x = T −
survivors ≥ 0, |d| = |checked − P − x(1 − p)| ≤ 5√(x p(1 − p)) + 2 + 0.06 p(1 − p) x.

**Result: 156 comparisons on 112 fields, 0 mismatches** [measured, `raw/compare.txt`, `raw/compare_detail.jsonl`]:

| original | rule | compared | equal / inside |
|---|---|---|---|
| demoux a7a59c1, sampled submissions | exact | 32 | 32 |
| demoux a7a59c1, other submissions on re-run fields (extension + second searches) | exact | 53 | 53 |
| box main repeats (timing round 2 vs round 1) | exact | 6 | 6 |
| fleet v3.4.7 RTX 4060, sampled | bound | 16 | 16 |
| fleet v3.4.7 RTX 4060, other (extension + duplicates) | bound | 37 | 37 |
| box v3.4.7 RTX 3080 (timing runs) | bound | 12 | 12 |

Demoux's RX 9070 XT (wgpu/Vulkan, 14 slices) and the 3080 (CUDA, 11 slices) agree to the unit on all 85 demoux
submissions; no nice number anywhere (every list empty). Coverage of what has been searched: 85 of 532 demoux real
submissions and 53 of 87 fleet real submissions. 95 % upper bound on a per-field disagreement rate given 0 of n
[derived]: demoux 3.5 % (n = 85), fleet 5.5 % (n = 53).

Every comparison (field, device, build, both counts, rule, margin): `raw/compare_table.md`, reproduced here:

| field | compared submission | device | build | survivors | checked | main survivors (T) | main checked (P) | rule | result | margin |
|---|---|---|---|---|---|---|---|---|---|---|
| 207072495 | box main repeat T2_54d0aac4_f0 | RTX 3080 (box) | 54d0aac4 | 193 | 32 | 193 | 32 | exact | equal | Δ 0 / 0 |
| 207072495 | box v3.4.7 T1_8bd154bc_f0 | RTX 3080 (box) | 8bd154bc | 193 | 32 | 193 | 32 | overrun-model | within bound | x=0, d=0.0, tol=2.0 (|d|/tol 0.00) |
| 207072495 | box v3.4.7 T2_8bd154bc_f0 | RTX 3080 (box) | 8bd154bc | 193 | 32 | 193 | 32 | overrun-model | within bound | x=0, d=0.0, tol=2.0 (|d|/tol 0.00) |
| 207072495 | wp-vast-fleet sub 294763463 [sample] | RTX 4060 | 8bd154bc | 193 | 32 | 193 | 32 | overrun-model | within bound | x=0, d=0.0, tol=2.0 (|d|/tol 0.00) |
| 207072501 | demoux sub 294763609 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 822,934,483,610 | 48,907,494,940 | 822,934,483,610 | 48,907,494,940 | exact | equal | Δ 0 / 0 |
| 207072502 | demoux sub 294763732 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 647,087,448,955 | 38,458,502,281 | 647,087,448,955 | 38,458,502,281 | exact | equal | Δ 0 / 0 |
| 207072503 | demoux sub 294763892 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 864,691,573,158 | 51,374,146,555 | 864,691,573,158 | 51,374,146,555 | exact | equal | Δ 0 / 0 |
| 207072504 | demoux sub 294764036 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 774,815,458,588 | 46,035,175,661 | 774,815,458,588 | 46,035,175,661 | exact | equal | Δ 0 / 0 |
| 207072505 | wp-vast-fleet sub 294764332 | RTX 4060 | 8bd154bc | 814,830,605,232 | 48,410,894,040 | 814,830,978,840 | 48,410,542,761 | overrun-model | within bound | x=373,608, d=-132.3, tol=1977.1 (|d|/tol 0.07) |
| 207072506 | wp-vast-fleet sub 294765179 | RTX 4060 | 8bd154bc | 784,897,349,683 | 46,637,329,335 | 784,897,422,933 | 46,637,260,502 | overrun-model | within bound | x=73,250, d=-64.6, tol=567.5 (|d|/tol 0.11) |
| 207072507 | demoux sub 294764195 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 854,777,030,923 | 50,786,387,577 | 854,777,030,923 | 50,786,387,577 | exact | equal | Δ 0 / 0 |
| 207072509 | wp-vast-fleet sub 294765910 [sample] | RTX 4060 | 8bd154bc | 651,705,246,096 | 38,722,669,199 | 651,705,271,228 | 38,722,645,641 | overrun-model | within bound | x=25,132, d=-80.7, tol=273.7 (|d|/tol 0.29) |
| 207072510 | wp-vast-fleet sub 294766753 | RTX 4060 | 8bd154bc | 745,439,890,168 | 44,291,790,322 | 745,439,891,036 | 44,291,789,516 | overrun-model | within bound | x=868, d=-10.4, tol=39.7 (|d|/tol 0.26) |
| 207072511 | wp-vast-fleet sub 294767633 | RTX 4060 | 8bd154bc | 795,767,229,324 | 47,278,810,692 | 795,767,255,794 | 47,278,785,787 | overrun-model | within bound | x=26,470, d=7.7, tol=283.1 (|d|/tol 0.03) |
| 207072512 | wp-vast-fleet sub 294768504 | RTX 4060 | 8bd154bc | 806,168,390,961 | 47,896,570,093 | 806,168,653,791 | 47,896,323,041 | overrun-model | within bound | x=262,830, d=-162.7, tol=1489.2 (|d|/tol 0.11) |
| 207072513 | wp-vast-fleet sub 294769442 [sample] | RTX 4060 | 8bd154bc | 891,910,772,873 | 52,990,320,286 | 891,911,243,581 | 52,989,877,704 | overrun-model | within bound | x=470,708, d=-160.5, tol=2391.2 (|d|/tol 0.07) |
| 207072514 | wp-vast-fleet sub 294770301 | RTX 4060 | 8bd154bc | 806,544,870,430 | 47,921,241,790 | 806,545,059,061 | 47,921,064,390 | overrun-model | within bound | x=188,631, d=-23.4, tol=1147.9 (|d|/tol 0.02) |
| 207072515 | wp-vast-fleet sub 294771120 | RTX 4060 | 8bd154bc | 786,156,952,395 | 46,709,982,473 | 786,158,896,952 | 46,708,154,325 | overrun-model | within bound | x=1,944,557, d=-876.8, tol=8170.3 (|d|/tol 0.11) |
| 207072516 | wp-vast-fleet sub 294772010 | RTX 4060 | 8bd154bc | 839,350,943,543 | 49,871,254,287 | 839,351,369,304 | 49,870,853,666 | overrun-model | within bound | x=425,761, d=157.0, tol=2200.9 (|d|/tol 0.07) |
| 207072517 | box main repeat T2_54d0aac4_f1 | RTX 3080 (box) | 54d0aac4 | 863,401,151,773 | 51,300,460,796 | 863,401,151,773 | 51,300,460,796 | exact | equal | Δ 0 / 0 |
| 207072517 | box v3.4.7 T1_8bd154bc_f1 | RTX 3080 (box) | 8bd154bc | 863,400,805,575 | 51,300,786,249 | 863,401,151,773 | 51,300,460,796 | overrun-model | within bound | x=346,198, d=-175.1, tol=1858.3 (|d|/tol 0.09) |
| 207072517 | box v3.4.7 T2_8bd154bc_f1 | RTX 3080 (box) | 8bd154bc | 863,400,798,813 | 51,300,792,631 | 863,401,151,773 | 51,300,460,796 | overrun-model | within bound | x=352,960, d=-153.3, tol=1887.8 (|d|/tol 0.08) |
| 207072517 | wp-vast-fleet sub 294772892 [sample] | RTX 4060 | 8bd154bc | 863,400,799,156 | 51,300,792,413 | 863,401,151,773 | 51,300,460,796 | overrun-model | within bound | x=352,617, d=-48.7, tol=1886.3 (|d|/tol 0.03) |
| 207072518 | wp-vast-fleet sub 294773835 | RTX 4060 | 8bd154bc | 890,622,111,430 | 52,914,463,856 | 890,622,475,439 | 52,914,121,780 | overrun-model | within bound | x=364,009, d=-306.3, tol=1935.6 (|d|/tol 0.16) |
| 207072524 | demoux sub 294765210 | AMD Radeon RX 9070 XT | a7a59c11 | 804,079,786,532 | 47,774,684,864 | 804,079,786,532 | 47,774,684,864 | exact | equal | Δ 0 / 0 |
| 207072528 | demoux sub 294765803 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 900,238,881,980 | 53,502,009,919 | 900,238,881,980 | 53,502,009,919 | exact | equal | Δ 0 / 0 |
| 207072532 | demoux sub 294765884 | AMD Radeon RX 9070 XT | a7a59c11 | 272,609,782,960 | 16,204,864,751 | 272,609,782,960 | 16,204,864,751 | exact | equal | Δ 0 / 0 |
| 207072541 | demoux sub 294767228 | AMD Radeon RX 9070 XT | a7a59c11 | 789,180,766,878 | 46,890,020,817 | 789,180,766,878 | 46,890,020,817 | exact | equal | Δ 0 / 0 |
| 207072545 | demoux sub 294767814 | AMD Radeon RX 9070 XT | a7a59c11 | 771,952,663,418 | 45,864,020,401 | 771,952,663,418 | 45,864,020,401 | exact | equal | Δ 0 / 0 |
| 207072546 | demoux sub 294767975 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 883,791,896,126 | 52,508,633,268 | 883,791,896,126 | 52,508,633,268 | exact | equal | Δ 0 / 0 |
| 207072560 | demoux sub 294769813 | AMD Radeon RX 9070 XT | a7a59c11 | 60,172,778,478 | 3,577,365,216 | 60,172,778,478 | 3,577,365,216 | exact | equal | Δ 0 / 0 |
| 207072561 | demoux sub 294769963 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 816,490,701,610 | 48,528,865,627 | 816,490,701,610 | 48,528,865,627 | exact | equal | Δ 0 / 0 |
| 207072564 | demoux sub 294770395 | AMD Radeon RX 9070 XT | a7a59c11 | 731,154,227,434 | 43,443,006,266 | 731,154,227,434 | 43,443,006,266 | exact | equal | Δ 0 / 0 |
| 207072568 | demoux sub 294770968 | AMD Radeon RX 9070 XT | a7a59c11 | 883,901,242,187 | 52,516,718,344 | 883,901,242,187 | 52,516,718,344 | exact | equal | Δ 0 / 0 |
| 207072570 | demoux sub 294771275 | AMD Radeon RX 9070 XT | a7a59c11 | 947,912,853,215 | 56,321,652,733 | 947,912,853,215 | 56,321,652,733 | exact | equal | Δ 0 / 0 |
| 207072572 | demoux sub 294771581 | AMD Radeon RX 9070 XT | a7a59c11 | 831,530,553,985 | 49,406,414,601 | 831,530,553,985 | 49,406,414,601 | exact | equal | Δ 0 / 0 |
| 207072577 | demoux sub 294772340 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 862,947,569,757 | 51,271,223,904 | 862,947,569,757 | 51,271,223,904 | exact | equal | Δ 0 / 0 |
| 207072578 | wp-vast-fleet sub 294774701 | RTX 4060 | 8bd154bc | 773,001,898,177 | 45,929,923,178 | 773,001,925,609 | 45,929,897,346 | overrun-model | within bound | x=27,432, d=29.9, tol=289.8 (|d|/tol 0.10) |
| 207072586 | demoux sub 294775592 | AMD Radeon RX 9070 XT | a7a59c11 | 971,518,783,988 | 57,722,311,489 | 971,518,783,988 | 57,722,311,489 | exact | equal | Δ 0 / 0 |
| 207072586 | wp-vast-fleet sub 294776004 | RTX 4060 | 8bd154bc | 971,518,224,879 | 57,722,836,863 | 971,518,783,988 | 57,722,311,489 | overrun-model | within bound | x=559,109, d=-515.8, tol=2760.5 (|d|/tol 0.19) |
| 207072587 | demoux sub 294773497 | AMD Radeon RX 9070 XT | a7a59c11 | 928,907,028,733 | 55,205,511,011 | 928,907,028,733 | 55,205,511,011 | exact | equal | Δ 0 / 0 |
| 207072597 | demoux sub 294774452 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 851,213,355,009 | 50,588,749,871 | 851,213,355,009 | 50,588,749,871 | exact | equal | Δ 0 / 0 |
| 207072602 | demoux sub 294775709 | AMD Radeon RX 9070 XT | a7a59c11 | 600,358,676,123 | 35,676,730,867 | 600,358,676,123 | 35,676,730,867 | exact | equal | Δ 0 / 0 |
| 207072602 | wp-vast-fleet sub 294776679 [sample] | RTX 4060 | 8bd154bc | 600,358,668,449 | 35,676,738,054 | 600,358,676,123 | 35,676,730,867 | overrun-model | within bound | x=7,674, d=-31.0, tol=131.3 (|d|/tol 0.24) |
| 207072837 | demoux sub 294776463 | AMD Radeon RX 9070 XT | a7a59c11 | 701,817,694,650 | 41,704,872,794 | 701,817,694,650 | 41,704,872,794 | exact | equal | Δ 0 / 0 |
| 207072840 | wp-vast-fleet sub 294777450 | RTX 4060 | 8bd154bc | 741,283,242,385 | 44,042,147,876 | 741,284,369,510 | 44,041,088,268 | overrun-model | within bound | x=1,127,125, d=-552.4, tol=5036.0 (|d|/tol 0.11) |
| 207072841 | wp-vast-fleet sub 294778306 | RTX 4060 | 8bd154bc | 823,928,874,514 | 48,954,727,901 | 823,931,538,498 | 48,952,223,234 | overrun-model | within bound | x=2,663,984, d=-1041.8, tol=10863.5 (|d|/tol 0.10) |
| 207072843 | demoux sub 294777130 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 935,491,486,570 | 55,573,534,545 | 935,491,486,570 | 55,573,534,545 | exact | equal | Δ 0 / 0 |
| 207072844 | wp-vast-fleet sub 294779096 [sample] | RTX 4060 | 8bd154bc | 743,668,500,711 | 44,185,160,366 | 743,669,356,897 | 44,184,355,323 | overrun-model | within bound | x=856,186, d=-273.6, tol=3966.5 (|d|/tol 0.07) |
| 207072850 | wp-vast-fleet sub 294779818 | RTX 4060 | 8bd154bc | 644,721,106,141 | 38,307,589,193 | 644,721,163,137 | 38,307,535,676 | overrun-model | within bound | x=56,996, d=-92.5, tol=475.3 (|d|/tol 0.19) |
| 207072855 | demoux sub 294778634 | AMD Radeon RX 9070 XT | a7a59c11 | 828,684,401,028 | 49,229,729,802 | 828,684,401,028 | 49,229,729,802 | exact | equal | Δ 0 / 0 |
| 207072856 | wp-vast-fleet sub 294780786 | RTX 4060 | 8bd154bc | 885,695,485,601 | 52,615,096,977 | 885,695,540,300 | 52,615,045,563 | overrun-model | within bound | x=54,699, d=-35.6, tol=461.8 (|d|/tol 0.08) |
| 207072858 | demoux sub 294778961 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 1,037,321,183,146 | 61,621,158,275 | 1,037,321,183,146 | 61,621,158,275 | exact | equal | Δ 0 / 0 |
| 207072862 | wp-vast-fleet sub 294781737 | RTX 4060 | 8bd154bc | 893,124,674,926 | 53,059,027,737 | 893,125,858,698 | 53,057,914,717 | overrun-model | within bound | x=1,183,772, d=-427.7, tol=5256.7 (|d|/tol 0.08) |
| 207072863 | demoux sub 294779592 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 960,504,938,962 | 57,061,610,525 | 960,504,938,962 | 57,061,610,525 | exact | equal | Δ 0 / 0 |
| 207072868 | box main repeat T2_54d0aac4_f2 | RTX 3080 (box) | 54d0aac4 | 780,224,058,985 | 46,355,547,549 | 780,224,058,985 | 46,355,547,549 | exact | equal | Δ 0 / 0 |
| 207072868 | box v3.4.7 T1_8bd154bc_f2 | RTX 3080 (box) | 8bd154bc | 780,224,050,434 | 46,355,555,595 | 780,224,058,985 | 46,355,547,549 | overrun-model | within bound | x=8,551, d=3.0, tol=140.0 (|d|/tol 0.02) |
| 207072868 | box v3.4.7 T2_8bd154bc_f2 | RTX 3080 (box) | 8bd154bc | 780,224,049,852 | 46,355,556,151 | 780,224,058,985 | 46,355,547,549 | overrun-model | within bound | x=9,133, d=11.6, tol=145.6 (|d|/tol 0.08) |
| 207072868 | wp-vast-fleet sub 294782601 [sample] | RTX 4060 | 8bd154bc | 780,224,050,139 | 46,355,555,856 | 780,224,058,985 | 46,355,547,549 | overrun-model | within bound | x=8,846, d=-13.4, tol=142.8 (|d|/tol 0.09) |
| 207072876 | wp-vast-fleet sub 294783560 | RTX 4060 | 8bd154bc | 878,795,283,314 | 52,205,694,718 | 878,795,366,262 | 52,205,616,678 | overrun-model | within bound | x=82,948, d=19.6, tol=620.5 (|d|/tol 0.03) |
| 207072880 | demoux sub 294781808 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 798,413,827,297 | 47,435,992,842 | 798,413,827,297 | 47,435,992,842 | exact | equal | Δ 0 / 0 |
| 207072883 | wp-vast-fleet sub 294784381 | RTX 4060 | 8bd154bc | 746,237,485,597 | 44,334,452,869 | 746,237,528,779 | 44,334,412,204 | overrun-model | within bound | x=43,182, d=48.5, tol=392.4 (|d|/tol 0.12) |
| 207072889 | demoux sub 294782770 | AMD Radeon RX 9070 XT | a7a59c11 | 783,333,198,720 | 46,550,515,119 | 783,333,198,720 | 46,550,515,119 | exact | equal | Δ 0 / 0 |
| 207072891 | wp-vast-fleet sub 294785326 | RTX 4060 | 8bd154bc | 892,337,929,412 | 53,013,809,219 | 892,338,304,542 | 53,013,456,654 | overrun-model | within bound | x=375,130, d=-278.7, tol=1983.7 (|d|/tol 0.14) |
| 207072896 | demoux sub 294783706 | AMD Radeon RX 9070 XT | a7a59c11 | 932,948,685,910 | 55,426,591,510 | 932,948,685,910 | 55,426,591,510 | exact | equal | Δ 0 / 0 |
| 207072899 | wp-vast-fleet sub 294786291 [sample] | RTX 4060 | 8bd154bc | 886,262,152,689 | 52,651,711,132 | 886,262,189,950 | 52,651,676,150 | overrun-model | within bound | x=37,261, d=-65.4, tol=355.1 (|d|/tol 0.18) |
| 207072900 | demoux sub 294784134 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 735,867,486,560 | 43,721,620,586 | 735,867,486,560 | 43,721,620,586 | exact | equal | Δ 0 / 0 |
| 207072905 | wp-vast-fleet sub 294787189 [sample] | RTX 4060 | 8bd154bc | 846,511,828,862 | 50,292,923,799 | 846,512,236,431 | 50,292,540,760 | overrun-model | within bound | x=407,569, d=-315.7, tol=2123.1 (|d|/tol 0.15) |
| 207072910 | demoux sub 294785494 | AMD Radeon RX 9070 XT | a7a59c11 | 768,007,707,695 | 45,630,025,063 | 768,007,707,695 | 45,630,025,063 | exact | equal | Δ 0 / 0 |
| 207072912 | wp-vast-fleet sub 294788020 | RTX 4060 | 8bd154bc | 772,472,390,823 | 45,896,759,993 | 772,472,520,600 | 45,896,638,065 | overrun-model | within bound | x=129,777, d=-138.3, tol=863.0 (|d|/tol 0.16) |
| 207072917 | demoux sub 294786409 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 889,468,059,218 | 52,842,030,629 | 889,468,059,218 | 52,842,030,629 | exact | equal | Δ 0 / 0 |
| 207072919 | demoux sub 294786706 | AMD Radeon RX 9070 XT | a7a59c11 | 779,012,482,940 | 46,285,294,442 | 779,012,482,940 | 46,285,294,442 | exact | equal | Δ 0 / 0 |
| 207072920 | wp-vast-fleet sub 294788875 | RTX 4060 | 8bd154bc | 795,237,539,164 | 47,244,294,296 | 795,237,608,582 | 47,244,229,115 | overrun-model | within bound | x=69,418, d=-112.9, tol=546.2 (|d|/tol 0.21) |
| 207072927 | box main repeat T2_54d0aac4_f3 | RTX 3080 (box) | 54d0aac4 | 929,869,783,337 | 55,258,161,356 | 929,869,783,337 | 55,258,161,356 | exact | equal | Δ 0 / 0 |
| 207072927 | box v3.4.7 T1_8bd154bc_f3 | RTX 3080 (box) | 8bd154bc | 929,869,767,081 | 55,258,176,718 | 929,869,783,337 | 55,258,161,356 | overrun-model | within bound | x=16,256, d=72.0, tol=207.2 (|d|/tol 0.35) |
| 207072927 | box v3.4.7 T2_8bd154bc_f3 | RTX 3080 (box) | 8bd154bc | 929,869,766,635 | 55,258,177,081 | 929,869,783,337 | 55,258,161,356 | overrun-model | within bound | x=16,702, d=15.5, tol=210.8 (|d|/tol 0.07) |
| 207072927 | wp-vast-fleet sub 294789898 [sample] | RTX 4060 | 8bd154bc | 929,869,764,648 | 55,258,178,894 | 929,869,783,337 | 55,258,161,356 | overrun-model | within bound | x=18,689, d=-40.4, tol=226.3 (|d|/tol 0.18) |
| 207072937 | wp-vast-fleet sub 294790804 | RTX 4060 | 8bd154bc | 750,554,372,586 | 44,591,720,538 | 750,554,372,586 | 44,591,720,538 | overrun-model | within bound | x=0, d=0.0, tol=2.0 (|d|/tol 0.00) |
| 207072939 | demoux sub 294788394 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 695,820,295,358 | 41,328,129,414 | 695,820,295,358 | 41,328,129,414 | exact | equal | Δ 0 / 0 |
| 207072941 | demoux sub 294788663 | AMD Radeon RX 9070 XT | a7a59c11 | 733,329,325,917 | 43,554,094,298 | 733,329,325,917 | 43,554,094,298 | exact | equal | Δ 0 / 0 |
| 207072946 | demoux sub 294796447 | AMD Radeon RX 9070 XT | a7a59c11 | 306,969,778,265 | 18,236,097,604 | 306,969,778,265 | 18,236,097,604 | exact | equal | Δ 0 / 0 |
| 207072946 | wp-vast-fleet sub 294791158 | RTX 4060 | 8bd154bc | 306,969,778,058 | 18,236,097,795 | 306,969,778,265 | 18,236,097,604 | overrun-model | within bound | x=207, d=-3.7, tol=19.7 (|d|/tol 0.19) |
| 207072950 | demoux sub 294789380 | AMD Radeon RX 9070 XT | a7a59c11 | 733,839,427,773 | 43,600,646,063 | 733,839,427,773 | 43,600,646,063 | exact | equal | Δ 0 / 0 |
| 207072957 | demoux sub 294796591 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 768,132,946,461 | 45,621,348,547 | 768,132,946,461 | 45,621,348,547 | exact | equal | Δ 0 / 0 |
| 207072958 | demoux sub 294790321 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 689,095,951,109 | 40,930,166,623 | 689,095,951,109 | 40,930,166,623 | exact | equal | Δ 0 / 0 |
| 207072961 | demoux sub 294790749 | AMD Radeon RX 9070 XT | a7a59c11 | 716,870,959,730 | 42,577,035,858 | 716,870,959,730 | 42,577,035,858 | exact | equal | Δ 0 / 0 |
| 207072966 | demoux sub 294791320 | AMD Radeon RX 9070 XT | a7a59c11 | 765,873,367,205 | 45,489,761,484 | 765,873,367,205 | 45,489,761,484 | exact | equal | Δ 0 / 0 |
| 207072966 | wp-vast-fleet sub 294799214 | RTX 4060 | 8bd154bc | 765,873,357,616 | 45,489,770,519 | 765,873,367,205 | 45,489,761,484 | overrun-model | within bound | x=9,589, d=15.5, tol=149.9 (|d|/tol 0.10) |
| 207072967 | demoux sub 294791464 | AMD Radeon RX 9070 XT | a7a59c11 | 781,946,309,141 | 46,442,648,103 | 781,946,309,141 | 46,442,648,103 | exact | equal | Δ 0 / 0 |
| 207072967 | demoux sub 294797194 | AMD Radeon RX 9070 XT | a7a59c11 | 781,946,309,141 | 46,442,648,103 | 781,946,309,141 | 46,442,648,103 | exact | equal | Δ 0 / 0 |
| 207072971 | demoux sub 294791885 | AMD Radeon RX 9070 XT | a7a59c11 | 760,820,587,613 | 45,187,583,261 | 760,820,587,613 | 45,187,583,261 | exact | equal | Δ 0 / 0 |
| 207072971 | demoux sub 294797759 | AMD Radeon RX 9070 XT | a7a59c11 | 760,820,587,613 | 45,187,583,261 | 760,820,587,613 | 45,187,583,261 | exact | equal | Δ 0 / 0 |
| 207072972 | demoux sub 294792014 | AMD Radeon RX 9070 XT | a7a59c11 | 689,436,780,683 | 40,951,528,770 | 689,436,780,683 | 40,951,528,770 | exact | equal | Δ 0 / 0 |
| 207072972 | demoux sub 294797888 | AMD Radeon RX 9070 XT | a7a59c11 | 689,436,780,683 | 40,951,528,770 | 689,436,780,683 | 40,951,528,770 | exact | equal | Δ 0 / 0 |
| 207072973 | wp-vast-fleet sub 294800089 [sample] | RTX 4060 | 8bd154bc | 767,209,727,104 | 45,567,290,628 | 767,209,727,342 | 45,567,290,403 | overrun-model | within bound | x=238, d=1.1, tol=21.0 (|d|/tol 0.05) |
| 207072977 | demoux sub 294792264 | AMD Radeon RX 9070 XT | a7a59c11 | 681,256,943,797 | 40,462,306,571 | 681,256,943,797 | 40,462,306,571 | exact | equal | Δ 0 / 0 |
| 207072977 | demoux sub 294798416 | AMD Radeon RX 9070 XT | a7a59c11 | 681,256,943,797 | 40,462,306,571 | 681,256,943,797 | 40,462,306,571 | exact | equal | Δ 0 / 0 |
| 207072979 | demoux sub 294792520 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 631,831,402,056 | 37,530,414,447 | 631,831,402,056 | 37,530,414,447 | exact | equal | Δ 0 / 0 |
| 207072979 | demoux sub 294798672 | AMD Radeon RX 9070 XT | a7a59c11 | 631,831,402,056 | 37,530,414,447 | 631,831,402,056 | 37,530,414,447 | exact | equal | Δ 0 / 0 |
| 207072980 | demoux sub 294792655 | AMD Radeon RX 9070 XT | a7a59c11 | 728,205,989,226 | 43,251,604,782 | 728,205,989,226 | 43,251,604,782 | exact | equal | Δ 0 / 0 |
| 207072980 | wp-vast-fleet sub 294800926 | RTX 4060 | 8bd154bc | 728,205,989,133 | 43,251,604,870 | 728,205,989,226 | 43,251,604,782 | overrun-model | within bound | x=93, d=0.5, tol=13.7 (|d|/tol 0.04) |
| 207072981 | demoux sub 294798807 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 715,909,010,384 | 42,522,359,770 | 715,909,010,384 | 42,522,359,770 | exact | equal | Δ 0 / 0 |
| 207072981 | wp-vast-fleet sub 294793121 | RTX 4060 | 8bd154bc | 715,909,008,823 | 42,522,361,258 | 715,909,010,384 | 42,522,359,770 | overrun-model | within bound | x=1,561, d=19.7, tol=53.9 (|d|/tol 0.37) |
| 207072982 | demoux sub 294798952 | AMD Radeon RX 9070 XT | a7a59c11 | 772,332,528,097 | 45,872,994,470 | 772,332,528,097 | 45,872,994,470 | exact | equal | Δ 0 / 0 |
| 207072982 | wp-vast-fleet sub 294793980 [sample] | RTX 4060 | 8bd154bc | 772,332,522,347 | 45,872,999,864 | 772,332,528,097 | 45,872,994,470 | overrun-model | within bound | x=5,750, d=-14.5, tol=110.9 (|d|/tol 0.13) |
| 207072983 | demoux sub 294799103 | AMD Radeon RX 9070 XT | a7a59c11 | 808,242,353,593 | 48,001,589,963 | 808,242,353,593 | 48,001,589,963 | exact | equal | Δ 0 / 0 |
| 207072983 | wp-vast-fleet sub 294794915 | RTX 4060 | 8bd154bc | 808,242,353,404 | 48,001,590,138 | 808,242,353,593 | 48,001,589,963 | overrun-model | within bound | x=189, d=-2.8, tol=18.9 (|d|/tol 0.15) |
| 207072987 | demoux sub 294793176 | AMD Radeon RX 9070 XT | a7a59c11 | 727,869,177,079 | 43,228,878,168 | 727,869,177,079 | 43,228,878,168 | exact | equal | Δ 0 / 0 |
| 207072987 | wp-vast-fleet sub 294801769 | RTX 4060 | 8bd154bc | 727,869,176,875 | 43,228,878,362 | 727,869,177,079 | 43,228,878,168 | overrun-model | within bound | x=204, d=2.1, tol=19.6 (|d|/tol 0.11) |
| 207072989 | demoux sub 294793438 | AMD Radeon RX 9070 XT | a7a59c11 | 620,860,556,885 | 36,878,848,734 | 620,860,556,885 | 36,878,848,734 | exact | equal | Δ 0 / 0 |
| 207072989 | demoux sub 294799750 | AMD Radeon RX 9070 XT | a7a59c11 | 620,860,556,885 | 36,878,848,734 | 620,860,556,885 | 36,878,848,734 | exact | equal | Δ 0 / 0 |
| 207072990 | demoux sub 294799899 | AMD Radeon RX 9070 XT | a7a59c11 | 798,026,289,905 | 47,394,689,115 | 798,026,289,905 | 47,394,689,115 | exact | equal | Δ 0 / 0 |
| 207072990 | wp-vast-fleet sub 294795854 | RTX 4060 | 8bd154bc | 798,026,289,838 | 47,394,689,177 | 798,026,289,905 | 47,394,689,115 | overrun-model | within bound | x=67, d=-1.0, tol=11.9 (|d|/tol 0.08) |
| 207072995 | demoux sub 294793872 | AMD Radeon RX 9070 XT | a7a59c11 | 320,258,973,238 | 19,033,259,013 | 320,258,973,238 | 19,033,259,013 | exact | equal | Δ 0 / 0 |
| 207072995 | wp-vast-fleet sub 294802152 | RTX 4060 | 8bd154bc | 320,258,973,238 | 19,033,259,013 | 320,258,973,238 | 19,033,259,013 | overrun-model | within bound | x=0, d=0.0, tol=2.0 (|d|/tol 0.00) |
| 207072999 | box main repeat T2_54d0aac4_f4 | RTX 3080 (box) | 54d0aac4 | 710,206,564,304 | 42,183,717,957 | 710,206,564,304 | 42,183,717,957 | exact | equal | Δ 0 / 0 |
| 207072999 | demoux sub 294800825 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 710,206,564,304 | 42,183,717,957 | 710,206,564,304 | 42,183,717,957 | exact | equal | Δ 0 / 0 |
| 207072999 | box v3.4.7 T1_8bd154bc_f4 | RTX 3080 (box) | 8bd154bc | 710,206,564,190 | 42,183,718,062 | 710,206,564,304 | 42,183,717,957 | overrun-model | within bound | x=114, d=-2.2, tol=15.0 (|d|/tol 0.15) |
| 207072999 | box v3.4.7 T2_8bd154bc_f4 | RTX 3080 (box) | 8bd154bc | 710,206,564,123 | 42,183,718,129 | 710,206,564,304 | 42,183,717,957 | overrun-model | within bound | x=181, d=1.8, tol=18.5 (|d|/tol 0.10) |
| 207072999 | wp-vast-fleet sub 294796674 [sample] | RTX 4060 | 8bd154bc | 710,206,564,146 | 42,183,718,108 | 710,206,564,304 | 42,183,717,957 | overrun-model | within bound | x=158, d=2.4, tol=17.4 (|d|/tol 0.14) |
| 207073000 | demoux sub 294794446 | AMD Radeon RX 9070 XT | a7a59c11 | 821,262,164,149 | 48,777,438,665 | 821,262,164,149 | 48,777,438,665 | exact | equal | Δ 0 / 0 |
| 207073000 | demoux sub 294800977 | AMD Radeon RX 9070 XT | a7a59c11 | 821,262,164,149 | 48,777,438,665 | 821,262,164,149 | 48,777,438,665 | exact | equal | Δ 0 / 0 |
| 207073001 | demoux sub 294794586 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 728,238,971,731 | 43,255,571,616 | 728,238,971,731 | 43,255,571,616 | exact | equal | Δ 0 / 0 |
| 207073001 | demoux sub 294801118 | AMD Radeon RX 9070 XT | a7a59c11 | 728,238,971,731 | 43,255,571,616 | 728,238,971,731 | 43,255,571,616 | exact | equal | Δ 0 / 0 |
| 207073003 | demoux sub 294794879 | AMD Radeon RX 9070 XT | a7a59c11 | 887,595,100,979 | 52,715,631,716 | 887,595,100,979 | 52,715,631,716 | exact | equal | Δ 0 / 0 |
| 207073003 | wp-vast-fleet sub 294803128 [sample] | RTX 4060 | 8bd154bc | 887,595,091,856 | 52,715,640,307 | 887,595,100,979 | 52,715,631,716 | overrun-model | within bound | x=9,123, d=9.8, tol=145.5 (|d|/tol 0.07) |
| 207073005 | demoux sub 294795147 | AMD Radeon RX 9070 XT | a7a59c11 | 631,206,707,651 | 37,494,818,007 | 631,206,707,651 | 37,494,818,007 | exact | equal | Δ 0 / 0 |
| 207073005 | demoux sub 294801514 | AMD Radeon RX 9070 XT | a7a59c11 | 631,206,707,651 | 37,494,818,007 | 631,206,707,651 | 37,494,818,007 | exact | equal | Δ 0 / 0 |
| 207073007 | demoux sub 294801809 | AMD Radeon RX 9070 XT | a7a59c11 | 738,496,093,587 | 43,863,182,118 | 738,496,093,587 | 43,863,182,118 | exact | equal | Δ 0 / 0 |
| 207073007 | wp-vast-fleet sub 294797547 | RTX 4060 | 8bd154bc | 738,496,093,584 | 43,863,182,121 | 738,496,093,587 | 43,863,182,118 | overrun-model | within bound | x=3, d=0.2, tol=4.1 (|d|/tol 0.05) |
| 207073010 | demoux sub 294795695 | AMD Radeon RX 9070 XT | a7a59c11 | 732,377,289,194 | 43,500,749,366 | 732,377,289,194 | 43,500,749,366 | exact | equal | Δ 0 / 0 |
| 207073010 | wp-vast-fleet sub 294803987 | RTX 4060 | 8bd154bc | 732,377,287,417 | 43,500,751,056 | 732,377,289,194 | 43,500,749,366 | overrun-model | within bound | x=1,777, d=18.5, tol=57.8 (|d|/tol 0.32) |
| 207073012 | demoux sub 294795979 | AMD Radeon RX 9070 XT | a7a59c11 | 647,801,095,313 | 38,481,137,779 | 647,801,095,313 | 38,481,137,779 | exact | equal | Δ 0 / 0 |
| 207073012 | demoux sub 294802348 | AMD Radeon RX 9070 XT | a7a59c11 | 647,801,095,313 | 38,481,137,779 | 647,801,095,313 | 38,481,137,779 | exact | equal | Δ 0 / 0 |
| 207073014 | wp-vast-fleet sub 294798372 | RTX 4060 | 8bd154bc | 688,326,325,156 | 40,884,954,397 | 688,326,325,156 | 40,884,954,397 | overrun-model | within bound | x=0, d=0.0, tol=2.0 (|d|/tol 0.00) |
| 207073014 | wp-vast-fleet sub 294804825 | RTX 4060 | 8bd154bc | 688,326,325,146 | 40,884,954,405 | 688,326,325,156 | 40,884,954,397 | overrun-model | within bound | x=10, d=-1.4, tol=5.8 (|d|/tol 0.24) |
| 207073018 | demoux sub 294803024 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 691,606,906,925 | 41,082,017,723 | 691,606,906,925 | 41,082,017,723 | exact | equal | Δ 0 / 0 |
| 207073022 | wp-vast-fleet sub 294805572 | RTX 4060 | 8bd154bc | 648,502,659,219 | 38,535,285,068 | 648,502,659,515 | 38,535,284,801 | overrun-model | within bound | x=296, d=-11.4, tol=23.3 (|d|/tol 0.49) |
| 207073023 | demoux sub 294803586 | AMD Radeon RX 9070 XT | a7a59c11 | 815,548,736,600 | 48,454,122,061 | 815,548,736,600 | 48,454,122,061 | exact | equal | Δ 0 / 0 |
| 207073046 | demoux sub 294804689 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 27,976,946,703 | 1,663,724,471 | 27,976,946,703 | 1,663,724,471 | exact | equal | Δ 0 / 0 |
| 207073047 | demoux sub 294804852 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 883,492,223,996 | 52,508,387,916 | 883,492,223,996 | 52,508,387,916 | exact | equal | Δ 0 / 0 |
| 207073050 | wp-vast-fleet sub 294806462 [sample] | RTX 4060 | 8bd154bc | 772,062,282,774 | 45,863,800,283 | 772,062,283,822 | 45,863,799,305 | overrun-model | within bound | x=1,048, d=-7.7, tol=43.8 (|d|/tol 0.18) |
| 207073051 | demoux sub 294805229 | AMD Radeon RX 9070 XT | a7a59c11 | 753,121,597,429 | 44,736,710,918 | 753,121,597,429 | 44,736,710,918 | exact | equal | Δ 0 / 0 |
| 207073057 | wp-vast-fleet sub 294807354 | RTX 4060 | 8bd154bc | 814,444,263,489 | 48,375,434,650 | 814,444,275,431 | 48,375,423,445 | overrun-model | within bound | x=11,942, d=-27.7, tol=171.2 (|d|/tol 0.16) |
| 207073058 | wp-vast-fleet sub 294808071 | RTX 4060 | 8bd154bc | 644,220,348,917 | 38,268,931,643 | 644,220,352,672 | 38,268,928,105 | overrun-model | within bound | x=3,755, d=6.1, tol=87.0 (|d|/tol 0.07) |
| 207073066 | box main repeat T2_54d0aac4_f5 | RTX 3080 (box) | 54d0aac4 | 810,528,931,394 | 48,141,700,719 | 810,528,931,394 | 48,141,700,719 | exact | equal | Δ 0 / 0 |
| 207073066 | box v3.4.7 T1_8bd154bc_f5 | RTX 3080 (box) | 8bd154bc | 810,528,913,713 | 48,141,717,325 | 810,528,931,394 | 48,141,700,719 | overrun-model | within bound | x=17,681, d=-24.8, tol=218.4 (|d|/tol 0.11) |
| 207073066 | box v3.4.7 T2_8bd154bc_f5 | RTX 3080 (box) | 8bd154bc | 810,528,915,071 | 48,141,716,099 | 810,528,931,394 | 48,141,700,719 | overrun-model | within bound | x=16,323, d=26.5, tol=207.7 (|d|/tol 0.13) |
| 207073066 | wp-vast-fleet sub 294808959 [sample] | RTX 4060 | 8bd154bc | 810,528,910,099 | 48,141,720,680 | 810,528,931,394 | 48,141,700,719 | overrun-model | within bound | x=21,295, d=-69.2, tol=245.8 (|d|/tol 0.28) |
| 207073067 | demoux sub 294807052 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 875,015,558,486 | 51,971,676,743 | 875,015,558,486 | 51,971,676,743 | exact | equal | Δ 0 / 0 |
| 207073075 | demoux sub 294808023 | AMD Radeon RX 9070 XT | a7a59c11 | 781,804,979,119 | 46,435,960,878 | 781,804,979,119 | 46,435,960,878 | exact | equal | Δ 0 / 0 |
| 207073080 | demoux sub 294808599 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 876,142,229,209 | 52,037,365,713 | 876,142,229,209 | 52,037,365,713 | exact | equal | Δ 0 / 0 |
| 207073081 | demoux sub 294808733 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 706,966,841,387 | 41,994,717,890 | 706,966,841,387 | 41,994,717,890 | exact | equal | Δ 0 / 0 |
| 207073082 | demoux sub 294808884 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 792,707,412,760 | 47,085,565,151 | 792,707,412,760 | 47,085,565,151 | exact | equal | Δ 0 / 0 |
| 207073083 | demoux sub 294809043 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 851,183,359,625 | 50,557,601,436 | 851,183,359,625 | 50,557,601,436 | exact | equal | Δ 0 / 0 |
| 207073084 | demoux sub 294809171 [sample] | AMD Radeon RX 9070 XT | a7a59c11 | 666,291,887,609 | 39,578,295,889 | 666,291,887,609 | 39,578,295,889 | exact | equal | Δ 0 / 0 |

## 3. v3.4.7 against main on the RTX 3080 (150 W cap)

Six fields from the fleet sample (`raw/queue_timing.json`), one client process per (build, field), the two builds
alternated per field (round 1: v3.4.7 first on fields 0, 2, 4 and main first on 1, 3, 5; round 2 the reverse; round 2 ran after the 41-field sample): `raw/chain.sh`. Wall =
stub claim → stub receipt of the submission. Power / clock = mean of 5 s `nvidia-smi` samples with utilisation > 50 %
during the run (`raw/box/gpu.csv`). The card sat at its 150 W cap and ≈ 1.1–1.2 GHz in every run of both builds, 58 °C.
Table `raw/timing.txt` (script `raw/timing.py`):

| field | round | build | join run_secs | setup_secs | whole-field wall s | survivors | checked | slots | mean W | mean SM MHz | max °C |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 207072495 | 1 | 54d0aac4 | 3.2 | 0.1 | 3.2 | 193 | 32 | 16 | 0 | 0 | 0 |
| 207072495 | 1 | 8bd154bc | 4.0 | 0.1 | 4.1 | 193 | 32 | 16 | 0 | 0 | 0 |
| 207072495 | 2 | 54d0aac4 | 2.7 | 0.1 | 2.8 | 193 | 32 | 16 | 0 | 0 | 0 |
| 207072495 | 2 | 8bd154bc | 3.5 | 0.1 | 3.6 | 193 | 32 | 16 | 0 | 0 | 0 |
| 207072517 | 1 | 54d0aac4 | 82.1 | 15.9 | 83.9 | 863,401,151,773 | 51,300,460,796 | 12 | 150 | 1160 | 51 |
| 207072517 | 1 | 8bd154bc | 258.4 | 15.7 | 260.0 | 863,400,805,575 | 51,300,786,249 | 6 | 149 | 1129 | 57 |
| 207072517 | 2 | 54d0aac4 | 86.5 | 15.9 | 88.4 | 863,401,151,773 | 51,300,460,796 | 12 | 149 | 1109 | 58 |
| 207072517 | 2 | 8bd154bc | 268.2 | 15.5 | 269.8 | 863,400,798,813 | 51,300,792,631 | 6 | 150 | 1132 | 58 |
| 207072868 | 1 | 54d0aac4 | 79.7 | 15.7 | 81.5 | 780,224,058,985 | 46,355,547,549 | 12 | 150 | 1137 | 58 |
| 207072868 | 1 | 8bd154bc | 251.3 | 15.1 | 253.0 | 780,224,050,434 | 46,355,555,595 | 6 | 150 | 1123 | 58 |
| 207072868 | 2 | 54d0aac4 | 80.3 | 15.7 | 82.2 | 780,224,058,985 | 46,355,547,549 | 12 | 149 | 1192 | 58 |
| 207072868 | 2 | 8bd154bc | 248.2 | 15.2 | 249.9 | 780,224,049,852 | 46,355,556,151 | 6 | 149 | 1129 | 58 |
| 207072927 | 1 | 54d0aac4 | 99.7 | 18.6 | 101.7 | 929,869,783,337 | 55,258,161,356 | 11 | 150 | 1083 | 58 |
| 207072927 | 1 | 8bd154bc | 298.5 | 17.9 | 300.3 | 929,869,767,081 | 55,258,176,718 | 5 | 150 | 1145 | 58 |
| 207072927 | 2 | 54d0aac4 | 93.1 | 18.7 | 95.1 | 929,869,783,337 | 55,258,161,356 | 11 | 149 | 1155 | 58 |
| 207072927 | 2 | 8bd154bc | 299.2 | 18.0 | 301.1 | 929,869,766,635 | 55,258,177,081 | 5 | 150 | 1128 | 58 |
| 207072999 | 1 | 54d0aac4 | 75.5 | 15.5 | 76.7 | 710,206,564,304 | 42,183,717,957 | 16 | 150 | 1140 | 58 |
| 207072999 | 1 | 8bd154bc | 239.2 | 15.0 | 240.2 | 710,206,564,190 | 42,183,718,062 | 9 | 149 | 1139 | 58 |
| 207072999 | 2 | 54d0aac4 | 75.7 | 15.5 | 76.9 | 710,206,564,304 | 42,183,717,957 | 16 | 150 | 1161 | 58 |
| 207072999 | 2 | 8bd154bc | 237.9 | 15.0 | 239.0 | 710,206,564,123 | 42,183,718,129 | 9 | 150 | 1156 | 58 |
| 207073066 | 1 | 54d0aac4 | 82.5 | 16.3 | 84.4 | 810,528,931,394 | 48,141,700,719 | 11 | 150 | 1173 | 58 |
| 207073066 | 1 | 8bd154bc | 259.7 | 15.4 | 261.4 | 810,528,913,713 | 48,141,717,325 | 5 | 150 | 1133 | 58 |
| 207073066 | 2 | 54d0aac4 | 82.7 | 16.3 | 84.7 | 810,528,931,394 | 48,141,700,719 | 11 | 150 | 1135 | 58 |
| 207073066 | 2 | 8bd154bc | 260.4 | 15.7 | 262.1 | 810,528,915,071 | 48,141,716,099 | 5 | 150 | 1140 | 58 |

f0 round 1: v3.4.7/main run 1.265, wall 1.265
f0 round 2: v3.4.7/main run 1.292, wall 1.284
f1 round 1: v3.4.7/main run 3.147, wall 3.098
f1 round 2: v3.4.7/main run 3.100, wall 3.053
f2 round 1: v3.4.7/main run 3.153, wall 3.102
f2 round 2: v3.4.7/main run 3.091, wall 3.042
f3 round 1: v3.4.7/main run 2.993, wall 2.952
f3 round 2: v3.4.7/main run 3.213, wall 3.165
f4 round 1: v3.4.7/main run 3.167, wall 3.131
f4 round 2: v3.4.7/main run 3.142, wall 3.106
f5 round 1: v3.4.7/main run 3.148, wall 3.097
f5 round 2: v3.4.7/main run 3.147, wall 3.096
geomean over the 10 real-size runs pairs (f1-f5, 2 rounds): run 3.129 (range 2.993-3.213), wall 3.084 (range 2.952-3.165)

207072495 is a 193-survivor field (the first past the boundary): its ×1.27 is fixed overhead, excluded from the
geomean. For comparison, main's whole 41-field sample queue (two fields in flight) took 52.7 min = 77 s per field on
this card [measured, `raw/box/runs.log`]; the extension 65 fields in 80.9 min = 75 s.

**Fleet implication [derived, assumption: the ratio carries over from a power-capped 3080 to an RTX 4060, both
CubeCL CUDA]:** the 4060s' median 337 s per real field on v3.4.7 would become ≈ 108 s on main; fields per box-hour
and hence per dollar-hour ×3.1 (≈ 10.7 → ≈ 33 real fields/h per box at today's one-box rate). At base 62 the fleet is
≈ 11 of ≈ 62–78 real fields/h, so the deploy would move the whole search's rate by ≈ +35 % (≈ 84 vs 62 new fields/h).

## 4. Telemetry facts (census to 09:01 UTC; `raw/telemetry.txt`, `raw/rate.txt`)

- Base 62 began at **00:57:50 UTC** (first submission, field 207064110) [measured], not 00:00.
- **demoux** (RX 9070 XT, a7a59c1): 532 real submissions, 7,501 instant. Join run_secs min 2.5 / p10 46.9 / median
  56.2 / p90 62.9 / max 73.3; setup median 6.3 s; slices 14 always; slots 5–16 (mode 5), min_slots 5 in 522 of 532;
  no retried partitions; elapsed (claim to submit, two fields in flight) median 168 s; ≈ 67 real submissions/h,
  flat from 01 to 08 UTC.
- **fleet** (wp-vast-fleet, v3.4.7, RTX 4060 only so far): 87 real, 1,228 instant. Join run_secs min 3.9 / p10 282 /
  median 337 / p90 373 / max 401; setup median 15.0 s; slices 14; slots 5–16 (mode 5); no retries; elapsed median
  1,002 s; ≈ 11 real submissions/h (≈ one 4060's worth: 3600/337 = 10.7).
- **Duplicates:** 51 fields had two real submissions by 06:00 (35 demoux–demoux, 15 demoux–fleet, 1 fleet–fleet);
  by hour, 0–48 of each hour's real submissions are a second search of a field (`raw/rate.txt`), ≈ 19 % overall:
  the pre-claim queue re-issuing fields (known from 10-09). All such pairs agree (they are in the comparison above).
- **Frontier** (max submitted field id per UTC hour, `raw/rate.txt`): 01 207072579, 02 207072880, 03 207072963,
  04 207073016, 05 207073085, 06 207073160, 07 207073198, 08 207073292. Queue-fill frontier (max field with a
  `last_claim_time`) 207073448 at 09:01; 156 fields at or below it are claimed but not submitted.
- **Instant fraction past the boundary so far:** 280 of 798 submitted fields (35 %); at 06:00 it was 44 % (259 of
  588). My field-level predictor over the whole base (`raw/predict_instant.py`, `raw/predict_instant.json`) gives
  ≈ 74 % instant in ids 207069110–207074109, 29 % in the next 5,000 (includes the (2,2) block), then 7–14 % per 5,000
  ids to the end of the base.
- **Estimate:** remaining past the processed frontier 86,245 fields, of which 76,762 need a real run (predictor;
  it agreed with the client on 795 of 798 fields past the boundary, the 3 it missed are instant ones, so this
  slightly overcounts). At 61.7 new real fields/h (03–08 UTC mean): 1,245 h → **≈ 2027-01-06** [derived]. Without
  the duplicate searches (gross 78/h): ≈ 2026-12-26. With the fleet on main (×3.1) and duplicates as now: ≈ 84/h →
  ≈ 2026-12-23. Assumptions [assumed]: the run cost per real field stays at today's (only ids 207072495–207073292,
  0.9 % of the base, have been seen; survivors per field may drift with x), demoux and one-box-equivalent fleet keep
  running as now, instant fields cost nothing.
- **Base 60 is complete:** every one of its 162,076 fields (ids 206902034–207064109) has check_level ≥ 1 (counted
  with `check_level=lt.1` in two bounded id ranges: 0 rows; `raw/b60_complete.txt`) [measured]; its last 10,000 fields
  are all check_level 1 (`raw/fields_b60_tail.json`).

## Files (`raw/`)

Census (ivory, read-only, bounded id ranges, 0.2 s apart, User-Agent nice-audit-census): `census.py`,
`fields_b62.json` (06:00), `fields_b62_0900.json`, `fields_b60_tail.json`, `b60_complete.txt`, `subs_0615.json`,
`subs_0900.json`, `subs_merged.json`. Task 1: `instant_check.py`, `instant_ids.txt`, `instant_check.jsonl`,
`real_ids.txt`, `real_check.jsonl`, `instant_summary.py/.txt`, `soundness_test.py`, `soundness_test2.py`,
`soundness.txt`, `predict_instant.py/.json`. Box side: `box.sh`, `hosts_block.sh`, `proof_hosts_block.txt`,
`box_build.sh`, `builds.sh`, `stub_api.py`, `run_queue.sh`, `chain.sh`, `chain2.sh`, `make_sample.py`, `sample.json`,
`queue_main_sample.json`, `queue_timing.json`, `make_ext.py`, `queue_ext.json`, `pull.sh`, `waitbox.sh`; outputs
`box/` (`out_*.jsonl` = every real-field submission body the clients sent the stub, padding dropped; `client_*.log`;
`runs.log`; `gpu.csv`). Analysis: `extract.py`, `compare.py` → `compare.txt`, `compare_detail.jsonl`,
`compare_table.py` → `compare_table.md`; `timing.py` → `timing.txt`; `telemetry.py` → `telemetry.txt`; `rate.py` →
`rate.txt`. Cost: box rented by the director (≈ 4.4 h of a 3080). Nothing was claimed from or submitted to
production; nothing changed on the fleet, server, demoux or mayalaran.
