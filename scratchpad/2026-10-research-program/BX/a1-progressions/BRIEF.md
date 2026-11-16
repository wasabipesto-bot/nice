# A1: the middle digits as digits of polynomial progressions (analytic / lattice angle)

Read `../COMMON.md` first; it defines the problem, the baseline and the rules.

## Your angle

Write n = H + m with H the top part (a multiple of B = b^u) and 0 ≤ m < B. Then

- n² = H² + 2Hm + m², and n³ = H³ + 3H²m + 3Hm² + m³.
- For output positions above 2u, the digits of n² are the digits of the **arithmetic
  progression** H² + 2H·m (the m² term only sends a carry); for positions above L + 2u the
  digits of n³ are those of H³ + 3H²·m. Below that, quadratic and cubic progressions.
- From the bottom, digit j of n² is a function of (H mod b^(j+1)) and m through the
  **polynomial congruence** (H² + 2Hm + m²) mod b^(j+1).

So for a fixed top, "which bottoms m survive" is a question about the base-b digits of
polynomial sequences in m, and for a fixed bottom it is a question about linear congruential
maps in the low digits of H. Digits of arithmetic progressions have rigid structure
(three-distance theorem, continued fractions, lattice points in polytopes, Bohr sets); digits
of quadratic sequences are the territory of Weyl differencing and van der Corput.

Questions to attack, in whatever order looks best to you, and any better ones you find:

1. For a fixed top, can the set of m whose progression digits avoid a forbidden set and are
   pairwise distinct be **enumerated in time proportional to its size** (or counted, or shown
   empty) without walking a digit tree, and does combining the two progressions (differences 2H
   and 3H², one variable) give more than each alone? The known answer for a single window is
   "one prescribed output digit per free digit of m, against two for the tree": is there a
   joint structure (a lattice in dimension 3 or 4, simultaneous Diophantine approximation) that
   beats two?
2. The true middle (positions where the quadratic terms matter): is there any regime of (u,
   position) in which a middle digit of n² or n³ is a **low-complexity function** of partial
   information (few digits of H and few of m)? Search for it by computer: for small bases,
   tabulate each middle output digit against every pair (a digits of H's low end, c digits of
   m's high end, and the other three combinations) and measure how much of it is determined
   (conditional entropy). Any digit that is, say, 90 % determined by fewer than L digits of n
   in total is a lead.
3. Inversion: choose output digits first and solve for n (square roots mod b^J, cube roots,
   real roots). Mixed prescriptions (the top of n² with the bottom of n³, and so on): is there
   a combination in which d fixed digits of n certify more than 2d output digits, or in which
   the enumeration is over a set smaller than the tree's?
4. Anything analytic that yields a **necessary condition on a top alone or a bottom alone**
   involving middle digits (for example: for this top, the middle digits of n² can only take
   values in a set smaller than everything, for all bottoms).

Baseline to beat and the form of a result: COMMON.md. Hard stop **20:30 UTC** today.
