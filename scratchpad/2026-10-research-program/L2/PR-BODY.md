# Detailed mode: digit arrays by finite differences instead of division

Detailed mode records, for every n in a field, how many distinct base-b digits n² and n³ use together. On the CPU, `process_range_detailed` squares and cubes each n (in `u128` at base 40, in the hand-rolled `U256` above) and pulls every digit out with `% b` and `/ b` on a two- to four-limb value: at base 50 that is 50 digit extractions per number, each a chain of limb divisions, strictly serial. Over a run of consecutive n none of that is needed, because the square and cube follow from additions alone: with dS = 2n + 1, dC = 3n² + 3n + 1 and ddC = 6n + 6, stepping to n + 1 is S += dS, dS += 2, C += dC, dC += ddC, ddC += 6. This PR adds `common/src/detailed_fd.rs`, which keeps those five values as little-endian base-b digit arrays (one digit per byte, plus a length), seeds them once per chunk from the existing `U256` products, and steps them with five array additions per number. Each addition does eight digits per 64-bit add: biased addition as in BCD, where adding 256 − b to every addend byte makes a byte overflow into the next exactly when its digit sum reaches b, so the native add carries all eight digits and the bytes that did not carry take the bias back. Carries are arithmetic, not branches (an earlier digit-at-a-time version lost a factor of 3 to a branch LLVM made out of its carry select). The digit mask is then built from the significant digits of S and C and popcounted exactly as before. `process_range_detailed_fd` runs this loop at the bases the division path specialises (40–64 with a legal range, except 63) and sends every other base to `process_range_detailed`; the client's CPU chunk path in `process_field_sync` calls it, so claimed fields, `--validate` and `--benchmark` all take it. `process_range_detailed` itself is unchanged: it stays the reference for the tests and the GPU backends' small-range fallback.

Why the results are identical: everything is exact integer arithmetic. The seed is the same `U256` square and cube the division path computes, converted to digits once; each step is an exact base-b addition, so after k steps the arrays hold exactly (n+k)², (n+k)³ and the three differences. The biased add needs every digit below b, which its own output keeps true; the length is updated as max(len_a, len_b) plus one if the digit at that position is non-zero, since a sum has at most one more digit than its longer operand; every position at and above the length stays zero. The mask uses exactly the `len` significant digits of n² and n³, which are the digits the division loop emits (it stops when the quotient reaches zero), so `num_uniques`, the histogram and the near-miss list come out the same. Inside the legal ranges n³ needs at most 38 digits (base 64) and the arrays hold 72, so nothing can wrap; running out of room would panic on a slice bounds check. The tests below check this number by number against `get_num_unique_digits`, including every point where n² or n³ gains a digit.

## Measured

Intel Xeon E5-2682 v4 (Broadwell-EP, 2 × 16 cores, 2 threads per core, 2.5 GHz base, 3.0 GHz turbo), in a container with a CPU quota of 15.36 CPUs: `nproc` reports 64, `std::thread::available_parallelism` (what `--threads 0` uses) reports 15. Clocks are not capped (schedutil governor, `scaling_max_freq` 3.0 GHz, turbo on; busy cores sampled at 2.9–3.0 GHz). Rust 1.99.1, release profile, default features, no `target-cpu` flags. A is `main` (d1ff798), B is this branch, same box, interleaved A B A B A B, `nice_client detailed --benchmark --benchmark-secs 150 --threads T`. Rates in million numbers per second; spread is the lowest and highest round relative to the median.

`--threads 15` (one thread per CPU of the quota; the cgroup throttled for 8 ms in total over these six runs):

| scenario | threads | A rounds | A median (spread) | B rounds | B median (spread) | B / A |
|---|---|---|---|---|---|---|
| b40_detailed | 15 | 51.49 52.02 51.55 | 51.55 (−0.1/+0.9 %) | 287.95 287.38 291.51 | 287.95 (−0.2/+1.2 %) | **5.59×** |
| b50_detailed | 15 | 33.84 33.71 33.80 | 33.80 (−0.3/+0.1 %) | 272.39 271.04 271.09 | 271.09 (−0.0/+0.5 %) | **8.02×** |
| b50_detailed_1t | 1 | 2.22 2.24 2.21 | 2.22 (−0.8/+0.6 %) | 15.24 15.19 15.23 | 15.23 (−0.2/+0.1 %) | **6.85×** |
| detailed score | | 1247 1252 1244 | 1247 (−0.3/+0.4 %) | 8424 8396 8444 | 8424 (−0.3/+0.2 %) | **6.76×** |

