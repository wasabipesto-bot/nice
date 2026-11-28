# CX: can a second nice number be constructed instead of searched for? (director, 2026-11-18, no hardware)

Closed by argument the same morning. No agent, no prototype. `ecount.py` / `ecount.txt` hold the one computation.


**Correction, 2026-11-28 (EXPERIMENTS.md YIELD.2):** `ecount.py` leaves out the residue factor R_b of the published
odds model; with it the running total passes 1 between bases 110 and 120, not 125–128. The argument of this note
(search cost grows far faster than the odds) does not depend on that.

## Where a second nice number is expected [computed, uniform heuristic]

Expected nice numbers in base b = (count of n whose square and cube have b digits together) × b!/b^b, for the
bases that have a range (b ≢ 1 mod 5) and a root class. The residue filter moves candidates between classes and
leaves the total unchanged.

| bases | expected nice numbers |
|---|---|
| 11–60 (searched: none found) | 0.033 |
| 62, 64, 65 | 2.2e-4, 1.2e-4, 3.3e-4 |
| 11–100 | 0.061 |
| 11–120 | 0.44 |
| 11–128 | 1.2 (the running total passes 1 between bases 125 and 128) |
| 140 alone | 4.7 |
| 160 alone | 290 |
| 200 alone | 4.5 million (among 1e92 candidates) |

The per-base expectation has its minimum near base 55 (d/db of (b/5) ln b − b is zero at b = e^4) and grows
without bound after about base 130: heuristically there are infinitely many nice numbers and the second one sits
near base 125–130, where a base has about 1e52–1e55 candidates. The density is e^(−b) √(2πb) at every base, so
plenty does not mean findable: exhaustive search reaches base 64–65.

## Why construction fails (argument, not experiment)

1. **Generic n: no locality.** Changing digit i of n rewrites digits i … i+L of n² and i … i+2L of n³ (3L + 2 of
   the 5L output digits), wherever i is. Fixing digits of n from the two ends controls 2 output digits per digit
   of n (BX); the other 3L are a uniform lottery given the ends (BX: 7e9 candidates). Local search, annealing and
   prescribe-and-solve are that lottery under another name; at base 140 it needs about 1e54 clean-ended n.
2. **Carry-free polynomial n** (digits a_i small, n² and n³ digit strings = coefficients of A² and A³): the digit
   sum is then exactly s² + s³ with s = A(1), so s²(s + 1) = b(b − 1)/2, an elliptic curve; s ≤ 2,000,000 gives only
   (s, b) = (3, 9) [checked by script]. And the cube's middle coefficients force s ≲ (b²/5)^(1/3), which leaves the square's
   coefficients too small to be 2L distinct digits. Carries are unavoidable and bring the lottery back.
3. **Rational-type n** (n ≈ P·b^L/Q with Q | b − 1, e.g. near-repdigits p·R_L + κ): the digits are explicit. The
   expansion of P/(b−1)² is an arithmetic progression mod b − 1 (digit = u + [u ≥ m − P₀], u = P₁ + (i−1)P₀ mod m,
   m = b − 1), so n² can be given 2L − 1 distinct digits by design (bottom and top halves made one progression by
   the last digit κ' = pL/2). But n³'s digits are then quadratic in the position (p³·T_j at the top, p³[T + (3L/2)·
   linear + 3L²/4] at the bottom, mixed in the middle), and niceness needs those 3L quadratic values to be exactly
   the complementary run of the progression. Value sets of quadratics mod m are not runs of an arithmetic
   progression; the three thirds of n³ follow different quadratics; the family has only about b² members per base.
   Making n³ linear instead needs p³ ≡ 0 with p² a unit mod b − 1: impossible. Denominators (b−1)^(3/2) (b − 1 a
   square) make n² quadratic and n³ quartic: two different permutation polynomials with no reason to be
   complementary.
4. **The record agrees.** Every base to 60 is searched exhaustively and holds only 69. A family built on simple
   algebraic structure would have had small members.

Verdict: dead. A constructive route would need digit control of n² and n³ at once from one free parameter set,
and squares and cubes of the same n follow polynomial laws of different degree. What exhaustive search certifies
(bases to 64–65 empty) is the project's reachable output; the join redesign (G2) decides how fast.
