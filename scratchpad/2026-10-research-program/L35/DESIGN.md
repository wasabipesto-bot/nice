# L35 design: the top kernel stepping partitions by finite differences (2026-11-02)

Base: fork `exp/join-all3` (0f1a8a7 = main 04693ac + #235 + #236 + #237). Work branch `exp/top-fd`.
Switch: `NICE_EXP_TOP_FD=1` read in `JoinDevice::new` → `launch_batch` launches `top_fd_kernel`
instead of `top_kernel`; everything after the top stage is unchanged. One binary does A/B.

## Observation that shapes the state

A top block is a = P·W, e = a + W − 1 with W = w = b^f0 (`FieldSetup::w`, f0 = L − t). So for an
unclipped block a² = P²·b^(2f0) and a³ = P³·b^(3f0): the digits of a^k are the digits of P^k shifted
up by z_k = k·f0, with zeros below. Stepping v → v+1 steps P → P+1, which is exactly the detailed-FD
recurrence of #221/#225 with n = P:

    SQ = P², DS = 2P+1, CU = P³, DC = 3P²+3P+1, DDC = 6P+6
    step: SQ += DS; DS += 2; CU += DC; DC += DDC; DDC += 6

No shifted increments are needed, the arrays are short (P has t digits, not L: at b62 1e17
t = 9, so SQ ≤ 17 digits, CU ≤ 25 instead of 25 / 37), and the step reuses the GPU FD's packed
form and adder (`cubecl_detailed_fd::fd_add_top`: 4 digits per u32, 8-bit lanes, biased add,
needs b ≤ 128). f0 and q = t are made comptime so every digit position is a comptime index.

## State layout (registers, per thread)

| array | holds | digits (capacity) | words at b62 1e17 |
|---|---|---|---|
| SQ | P² | q2 = s2 − 2f0 | 5 |
| CU | P³ | q3 = s3 − 3f0 | 7 |
| DS, DDC | 2P+1, 6P+6 | t + 1 | 3, 3 |
| DC | 3P²+3P+1 | q2 + 1 | 5 |

≈ 23 u32. Bounds: an unclipped block has s ≤ a ≤ e−1 so a^k < b^(s_k) and P^k < b^(q_k); the
state only ever holds a P whose own block is unclipped and in range (stepped onto, never past), so
no array can overflow. Host checks the width relations (DS fits SQ, DC fits CU) and falls back to
the old kernel if any fails.

## Kernel (`top_fd_kernel`)

Grid x over top-layer prefixes only (`CubeCount::Static(top_cubes, 1, 1)`); each thread loops over
the batch's slots in order. Per slot j: p = P0·pdiv + vs[j]; out of [plo, phi] → skip (state
invalid). Compute a, e and the clipping exactly as now. Clipped → the existing `top_cert` (division
path), state invalid. Unclipped → if the state is valid and vs[j] = vs[j−1] + 1, step it; else seed it
(below). Then the FD certificate. Outputs, `top_count[slot]` / `bucket_cnt` atomics, the floor rule
and the bucket loop are the current kernel's code; `cube_done(ran, 0)` once per cube, so
`expect[0]` = top_cubes (not × nslots).

**Seed** (first slot, after a gap or a clipped/out-of-range slot): P, P², P³ in 16-bit limbs by
schoolbook from P (< 2^64), each converted to packed digits by split16 long division with
#237's limb trim (the value is below b^q, so before pass i only pow_limbs16(b, q − i·cd) limbs can be
nonzero) and the Apple-safe first step (top two stored limbs as one u32). Then in digits:
DS = 2·P + 1, DDC = 6·(P + 1), DC = 3·(P² + P) + 1 by biased adds. About 0.7 of today's per-slot
division (q2 + q3 = 42 digits instead of s2 + s3 = 62 at b62 1e17).

## Where the certificate read-off plugs in (`cert_power_fd`)

Same contract as `cert_power`; only the digit source changes. d = e^k − a^k still comes from
`powers_diff` in binary (a³ is not formed: comptime flag), so c0 = max(cap, ndig_fast(d)) is
unchanged. The scan reads a digit at position pos as 0 for pos < z_k and Q[pos − z_k] (comptime lane
extract) above, so no `% b` / `/ b` and no long division; the run / dup / runc / dupc / dlo logic,
x mod b^c0 and #235's carry test (x mod b^c0) + d ≥ b^c0 keep their meaning. If c0 < z_k (cannot
happen for P ≥ 1: d2 ≥ W², d3 ≥ W³) the slot falls back to `top_cert`.

