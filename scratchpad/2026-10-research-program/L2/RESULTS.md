# L2 results: detailed mode by finite differences (2026-10-29)

**Verdict: PROCEED.** On the `b50_detailed_1t` window (base-50 range start,
1,000,000 numbers, one thread, one pinned core) the scalar finite-difference loop
is **5.6×** the current division loop, and **8.5×** with word-parallel digit adds.
Kill criterion was < 1.3×. Every comparison is exact (per-number `num_uniques`
and whole `FieldResults`).

Branch `rp/l2-finite-diff` on `fork` (wasabipesto-bot/nice), two commits on
origin/main 2709d3f:

- `b003967`: scalar prototype, digit-serial adds ("fd-bytes")
- `da9aaeb`: word-parallel adds, 8 digits per 64-bit add ("fd-words"); both variants
  stay selectable so the timing test measures them side by side

Code: `common/src/detailed_fd.rs` (new module, registered in `common/src/lib.rs`).
It is a function only, not wired into the client.

## Method

`process_range_detailed_fd(range, base)` has the same signature and output as
`process_range_detailed`. It dispatches the same const-generic bases (40, 42–45,
47–50, 52–55, 57–60, 62, 64) to `run::<BASE, SWAR>` and sends every other base to
the old function.

- State: base-b digit arrays (one `u8` per digit, little-endian, `[u8; 72]`) for
  S = n², dS = 2n+1, C = n³, dC = 3n²+3n+1, ddC = 6n+6, each with a length (the
  position past the top non-zero digit; everything at and above it is zero).
- Seed: once per range, from the existing exact `U256` arithmetic
  (`mul_u128_u128`, `mul_u128_truncating`, `div_assign_rem_u32_const`).
  dC is computed as 3·n(n+1) | 1.
- Step: S += dS; dS += 2; C += dC; dC += ddC; ddC += 6.
- `num_uniques`: OR `1 << d` over the `len` digits of S and C, then
  `count_ones()`. This is the same mask as today, and the length means
  leading zeros never enter it.
- Digit growth: a carry past the top digit extends `len`. An addend longer than
  the accumulator is handled too (needed from n = 0 in the small-base tests).
  Inside a legal range n² and n³ never gain a digit (every b mod 5 class checks
  out from the range formulas), but dS, dC and ddC do.
- fd-bytes add: add, compare with b, conditional subtract, carry, one digit at a time.
- fd-words add: biased-byte addition, BCD-style. Add 256−b to each addend byte,
  so a byte overflows into the next exactly when its digit sum reaches b. The
  native 64-bit add (with carry between words) then carries all 8 digits at
  once. Bytes with no carry-out (read from `(t ^ a ^ rb) >> 8`) get the bias
  subtracted back. The word above the addend's top word always takes the
  carry. Only a carry out of that word branches, and that needs 8 digits of
  b−1. Length update: the sum has at most one more digit than the longer
  operand, so `len = max + (d[max] != 0)`.

### The first build was 3× slower than it needed to be

The first version wrote the digit carry as `if t >= b { t - b } else { t }`.
LLVM's x86 cmov converter turned that into a **branch**, and the branch goes
the wrong way about half the time. perf counted about 17.5 branch misses per
number (157 M misses over the run; the old path alone has 0.04 per number).
Measured at that stage: b40 1.57×, b50 2.12×, b60 2.21×. Rewriting it as
`std::hint::select_unpredictable` (a cmov) and applying the carry out of the
top addend digit unconditionally brought misses to ≈0 and gave the fd-bytes
numbers below. The GPU port should watch for the same thing (data-dependent
selects).

## Commands

```sh
cd /home/claude/projects/nice && git fetch -q origin main
git worktree add .worktrees/rp-l2 origin/main -b rp/l2-finite-diff
cd .worktrees/rp-l2
export CARGO_TARGET_DIR=/home/claude/projects/nice/.worktrees/rp-l1/target
df -h /   # 3.6 G before the first build (malachite 0.12→0.14 rebuilt), 1.6 G after
# exactness (11 tests)
nice -n 19 cargo test --release -p nice_common -j 3 --lib detailed_fd -- --test-threads 3 --nocapture
# timing (ignored test), core 3 pinned
nice -n 19 taskset -c 3 cargo test --release -p nice_common -j 3 --lib detailed_fd::tests::fd_timing \
  -- --ignored --nocapture --test-threads 1
# per-variant counters, b50 only
B=$CARGO_TARGET_DIR/release/deps/nice_common-<hash>
FD_TIMING_BASE=50 FD_TIMING_ONLY=old|bytes|words nice -n 19 taskset -c 3 \
  perf stat -e cycles,instructions,branches,branch-misses $B detailed_fd::tests::fd_timing --ignored --test-threads 1
# lint / regression
nice -n 19 cargo clippy -p nice_common -j 3 --release --all-targets   # clean
nice -n 19 cargo test --release -p nice_common -j 3 --lib -- --test-threads 3   # 179 passed, 5 ignored
```

