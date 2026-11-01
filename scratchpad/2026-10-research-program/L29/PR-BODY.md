# Overlap join: certify tops from one endpoint's digits and a carry test

## What and why

The GPU join's `top_kernel` certifies every top, an interval [a, e] of n. For n² and n³, the digits at positions ≥ c0 = max(cap, ndig(e^j − a^j)) that every n in the interval shares are the common top digits of a^j and e^j, down to their first disagreement. Since #203, every n's digit at that disagreement also lies between the two endpoints' digits. The kernel found these digits by dividing both a^j and e^j into digits and comparing them in lockstep. #204 gave the CPU join (`Base::cert`) a cheaper form of the same certificate, and this PR ports it to the device. Because e^j − a^j < b^c0, ⌊e^j / b^c0⌋ is either ⌊a^j / b^c0⌋ or one more. It is one more exactly when (a^j mod b^c0) + (e^j − a^j) ≥ b^c0. Without that carry, every digit of a^j from c0 up is common. With it, e^j differs from a^j on a^j's run of (b − 1)s from c0 up and on the digit d above that run (d + 1 in e^j). The certificate is then the digits above d, and every n's digit at d's position is d or d + 1. So only a^j has to be divided into digits.

On the device, `cert_power` now runs its long division on a^j only:
- The scan goes from the least significant digit up, so it keeps both candidate answers as it goes: every digit from c0 up, and the digits above the first one that is not b − 1. The carry test picks one at the end.
- The remainder a^j mod b^c0 is assembled in 16-bit limbs from the digits below c0, which the scan divides out on its way up anyway. Each pass adds its chunk's digits below c0 times B^pass. B is the chunk divisor, so the limbs of B^pass are compile-time constants.
- One multi-word add and compare against b^c0 decides the carry.
- e^j is still computed, but only for e^j − a^j.

The schoolbook powers and the certificate's closure move into `powers16` and `top_cert` (the code is otherwise unchanged), so a test kernel can call them.

## Soundness

The certificate is the same mathematical object, computed differently. It is bit-identical to the previous one:

- **New test** `top_certificates_match_the_lockstep_scan_and_the_cpu` (wgpu; `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` on CUDA).
  - A test kernel runs each interval through the new `cert_power` and through the previous lockstep scan, which the test module keeps as `cert_power_lockstep`.
  - For the square and the cube, the two must give the same mask, repeat flag, digit interval at the first disagreement and c0, word for word.
  - `top_cert`'s kept flag and mask must equal the CPU's `Base::cert`, and its c0 terms must equal `cert_floor`.
  - Intervals:
    - partition-extended tops of production-shaped fields at b58 (1e15) and b60/62/64 (1e16), from the same generator as the CPU's `the_fast_certificate_matches_the_reference`;
    - arbitrary intervals and caps at bases 10, 12, 20, 30, 40, 47, 50 and 57, with four kernel shapes per base and n of one to three words.
  - Coverage: 102,365 intervals, of which 33,582 are kept. 203,413 powers have digits above c0, and 69,824 of those take the carry.
  - Passes on CUDA (RTX 3080) and on lavapipe. `NICE_TEST_CERT_SAMPLES` raises the count.
- **Existing join tests, all passing on CUDA:**
  - `cubecl_cuda_join_matches_the_cpu_reference`: base 10's 69; every window from b20 to b64, including b50 and b54; the b57 frontier field; tight, sliced and refused layouts; and the production shape.
  - The dense-field test: b58 1e15 (64 partitions, 0 overran) and b64 1e16 (8 partitions; 2.7e-5 overran, main 2.9e-5).
  - The whole b42 field.
  - Join = stride on two 1e14 fields per base at b58–64 (`NICE_TEST_JOIN_COMPARE=1`).
