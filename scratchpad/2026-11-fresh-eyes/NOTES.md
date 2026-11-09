# Fresh-eyes review, 2026-11-09 (new director session)

Working notes behind the 2026-11-09 handover report. Counts are from `mc_counts.py`
(Monte Carlo over admissible n of a base's range, simplified certificate = common leading
digits of a^j and e^j; outputs `mc_b60.txt`, `mc_b62.txt`, `mc_b64.txt`). Costs are
projections from the current kernel's measured shares, not measurements.

## 1. Where the odds are (existing model, `../2026-08-cost-probability/curve.json`)

| base | λ (expected nice numbers) | price at v3.4.6 | price on today's main (≈ ÷2.2–2.6) |
|---|---|---|---|
| 60 (25 % left) | 4.6e-4 (1.1e-4 left) | $206 | ≈ $20 left |
| 62 | 4.3e-4 | $983 | ≈ $380 |
| 64 | 8.5e-4 | $8.3K | ≈ $3.5K |
| 65 | 3.2e-4 | $1.0M stride / $27–49K join past 64 | ≈ $10–20K |
| 68, 69 | 3.1e-4, 2.9e-4 | $8M, $19M | — |
| 70 | 1.6e-3 | $150M | — |

λ per base has its minimum at b ≈ 55 (exponent b(ln b/5 − 1), derivative zero at ln b = 4)
and only reaches ~0.01 near b 100, ~1 near b 125–135. λ/cost depends on the base alone
(range width and root count cancel), falling ≈ ×0.45 per base. Everything reachable
(rest of 60, 62, 64, 65) sums to ≈ 0.19 %. A ×10 in compute or algorithm buys about one
more base. No lead in this file changes that order of magnitude.

## 2. Why no sub-exhaustive method is in sight (argument to be attacked, not a proof)

- Output digit p of n² (n³) is a function of n mod b^(p+1) and, from above, of n's
  leading digits down to p − L (p − 2L). Fixing a top prefix and a bottom suffix of n
  reveals at most 2 output digits per fixed digit of n; the middle ~L digits of n³ and the
  window around position L of n² are determined only by all of n. So every digit-local
  search reaches full n with ≈ 2L known digits and the other ≈ 3L arrive at once
  (success ≈ (3L)!/b^(3L) ≈ e^(−4.5L) per candidate).
- Lattice / Coppersmith prescription of a linear window (n = T + B: n² positions above 2|B|
  and n³ above L + 2|B| are affine in B) buys at most one prescribed output digit per free
  digit of n, against two for the tree. Net loss.
- Repetend families n = (r·b^k − e)/s make every digit block an orbit of ×b mod s² or s³;
  injective digit maps need s³ ≤ b while 2k distinct digits need s² > 0.4b: only b < 10.
- No further congruence invariant: b^r ± 1 saturate (closed 2026-08), symmetric functions
  of the digit multiset have no arithmetic handle beyond mod b − 1.
- Lesson from the Fable multi-agent write-up: agents misjudge hard problems as infeasible.
  So this gets one adversarial review (lead N5), not silence.

## 3. The join's macro shape (lead N1): the real compute lever

The join is fixed at t = L − 3 (f0 = 3), k = 6, p = 2 since Dan's CPU tuning on 1e14 b57
fields ("GPU-specific tuning has not been done"); the program since 10-28 optimised kernels
at that shape. Model: AND pairs = admissible n × P_T(f0) × P_B(k) × prune; survivors =
admissible × P_S(f0, k); lists must be built (tops W/b^f0 after the layer hierarchy, bottoms
b^k per rebuild).

b62, per admissible n (admissible = 3.13e20 for the base):

| | P_T | P_B | pairs (no prune) | pairs (prune at b^10 / b^9 block) | AND survivors |
|---|---|---|---|---|---|
| f0 3, k 6 (today) | 0.070 | 0.305 | 2.2e-2 | 1.0e-2 / 6.3e-3 | 2.0e-4 |
| f0 4, k 9 | 0.127 | 0.061 | 8.0e-3 | 2.4e-3 / 1.2e-3 | 2.7e-5 |
| f0 3, k 9 | 0.070 | 0.061 | 4.3e-3 | 1.3e-3 / 6.1e-4 | 1.3e-5 |
| f0 4, k 10 | 0.127 | 0.030 | 4.1e-3 | 1.1e-3 / 4.6e-4 | 6.7e-6 |