Toolchain 1.99.1 (repo pin), release profile (LTO, 1 CGU), no target-cpu
flags. The repo's builds set none either (no `RUSTFLAGS` or `target-cpu` in
`.github/`, `justfile` or `client/`), so this is the production codegen:
baseline x86-64 with no POPCNT and no BMI2. ivory is an AMD EPYC-Rome (Zen 2)
VM with 4 cores and an effective clock of ≈3.24 GHz under perf. The machine
was idle (load < 1).

## Exactness evidence (all pass, both variants unless noted)

| test | what |
|---|---|
| `fd_matches_division_b{40,50,60}_random_windows` | per number vs `get_num_unique_digits`: 20 seeded random windows × 10,000 across the legal range plus the first and last 10,000 (220,000 numbers per base) |
| `fd_matches_division_other_bases_random_windows` | same at b42, b47, b53, b59, b64 |
| `fd_matches_division_b{40,50,60}_digit_gains` | 10,000-number windows centred on every n where n² or n³ gains a digit, from a factor b below the range start up to the range end (the smallest n with n^r ≥ b^m, via malachite `ceiling_root`). That is 7 windows per base, including the range start (n³ gains) and the range end (both gain) |
| `fd_matches_division_small_base_from_zero` | b10 n = 0..200,000 and b7 n = 0..50,000: hundreds of digit gains in all five arrays, the zero start, an addend longer than the accumulator |
| `fd_field_results_match_detailed_benchmark_windows` | whole `FieldResults` (distribution and near-miss list) equal to `process_range_detailed` on the `b40_detailed` and `b50_detailed` windows (range start, 2,000,000 numbers), both variants |
| `fd_field_results_match_small_bases_full_range` | the benchmark windows hold 0 near-misses, so the list is checked here: the full range of every base 10–24 (12 bases, 2.24 M numbers, **27 near-misses**), identical |
| `fd_falls_through_for_other_bases` | b10 through the public function equals the old one |

The timing test also asserts that old, bytes and words give identical `FieldResults` on every timed window.

## Timing

ns per number, single thread, `taskset -c 3`, 1,000,000-number window at each
base's range start (at b50 this is exactly the `b50_detailed_1t` window). Each
pass interleaves old, bytes, words three times. Two passes at `da9aaeb`.
Ratio = median old ÷ median fd.

| base | pass | old (rounds) | med | fd-bytes (rounds) | med | ×  | fd-words (rounds) | med | × |
|---|---|---|---|---|---|---|---|---|---|
| 40 | 1 | 264.33 264.71 264.69 | 264.69 | 60.28 59.91 61.21 | 60.28 | **4.39** | 42.95 42.59 41.65 | 42.59 | **6.21** |
| 40 | 2 | 265.24 265.26 265.82 | 265.26 | 59.82 60.67 59.60 | 59.82 | **4.43** | 42.10 41.30 43.85 | 42.10 | **6.30** |
| 50 | 1 | 414.19 415.84 419.98 | 415.84 | 75.30 73.03 73.10 | 73.10 | **5.69** | 52.14 47.21 48.16 | 48.16 | **8.64** |
| 50 | 2 | 415.53 417.94 420.32 | 417.94 | 73.48 74.22 84.14 | 74.22 | **5.63** | 49.25 49.90 46.75 | 49.25 | **8.49** |
| 60 | 1 | 540.67 537.71 543.35 | 540.67 | 87.00 88.75 89.28 | 88.75 | **6.09** | 49.88 49.63 51.27 | 49.88 | **10.84** |
| 60 | 2 | 537.43 545.82 537.10 | 537.43 | 89.76 88.59 89.40 | 89.40 | **6.01** | 62.67 50.98 53.30 | 53.30 | **10.08** |

