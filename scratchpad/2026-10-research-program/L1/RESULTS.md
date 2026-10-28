# L1: join selectivity by base, by counting (CPU, 2026-10-28)

Branch `rp/l1-selectivity` on the fork, commit `a76984f` (on origin/main `85b5b4e`). Host: ivory (AMD EPYC-Rome, AVX2, 4 vCPU), `nice -n 19`, 3 partitions at a time, one thread each.

## Answer in brief

- **Hypothesis A explains the b64 jump and the b58 > b60 ordering.** ANDs per top equal (roots) × (mean class size) to within 0.1 % at every base. That is 3.8k at b58 (4 roots), 1.9k at b60 (2), 2.4k at b62 (2) and 9.7k at b64 (8).
- **Hypothesis B is real but small, and it points the other way.** Tops know 15.7 / 16.2 / 17.3 / 18.4 digits. The AND's pass rate follows the uniform model C(b−pc, 12)/C(b, 12), so b64 has the lowest pass rate: 1.06 %, against 1.64 % at b60.
- **Net effect.** AND survivors per top are 53 / 31 / 30 / 103. Tops per prefix are flat (1.2–1.3k), so the cost per prefix follows ANDs and survivors. On the CPU it is 5.8 / 3.5–3.9 / 4.0–4.4 / 11.0–11.5 ms. That is the GPU's ordering (11.2 / 7.0 / 9.4 / 19.5 µs), with ratios within about 15 %.
- **Where b64's extra time goes.** Mostly into handling the AND's survivors (range test, prefilter, dispatch: 52 % of the b60→b64 increase), then the ANDs themselves (33 %).
- **The lever.** Signature bucketing with S taken from the top masks skips 56–62 % (s=4), 70–75 % (s=6) and 75–81 % (s=8) of ANDs. Almost all of that comes from a simpler rule: drop the bottoms that meet the field's own certificate, which every top knows. That alone skips 60–79 % (79 % at b64), with no sub-buckets.
- **What it saves.** Only failing ANDs are skipped, so survivors do not change. On the CPU the saving is at most about 10 % of a partition at b58–b62 and about 20 % at b64.

## Method

**Code.** An ignored test, `cpu_join::selectivity::l1_selectivity` (`common/src/cpu_join/selectivity.rs`, a child module of `cpu_join`, so it calls the private stages directly).
- It runs each sampled partition through the same `tops` → `extend` → `list` → `scan` calls as `CpuJoin::run`, with an `Instant` around each stage.
- It then times the ANDs alone: an AVX2 loop identical to `scan_avx2` that counts instead of dispatching. It also times the full checks alone, re-running `get_is_nice_with_known_lsd` on the recorded prefilter survivors.
- The only non-test change is a `#[cfg(test)]` `Base::cert_split` in `overlap_join.rs`, the certificate with its n² and n³ digit counts. It is asserted equal to `cert` on every 8th top. Production code is unchanged.
- Asserts on every run: the full-check re-run finds the same hits; every simulated skip keeps every pair that passes the AND; every top's mask contains each prune mask.

**Fields.** Two per base, at the sizes EXPERIMENTS item 23 profiled: 1e16 at b60–64 and 1e15 at b58.
- The first is item 23's own field.
- The second is `PLAN_FIELDS`' start at 1e16 (b60/62/64), or item 18's b58 GPU field (130525216587923470200).
- `PLAN_FIELDS` b64 is also `THROUGHPUT_STARTS` b64.
- Item 18's other b58 field (140539216587923470200) is empty at 1e16 (top layer 0, from the probe `l1_probe_windows`), so it was not used.

**Sample.** 6 partitions per field (12 per base), one seeded draw from each sixth of the b² partition range.