Calibration (b62 1e17 field, ~80 s on a 3080 on today's main): 8.9e10 tested tops
(0.21 ns), 2.6e13 pairs (≈ 0.8 ps incl. the per-wave base), 6.7e11 AND survivors (36 ps),
4e10 full checks. Shares: dense AND 26 %, survivor path 30 %, tops 23 %, check 12 %,
setup 5 %. The model reproduces the measured profile, including "68 % of (prefix,
partition) pairs fail" (P_T(3)/P_T(5) = 0.33).

Why k is stuck at 6: a contiguous field rebuilds every k-digit bottom per slice (b^k
candidates: 5.7e10 at k 6, 3.5e12 at k 7, against 4.2e11 tops per 1e17 field).
Deeper bottoms need the bottom list of a partition value to be shared by every top of the
base that has that partition value, i.e. a work unit keyed by the shared middle digits
("transversal" unit: π = digits [f0, k) of n, all leading digits) instead of a range of n.

Projection for (f0 4, k 9), units keyed by π (5 digits; 9.2e8 units of ≈ 1 ms):
pairs 2.5e18 for the base (the same count as today, the field prune is lost), survivors
÷7.6, checks ÷8+, tested tops ÷60, bottoms 1.5e15 cheap linear extensions. Whole base
≈ 35 % of today's time → **≈ ×3 (range ×2.5–4)**; b64 and b60 counts show the same ratios.
Side effects: per-unit memory is MBs (bottoms 9e5 × 16 B, tops 9e4 × 32 B), so the device
size limits, slices, and small-field fixed cost go away; top and check kernels stop
mattering; CPU and WebGPU get the same structure.

Not free:
- k 10 loses: its 2.5e16 materialised bottoms are ≈ 1 byte of DRAM traffic per AND pair
  saved (1.3 ps/byte at 760 GB/s against 0.3–0.8 ps/pair). Only an L2-resident parent
  bucket with children extended on the fly could beat that; device dependent; measure.
- The leading-block prune needs ≳ 300 certified tops per (block, π) group to pay for
  filtering the bottom list (≈ 3 free digits between block and π), which is exactly the
  digits k 9 spends. The current shape is a local optimum of that trade under contiguous
  fields. A bit-parallel prune (per-digit bitmaps over a π's bottoms) could recover part.
- Disjointness is thin over all 62 digits (0.3 % of pairs pass), so bucket or trie
  indexing of the AND saves < ×2; the flat bit-parallel AND stays.
- The server's unit of work changes (non-contiguous fields, or a virtual coordinate
  v(n) that orders n by π first so the server still sees ranges). User decision.

Kill criterion for N1: tile microbenchmark + exact small-base prototype project less than
×2 on a whole b62 base, or the count model is off by > 30 % against the prototype.

## 4. New threads (recorded for the ledger)

- N1 transversal join (above).
- N2 independent second pass (CL2) of the single-pass nice-only bases 50–60 as N1's
  shakedown workload; today ≈ $15–25 by the current join for b50–58. Exposure analysis
  first (client versions per field from the public API; Apple Metal miscompile #228,
  join flush race #222, the 2024 b47/48 import).
- N3 server work-unit design for N1 (virtual coordinate); proposal only.
- N4 report every lead as $/base at the frontier and Δλ; park kernel trims under ×1.10.
- N5 adversarial review of §2; near-miss structure mining on the detailed data
  (residues beyond b − 1, closeness of n/b^L to small rationals).
- N6 child-only top certificates (truncated FD on the certificate window) if f0 3 returns.
- N7 u64 chunks for the transposed AND on CUDA (the AND is ~70 % of the time after N1).
- N8 a browser WebGPU nice-only client becomes natural after N1 (MB-sized units).
