# Below exhaustive, round 2 (director, 2026-11-21): where a second nice number could come from, and what any method would have to control

Standing line (the user, 2026-11-21: "a broadening of what sorts of advancements are possible given continual
pressure"). A round here records what was tried and names the next attack; a negative round is a status.
Labels: **[M]** measured (`BX/round2/window.py`, `window.out`), **[P]** proven or plain computation, **[J]** judged.
Round 1 (`EXPERIMENTS.md` BX.1) measured that the middle output digits are uniform and independent given both
ends at bases ≤ 62 and that prescribe-and-solve methods lose to the join. This round asks the question at the
bases where nice numbers must exist, and for families and moves round 1 did not look at.

## 1. Where they are [P, uniform model: candidates × b!/b^b]

log10 of the expected number of nice numbers in a base: 64: −3.9; 65: −3.5; 70: −3.4; 80: −3.1; 100: −2.1;
120: −0.9; 130: −0.1; 140: +0.7; 150: +1.5; 200: +6.7. Everything the exhaustive search can reach (bases to
about 70) has a chance of a few in ten thousand per base. **A second nice number almost surely exists near base
130–150 and there are millions by base 200; n there has 26–40 digits (10^55–10^92 candidates).** So finding one
is not a matter of a faster join by any constant. It needs a method that does not pay per candidate.

## 2. What such a method must control [P]

Any method fixes part of n, learns the outputs that part determines, and leaves the rest to chance. If a
fraction u of the b output digits is left to chance, a trial succeeds with probability (ub)!/b^(ub). log10 of
trials per success:

| base | u = 0.60 (today's two-sided certificates) | 0.47 | 0.30 | 0.20 | 0.10 | 0.05 |
|---|---|---|---|---|---|---|
| 140 | 54 | 49 | 39 | 31 | 19 | 11 |
| 200 | 77 | 70 | 56 | 44 | 28 | 16 |

**To find a nice number at base 140 with about 10^19 trials, a method must determine 90 % of the output digits
before it gambles, and must do so without paying to list what it determined.** That is the size of the gap.

What the join family can do there [P, a crude model that reproduces base 64: it gives 10^16 surviving pairs for
the middle-out shape against 1.3·10^16 measured]: two ends that share no position of n determine 40 % (u = 0.60);
letting them share s positions raises what a pair knows (up to 80 % when both know all of n) but each side's list
grows by b^(s/2). The best balance at base 140 is s = 16 shared positions, u = 0.37, **about 10^44 operations**
(lists and surviving pairs both 10^44); at base 200, 10^65. So no join of this family, at any shape and any
constant, reaches a base where a nice number is expected.

## 3. Why 40 % is rigid for generic n [P + M]

- **Window lemma.** Change n by Δ = δ·b^i. Then n² and n³ are unchanged below position i (Δ ≡ 0 mod b^i) and,
  carries aside, above positions i + L + 1 and i + 2L + 1 (L = digits of n; the change 2nΔ and 3n²Δ does not
  reach higher). So every move scrambles a window of L + 2 digits of n² and 2L + 2 of n³, **60 % of all output
  digits, wherever the changed digit sits.** Measured: 37.1 %, 38.0 %, 38.8 %, 39.0 % of outputs unchanged at
  bases 60, 100, 150, 200, flat across the position of the changed digit [M].
- Consequence: local search, annealing and beam search on n see a landscape that is a fresh lottery on 60 % of
  the digits at every step; the 40 % that persists is exactly what the top and bottom certificates already use.
  Two digits changed together scramble the union of their windows, never less than one window.
- Knowing K digit positions of n from an end fixes 2K outputs; n has b/5 positions; two ends that share nothing
  fix 2·(b/5) = 40 %. Sharing positions buys certified digits only at the price of listing them (§2).

## 4. Structured families: the best is 53 %, and it lives where it is useless [P]

- Zeros inside n are positions known to both ends at no cost in freedom, so sparse n raise the controlled
  fraction. But n² then has zero runs unless its blocks abut exactly. The family that abuts is
  n = [x][0^m][y] (x, y of m digits; n² = [x²][2xy][y²], b = 15m): each end knows 2m positions, 8m of 15m
  outputs are controlled, **u = 7/15 = 0.47**; with t blocks the fraction is 4t/(10t − 5), falling back to 0.40.
- The family has b^(2b/15) members against b^(b/5) candidates, so it is expected to contain a nice number only
  when (2/15)·ln b > 1: **b > 1,808**. There 47 % left to chance costs 10^650 trials. No family of this kind
  helps: structure that adds control removes candidates faster than the lottery improves.
- Closed forms whose digits are provably all distinct exist (the ramp 0 1 2 … of 1/(b − 1)², cyclic numbers
  ⌊r·b^k/p⌋ for primes p < b): a square and a cube would both have to land on such strings with complementary
  digit sets. The strings number about b² against b^(2b/5) squares in range; and the natural identities force
  an equation of the type "a ramp is a perfect square", which has no solutions by Catalan-type arguments in
  the cases I worked (the full-period ramp is never a square). Measure zero [J].

## 5. Status after round 2

Nothing below exhaustive, again, and now with the target stated: **control 90 % of the outputs, not 40 %**, or
make trials cost nothing. Round 1 showed the middle is uniform given the ends; this round shows why moves and
families cannot change the fraction. What is not excluded, because none of the arguments above touch it:

1. **A second source of certified digits that is not "an end of n".** Both certificates read n from an end.
   A relation that fixes output digits from a *non-contiguous* description of n (n modulo a number coprime to
   b fixes nothing digit-wise; n in a union of intervals is still an end; but n = u·v with constraints on u and
   v, or n on a curve, is neither) has not been examined. First concrete case to try: n = u·v with u, v of
   half length: n² = u²v², n³ = u³v³; do the digits of a product have any end-like structure in both factors
   at once (low digits of n depend on low digits of u and v jointly: yes, bilinearly; that is a different
   shape of "view" from the ones round 1's lower bound covers).
2. **Paying less than one unit per trial** when trials share work: the join already shares; the middle-digit
   lottery is per pair. A batch test for "the middle is a permutation of the missing digits" over many pairs at
   once (for a fixed bottom the 18 lowest middle digits are an affine function of the top's free part, a
   rotation on a torus) would be the place to look; round 1's counting identity covers prescribing them, not
   batch-rejecting them.
3. **Bases where the model is wrong in our favour.** The uniform model holds to 2–3 % where measured (L8,
   bases ≤ 62). A base family in which squares and cubes repel each other's digits (b with special factors,
   b = c^k) would raise the count; no reason is known, and it has not been measured above 62 by sampling.

**Next round (named now so the line does not lapse): item 2, the batch test**, because it is the only one with
a mechanism already half built (the affine structure is used per pair in the prefilter): count, on real base-64
slices and on sampled pairs at bases 100–140, how many top values survive the affine middle digits for a fixed
bottom, and whether a lattice or rotation argument lists them faster than testing each (the rotation's target
set is a union of digit boxes; if its structure allows listing survivors in time near their number, the
per-pair lottery becomes a per-bottom one: at base 64's shape 18 of the 27 uncertified digits are affine in the
top's free part, so u would fall from 0.42 to 0.14 for the price of one listing per bottom). My own first
estimate says the listing costs more than the tests it saves at base 64 (a box per allowed digit pattern);
the round is to find out whether that estimate survives at large bases, where the free part of the top is long.