**Counts per partition.**
- Tops, and the top-mask popcount (mean, p10, p90).
- Digits the certificate knows of n² and of n³.
- Bottoms after the partition's two fixed digits (`ext` rows), and bottoms per key-digit list.
- Roots, ANDs per top (the sum of the class sizes probed), AND passes per top, range-test survivors per top (the production `survivors`) and prefilter survivors per top (the production `checked`). Every prefilter survivor gets one full check, so the last is also full checks per top.

**Signature bucketing (simulated exactly).**
- Per key list and class, a histogram of `bottom ∩ S` over the 2^s sub-buckets, turned into subset sums (a zeta transform). A top then still ANDs `g[S \ top]` bottoms per class probed.
- Also counted: how many sub-buckets it visits (2^|S \ top|), and how many of those are non-empty.
- Three choices of S:
  - `low`: digits 0..s−1.
  - `top`: the s digits most often in the field's top masks.
  - `coll`: the largest (top frequency × bottom frequency).
  - `top` and `coll` are chosen per field, from 2 partitions outside the sample.

**Pruning (simulated exactly).** Drop the bottoms that meet a mask every top knows. Three masks:
- the field's certificate, `cert(start, end−1, k)`;
- the certificate of the 1e16 field from the same start (it differs only for the 1e15 b58 fields);
- the AND of the key's top masks.

**Reproducibility.** Round 1 ran from the working tree, which equals `a76984f` up to rustfmt and lint attributes. Round 2 (`round2/`) ran from `a76984f`. Counts are identical. Stage times agree within ±5 %, and within ±25 % for the tiny `extend` stage.

## Commands

```
cd /home/claude/projects/nice && git worktree add .worktrees/rp-l1 origin/main -b rp/l1-selectivity
cd .worktrees/rp-l1 && nice -n 19 cargo test -p nice_common --release --no-run -j 3
# top-layer size of each tenth of each field (picks non-empty fields; 20 s)
NICE_TEST_L1_PROBE=1 nice -n 19 target/release/deps/nice_common-ff746edb5f48128a \
  --ignored --exact cpu_join::selectivity::l1_probe_windows --nocapture
# the run (about 3 min)
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L1
NICE_TEST_L1=$R NICE_TEST_L1_PARTS=6 NICE_TEST_L1_THREADS=3 nice -n 19 \
  target/release/deps/nice_common-ff746edb5f48128a --ignored --exact cpu_join::selectivity::l1_selectivity --nocapture
python3 $R/analyze.py > $R/tables.md          # round 2: same with NICE_TEST_L1=$R/round2; analyze.py $R/round2
```

Options: `NICE_TEST_L1_BASES` (default `58,60,62,64`) and `NICE_TEST_L1_SIZE`, which overrides every field's size. The same run through cargo: `NICE_TEST_L1=<dir> cargo test -p nice_common --release l1_selectivity -- --ignored --nocapture`.

## Results

### 1. Counts per base (both fields, weighted by tops)

| base | b−1 | roots | L | t | digits n²/n³ | bottoms after the partition digits | bottoms per key list | per class | ANDs/top | roots×class | top popcount mean (p10–p90) | known n² / n³ | AND pass rate | uniform model | AND survivors/top | prefilter survivors (= full checks)/top |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 58 | 57 | 4 | 12 | 9 | 23/35 | 81,676 | 54,779 | 961 | 3,844 | 3,844 | 15.68 (15–16) | 7.73 / 7.95 | 1.372% | 1.396% | 52.7 | 3.25 |
| 60 | 59 | 2 | 12 | 9 | 24/36 | 80,733 | 54,940 | 931 | 1,863 | 1,862 | 16.23 (16–18) | 8.06 / 8.18 | 1.637% | 1.421% | 30.5 | 2.00 |
| 62 | 61 | 2 | 13 | 10 | 25/37 | 105,337 | 72,673 | 1,191 | 2,383 | 2,383 | 17.31 (16–18) | 8.87 / 8.45 | 1.252% | 1.231% | 29.8 | 1.94 |
| 64 | 63 | 8 | 13 | 10 | 26/38 | 109,338 | 76,384 | 1,212 | 9,702 | 9,700 | 18.43 (17–19) | 9.56 / 8.86 | 1.063% | 1.061% | 103.1 | 6.59 |

