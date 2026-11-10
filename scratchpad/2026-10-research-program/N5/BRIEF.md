# N5 brief: break the no-shortcut argument, or tighten it (2026-11-10)

You are a mathematician and algorithm designer reviewing one claim for the nice research
program. No code is required; small scripts to test an idea are welcome (python3, `nice -n 19`,
no more than ~10 CPU-minutes each). Work alone: no subagents, no web canvass beyond checking a
specific known result.

## The problem

Fix a base b. A positive integer n is *nice* if the base-b digits of n² and of n³, taken
together, are a permutation of {0, …, b−1}: b digits in all, each exactly once. The only known
one is 69 in base 10 (69² = 4761, 69³ = 328509). For a base the candidates are the n whose
square and cube have b digits together: an interval of width ≈ b^(b/5)·c. Write L for the digit
length of n (L = 13 at b = 62; n² has 25 digits, n³ has 37).

Heuristically (digits behave like independent uniform draws, corrected for the leading and
trailing digits; validated against the search's near-miss counts to a few percent) the expected
number of nice n in base b is ≈ width × b!/b^b × R_b, where R_b is the number of roots of
x² + x³ ≡ b(b−1)/2 (mod b−1) (digit sums: the one exact congruence known). It is ≈ 4e-4 per
base around b = 60, has its minimum near b = 55, and passes 1 only near b ≈ 125–135. Exhaustive
search has covered every base below 60 and found nothing after 69.

## What the search does

- Residue filter: n mod (b−1) must be one of the R_b roots (2 of 61 at b = 62).
- Top prefixes: the top t digits of n fix the leading digits of n² and n³ (those common to
  every n of the block); a prefix whose known digits repeat is dropped.
- Bottom residues: n mod b^k fixes the low k digits of n² and n³ exactly; a residue whose
  known digits repeat is dropped.
- The "overlap join": the two lists share some digits of n; a (prefix, residue) pair that
  agrees on them is one n; one 64-bit AND tests that the top's digit set and the bottom's are
  disjoint. Pairs that pass get a cheap check of a few more digits, then a full check.
- At b = 62 a pair knows ≈ 29–35 of the 62 output digits. Cost per base ≈ (admissible n) ×
  P(top ok) × P(bottom ok) bit-parallel ANDs (≈ 2.5e18 at b = 62) plus list building.
  Each further base costs ×10–100 more; the reachable bases (62, 64, 65) sum to ≈ 0.2 % odds.

## The argument to attack (the director's; it is an argument, not a proof)

1. Digit p of n² (of n³) is a function of n mod b^(p+1); from above it is fixed by the leading
   digits of n down to about position p − L (p − 2L). So fixing a top prefix and a bottom suffix
   of n reveals at most 2 output digits per fixed digit of n, and the remaining ≈ 3L output
   digits (the middle L of n³ and the window around position L of n²) are determined only by
   all of n. Every digit-local search therefore reaches full n with ≈ 2L known digits, and the
   other ≈ 3L arrive at once: success ≈ (3L)!/b^(3L) ≈ e^(−4.5L) per candidate.
2. With n = T + B (T the top part, B < b^c), the digits of n² above position 2c and of n³ above
   L + 2c are affine in B, so a lattice / Coppersmith-style method can prescribe a window of
   them and solve for B. But it buys one prescribed output digit per free digit of n, against
   two for the tree, so it is a net loss.
3. Families n = (r·b^k − e)/s make every digit block of n² and n³ an orbit of multiplication by
   b mod s² or s³; distinct digits need injective digit maps (s³ ≤ b) and long orbits
   (s² > 0.4b): only b < 10.
4. No further congruence: b^r ± 1 saturate (every residue attainable, checked exactly for
   b 10–20, r 2–3); symmetric functions of the digit multiset have no arithmetic handle
   beyond mod b−1.
5. The disjointness join itself: only ≈ 0.3 % of pairs pass and the agreement is spread thinly
   over all digits, so bucket or trie indexing saves less than ×2 over the flat bit-parallel AND.

Earlier work closed, with evidence: carry-state automata / CP-SAT (states do not collapse),
Hall-type subdivision of interval digit domains (negative on whole fields), Swaenepoel-type
prescribed-digit theorems (no admissible budget at these lengths), Bassily–Kátai / Drmota
interior-digit results (non-effective).

## What I want from you

Agents and people both tend to declare hard problems infeasible too early. Assume the argument
above has a hole and look for it. Specifically:

- **A.** Is step 1 right that nothing about the ≈ 3L middle digits is available before all of n
  is fixed? Consider: the bilinear structure n² = A²b^(2j) + 2AB·b^j + B²; partial information
  (the digits of n² just above the bottom region depend on the bottom and only a few low digits
  of the top; is there a mirror image at the top, and at both ends of n³?); three-way or
  multi-level splits of n; representations other than top/bottom digits (n mod m for other m,
  n as a product, n in a mixed radix when b is composite or a perfect power: b = 64 = 2^6 = 8²
  = 4³, where digits are bit groups and the bit-level structure of squaring and cubing is
  available).
- **B.** Can any method reach more than 2 output digits per digit of n fixed, even on average,
  even for a subset of n of positive density that is cheap to enumerate?
- **C.** Is there an algorithm that does not enumerate candidates at all for part of the
  constraint: generalised birthday / k-list methods, dissection, representation techniques,
  lattice methods with partial prescriptions, anything that would give an exponent below
  the join's? Give the exponent and the constants at b = 62 and b = 64.
- **D.** Large bases (b ≥ 150), where nice numbers should be plentiful (expected count per base
  grows without bound) but exhaustive search is impossible: is there a construction or a
  search that finds *one*, with success probability per unit work far above the density
  e^(−b)·poly? The argument says no (every single-digit change of n re-randomises ≥ 3L output
  digits, so there is no local search; the last 3L digits are a lottery). Attack that.
- **E.** If you find no hole, tighten the argument: state precisely the model of computation in
  which "≥ (admissible n) × P(2L−2 digits distinct) candidate visits" is a lower bound, and what
  an algorithm would have to do to escape the model.

For every idea give a concrete cost estimate at b = 62 (L = 13, width 9.5e21, 2 roots of 61)
and b = 64 (L = 13, width 3.8e22, 8 roots of 63), against the join's ≈ 2.5e18 bit-parallel ANDs
and ≈ 1e15–1e17 survivor checks per b = 62 base. An idea without a number is not a finding. Mark
anything that can be tested in under a day as an experiment, with what to measure and what
result would kill it.

## Deliver

`N5/REVIEW.md` in this directory
(`~/projects/nice/scratchpad/2026-10-research-program/N5/`): a verdict per item A–E; each idea
with its cost estimate, its status (dead with the reason / open with the test that decides it),
and the strongest objection to your own conclusion. Scripts and outputs under `N5/raw/`. Writes
only there. Context if you want it: `~/projects/nice/scratchpad/2026-11-fresh-eyes/NOTES.md`,
`~/projects/nice/common/src/overlap_join.rs` (module docs), and the earlier closed-direction
write-ups under `~/projects/nice/scratchpad/2026-08-*` and `2026-09-literature-review`,
`2026-09-math-reassessment`. Hard stop: about 3 hours of work.