`--threads 1`, once per tree:

| scenario | A | B | B / A |
|---|---|---|---|
| b40_detailed | 3.56 | 19.82 | **5.57×** |
| b50_detailed | 2.29 | 18.60 | **8.12×** |
| b50_detailed_1t | 2.23 | 15.18 | **6.80×** |
| detailed score | 209 | 1409 | **6.75×** |

`--threads 64` (`nproc`, four times the quota, so the cgroup throttles throughout and the threads share physical cores): A b40 41.95, b50 24.34; B b40 129.91, b50 125.45 (medians of three, every spread within ±2.4 %); **3.10×** and **5.15×**, score 1042 → 5000 (**4.80×**). Both trees lose to the oversubscription and the new loop loses more, likely because it gets less out of sharing a physical core with a hyperthread sibling. No scenario regresses at any thread count.

Per number, single thread pinned to one core, 1,000,000 numbers at the start of each base's range (at base 50 this is the `b50_detailed_1t` window), division and finite differences interleaved over three rounds, two passes; ns per number, median of three (`fd_timing`, ignored by default):

| base | pass | division | finite differences | × |
|---|---|---|---|---|
| 40 | 1 | 279.48 | 50.53 | **5.53** |
| 40 | 2 | 281.74 | 50.21 | **5.61** |
| 50 | 1 | 438.66 | 57.30 | **7.65** |
| 50 | 2 | 432.00 | 56.97 | **7.58** |
| 60 | 1 | 569.34 | 59.34 | **9.59** |
| 60 | 2 | 550.75 | 57.23 | **9.62** |

Every round is within −2.1/+3.8 % of its median. The new loop's cost barely grows with the base (the difference terms span the same number of 64-bit words at bases 50 and 60; only the mask gets longer), while the division loop's grows with the digit count. `b50_detailed_1t` gains less than the pinned timing of the same window (6.85× against 7.6×): the scenario takes 66 ns per number against 57 pinned for the new loop, and 450 against 435 for the old, so 9–15 ms more per 1M-number repetition on both trees, which weighs more once the loop is fast.

## Exactness

All in `common/src/detailed_fd.rs`; the whole `nice_common` suite passes on the box above (180 passed, 5 ignored, release).

- `fd_matches_division_b{40,50,60}_random_windows`: `num_uniques` number by number against `get_num_unique_digits` on 20 seeded random windows of 10,000 across the legal range plus its first and last 10,000 (220,000 numbers per base).
- `fd_matches_division_other_bases_random_windows`: the same at bases 42, 47, 53, 59 and 64.
- `fd_matches_division_b{40,50,60}_digit_gains`: 10,000-number windows centred on every n where n² or n³ gains a digit (the smallest n with n^r ≥ b^m, by exact integer root), from a factor b below the range start up to the range end, including both ends of the range.
- `fd_matches_division_small_base_from_zero`: base 10 for n = 0..200,000 and base 7 for n = 0..50,000: the zero start, hundreds of digit gains in all five arrays, and addends longer than the value they are added to.
- `fd_field_results_match_detailed_benchmark_windows`: whole `FieldResults` (distribution and near-miss list) through `process_range_detailed_fd` equal to `process_range_detailed` on the `b40_detailed` and `b50_detailed` windows (2,000,000 numbers each).
- `fd_field_results_match_small_bases_full_range`: those windows hold no near-misses, so the list is checked here: the whole range of every base from 10 to 24 that has one (12 bases, 2.24 million numbers, 27 near-misses), identical.
- `dispatch_uses_finite_differences_where_supported`: bases 40 and 50 take the new loop, as does every base from 40 to 64 with a legal range except 63; base 10 stays on the division loop and gives its results.
- `fd_timing` (ignored): the timing above; it also asserts equal `FieldResults` on every timed window.

## Not in this PR

- The GPU detailed kernels (CUDA and `CubeCL`): they still divide per number.
- SIMD: the mask build and `count_ones()` stay baseline x86-64 (no AVX2 or POPCNT dispatch).
- Bases below 40, 63 and above 64: they stay on the division loop.
- The WASM browser client: it still calls `process_range_detailed`.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