Spread: old within ±1 % in every cell. fd-bytes within ±2 % except one
84.14 outlier at b50. fd-words within about ±5 % except one 62.67 at b60.
The scalar-only run at `b003967` (old/fd-bytes, 3 rounds) gave the same
picture: 4.41× / 5.27× / 5.86×. As rates at b50 on one core: old 2.4 M/s,
fd-bytes 13.5 M/s, fd-words 20.3 M/s. The scoping doc's reference is
2.8 M/s single thread on another machine.

Hardware counters, b50, 3 × 1 M numbers per variant (per number; includes process start, negligible):

| variant | cycles | instructions | IPC | branch misses |
|---|---|---|---|---|
| old | 1,390 | 2,592 | 1.86 | 0.04 |
| fd-bytes | 244 | 708 | 2.91 | 0.03 |
| fd-words | 163 | 568 | 3.49 | 0.01 |
| (first build, branchy carry) | ≈640 | — | 1.57 (whole run) | ≈17.5 |

The scoping estimate was 120–200 cycles scalar. fd-bytes came in at 244 and
fd-words at 163.

## What limits the speed-up

- **fd-bytes: instruction throughput on the digit adds.** About 43 digit-adds
  per number at b50 (dS 10–11, dC 20–21, ddC 10–11, plus the two constants), at
  about 8 instructions each after LLVM's sbb carry fold. That is ≈70 % of the
  samples. Mask build ≈20 %, popcount and histogram ≈8 %. There are no misses
  and IPC is 2.9, so this is instruction count, not latency: the three carry
  chains (S, C, dC) overlap.
- **fd-words: now about 30 % mask build, 13 % popcount + histogram, 57 % adds and bookkeeping**
  (673 perf samples at b50). Total instructions fell from 708 to 568 per
  number; the compiler unrolls the 2–3 word add loop. The mask build is unchanged: 50 byte loads plus `bts` per
  number at b50, which is ≈125 instructions and the largest single block left.
  `count_ones()` compiles to a 17-instruction software popcount, because
  baseline x86-64 has no POPCNT (the old path pays the same). The `u128`
  histogram increment is a load-add-adc-store on a bin that consecutive
  numbers often share. It is cheap at 160 cycles per number but would matter
  below ~30.
- fd-words is nearly flat from b50 to b60 (48 → 50 ns), because both need the same
  word counts for the addends (dS/ddC 2 words, dC 3 words at both bases). Only the mask grows (50 → 60 digits).
- Seeding costs one `U256` square and cube plus about 100 digit extractions,
  a few µs, once per range. The client's detailed chunks are at least 1 M
  numbers (`client/src/main.rs` ~811), so it does not matter on CPU. On a GPU,
  the per-thread run length must amortise it (see below).

## Not done

- Incremental mask: not tried. The brief allowed one cheap improvement, and I
  spent it on word-parallel adds instead of the two named options, because
  the fd-bytes profile showed the adds at ~70 % and the mask at ~20 %. The
  incremental mask would cache the mask of the S and C digits above the
  addend's top word, which change only on a rare ripple. That is 18 of 50
  mask digits at b50, an estimated ≈10 % overall.
- No multi-thread measurement (b40/b50_detailed at full threads), no `nice benchmark` run (the
  function is not wired into the client), no SIMD.

## Next steps

1. **PR candidate (CPU):** call `process_range_detailed_fd` from the client's
   detailed path (`client/src/main.rs:845`). Check whether the WASM/web
   client's CPU detailed path should switch too; u64 is native on wasm32.
   Then run the 5 % protocol on `b40_detailed`, `b50_detailed` and
   `b50_detailed_1t`. Expect about 6× / 8.5× / 8.5× if the multi-thread
   scenarios scale like single thread; the state is ≈400 bytes per thread, so
   they should. Tidy-ups before review: drop the fd-bytes variant (or keep it
   test-only), and decide whether the timing test and its env knobs stay.
2. **GPU port (the prize, separate scoping):** each thread walks a run of
   consecutive n with the digit arrays in registers. Use 32-bit words with 4
   digits each for the biased add. At b50, S, C, dS, dC and ddC need ≈24 u32
   registers. Seed per run with the existing division code, sized so a run
   of ≥ ~100 numbers amortises the seed. Make the carry select explicitly
   branch-free (see the cmov-converter lesson above). The mask build and
   popcount will dominate there, as on the CPU.
3. **CPU SIMD (only if the PR lands and more is wanted):** the mask build via AVX2 `vpsllvq`
   (Zen 2 has AVX2; needs runtime dispatch, since production is baseline x86-64), and POPCNT
   by runtime detection, which would also help the old path and niceonly. The incremental
   high-digit mask cache is the scalar alternative.
