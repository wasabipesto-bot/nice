# A3: the adversary, and the hunt for hidden structure by measurement

Read `../COMMON.md` first; it defines the problem, the baseline and the rules.

## Your angle

Two jobs, both empirical before they are theoretical.

**1. Look for structure nobody has assumed.** Everything in the standing argument is reasoning
about digits. Check it against data instead:

- Enumerate exhaustively for bases where that takes minutes (the admissible range of n for
  each base b with a valid digit count: compute it; base 10 through about 30 in full, larger
  bases on windows), and record for every n the "niceness" (number of distinct digits among
  the b output digits), which positions collide, and the collision's distance.
- Then test, base by base, whether **any cheap feature of n predicts niceness or near-niceness
  beyond the known filters**: residues of n modulo every m up to a few hundred (the known one
  is b−1; check b+1, b²−1, divisors of b, primes), digits of n itself (their sum, their
  distinctness, their order statistics), n's position within the range (x = n / b^(L−1)),
  simple functions of those. Use the top 1e-3 or 1e-4 by niceness as the positive class and
  report lift with confidence intervals; a feature must replicate across at least five bases
  to count. Also test **dependence between the square's and the cube's digit multisets** (given
  the square uses a digit set A, is the cube's set less or more likely to avoid A than
  independence predicts, as a function of anything cheap).
- Test the baseline's independence assumption directly: the measured number of n whose 2L
  end-determined digits are distinct, and the measured fraction of those whose middle is also
  clean, against the product formula. A middle that is **far from uniform given the ends**
  would be the lead of the year, in either direction.

**2. Then be the adversary.** State the weakest model in which a lower bound can be argued (for
example: an algorithm that learns output digits only through evaluations of digit functions
of partial assignments), say exactly which known technique falls inside it and which would
fall outside it (lattice methods? algebraic structure of squares and cubes together, n³ = n ·
n²? p-adic or CRT decompositions of the base? the factorisation n²(n·b^D + 1) of the
concatenated pandigital number?), and for each class outside the model give either a concrete
attempt with code or the reason it cannot help. Two other investigators work in parallel on
`../a1-progressions` (analytic and lattice structure of the middle digits) and `../a2-digitsets`
(the exact cover, combinatorially); read their `NOTES.md` near the end of your time and attack
whatever they claim.

Baseline and the form of a result: COMMON.md. Hard stop **20:30 UTC** today.
