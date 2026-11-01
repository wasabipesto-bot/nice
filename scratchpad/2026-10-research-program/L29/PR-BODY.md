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
  - `cubecl_cuda_join_matches_the_cpu_reference`: every window from b20 to b64, including b50 and b54; the b57 frontier field; tight, sliced and refused layouts; and the production shape.
  - The dense-field test: b58 1e15 (64 partitions, 0 overran) and b64 1e16 (8 partitions, 2.7e-5 overran, as on main).
  - The whole b42 field.
  - Join = stride on two 1e14 fields per base at b58–64 (`NICE_TEST_JOIN_COMPARE=1`).
- **Division safety (#228):** the long division is the existing one. The remainder and the carry test only multiply, add, shift and compare.
  - The WGSL lint (`wgsl_dump_for_lint` + `scripts/wgsl-lint.py` with CI's requirements) reports 0 flagged sites.
  - The test kernel's WGSL holds `top_cert` at bases 10–64 and one to three words. It lints clean too: 35 compilations, 0 flagged.

## Measured

(pending)

## Exactness

(pending)

## Not in this PR

(pending)
