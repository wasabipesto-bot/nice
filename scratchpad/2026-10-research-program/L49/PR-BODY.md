Stacked on #247: its commit is the base of this branch; the new work is the last commit.

## What

Every pair that passes the CPU join's AND inside the field goes through the middle-digit prefilter (`CpuJoin::survivor` → `prefilter`), which keeps about 6 % of them for the client's full check. At mid = 2 (every production shape) it tests the two base-b digits of x2 = (A2 + P2·D) mod b² and x3 = (A3 + P3·D) mod b², where A (< b²) is the listed bottom's carry (`Info.carries`), P (< b²) its coefficient 2R or 3R² (`Ext.p2`, `p3`) and D (< b²) the top's next two digits (`Top.dm` before this PR): the four digits must be distinct, and none of them in the bottom's digits or, when the top's seed flag is set, its certificate. It reduced A + P·D mod b² with a reciprocal multiply per power (`SmallDiv::rem`), took x % b and x / b per digit (`divrem_small`), and built and tested two one-hot masks per digit pair with an early exit after each pair.

This PR computes the same predicate the way #246 does on the GPU:

- **Digits by fixed point instead of a reduction and two divisions by b** (`Fx`). Each top keeps `dh = ceil(D·2^32/b²)` in place of D (as `D·q + ceil(D·r/b²)`, 2^32 = q·b² + r, once per kept top). Per pair, `F = A·C + P·dh mod 2^32` with `C = ceil(2^32/b²)`; the digits are `h = hi32(F·b)` and `g = hi32((F·b mod 2^32)·b)`. Four multiplies per power (`A·C`, `P·dh` and two by b), and no reduction mod b².
- **Membership by shifts** (`fresh4`). Digit g is in `seen` iff bit 0 of `seen >> g` is set: the four shifts OR into one test, and six compares check that the four digits are distinct. All of it is combined with `&`, so a survivor takes one branch on the outcome instead of up to four.
- **Seed-gated top masks.** `Top` keeps `gmask` (its certificate if the seed flag is set, else 0) in place of the flag, so a pair ORs it in without a select.

The fixed-point path covers mid = 2 with k > 2, which is every production shape. Every other shape keeps the general form (`prefilter_any`): in the tests, b10's k = 1 and one b20 window with k = 2, whose last bottom digit reaches below b^mid. (Shapes with mid = 1 and k ≥ 2 also move from the old `prefilter` to `prefilter_any`, which is equivalent there; no field or test window has mid = 1.) `prefilter_any` now reads `gmask`, and recomputes D from P, since `Top` no longer keeps it. The old `prefilter` body and `SmallDiv::rem` are gone. **`Top` stays at 48 bytes**: `dh` replaces `dm`, and `gmask` takes the flag's byte and the padding after it (a compile-time assertion pins the size).

Unlike #246, the masks keep digit d at bit d: on the CPU a u64 shift takes any count below 64, on any target, so no bit reversal is needed. `A·C` is formed per pair (two multiplies) rather than stored per listed bottom, so `Info` stays 8 bytes. The residue range test stays per pair (below).

## Why

Measured with perf on #247's head at production shapes (b60 1e16 and b62 1e17 slice 0, 1 thread, 4 partitions, recording after the slice setup; each run started at a 1-min load of ≤ 2):

