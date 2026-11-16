# A2: the exact cover (combinatorial / algorithmic angle)

Read `../COMMON.md` first; it defines the problem, the baseline and the rules.

## Your angle

Niceness is an **exact cover**: the digits at the 5L output positions are a permutation of the
alphabet. Every method so far treats that as "no repeated digit among the positions I already
know" and waits for the rest. Treat it instead as a combinatorial object.

Questions to attack, in whatever order looks best to you, and any better ones you find:

1. **Pairing through digit sets.** The join tests (top, bottom) pairs with an AND of two masks;
   about 8 % pass. Finding all disjoint pairs between two families of sets is the Orthogonal
   Vectors problem. With the real distributions of the masks (take them from a prototype of
   the top and bottom lists at bases 20–40; the reference join in `common/src/overlap_join.rs`
   shows how the lists are built), is there an index, a subset (zeta) transform on a compressed
   alphabet, or a multi-level bucketing under which the join touches only pairs that pass, and
   what would that save in total, given that the AND stage is about 12 % of a field today? If
   the ceiling is ×1.1, say so in a paragraph and move on.
2. **The complement.** Once a top and a bottom are known, the middle digits must be exactly the
   complement set C, in some order, at known positions, and the middle block's value is
   determined by n. Is there a condition on (top, bottom) that is necessary for *any*
   arrangement of C to be consistent, computable from data that can be precomputed per top and
   per bottom separately (so that it can be a join key or a filter before pairing)? The digit
   sum gives the residue class mod b−1 (already a key). Systematically search for more:
   weighted sums, sums of squares of digits against n² + n³ in some modulus, the split of C
   between the square's and the cube's middle positions (two digit sums, each known mod b−1
   from n), bounds on the middle block's value from the largest and smallest arrangements of C.
   Measure each candidate's rejection rate on real pairs at small bases.
3. **Counting instead of finding.** #nice = Σ over digit subsets S of (−1)^(b−|S|) · #{n : every
   output digit of n² and n³ lies in S}. Is there any family of constraints for which the inner
   counts are cheap and the sum is short (a truncated or Bonferroni-type bound that certifies
   "none in this range" without visiting the candidates)? What do the truncations give on
   small bases?
4. **The representation technique** (Howgrave-Graham and Joux for subset sum; dissection, by
   Dinur, Dunkelman, Keller and Shamir): these beat plain meet-in-the-middle when a solution
   has many representations as a combination of partial objects. A candidate n has one
   decomposition into (top, bottom) for each split point, and the digit sets it uses at
   different split points are nested. Is there any formulation in which a nice number has
   exponentially many representations that a birthday-style search can exploit?
5. **Constraint solving.** Model a small base as a SAT or CP problem (digit variables for n,
   n², n³, the multiplication constraints, all-different): how do modern solvers scale against
   the tree on bases 10–24? If a solver's learnt clauses show a pattern (a pruning rule humans
   have not written down), extract it.

Baseline to beat and the form of a result: COMMON.md. Hard stop **20:30 UTC** today.
