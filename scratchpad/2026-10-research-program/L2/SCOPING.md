# L2 scoping: detailed mode by finite differences (2026-10-28, director)

## What detailed mode does today (from the code map, `common/src/client_process.rs`)

Per number: `n²` and `n³` recomputed by multiplication (u128 at b40, hand-rolled U256 at
b42–64), then every digit extracted by `n % b; n /= b` on a 2–3 limb value (two native
64-bit divisions per limb per digit, base a compile-time constant), OR-ed into a 64-bit
presence mask, `count_ones()` into a histogram. At b50 that is about 50 digit steps and
60–90 limb divisions per number, strictly serial. Reference rates: b50_detailed 1.7e7/s
(CPU, all threads), 2.8e6/s single thread ≈ 1,200 cycles per number; GPU b50_detailed
1.5e9/s. No incremental trick, no SIMD in this path. April 2026 tried a fixed iteration
count (−58 %) and b²-radix extraction (+2–5 %), nothing else.

## The idea

Consecutive `n` in a chunk: keep base-b digit arrays and update them by addition only.

```
S  = n²          S  += dS      dS = 2n+1      dS += 2
C  = n³          C  += dC      dC = 3n²+3n+1  dC += ddC     ddC = 6n+6   ddC += 6
```

Digit-array addition is add, compare with b, conditional subtract, carry. Addend
lengths at b50: dS ≈ 10 digits, dC ≈ 20, ddC ≈ 10; S has 20 digits, C 30. About 40
digit-adds per number, in two or three independent carry chains, no division anywhere.
Leading zeros: track the top position of each array (it only grows).

Uniqueness: rebuild the 64-bit mask from the ~50 digits (shift and OR; with AVX-512
`vpsllvq` eight digits per instruction) and `popcnt`. Or maintain per-digit counts and a
distinct counter from the changed positions (~30 per step).

Estimate: scalar 120–200 cycles per number against about 1,200 today, so **3–8× on
b40/b50_detailed single-thread**; the multi-thread scenario scales the same way. The
estimate is from operation counts, not a measurement; the April −58 % surprise says to
measure before believing it.

Exactness: integer arithmetic throughout. Verify `num_uniques` per number against
`get_num_unique_digits` on random windows at b40, b50, b60, including windows where n²
or n³ gains a digit, and the whole-range histogram on a benchmark window.

## Why it may matter beyond the CPU benchmark

Production detailed work is on GPUs (fleet $10/month, Anvil). The GPU kernel also
extracts digits by division per number per thread (to be confirmed by the L3 notes).
A per-thread run of consecutive numbers with digit arrays in registers would remove the
128/256-bit divisions there too. If the CPU prototype confirms the factor, the GPU port
is the real prize and gets its own scoping.

## Plan

1. CPU prototype in a worktree: `get_num_unique_digits` replacement for a chunk, scalar
   first, behind a function, with the exactness tests above. Measure with the
   `b50_detailed_1t` scenario (same box, interleaved, 3 rounds). Budget: one agent-day.
2. If ≥ 2×: SIMD the digit-array adds and the mask build; measure again; then PR
   (b40/b50_detailed are existing benchmarks, so the merge bar is the 5 % protocol).
3. If < 1.3× scalar: close with the numbers.

Kill criterion: scalar prototype under 1.3× on `b50_detailed_1t`.