## Gaps

Production batches are consecutive (`run_pass` chunks 0..nparts); a test's thinned partitions and
the overflow re-runs are not. Any vs[j] ≠ vs[j−1] + 1 re-seeds; the common production case is a
step of exactly one. Field ends (clipped a or e, P outside [plo, phi]) take the division path.

## Exactness test

`cubecl_cuda_top_fd_matches_the_top_kernel`: on production-shaped fields (b57 frontier, b60, b62,
b64; 1e14 and 1e16 plans, first and last slices so that both ends clip), for consecutive batches,
the last partitions, thinned / out-of-order batches (gaps, a backwards step), it launches both
top kernels on the same `JoinDevice` and batch and asserts per slot: `top_count`, every
`bucket_cnt`, and the sorted list of (top_p, top_m, top_r, top_x, top_b) entries equal. Then the
join parity tests and the dense fields with `NICE_EXP_TOP_FD=1`, the 1e14 COMPARE runs
(deterministic counts) against the base, and lavapipe naga + direct SPIR-V.

## Not done here (noted for RESULTS)

Persisting the state across batches (≈ 23 u32 per prefix ≈ 260 MB at b62 1e17) would remove the
seed; d2/d3 could also be stepped in binary (d2 += 2δW, d3 += Δ3, Δ3 += 6δW²) to drop `powers_diff`.

## As built (changes from the plan above, in the order they were made; RESULTS.md has the numbers)

1. **Clipped blocks leave the FD kernel.** Only P = plo and P = phi can clip (a < s needs P·w < s,
   e > e−1 needs P = phi), i.e. one partition value each per slice. `top_fd_kernel` skips them;
   `top_kernel` gained a comptime `only_clipped` and is launched beside it, on the normal grid, only
   for batches holding one of those two partition values (`JoinDevice::clip_vs`, `top_fix`,
   `top_expect`). Dropping the division path from the FD kernel took it from 128 to 95 registers.
2. **c0 < z handled in `cert_power_fd`, not by fallback.** The zero digits at c0..z are put into the
   run before the scan (the first ends x's run of (b − 1)s with digit 0, the rest lie above it), so the
   FD kernel has no division path at all. (Never reached in practice; exact by construction.)
3. **The scan walks Q's packed words** (4 digits per remainder update, x mod b^c0 in u32 words with
   u64 products; nothing divides it), and the repeat flags come from popcounts: a mask over n
   positions has a repeat iff it has fewer than n bits; the end of the (b − 1)-run is kept as a
   position, so dupc = popcount(runc) ≠ (sp − 1 − qend).
4. **Mode 2 (`NICE_EXP_TOP_FD=2`) steps d2 and d3 in binary too**: d2 += 2wδ, d3 += Δ3,
   Δ3 += 6w²δ (δ = w − 1; Δ3 seeded as 3wδ·(2a + 2w − 1)), so a stepped slot runs no
   `powers_diff`. Mode 1 keeps `powers_diff` per slot (fewer registers: 80 vs 109).
5. **Plane-aggregated append.** `top_kernel`'s `top_count[slot]` atomic is warp-aggregated by the
   compiler (VOTEU.ANY + one ATOMG) because its slot is the cube's y; in the FD kernel the slot is a
   loop counter and every kept lane did its own same-address atomic, which capped the kernel.
   Every unit now runs the slot loop (a `live` flag instead of `if i < ntlay`), and kept tops are
   appended with plane_sum / plane_exclusive_sum / one fetch_add per plane / plane_broadcast.
6. **Timing-only knobs**: `NICE_EXP_TOP_FD_ABL` (comptime bitmask dropping parts of the FD kernel;
   its tops are wrong when set) and the `cubecl_cuda_top_fd_timing` test (`NICE_TEST_TOPFD_TIMING`,
   `NICE_TEST_TOPFD_BATCHES`, `NICE_TEST_TOPFD_SLOTS`).
7. **After the A/B** (`2111f09`, `6c8db87`; RESULTS §7):
   - FD stays off at power-of-two bases. At b64 the top kernel's division is shifts, and FD measured
     ×0.985.
   - Top layers below 2^17 prefixes split the batch's slots into groups along y, each seeding once
     (`NICE_EXP_TOP_FD_MIN_UNITS`).
   - Each FD `JoinDevice` runs its top stage once on its first clipped partition, so the
     `only_clipped` kernel compiles at setup, not inside a timed batch.