- **Division safety (#228):** the long division is the existing one. The remainder and the carry test only multiply, add, shift and compare.
  - The WGSL lint (`wgsl_dump_for_lint` + `scripts/wgsl-lint.py` with CI's requirements) reports 0 flagged sites.
  - The test kernel's WGSL holds `top_cert` at bases 10–64 and one to three words. It lints clean too: 35 compilations, 0 flagged.

## Measured

**Card:** RTX 3080 10 GB on a rented box whose host caps it at **180 W** (default 340 W). Under the join it sat at the cap the whole time: 1410–1470 MHz, 179.5 W, at most 66 °C, throttled by the SW power cap.

**Method:**
- main (`9bde4a8`) and this PR, same box, rounds interleaved (main, PR, main, PR, main, PR).
- Harness: `cubecl_cuda_join_throughput_fixed_fields`, after one 1e14 warm-up field per base, at the starts b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the harness's wall time per field, with two fields in flight. Each figure is the median of 3 rounds; spread = (max − min) / median.

| field | main s/field (rounds) | spread | PR s/field (rounds) | spread | PR / main | speed-up |
|---|---|---|---|---|---|---|
| b62 1e17, 1 field | **229.27** (226.81, 229.53, 229.27) | 1.2 % | **213.28** (213.28, 212.89, 213.33) | 0.2 % | ×0.930 | **×1.075** |
| b62 1e16, 2 fields | **19.754** (19.664, 19.936, 19.754) | 1.4 % | **18.140** (18.140, 17.951, 18.290) | 1.9 % | ×0.918 | **×1.089** |
| b60 1e16, 2 fields | **43.710** (43.710, 44.118, 43.649) | 1.1 % | **41.524** (40.943, 41.524, 41.639) | 1.7 % | ×0.950 | **×1.053** |
| b64 1e16, 2 fields | **54.847** (54.847, 54.916, 53.447) | 2.7 % | **52.741** (53.837, 52.689, 52.741) | 2.2 % | ×0.962 | **×1.040** |

Every PR round beat the main round before it. Layouts were identical: 5 partitions per launch at b62 1e17; 13, 4 and 6 at b62, b60 and b64 1e16.

**NiceMark nice-only** (`--benchmark-secs 150`, 3 rounds each, interleaved):
- Score: 3711 → 3976, ×1.071. Rounds: 3669, 3716, 3711 against 3963, 3976, 4055.
- Scenarios (median rates):

| scenario | main | PR | PR / main |
|---|---|---|---|
| b58 msd-weak | 1.597e14 | 1.711e14 | ×1.071 |
| b58 msd-strong | 9.704e14 | 1.018e15 | ×1.049 |
| b60 msd-weak | 3.190e14 | 3.508e14 | ×1.100 |
| b62 msd-weak | 4.022e14 | 4.449e14 | ×1.106 |

Spreads were 1.4–3.4 %. No scenario is slower.

**Where it comes from.** A per-phase profile synchronises the device after each kernel group, so its device times run longer than unprofiled ones. At 1e16, 2 rounds per base, the top kernel's time went:

| base | main top kernel | PR top kernel | speed-up | share of device time |
|---|---|---|---|---|
| b62 | 11.11 s | 8.95 s | ×1.24 | 41.8 % → 36.4 % |
| b60 | 14.80 s | 12.09 s | ×1.22 | 34.3 % → 29.9 % |
| b64 | 8.65 s | 7.98 s | ×1.08 | 16.3 % → 14.9 % |

The other phases stay within their round-to-round variation (up to 5 % for the join at b64). At b64 the chunk divisor is 64² = 2^12, so both endpoints' long divisions compile to shifts and masks, and dropping one saves less there.

**Production-size fields (1e14),** 2 rounds only, two fields per base, with the same starts plus b58 104400216587923470200:

| base | main s/field (rounds) | PR s/field (rounds) | speed-up |
|---|---|---|---|
| b58 | 0.925 (0.921, 0.928) | 0.877 (0.881, 0.872) | ×1.055 |
| b60 | 0.796 (0.788, 0.804) | 0.784 (0.786, 0.783) | ×1.015 |
| b62 | 0.691 (0.696, 0.685) | 0.661 (0.668, 0.653) | ×1.045 |
| b64 | 1.047 (1.044, 1.051) | 1.040 (1.035, 1.046) | ×1.007 |

## Exactness

- **Certified tops** (profile counters) are identical to main's: 4,508,762,994, 6,869,484,234 and 3,866,773,495 at b62, b60 and b64 1e16.
- **1e14 fields**, where the counts are deterministic: two fields per base at the starts above, b58 104400216587923470200, 2 rounds per tree. Join survivors and full checks are identical to main's to the last digit at every base:
  - b58: 7,621,203,662 / 429,530,619
  - b60: 5,634,417,625 / 377,421,465
  - b62: 2,723,010,177 / 166,801,084
  - b64: 11,007,394,280 / 669,464,864
- **1e16 and 1e17:** the survivor counts vary run to run on main as well, through the stage overrun, which depends on timing. The PR's counts vary by the same amount. For example, b62 1e16 survivors were 163,510,219,261–163,510,235,912 on main and 163,510,215,810–163,510,233,888 on the PR.
- **Dense b64 1e16 test:** main 21,899 overran and the PR 20,889. In both, survivors plus overrun equal the CPU join's 763,743,660.
- **Hits:** none anywhere.
- **Host suite:** `nice_common`, 221 passed. fmt and clippy are clean with default features, `nice_client/gpu` and `nice_client/gpu,nice_client/cubecl-spirv`.

## Not in this PR

- e^j is still computed by schoolbook, though it is now only used for e^j − a^j. With δ = e − a < 2^32 that difference is δ(2a + δ) and δ(3a² + 3aδ + δ²), which would replace e's two products. By operation count that is an estimated tenth or less of the certificate's arithmetic.
- The long division still runs over all of the power's limbs in every pass, although the quotient loses log2(B) bits per pass. A compile-time bound on the live limbs, tried on top of this PR, roughly halves the division steps. It is still bit-identical, but it measured no clear gain on this card: ×0.98–1.03 at 1e16 over 2 rounds, within noise. So it is left out.
- No change to the CPU join, which has had this form since #204, nor to what the certificate is or what the join keeps.
- Not measured on AMD or Apple GPUs. On those, the WGSL lint is the check for the Metal division pattern.