### 2. Per top-layer prefix (over all b² partitions), field by field

| base | field | size | prefixes | tops/prefix | ANDs/prefix | AND survivors/prefix | prefilter survivors/prefix | GPU µs/prefix (9070 XT) |
|---|---|---|---|---|---|---|---|---|
| 58 | item18 | 1e+15 | 693,548 | 1,192 | 4.58M | 65.4k | 4.00k | 11.2 |
| 58 | item23 | 1e+15 | 474,289 | 1,203 | 4.63M | 59.7k | 3.73k | 11.2 |
| 60 | item23 | 1e+16 | 3,467,368 | 1,219 | 2.27M | 31.4k | 1.95k | 6.8–7.3 |
| 60 | plan | 1e+16 | 5,251,096 | 1,303 | 2.43M | 43.6k | 2.93k | 6.8–7.3 |
| 62 | item23 | 1e+16 | 2,780,153 | 1,314 | 3.13M | 42.4k | 2.84k | 9.2–9.6 |
| 62 | plan | 1e+16 | 3,693,911 | 1,264 | 3.01M | 35.4k | 2.24k | 9.2–9.6 |
| 64 | item23 | 1e+16 | 1,877,820 | 1,326 | 12.85M | 123.4k | 8.16k | 19.5 |
| 64 | plan | 1e+16 | 3,090,692 | 1,285 | 12.48M | 140.6k | 8.82k | 19.5 |

### 3. CPU stage times per partition (mean of 6)

