## What

The CPU join (`CpuJoin::tops`) certifies one key's top prefixes at a time. For each prefix P it builds the block [a, e] = [P·w, P·w + w − 1] (w = b^f0), squares and cubes a, and divides a² and a³ into base-b digits from position c0 up (`Base::cert`). It then reads the certificate off those digits and #204's carry test.

This PR steps those digits from one prefix to the next with additions, as #240 does on the GPU across a batch's partitions.

A key's prefixes come from the top layer, which `CpuJoin::new` sorts by key stably, so they come in ascending order. Two prefixes of one key differ by a multiple of h = b^o, where o = k − f0: the partition's p digits and the key digit are P's lowest o. Since a^j = P^j·b^(j·f0), the digits of a² and a³ are those of P² and P³, shifted up. Over P, P + h, P + 2h, … they follow from the detailed mode's finite differences (#221) with step h instead of 1:

    SQ = P²   SQ += DS   DS  = 2Ph + h²           DS  += 2h²
    CU = P³   CU += DC   DC  = 3P²h + 3Ph² + h³   DC  += DDC
                         DDC = 6Ph² + 6h³         DDC += 6h³

**`common/src/cpu_top_fd.rs`** (new):
- **State.** The five arrays as packed base-b digits, eight to a u64 word, added with `detailed_fd`'s biased add (with a runtime bias here). 2h² and 6h³ are single digits at positions 2o and 3o. The binary differences the certificate needs step too: with δ = w − 1 and H = h·w, d2 = e² − a² grows by 2δH, and d3 = e³ − a³ by Δ3 = 3δH(2a + H + δ), which itself grows by 6δH².
- **Step.** Five array additions and three 256-bit ones. Each array addition covers only the words its addend can occupy anywhere in the slice, plus the word its carry goes into; a carry past that needs eight digits of b − 1 and branches out of line. At b60 and b62 that is 14 word additions a step.
- **Walk.** A prefix at most four steps above the last stepped one is reached by stepping. Anything else seeds the state: a key's first prefix, a larger gap, or a step that does not land on P. A whole partition takes 1.38–1.43 steps per prefix on average, and 2.3 % (b60 1e16) to 4.7 % (b62 1e17) of the prefixes seed.
- **Seed.**
  - P, P² and P³ are converted to digits without a hardware division: `Div64` (Möller–Granlund) divisions by b^8 and b^4, then a reciprocal multiply per digit.
  - DS, DC and DDC are built from the digits of P and P² by digit shifts and additions, so only P² and P³ are long conversions.
  - d2, d3 and Δ3 come from exact `W4` products.
- **Certificate** (`TopFdSetup::cert`). It is `Base::cert` with the digits read from the arrays instead of divided out:
  - digit i of a^j is digit i − j·f0 of P^j (zero below);
  - c0 = max(cap, ndig(d_j)), with ndig from a bit-length table and one compare (as #237 does on the GPU);
  - #204's carry test (a^j mod b^c0) + d_j ≥ b^c0 is screened in f64 from the top two digits of P^j mod b^(c0 − j·f0) (see Soundness). Inside the screen's margin, about 1/b² of the tests, the remainder is put together from the packed digits (three multiplies per eight digits) and compared exactly;
  - the run of (b − 1)s, the digit range at the first disagreement and `close_certificate` are `Base::cert`'s.
- **Kept tops.** P mod (b − 1) and ⌊P/h⌋ mod b^mid (`Top.pc`, `Top.dm`) step by one with P, since h ≡ 1 mod (b − 1) and `Top.dm`'s divisor b^(k − f0) is h. A seed computes them as before. That drops the u128 division and remainder (`__udivti3`, `__umodti3`) from every kept top that is not a seed.

**`CpuJoin::tops`.** An unclipped block goes through the stepped state. A clipped one goes through `Base::cert` as before and leaves the state alone; only P = plo and P = phi of a slice can be clipped. So does every block of a field whose arrays would not fit (`TopFdSetup::try_new` returns `None`), or of a base ≤ 6 (no field the join takes). Nothing else in the join changes: the bottoms, the lists, the scan and the survivors are as they were.

**Power-of-two bases take the stepped path too.** #240 kept the old kernel at b64 on the GPU, where the long division compiles to shifts and FD measured slower. On the CPU `Base::cert` divides by a runtime base at every base, b64 included, so that reason does not apply. At b64 the step is 14–15 word additions. B64_MEASURED

## Why

Measured on main with perf and a per-phase TSC split (not in this PR), at production shapes (b60 1e16, b62 1e16 and slices of b62 1e17, 1 and 4 threads alike):
- **The top certificates were 42–43 % of the CPU join's time.** `Base::cert` plus the 256-bit division it calls were 40.4–40.6 %. The AND scan and the survivors were the other ~55 %; bottoms and lists were ~1 %.
- **About 57 % of `Base::cert`'s own samples sat on two hardware `div` instructions:** the per-digit `% b` and `/ b` by a runtime base in `digits_w`, 9–11 digits a power. That is ~17 % of the join on this core. The `shift_down_rem` division (`divrem_w4`) was another quarter of the certificate.
- A certified prefix cost ~650 TSC cycles (≈ 260 ns) whatever the shape. Per b60 1e16 partition the join certifies 5.07 M prefixes and keeps 1.76 M.

The GPU took the same step in #240, where the top kernel went ×1.48–1.61. On the CPU it needs no batching: `tops()` already walks a key's prefixes in order, so there is no new memory, and the threads, the bottoms and the scan are untouched.

## Soundness

- **The stepped arrays hold exactly the divided digits** (#240's argument, with step h):
  - The seed is exact. The products are exact `W4` arithmetic. The digit conversion is exact division: `Div64` returns the exact quotient and remainder, and the reciprocal multiply is `cpu_join`'s `SmallDiv`, exact below 2^48/b, which every four-digit half of a chunk (< b^4 ≤ 2^24) is. Shifting digits multiplies by b^o, and the additions are exact base-b additions.
  - Every step is an exact base-b addition. The biased add is valid for every b ≤ 128.
  - So after m steps the arrays hold P'², P'³ and their differences for P' = P + m·h, digit for digit, and d2, d3 and Δ3 are their binary values (identities in P).
- **No overflow.** The state only ever certifies a P whose block is unclipped and in the slice. In the join every gap is a multiple of h, so the walk lands on P. A gap that is not (only the tests make one) steps once past P and then re-seeds: that step's addends are taken at a prefix below P, and the values it passes through (below phi + h; P³ has at most 29 digits at bases 40–64, against the arrays' 48) still fit.
  - Every array is increasing in P, so `TopFdSetup::try_new` sizes each one from its value at the slice's last prefix, phi. It requires every addend plus its carry word to fit the six-word arrays, and P³'s digits to stay within them.
  - Otherwise the field keeps `Base::cert`. Every production field (b40–b64) and every test window but base 10's (blocks of one number) fits.
- **The certificate is the same function of the same digits.**
  - Digits below j·f0 are zero.
  - ndig(d) ∈ {ndig(2^(L−1)), ndig(2^(L−1)) + 1} for d of bit length L, since 2 < b; the compare with b^c picks the right one.
  - **The carry screen.** With k = c0 − j·f0 ≥ 2 and R = P^j mod b^k, dividing by b^(c0−2) turns the test into R/b^(k−2) + d/b^(c0−2) ≥ b².
    - The first term lies in [r, r + 1) for r the top two digits of R, read exactly.
    - The second is below b² ≤ 4096. It is computed in f64 as d̂ = d·(1/b^(c0−2)) from operands each within a relative 2^-51 and one more rounding, so within 1e-11 of the truth.
    - So the screen answers only when r + d̂ ≥ b² + 2^-20 (true) or r + 1 + d̂ ≤ b² − 2^-20 (false). Every other case, and k < 2, takes the exact remainder.
  - The scan, the domains and `close_certificate` are `Base::cert`'s.
- **Gaps and order.** Exactness does not depend on the prefixes' order. A step only goes forward from the previous stepped prefix of the same `tops()` call (one key and one partition), and only if P is at most 4h above it. If the steps do not land on P exactly, it seeds. A new key starts from a fresh state.
- **Outputs.** Per key, the same tops in the same order: the same P, mask, residue range, `dm`, seed flag and `pc`. So the scan, the survivors, the prefilter and the full check see what they saw before.

## Measurements

**Machine:** a 4-vCPU AMD EPYC-Rome (**Zen 2**) VM with **AVX2 only** (so the scan is `scan_avx2`); every run under `nice -n 19`. Zen 2's 64-bit `div` is slow. Zen 3 and Zen 4 divide much faster, so there `Base::cert` is cheaper, its share of the join is smaller, and the gain from this PR should be smaller. The PR also removes the 256-bit divisions and products, so some gain should remain. With AVX-512 the scan is cheaper, which raises the certificates' share. I have not measured either.

**Method:** release builds of main (`6f060a9`) and this PR. A harness outside this PR, using only `CpuJoin`'s public API, runs sampled partitions of one slice (NiceMark's bit-reversed `sample_order`) through `CpuJoin::run_partition` on 1 or 4 threads; whole fields run every partition. The two binaries are interleaved with the order alternating per round (main, PR; PR, main; main, PR), 3 rounds. Figures are medians; spread = (max − min) / median; "per round" is main's time over the PR's in the same round. Before each round the script waited for the 1-min load average (other processes on the VM) to be ≤ 2 and logged it: every round started at ≤ 2 (1.64, 1.87, 1.97; b64: LOADS_B64).

Fields: b60 starts at NiceMark's `b60_msd_weak` start, 1157209632114824200908. b62 1e17 is the whole field 4473066762334864396992 + 1e17, which the CPU cuts into 7 slices; its slice 0 is used here, 4.75 M top-layer prefixes. b62 1e14 starts at 4473156762334864396992.

Times are ms per partition and thread for the sampled partitions (wall × threads / partitions) and wall seconds for the whole fields. Every run of both sides found the same join survivors and full checks (below).

| work | threads | main (rounds) | spread | this PR (rounds) | spread | speed-up | per round |
|---|---|---|---|---|---|---|---|
| **b60 1e16**, 4 partitions | 1 | **3069** ms (3058, 3069, 3071) | 0.4 % | **2410** ms (2423, 2410, 2339) | 3.5 % | **×1.274** | 1.262, 1.274, 1.313 |
| **b60 1e16**, 16 partitions | 4 | **3270** ms (3196, 3675, 3270) | 14.6 % | **2536** ms (2499, 2555, 2536) | 2.2 % | **×1.289** | 1.279, 1.439, 1.289 |
| **b62 1e17** slice 0, 4 partitions | 1 | **2914** ms (2914, 2918, 2904) | 0.5 % | **2306** ms (2330, 2302, 2306) | 1.2 % | **×1.264** | 1.251, 1.267, 1.259 |
| **b62 1e17** slice 0, 16 partitions | 4 | **3044** ms (3149, 3032, 3044) | 3.9 % | **2443** ms (2476, 2443, 2436) | 1.6 % | **×1.246** | 1.272, 1.241, 1.250 |
| b60 1e14, whole field (3600 partitions) | 1 | **159.5** s (160.8, 158.9, 159.5) | 1.2 % | **130.3** s (129.7, 130.3, 130.9) | 0.9 % | **×1.224** | 1.239, 1.219, 1.219 |
| b60 1e14, whole field | 4 | **41.9** s (42.2, 41.3, 41.9) | 2.2 % | **34.3** s (34.9, 34.3, 34.1) | 2.4 % | **×1.224** | 1.210, 1.205, 1.231 |
| b62 1e14, whole field (3844 partitions) | 1 | **191.3** s (190.9, 192.2, 191.3) | 0.7 % | **165.6** s (165.6, 165.7, 163.7) | 1.2 % | **×1.155** | 1.153, 1.160, 1.168 |
| b62 1e14, whole field | 4 | **50.2** s (51.5, 49.9, 50.2) | 3.1 % | **43.2** s (43.1, 43.2, 43.2) | 0.2 % | **×1.163** | 1.195, 1.156, 1.163 |

- **At production shapes (b60 1e16, b62 1e17) the join is ×1.25–1.29 faster**, at 1 and 4 threads alike. The certificates were 42–43 % of the join there. ×1.27 means they now take ~22 % of main's time instead of ~43 %, about ×1.9 for the certificates in place.
- The 1e14 fields gain less (×1.16–1.22): there the bottoms and lists are rebuilt for every partition and take a larger share (main's split at b62 1e14: certificates 27 %, bottoms and lists 39 %).
- main's second-round b60 1e16 run on 4 threads (3675 ms) is an outlier, probably from other load on the VM. The median does not use it.

NiceMark nice-only on the CPU (`nice_client niceonly --threads 4 --benchmark-secs 150 --benchmark-json`, no `--gpu`), 4 rounds alternating (main, PR; PR, main; …), medians; the scenario rows are numbers/s; "per round" is the PR's over main's:

| | main (rounds) | this PR (rounds) | speed-up | per round |
|---|---|---|---|---|
| **score** | 673.2 (674.1, 672.8, 673.6, 649.5) | 798.7 (792.6, 804.8, 806.6, 780.2) | **×1.186** | 1.176, 1.196, 1.197, 1.201 |
| b58 MSD-weak (1e15 field, 4 threads) | 1.630e12 (1.633e12, 1.627e12, 1.647e12, 1.523e12) | 1.859e12 (1.840e12, 1.887e12, 1.878e12, 1.735e12) | **×1.141** | 1.127, 1.160, 1.141, 1.139 |
| b58 MSD-weak, 1 thread | 4.349e11 (4.361e11, 4.336e11, 4.328e11, 4.385e11) | 4.968e11 (4.901e11, 5.034e11, 5.040e11, 4.880e11) | **×1.142** | 1.124, 1.161, 1.165, 1.113 |
| b58 MSD-strong (1e15 field, 4 threads) | 1.078e13 (1.066e13, 1.094e13, 1.082e13, 1.074e13) | 1.184e13 (1.185e13, 1.183e13, 1.202e13, 1.164e13) | **×1.099** | 1.111, 1.082, 1.111, 1.084 |
| b60 MSD-weak (a 3e15 window of a 1e16 field, 4 threads) | 3.754e12 (3.826e12, 3.742e12, 3.757e12, 3.751e12) | 5.016e12 (4.949e12, 5.035e12, 5.035e12, 4.997e12) | **×1.336** | 1.293, 1.345, 1.340, 1.332 |
| b62 MSD-weak (a 3e15 window of a 1e16 field, 4 threads) | 4.181e12 (4.190e12, 4.175e12, 4.187e12, 3.759e12) | 5.191e12 (5.173e12, 5.218e12, 5.209e12, 5.136e12) | **×1.241** | 1.235, 1.250, 1.244, 1.367 |

- main's fourth round ran low on two scenarios (b58 MSD-weak, b62), probably from other load on the VM. The medians barely move with it: main's score is 673.6 without it.
- NiceMark samples partitions in bit-reversed order, but the stepping happens inside a partition, so its order does not matter here (unlike #240's, which steps across partitions).

## Exactness

All on this branch's head, release builds:

- **New `cpu_top_fd::stepped_certificates_equal_the_divided_ones`.** Bases 10–64, four random fields inside each base's nice band (n, n² and n³ of one length each), every f0 with b^f0 < 2^32 and o = 1–3 (cap = f0 + o): 1876 setups. Each is walked in runs of 200 prefixes from random starts, from the field's first prefix and up to its last, with random gaps (one step 62 %, two to four 25 %, 5–24 steps 9 %, backwards 3 %).
  - 1,860,723 unclipped blocks certified (413,250 kept; 243,907 seeded), every certificate equal to `Base::cert`'s, and `pc`, `dm` equal to P's.
  - 3654 clipped blocks left out, as the join leaves them out, without touching the state.
- **New `cpu_join::stepped_tops_equal_divided_tops_on_production_fields`.** For each production plan field (b42 1e13; b50, b57, b60, b62, b64 1e14), 25 sampled partitions including the first and last live ones. For every key, `tops()` must give the same tops, field by field and in order, as a join with every block through `Base::cert`: 3,698,847 tops.
- **`check_partitions` now also compares every key's tops with the divided ones.** So `cpu_join_matches_the_reference_on_the_test_windows` (b10's band and the b20–b64 windows, clipped at both ends) checks them on every partition it visits. The opt-in `cpu_join_matches_the_reference_on_production_fields` (`NICE_TEST_CPU_JOIN_REF=16`: 16 partitions of each plan field) passes too, against the reference join. New `the_test_windows_step_their_top_certificates`: every window but b10's takes the stepped path.
- The other `cpu_join` tests are unchanged and pass: all three scans, stride agreement on whole windows, slices, the field prune, b10's 69. `cargo test --release -p nice_common -p nice_client`: 184 + 22 passed.
- The whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): join = reference = stride, 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits. On 4 threads: reference 85 s, join 12.9 s, stride 113.7 s.
- **Every timed run above has main's join survivors and full checks:**
  - b60 1e16, 4 partitions: 136,900,315 / 8,692,368;
  - b60 1e16, 16 partitions: 549,719,536 / 34,926,644;
  - b62 1e17 slice 0, 4 partitions: 137,605,271 / 8,194,223;
  - b62 1e17 slice 0, 16 partitions: 550,916,180 / 32,806,057;
  - whole b60 1e14 field: 1,326,103,590 / 84,383,498;
  - whole b62 1e14 field: 1,470,093,637 / 87,495,922.
  - No hits on either side.
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default features, rustc 1.99.1): clean. The GPU feature sets do not change this code.

## Not in this PR

- **A leaner survivor prefilter.** The CPU's middle-digit prefilter is the same arithmetic as the GPU's `walk_pf`. A fixed-point, branch-free form of it measured ×1.05–1.08 on its own at production shapes, with identical survivor and checked counts. It follows separately once the GPU version lands.
- **The seed budget** (4 steps) is not tuned. Seeds are 2–5 % of prefixes.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