| | b60 1e16, #247 | b60 1e16, this PR | b62 1e17 slice 0, #247 | b62 1e17 slice 0, this PR |
|---|---|---|---|---|
| `scan_avx2` (the AND and its pop loop) | 37.0 % | 39.2 % | 34.6 % | 38.3 % |
| the partition loop (`run` with the stepped top certificates, bottoms and lists, inlined into the harness's thread) | 28.4 % | 31.7 % | 28.7 % | 32.1 % |
| **`survivor`** (the residue range test and the prefilter; the full check is not inlined) | **21.9 %** | **14.5 %** | **22.8 %** | **14.5 %** |
| `get_is_nice_with_known_lsd` (the full check) | 10.3 % | 12.0 % | 11.0 % | 11.7 % |
| sorting the tops | 1.3 % | 1.4 % | 1.1 % | 1.3 % |
| ms per partition in these runs | 2598 | 2345 | 2445 | 2265 |

- **`survivor` was 22–23 % of the join** at both shapes. #247 cut the top certificates and left it alone, so its share grew (perf on main at the same shapes: 17–18 %). A b60 1e16 partition sends 34.2 M pairs through it, of which 2.17 M (6.3 %) go on to the full check.
- With this PR it takes ~340 ms of a b60 1e16 partition instead of ~570 ms (×1.7). That predicts ×1.10 for the partition; the A/B below measured ×1.07–1.11 (on a first version; the final one is no slower).
- The top sort moves whole `Top`s. A first version of this PR grew `Top` to 64 bytes, and the sort's share rose to 1.8 % (b60) and 1.6 % (b62); at 48 bytes it costs what it did on #247 (33 ms of a b60 1e16 partition on both sides).

#246 makes the same change in the GPU join's walk, together with a per-chunk range test (×1.07–1.12 there on 1e16 and 1e17 fields).

## Soundness

**The fixed-point digits are exact.** For b ≤ 64 and A, P, D < b²:

1. `C·b² = 2^32 + ε1` and `dh·b² = D·2^32 + ε2` with `0 ≤ ε1, ε2 < b²` (both are ceilings).
2. Write `A + P·D = m·b² + x` with `x = (A + P·D) mod b²`. Then `(A·C + P·dh)·b² = m·b²·2^32 + x·2^32 + Δ`, with `Δ = A·ε1 + P·ε2`, so `0 ≤ Δ < 2b⁴ ≤ 2^25`.
3. Hence `A·C + P·dh = m·2^32 + F0` with `F0 = (x·2^32 + Δ)/b²`, an integer (b² divides the rest of step 2's equation) and below 2^32 because `x ≤ b² − 1` and `Δ < 2^32`. So `F = (A·C + P·dh) mod 2^32 = F0` and `F·b² = x·2^32 + Δ`.
4. The two multiplies split `F·b²` exactly: `F·b = h·2^32 + F′` and `F′·b = g·2^32 + F″` with `g < b`, so `⌊F·b²/2^32⌋ = h·b + g`. Since `Δ < 2^32`, that is x: (h, g) are x's two base-b digits.

The only condition is Δ < 2^32. The exact maximum of Δ over A, P, D < b² at bases 10–64 is 26,655,048 (about 2^24.7, at b62): a factor of 161 to spare. At b64, ε1 = ε2 = 0.

**The operands are in range on the CPU** (re-derived for this code, not taken from the GPU's):

- A2 and A3 come from `list`: `t2` = ⌊R²/b^(k−1)⌋ mod b^(mid+1), and `divrem_small(t2)` by b gives `a2 = ⌊t2/b⌋ < b^mid = b²`, which is ⌊R²/b^k⌋ mod b² (likewise A3 from `t3`). They are packed as `a2 | a3 << 16`, and b² ≤ 4096 < 2^16.
- P2 = 2ρ mod b² and P3 = 3ρ² mod b² (`extend`, ρ = r mod b² for the residue r with the partition's fixed digits). On the fixed-point path k > mid, so the last bottom digit (at position k − 1 ≥ 2) does not change r mod b², and the coefficients hold for every key.
- D = ⌊P/b^(k−f0)⌋ mod b² < b², on both top paths: the divided one computes it, the stepped one (#247) steps it, and each passes it to `dh`. The existing test that compares stepped and divided tops field by field now compares `dh` (strictly increasing in D, since 2^32/b² > 1) and `gmask`, which keeps the two construction sites consistent.
- `A·C` fits a word: `(b² − 1)·C < 2^32` for b < 256. `dh = D·q + ceil(D·r/b²) = ceil(D·2^32/b²) < 2^32`, and its division is `SmallDiv::divrem` of `D·r + b² − 1 < b⁴ ≤ 2^24`, inside its exact range (below 2^48/b²).
- `F·b < 2^38` fits a u64; h, g < b ≤ 64, so the shifts `seen >> g` are in range.

**The membership test is the same predicate.** Before (`fresh_digits`, unchanged, still used by the general form): low digits first, fail if `g2 = g3` or `{g2, g3} ∩ seen ≠ ∅`; then the high digits, fail if `h2 = h3` or `{h2, h3} ∩ (seen ∪ {g2, g3}) ≠ ∅`. Unrolled: the four digits pairwise distinct (six inequalities) and none in `seen`, which is what `fresh4` checks.

**The gated masks** are `seed ? mask : 0`, set where each top is made (stepped and divided paths alike): `seen = bmask | gmask` is the value the select gave.

What the tests pin about the gate:
- **Every full block is seeded, at every supported shape.** With f0 ≥ 1 and a ≥ b^(L−1), `e² − a² = (b^f0 − 1)(2a + b^f0 − 1) ≥ b^(L+f0−1)`, so the certificate floor is at least L + f0 ≥ L + 1 ≥ k + 2 ≥ k2 (the join needs k < L). So every stepped top has its gate on; `the_test_windows_step_their_top_certificates` now asserts `full_floor ≥ k2` for every window that steps.
- **An unseeded top is a clipped block of fewer than about b/2 numbers** at a field's end. Its certificate covers every digit of n² and n³ from position k or k + 1 up, so a join survivor on it is all but nice. b10's band (the general form) has them; no test window on the fixed-point path has one with a survivor (a search of every window start in b20's 4-digit band, with a first block of ≤ 10 numbers at t = k = 3, found none).
- So a regression that never gates is caught: the windows and the production reference compare every prefilter survivor, on seeded tops, with the prefilter's definition. One that always gates would change nothing on full blocks, and is caught only by b10's band, on the general form; on the fixed-point path's clipped blocks it is not pinned by a test.

**Host tests** (new, in `cpu_join::tests`; all but the second run in CI):

- `fx_digits_match_the_division`: at every base 10–64, `C`, `q`, `r` and `dh` against exact ceilings for every D < b², the bound Δ < 2^32 from the measured ε1, ε2, and the digits against `(A + P·D) mod b²` for every (P, D) at the largest A and every (A, D) at the largest P: 446,418,038 triples.
- `fx_digits_are_exact_everywhere` (ignored, opt-in by `NICE_TEST_FX_EXHAUSTIVE=1`, the variable #246's GPU test uses): every triple A, P, D < b² at every base 10–64, 663,187,945,915 in all (299 s on 4 threads).
- `lean_membership_matches_the_masks`: `fresh4` against `fresh_digits`' one-hot masks for every digit 4-tuple at every base 10–64 against two random sets (b/4 and b/2 digits), and 200,000 random tuples per base against sets of every size from 0 to b.
- `lean_prefilter_matches_the_division_form`: the whole fixed-point prefilter (`Fx::pass`) against the division form (`(A + P·D) mod b²` per power, then `fresh_digits`) on 10^6 random pairs per base 10–64, against sets of every size from 0 to b.
- `production_shapes_take_the_fixed_point_prefilter`: the fixed-point path is taken exactly where mid = 2 and k > 2: every production field in the tests (b42–b64), and every test window but b10's and the b20 k = 2 one, which take the general form. So the existing parity tests (reference join on the windows, the scans, the stride path, slices, the production reference) cover both paths.

## Measurements

**Machine:** a 4-vCPU AMD EPYC-Rome (**Zen 2**) VM with **AVX2 only** (so the scan is `scan_avx2`); every run under `nice -n 19`. On other cores the old form's multiplies and mispredicted branches cost differently, and with AVX-512 the scan is cheaper (a larger prefilter share), so the ratio there may differ. I have measured only this machine.

**Method:** release builds of #247's head (`caef70e`) and this PR. The three-round A/B and NiceMark below ran on this PR's first version, which kept D in `Top` beside `dh` (64 bytes); the final version (48 bytes, otherwise the same arithmetic) was then checked against #247 with the sanity rounds after them. A harness outside this PR, using only `CpuJoin`'s public API, runs sampled partitions of one slice (NiceMark's bit-reversed `sample_order`) through `CpuJoin::run_partition` on 1 or 4 threads; whole fields run every partition. The two binaries are interleaved with the order alternating per round (#247, PR; PR, #247; #247, PR), 3 rounds. Figures are medians; spread = (max − min) / median; "per round" is #247's time over the PR's in the same round. Before each round the script waited for the 1-min load average to be ≤ 2 and logged it: the rounds started at 2.00, 1.88 and 1.97 (the 4-thread runs themselves lift it to 3–4).

Fields: b60 starts at NiceMark's `b60_msd_weak` start, 1157209632114824200908. b62 1e17 is the whole field 4473066762334864396992 + 1e17, which the CPU cuts into 7 slices; its slice 0 is used here (4.75 M top-layer prefixes). b62 1e14 starts at 4473156762334864396992, and b64 at 41242006262957161709568.

Times are ms per partition and thread for the sampled partitions (wall × threads / partitions) and wall seconds for the whole fields. Every run of both sides found the same join survivors and full checks (below).

| work | threads | #247 (rounds) | spread | this PR (rounds) | spread | speed-up | per round |
|---|---|---|---|---|---|---|---|
| **b60 1e16**, 4 partitions | 1 | **2405** ms (2405, 2431, 2387) | 1.8 % | **2204** ms (2204, 2188, 2221) | 1.5 % | **×1.091** | 1.091, 1.111, 1.075 |
| **b60 1e16**, 16 partitions | 4 | **2569** ms (2606, 2515, 2569) | 3.5 % | **2389** ms (2453, 2389, 2318) | 5.6 % | **×1.076** | 1.062, 1.053, 1.108 |
| **b62 1e17** slice 0, 4 partitions | 1 | **2331** ms (2322, 2342, 2331) | 0.9 % | **2184** ms (2232, 2184, 2108) | 5.7 % | **×1.067** | 1.040, 1.072, 1.105 |
| **b62 1e17** slice 0, 16 partitions | 4 | **2491** ms (2460, 2573, 2491) | 4.6 % | **2252** ms (2252, 2204, 2291) | 3.9 % | **×1.106** | 1.092, 1.168, 1.087 |
| b60 1e14, whole field (3600 partitions) | 1 | **130.4** s (130.4, 130.4, 131.0) | 0.4 % | **124.1** s (124.3, 124.1, 122.9) | 1.1 % | **×1.051** | 1.050, 1.051, 1.066 |
| b60 1e14, whole field | 4 | **34.4** s (33.8, 34.4, 34.4) | 1.8 % | **32.6** s (32.6, 32.6, 32.2) | 1.1 % | **×1.056** | 1.037, 1.056, 1.068 |
| b62 1e14, whole field (3844 partitions) | 1 | **165.8** s (165.8, 165.6, 166.3) | 0.4 % | **158.4** s (158.4, 158.5, 155.7) | 1.8 % | **×1.047** | 1.047, 1.045, 1.069 |
| b62 1e14, whole field | 4 | **43.7** s (43.8, 43.2, 43.7) | 1.5 % | **41.1** s (41.2, 41.1, 40.9) | 0.8 % | **×1.064** | 1.064, 1.052, 1.069 |
| b64 1e14, whole field (4096 partitions) | 1 | **339.0** s (337.8, 339.0, 341.3) | 1.1 % | **302.9** s (304.6, 302.9, 301.3) | 1.1 % | **×1.119** | 1.109, 1.119, 1.133 |
| b64 1e14, whole field | 4 | **87.8** s (88.6, 86.8, 87.8) | 2.0 % | **79.2** s (78.0, 79.5, 79.2) | 1.8 % | **×1.109** | 1.135, 1.092, 1.109 |

- **At the production shapes (b60 1e16, b62 1e17) the join is ×1.07–1.11 faster**, at 1 and 4 threads. The single rounds scatter more (1.04–1.17) than the medians: a sampled run lasts about 10 s, and other load on the VM moves single runs by a few percent.
- The whole b60 and b62 1e14 fields gain ×1.05–1.06: there the bottom work per partition (extension and lists, unchanged here) takes a larger share. **b64 gains ×1.11–1.12**: its 1e14 field has 4.3× b60's join survivors for 1.14× its partitions, so the prefilter is a larger share of it.

**The final version (48-byte `Top`)**, sanity rounds at 4 threads, 16 partitions each, alternating (#247, PR; PR, #247; …), ms per partition and thread:

| work | round 1 | round 2 | round 3 | round 4 | rounds 2–4: #247 / this PR (medians) |
|---|---|---|---|---|---|
| b60 1e16 | 3154 / 4173 | 2642 / 2298 (×1.150) | 2558 / 2290 (×1.117) | 3258 / 2390 | 2642 / **2298** |
| b62 1e17 slice 0 | 4304 / 2730 | 2474 / 2234 (×1.108) | 2490 / 2428 (×1.026) | 2422 / 2234 (×1.084) | 2474 / **2234** (×1.107) |

- Round 1 ran while other processes loaded the VM (the 1-min load rose to 4.7 during it), and #247's b60 run in round 4 too (3258 ms); those runs are not comparable.
- The final version's medians (b60 2298 ms, b62 2234 ms) are at or below the first version's in the A/B above (2389 and 2252 ms): the smaller `Top` costs nothing, and saves the top sort's extra ~10 ms a partition (the perf table under Why). Every run had #247's counts.

NiceMark nice-only on the CPU (`nice_client niceonly --benchmark --threads 4 --benchmark-secs 150 --benchmark-json`, no `--gpu`), 4 rounds alternating (#247, PR; PR, #247; …), every run started at a 1-min load of ≤ 2.0 (1.85–2.00); medians; the scenario rows are numbers/s; "per round" is the PR's over #247's:

| | #247 (rounds) | this PR (rounds) | speed-up | per round |
|---|---|---|---|---|
| **score** | 798.5 (790.8, 792.1, 813.9, 804.9) | 868.5 (873.1, 863.9, 874.2, 860.1) | **×1.088** | 1.104, 1.091, 1.074, 1.069 |
| b58 MSD-weak (1e15 field, 4 threads) | 1.879e12 (1.822e12, 1.864e12, 1.923e12, 1.895e12) | 2.061e12 (2.063e12, 2.021e12, 2.075e12, 2.059e12) | **×1.097** | 1.132, 1.085, 1.079, 1.087 |
| b58 MSD-weak, 1 thread | 5.032e11 (5.062e11, 4.958e11, 5.044e11, 5.020e11) | 5.501e11 (5.568e11, 5.381e11, 5.480e11, 5.523e11) | **×1.093** | 1.100, 1.085, 1.086, 1.100 |
| b58 MSD-strong (1e15 field, 4 threads) | 1.205e13 (1.205e13, 1.188e13, 1.214e13, 1.205e13) | 1.268e13 (1.278e13, 1.272e13, 1.264e13, 1.261e13) | **×1.053** | 1.061, 1.071, 1.041, 1.047 |
| b60 MSD-weak (a 3e15 window of a 1e16 field, 4 threads) | 4.867e12 (4.690e12, 4.742e12, 5.002e12, 4.992e12) | 5.415e12 (5.430e12, 5.395e12, 5.455e12, 5.401e12) | **×1.113** | 1.158, 1.138, 1.090, 1.082 |
| b62 MSD-weak (a 3e15 window of a 1e16 field, 4 threads) | 5.213e12 (5.188e12, 5.238e12, 5.300e12, 5.163e12) | 5.600e12 (5.562e12, 5.637e12, 5.693e12, 5.314e12) | **×1.074** | 1.072, 1.076, 1.074, 1.029 |

- The PR's fourth b62 run was low (5.314e12; the others 5.56–5.69e12); the median does not use it.
- MSD-strong gains least: its fields have fewer join survivors per partition, so the prefilter is a smaller share.
- NiceMark samples partitions for a fixed time, so the two sides sampled different numbers of partitions and their survivor counts are not comparable; the A/B above compares counts.

## Exactness

All release builds. The tests ran on this head; the timed runs' counts are from both versions.

- **The four new host tests** above pass (`fx_digits_match_the_division`: 446,418,038 triples; `lean_membership_matches_the_masks`; `lean_prefilter_matches_the_division_form`; `production_shapes_take_the_fixed_point_prefilter`), and so does the opt-in exhaustive one: all 663,187,945,915 triples exact.
- **The existing `cpu_join` tests pass unchanged**, and with them the prefilter in place: `cpu_join_matches_the_reference_on_the_test_windows` compares every visited partition's prefilter survivors, one by one, with the prefilter's definition (`mid_mirror`, the digits of n² and n³ mod b^k2 in u128) on b10's band and the b20–b64 windows, clipped at both ends; the windows with k > 2 run the fixed-point form, b10 and the b20 k = 2 window the division form. Also all three scans, stride agreement on whole windows, slices, the field prune, the stepped-vs-divided tops on production fields (which now compare `dh` and `gmask` too), every stepped window seeded, b10's 69. `cargo test --release -p nice_common -p nice_client`: 188 + 22 passed, 6 ignored (opt-in).
- The opt-in `cpu_join_matches_the_reference_on_production_fields` (`NICE_TEST_CPU_JOIN_REF=3`: 3 partitions of each plan field, b42–b64): ok, against the reference join.
- The whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): join = reference = stride, 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits. On 4 threads: reference 86 s, join 12.1 s, stride 112.9 s (the first version; the head's run, with other load on the VM, took 107 s, 18.4 s and 164.8 s).
- **Every timed run above, of both versions, has #247's join survivors and full checks:**
  - b60 1e16, 4 partitions: 136,900,315 / 8,692,368;
  - b60 1e16, 16 partitions: 549,719,536 / 34,926,644;
  - b62 1e17 slice 0, 4 partitions: 137,605,271 / 8,194,223;
  - b62 1e17 slice 0, 16 partitions: 550,916,180 / 32,806,057;
  - whole b60 1e14 field: 1,326,103,590 / 84,383,498;
  - whole b62 1e14 field: 1,470,093,637 / 87,495,922;
  - whole b64 1e14 field: 5,702,041,796 / 346,647,759.
  - No hits on either side.
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default features, rustc 1.99.1): clean. The GPU feature sets do not touch this code: `cpu_join.rs` has no feature-gated items, and the GPU modules use only `CpuJoin`'s public API (one doc comment names `CpuJoin::prefilter`, which keeps its name).

## Not in this PR

- **The residue range test on clipped tops only** (#246's per-chunk test): on the CPU the per-pair test's loads (which hit L2) overlap the prefilter's work; skipping it for unclipped tops measured ×1.00 in a prototype on main (before #247; ×1.009 at b60 1e16 and ×0.987 at b62 1e17 slice 0, 1 thread, 2 rounds, both inside the noise). Not taken.
- **Sharing the fixed-point digits with the GPU.** #246 has the same constants and host tests in `cubecl_join`; neither PR is merged, so this one keeps its own `Fx`. Once both land, the constants (`C`, `q`, `r`, `dh`) and their exhaustive test can move to one module that both joins use.
- **A b²-entry table for `dh`** (16 KiB at b64) instead of its reciprocal division once per kept top (about 5 M tops a production partition): an estimated 0.2–0.4 % of a partition; not tried.
- **`A·C` per listed bottom** instead of per pair (the GPU keeps it per entry): `Info` would grow from 8 to 12 or 16 bytes for two multiplies per survivor; not tried.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