| base | field | tops s | extend s | list s | scan s | of which AND only | full check | range test + prefilter + dispatch | scan share | scan excl. full check (item 23's scan) | ns per prefix tried (tops stage) | ns/AND | ns/AND survivor (excl. full check) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 58 | item18 | 0.28 | 0.016 | 0.039 | 0.86 | 0.21 (17%) | 0.13 (11%) | 0.52 (43%) | 72% | 61% | 405 | 0.22 | 38 |
| 58 | item23 | 0.20 | 0.016 | 0.040 | 0.57 | 0.14 (17%) | 0.08 (10%) | 0.34 (42%) | 69% | 59% | 412 | 0.22 | 41 |
| 60 | item23 | 1.52 | 0.014 | 0.039 | 1.76 | 0.46 (14%) | 0.31 (9%) | 0.99 (30%) | 53% | 44% | 437 | 0.21 | 33 |
| 60 | plan | 2.13 | 0.015 | 0.038 | 3.50 | 0.74 (13%) | 0.70 (12%) | 2.06 (36%) | 62% | 49% | 406 | 0.21 | 32 |
| 62 | item23 | 1.26 | 0.016 | 0.052 | 1.85 | 0.47 (15%) | 0.35 (11%) | 1.02 (32%) | 58% | 47% | 452 | 0.21 | 33 |
| 62 | plan | 1.65 | 0.018 | 0.052 | 2.11 | 0.61 (16%) | 0.37 (10%) | 1.13 (30%) | 55% | 45% | 446 | 0.21 | 33 |
| 64 | item23 | 0.87 | 0.022 | 0.056 | 4.12 | 1.37 (27%) | 0.47 (9%) | 2.28 (45%) | 81% | 72% | 463 | 0.23 | 40 |
| 64 | plan | 1.45 | 0.016 | 0.057 | 7.12 | 2.23 (26%) | 0.83 (10%) | 4.07 (47%) | 82% | 73% | 471 | 0.24 | 38 |

The "scan excluding full check" column matches EXPERIMENTS item 23's profile on the EPYC 7K62, the same Zen 2 family: 58 / 45 / 48 / 72 %.

### 3b. CPU cost per top-layer prefix by stage (ms on one core, all b² partitions)

| base | field | tops | list + extend | ANDs | range test + prefilter + dispatch | full check | total | vs b60 item23 | GPU µs/prefix |
|---|---|---|---|---|---|---|---|---|---|
| 58 | item18 | 1.36 | 0.27 | 1.00 | 2.52 | 0.64 | 5.80 | ×1.68 | 11.2 |
| 58 | item23 | 1.39 | 0.40 | 1.01 | 2.42 | 0.59 | 5.81 | ×1.68 | 11.2 |
| 60 | item23 | 1.57 | 0.06 | 0.47 | 1.03 | 0.32 | 3.45 | ×1.00 | 6.8–7.3 |
| 60 | plan | 1.46 | 0.04 | 0.50 | 1.41 | 0.48 | 3.90 | ×1.13 | 6.8–7.3 |
| 62 | item23 | 1.74 | 0.09 | 0.65 | 1.41 | 0.49 | 4.38 | ×1.27 | 9.2–9.6 |
| 62 | plan | 1.71 | 0.07 | 0.63 | 1.18 | 0.39 | 3.99 | ×1.16 | 9.2–9.6 |
| 64 | item23 | 1.90 | 0.17 | 2.99 | 4.98 | 1.02 | 11.05 | ×3.20 | 19.5 |
| 64 | plan | 1.93 | 0.10 | 2.95 | 5.39 | 1.10 | 11.47 | ×3.32 | 19.5 |

### 4. ANDs skipped, per field (weighted by ANDs)

`prune_window` = prune by the field's own certificate. For the 1e16 fields it equals `prune_1e16`.

| base | field | low4 | low6 | low8 | top4 | top6 | top8 | coll4 | coll6 | coll8 | prune_window | prune_1e16 | prune_key |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 58 | item18 | 27.2% | 32.6% | 38.1% | 60.7% | 73.4% | 78.1% | 60.8% | 73.4% | 78.3% | 68.8% | 60.7% | 68.8% |
| 58 | item23 | 15.8% | 24.0% | 45.2% | 63.2% | 76.7% | 81.1% | 63.9% | 76.7% | 81.2% | 63.2% | 63.2% | 63.2% |
| 60 | item23 | 38.9% | 44.4% | 48.6% | 57.5% | 72.6% | 75.6% | 58.3% | 72.6% | 76.2% | 66.2% | 66.2% | 72.6% |
| 60 | plan | 14.6% | 22.8% | 27.8% | 54.6% | 67.0% | 73.9% | 54.6% | 67.0% | 73.9% | 54.6% | 54.6% | 54.6% |
| 62 | item23 | 12.7% | 19.0% | 23.9% | 56.4% | 73.8% | 77.9% | 60.7% | 73.8% | 78.0% | 66.8% | 66.8% | 73.8% |
| 62 | plan | 30.6% | 43.4% | 55.0% | 56.2% | 73.7% | 77.9% | 60.8% | 73.7% | 78.6% | 73.7% | 73.7% | 73.7% |
| 64 | item23 | 26.6% | 32.5% | 36.3% | 63.9% | 75.9% | 83.7% | 66.4% | 78.4% | 83.8% | 82.2% | 82.2% | 82.2% |
| 64 | plan | 29.3% | 35.0% | 47.6% | 54.1% | 71.7% | 79.2% | 58.4% | 71.6% | 79.2% | 76.8% | 76.8% | 76.8% |

**Per base (mean of the two fields):**

| base | low4 | low6 | low8 | top4 | top6 | top8 | coll4 | coll6 | coll8 | prune by field cert | prune by key AND |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 58 | 21% | 28% | 42% | 62% | 75% | 80% | 62% | 75% | 80% | 66% | 66% |
| 60 | 27% | 34% | 38% | 56% | 70% | 75% | 56% | 70% | 75% | 60% | 64% |
| 62 | 22% | 31% | 39% | 56% | 74% | 78% | 61% | 74% | 78% | 70% | 74% |
| 64 | 28% | 34% | 42% | 59% | 74% | 81% | 62% | 75% | 82% | 79% | 79% |

**Sub-buckets visited per (top, class probed)**, non-empty ones in brackets, with the class size for scale:

| base | field | class size | low4 | low6 | low8 | top4 | top6 | top8 | coll4 | coll6 | coll8 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 58 | item18 | 960 | 6.2 [6.1] | 20.6 [19.1] | 67.9 [48.1] | 1.0 [1.0] | 1.3 [1.3] | 3.2 [3.2] | 1.0 [1.0] | 1.3 [1.3] | 3.2 [3.2] |
| 58 | item23 | 962 | 10.0 [9.9] | 31.6 [27.1] | 54.9 [39.6] | 1.0 [1.0] | 1.3 [1.3] | 3.2 [3.2] | 1.1 [1.1] | 1.3 [1.3] | 3.2 [3.2] |
| 60 | item23 | 931 | 3.4 [3.4] | 11.2 [11.1] | 36.1 [29.6] | 1.0 [1.0] | 1.0 [1.0] | 3.1 [3.1] | 1.0 [1.0] | 1.0 [1.0] | 3.2 [3.2] |
| 60 | plan | 932 | 10.9 [10.7] | 35.7 [30.8] | 117.5 [69.5] | 1.0 [1.0] | 1.7 [1.7] | 3.2 [3.2] | 1.0 [1.0] | 1.7 [1.7] | 3.2 [3.2] |
| 62 | item23 | 1,192 | 11.2 [11.0] | 37.4 [32.1] | 124.8 [74.1] | 1.0 [1.0] | 1.0 [1.0] | 2.5 [2.5] | 1.0 [1.0] | 1.0 [1.0] | 2.7 [2.7] |
| 62 | plan | 1,191 | 4.9 [4.9] | 11.0 [10.9] | 20.1 [18.6] | 1.0 [1.0] | 1.0 [1.0] | 2.4 [2.4] | 1.0 [1.0] | 1.0 [1.0] | 2.5 [2.5] |
| 64 | item23 | 1,211 | 6.1 [6.1] | 20.5 [19.2] | 68.3 [48.9] | 1.0 [1.0] | 1.0 [1.0] | 1.6 [1.6] | 1.0 [1.0] | 1.0 [1.0] | 1.7 [1.7] |
| 64 | plan | 1,214 | 6.0 [6.0] | 20.2 [18.9] | 36.7 [30.4] | 1.0 [1.0] | 1.0 [1.0] | 1.4 [1.4] | 1.0 [1.0] | 1.0 [1.0] | 1.4 [1.4] |

The `top` and `coll` sets begin with the field's certificate digits, which are in 100 % of tops (`digits.csv`). In b60 item23 and b62 item23 one more digit is in every top as well: their tops fill only the first 8 tenths of the field. That is why `prune_key` beats the field certificate there.

### 5. What skipping would save on the CPU (upper bound)

The bound is (AND-only time) × (skipped fraction), as a share of a partition, ignoring the cost of visiting sub-buckets.

| base | field | AND-only share | low8 | top4 | top8 | coll8 | prune_1e16 | prune_key |
|---|---|---|---|---|---|---|---|---|
| 58 | item18 | 17% | 7% | 11% | 14% | 14% | 11% | 12% |
| 58 | item23 | 17% | 8% | 11% | 14% | 14% | 11% | 11% |
| 60 | item23 | 14% | 7% | 8% | 10% | 10% | 9% | 10% |
| 60 | plan | 13% | 4% | 7% | 10% | 10% | 7% | 7% |
| 62 | item23 | 15% | 4% | 8% | 12% | 12% | 10% | 11% |
| 62 | plan | 16% | 9% | 9% | 12% | 12% | 12% | 12% |
| 64 | item23 | 27% | 10% | 17% | 23% | 23% | 22% | 22% |
| 64 | plan | 26% | 12% | 14% | 20% | 20% | 20% | 20% |

### 6. AND pass rate by top popcount, measured / uniform model

Each cell: the share of the base's tops with that popcount, then the measured pass rate / the model's. The model is C(b−pc,12)/C(b,12): the bottom mask is always 12 distinct digits.

| popcount | b58 tops share, measured / model | b60 tops share, measured / model | b62 tops share, measured / model | b64 tops share, measured / model |
|---|---|---|---|---|
| 14 | 2%: 2.27% / 2.37% |  |  |  |
| 15 | 28%: 1.67% / 1.72% | 4%: 2.38% / 2.06% |  |  |
| 16 | 70%: 1.23% / 1.24% | 73%: 1.75% / 1.51% | 8%: 1.83% / 1.80% |  |
| 17 |  | 19%: 1.23% / 1.10% | 51%: 1.35% / 1.33% | 7%: 1.46% / 1.59% |
| 18 |  | 4%: 0.89% / 0.79% | 40%: 0.99% / 0.98% | 42%: 1.17% / 1.18% |
| 19 |  |  |  | 50%: 0.91% / 0.88% |

### Fields

| base | field | start | size | prefixes | field cert digits | 1e16 cert digits | S top8 | S coll8 |
|---|---|---|---|---|---|---|---|---|
| 58 | item18 | 130525216587923470200 | 1e+15 | 693,548 | 5 | 4 | 2 16 26 27 31 41 42 44 | 16 2 26 31 27 41 42 53 |
| 58 | item23 | 183859216587923470200 | 1e+15 | 474,289 | 4 | 4 | 6 8 50 54 23 24 22 55 | 54 6 23 50 8 24 22 53 |
| 60 | item23 | 795599612114824200908 | 1e+16 | 3,467,368 | 5 | 5 | 0 2 8 46 54 55 10 16 | 8 55 0 2 46 54 49 24 |
| 60 | plan | 1366405974057412100454 | 1e+16 | 5,251,096 | 4 | 4 | 14 23 38 50 31 25 26 30 | 50 38 14 23 25 31 26 30 |
| 62 | item23 | 12255736762397899821056 | 1e+16 | 2,780,153 | 5 | 5 | 14 26 41 42 50 54 31 29 | 54 50 14 41 42 26 29 30 |
| 62 | plan | 7997740455941656911841 | 1e+16 | 3,693,911 | 6 | 6 | 0 6 9 14 15 29 5 3 | 15 29 14 9 6 0 4 5 |
| 64 | item23 | 72806461862957161709568 | 1e+16 | 1,877,820 | 7 | 7 | 3 16 31 40 44 45 57 46 | 16 57 40 45 3 31 44 41 |
| 64 | plan | 41242006262957161709568 | 1e+16 | 3,090,692 | 7 | 7 | 1 6 10 12 17 22 26 31 | 17 1 10 26 22 12 6 31 |

## Interpretation

**Why b64 (and b58) cost more per prefix.** The cause is the number of roots (hypothesis A), through the ANDs per top. A top probes exactly `roots` classes, and the bottoms are spread evenly over the b−1 classes, so ANDs per top = roots × (bottoms per key list)/(b−1): 4 × 961, 2 × 931, 2 × 1191 and 8 × 1212.
- The list is 55k / 55k / 73k / 76k. That is 0.95 / 0.83 / 0.95 / 0.87 of b³ × P(12 uniform digits distinct).
- The 8 roots at b64 (b−1 = 63 = 7·9) make 4.1× b62's ANDs per top. The 4 roots at b58 (57 = 3·19) make 2.1× b60's.
- Hypothesis B holds in form but not as an explanation. The tops know 15.7 / 16.2 / 17.3 / 18.4 digits, about evenly split between n² and n³. That is one more top digit at L = 13 (b62, b64) than at L = 12. The AND's pass rate tracks the uniform model at each popcount; b60 runs about 15 % above it. So b64's pass rate is the lowest (1.06 %, 0.85× b62's and 0.65× b60's).
- Net: AND survivors per top are ×3.5 (b64 over b62) and ×1.7 (b58 over b60), and per prefix 123–141k at b64 against 31–44k at b60. That matches BACKLOG 68's 112–176k and ~26k.
- Tops per prefix are flat (1.19k–1.33k), and certifying costs the same per prefix at every base (405–471 ns per prefix tried). So everything base-dependent in the cost per prefix sits in the scan.
- On the CPU the cost per prefix is ×1.6 / 1 / ×1.15 / ×3.1 relative to b60. That reproduces the GPU's ordering (×1.6 / 1 / ×1.33 / ×2.8).
- From b60 to b64 the CPU's cost per prefix rises by 7.6 ms:
  - 3.95 ms (52 %) is the survivor path: range test, prefilter and dispatch, at 32–41 ns per AND survivor;
  - 2.5 ms (33 %) is the ANDs (about 0.22 ns each);
  - 0.7 ms is full checks;
  - 0.3 ms is tops.
- So b64's 72–78 % "scan" share is mostly the survivors that the 4× ANDs produce, not the ANDs themselves. The ANDs are only 26–27 % of a b64 partition.

**What signature bucketing would save.**
- **Low digits as S.** Fixed S = {0..s−1} skips only 21–28 % (s=4), 28–34 % (s=6) and 38–42 % (s=8) of ANDs, depending on the field. It costs 3–11, 11–37 and 20–125 sub-bucket visits per (top, class), against classes of about 1k bottoms.
- **S from the top masks.** Choosing S per field from the top masks skips 56–62 % / 70–75 % / 75–81 % at s = 4 / 6 / 8, with 1.0–3.2 visits per (top, class). Weighting by bottom frequency adds 0–4 points.
- **Most of that is the field's certificate.** The most frequent top digits are the field's certificate: the 4–7 leading digits of n² and n³ shared by the whole field (7 at b64), which every top knows. So the bottoms that meet them can never pass an AND in the field.
- **The simpler rule.** Dropping those bottoms once per partition, for example by seeding the bottom side's collision test with the field certificate, skips 60 % (b60), 66 % (b58), 70 % (b62) and 79 % (b64) of ANDs, with no sub-buckets. The AND of the key's top masks adds up to 7 points where a field's tops cover only part of it. Averaged per base, bucketing at s = 8 skips 2 points (b64) to 15 points (b60) more than the prune.
- **The limit.** All of these skip only failing ANDs, so the survivor path, the biggest cost at b64, is unchanged.
- **The CPU saving.** At most about 7–12 % of a partition at b58–b62 and 20–23 % at b64.
- **The GPU saving.** It depends on the AND's share of the GPU's per-prefix time, which this run does not measure. If the kernel is AND-bound, the prune would remove up to 79 % of that work at b64.

## Not done / caveats

- No GPU measurement. The stage split above is the CPU's, and the GPU's AND share is unknown.
- The CPU's per-prefix ratios match the GPU's to within about 15 %. The worst miss is b62: ×1.15 on the CPU against ×1.33 on the GPU.
- Sub-bucket overhead is counted (visits), not timed.
- Timings are from a shared 4-vCPU VPS, 3 partitions at a time. Two rounds agree within ±5 %.
- I did not try making the survivor path cheaper. It costs 32–41 ns per AND survivor and is 45–47 % of a b64 partition. Its row data (`ext.idx`, `bp_r`, `p2`, `p3`) is read at random rows, which would explain the cost, but that is unmeasured.

## Files

- `partitions.csv`: one row per sampled partition, every count, time and simulation.
- `windows.csv`: per-field parameters, certificates and the chosen S.
- `popcount.csv`: pass rate by popcount.
- `digits.csv`: per-digit frequency in tops and bottoms (pre-pass).
- `tables.md`: everything `analyze.py` prints.
- `round2/`: the repeat run.
- `run.log`.
