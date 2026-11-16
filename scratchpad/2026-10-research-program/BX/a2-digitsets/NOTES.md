# A2 digit sets / exact cover — living notes (started 2026-11-16 16:30 UTC)

Code in `code/`. All runs single-thread, `nice -n 19`, Python 3 (+ `uv run --with ortools` for CP-SAT).
Labels: **measured** (a script printed it), **derived** (algebra, checked where noted), **guess**.

Shared helper: `code/nicelib.py` (range, residue roots, top/bottom certificates).
Baseline counter: `code/tree_counts.py` (exact MSD-tree, LSD-tree, flat prefix–suffix-join
(PSJ) cost minimised over (t, k), and B2L = admissible n whose ≈2L end digits are distinct).

## Index of ideas (status, 2026-11-16 ~17:45 UTC)

| # | idea | outcome | kind |
|---|---|---|---|
| I1 | OV / output-sensitive pairing | ≤ ×1.14–1.35 on a base at today's shape; in-model ideal gap grows with b (×1.5→2.9, b17→25, unit weights) but is the generic OV problem | derived + measured |
| I2 | complement C: per-side split-sum conditions (mod b−1, mod b+1), value bounds, digit-class identities | S1 rejects 0/4400 survivors; S2 ≤ 1.5 % → 0; S3 needs n; class identities collapse to the mod b−1 root identically | measured + derived |
| I3 | inclusion–exclusion / Walsh counting | truncation error = Σ_{non-nice} C(f_n−1, m) exactly (useless until m ≈ max f_n); full sum = 2^b Gelfond-type sums, ≥ today's cost at b62 even if each were free | derived + measured |
| I4 | representation technique / dissection | O(L²) representations, no merge level: Σ_s 1/R_s ≥ 1 ⇒ work ≥ best single shape | derived |
| I5 | CP-SAT scaling, free and fixed order | branches = ×21–26 PSJ at constant ratio (same exponent); forced two-sided order ≈ the certificate tree; no hidden pruning rule | measured |
| I6 | optimal adaptive digit tree (exact DP) | adaptivity ×1.0–1.6, no trend; best tree ≥ ×4–6 the flat join ⇒ every digit-branching solver is ≥ ×4 the join | measured |
| I7 | output-side (exact-cover) branching | ×200–400 worse than the tree at b14 | measured |
| I8 | dual tree / block prune / digit-key index inside N1 units | IDEAL/FLAT 0.04–0.12 but dual tree costs 6–10× FLAT; best block ×1.0–1.2; digit key ×1.3–1.5 on the pair term | measured |
| I9 | structured (AP-digit) OV at the sibling level | b·r ≈ 10²–10³ pairs per group pair; one AND each beats any structure | derived |

**Bottom line so far:** the exact-cover structure adds no information a join can use beyond
"certificates distinct, disjoint, residue root". Every combinatorial lever measured lands in
constant factors ≤ ×1.6 on the whole, except the ideal-OV gap, which is a genuine in-model
exponent but is exactly OV in dimension ≈ 3–4·log(list size), where known algorithms lose to a
0.8 ps AND until b ≫ 62 (guess: ≈ 90+).

## I1. Pairing through digit sets (Orthogonal Vectors) — ceiling paragraph, no experiment

Derived. Any output-sensitive disjointness join can only remove the AND/pair-test term; the
survivor path, list building and checks are untouched. The pair-test term is 12 % (brief) to 26 %
(fresh-eyes §3, 1e17 b62 field on a 3080) of a field, so even a free, perfect OV oracle is worth
×1.14–×1.35 on a whole base, before index overhead. N5/REVIEW §C3 already estimated what a
practical digit-key index gets on that term (×2–2.5 ⇒ ×1.07–1.18 on a base). The only structure
the real masks have that independent-digit estimates miss — tops of one field share their
leading block digits — is what the existing block prune already takes. Ceiling ≤ ×1.35, realistic
≈ ×1.1: **below the ×10 bar; not pursued.** (The zeta transform itself is useful as a *counting*
tool, used in I5 below.)

Addendum (measured, exact, `code/tree_counts.py` → `code/ov_ceiling_small.out`): the ceiling
*at today's shape* is the paragraph above; with the shape re-optimised for a free OV oracle the
in-model ceiling is larger and grows with b. Unit weights (list entry = pair = check = 1):
flat join (lists + pairs + checks, best (t, k)) / ideal (lists + checks only, best (t, k)) =
1.54, 1.85, 2.40, 2.46, 2.58, 2.89 at b 17, 18, 20, 22, 24, 25 (ln slope 0.04–0.08 per base;
crude asymptotics give e^{≈0.08b}). N5 §C3 puts it at ×6 / ×10 for b62 / b64 with real weights.
So *ideal* disjointness pairing is an exponent in the model, but what reaches it is exactly OV in
dimension d = b ≈ 3–4·log₂(bucket size) with set weights ≈ 0.3b: colour-coding / LSF schemes
cost ≈ n_T·2^{|B|} + n_B·2^{|T|} plus per-colouring indexing and lose to a 0.8 ps bit-parallel AND
until buckets ≫ 2^{0.3b} on both sides (N5 §C3: b62 units are 9e4 × 9e5 against 2^18 = 2.6e5).
Not actionable at the frontier; recorded as the one place where the list model's exponent is
not tight against known algorithms. With N5's real weights (list entry 50, pair 1, survivor 45
AND-units; `code/ov_ceiling_weighted.out`) the same exact small-base comparison gives only
×1.01, 1.02, 1.03, 1.03, 1.03, 1.06 (b17–25): lists dominate at these sizes, so the small bases
cannot confirm N5's ×6 at b62; that figure stays a model extrapolation.

## I2. The complement: conditions on (top, bottom) from "the middle is exactly C" — measured, dead

Code: `code/complement_split.py b t k samples seed`. Population: AND survivors of the join at
overlap o = 1 (random admissible n whose prefix_t cert and residue_k cert are each distinct and
disjoint), 400 per base. C = unused digits; m2, m3 = middle positions of n², n³.

- **S1 (per-side computable; uses only the join key n mod b−1):** the n² middle must be an
  m2-subset of C with digit sum ≡ n² − S(known n² digits) (mod b−1) (and then the n³ part is
  automatic). Derived: this is a subset-sum feasibility over C with |C| ≥ 12, which saturates
  Z/(b−1) as soon as m2 ≥ 2 and |C| − m2 ≥ 2.
  **Measured rejection 0/4400 survivors** (b 20, 22, 24, 25, 28, 30, 32, 34, 37, 40).
- **S1+S2 (adds the alternating sums mod b+1 for n² and n³, four-way split of C into the
  even/odd middle positions of each; needs n mod b+1, which is also per-side additive — the
  alternating digit sum of n — so this would be a per-side condition with the key widened to
  n mod b²−1; it is the j = 2 member of the b^j ± 1 family closed in 2026-08):** 1.5 % (b20),
  0.5 % (b22), 0 % (b24, b25; DP restricted to ≤ b25). Vanishes as |C| grows.
- **S3 (value bound: the contiguous middle block of n² / n³ lies between the smallest and the
  largest arrangement of m-subsets of C; needs n):** 6.3, 7.8, 6.5, 4.3, 3.8, 5.0, 2.8, 5.5, 4.0,
  3.5 % for b 20…40. It is just "the leading middle digit is in [min C, max C]" in disguise, it
  needs the full n, and the full check costs the same. Useless.
- **Digit-class identities (derived, closed):** for m | b, digit d_i ≡ ⌊x/b^i⌋ (mod m), so
  Σ_i (d_i mod m) ≡ Σ_i ⌊x/b^i⌋ = x + (x − S(x))/(b−1) (mod m). Exact cover fixes the left side
  (and S(n²)+S(n³) = b(b−1)/2 exactly). Writing n²+n³ = T + (b−1)q (T = b(b−1)/2, i.e. the mod
  b−1 root condition) the condition becomes T + bq ≡ T (mod m): **identically true**. The same
  collapse happens for "number of odd digits = b/2" (m = 2). So exact digit-class counts and
  class sums carry nothing beyond the mod b−1 root. Non-linear symmetric functions (Σ d², Σ d·d')
  have no expression in n at all.

**At the frontier shape** (b62, t = 10 (f0 3), k = 6, sampler draws n directly in root classes):
150 AND survivors from 648,108 admissible n (2.3e-4 per admissible n, matching the 2.0e-4 of
fresh-eyes §3 — a check on the certificate code), mean |C| = 32.6; **S1 rejects 0/150, S3 4.7 %.**

Verdict: the complement C supports no per-side condition beyond the residue key; conditions
that do bite (S2, S3) need n and reject < 8 % of survivors, falling with b.

## I3. Counting by inclusion–exclusion — derived identity kills truncations; inner counts not cheap

Exact cover of b positions by b digits ⇔ no digit missing, so
#nice = Σ_j (−1)^j T_j with T_j = Σ_{|D|=j} Z(D), Z(D) = #{n : no output digit in D}.
Per n, the contribution of the first m+1 terms is Σ_{j≤m} (−1)^j C(f_n, j) = (−1)^m C(f_n − 1, m),
f_n = number of digits missing from n², n³ (C(−1, m) = (−1)^m gives exactly 1 for a nice n).
**So the Bonferroni truncation at level m is exactly #nice ± Σ_{non-nice n} C(f_n − 1, m)**: the
error is a sum over every candidate of a non-negative term, zero only if every candidate misses
at most m digits. Typical f_n ≈ b/e (b62: ≈ 23 of 62 missing), so certifying "none" needs m ≳
max f_n ≈ b/e + O(√b) and the inner counts Z(D) for C(b, ≤m) sets D (C(62, 25) ≈ 1e17).
Numbers on small bases: see I3 measurement below (f_n distribution).
The Ryser-style reading (2^b inner sums Z(D), each a product over positions) would change the
exponent only if Z(D) had a sub-linear counter. Z(D) is a digit-restricted counting problem for
squares and cubes; the only known counters are the same prefix/suffix trees with "digit ∉ D"
pruning, which prune *more weakly* than distinctness (per position (1 − |D|/b) instead of the
falling factorial), so Σ_D cost ≥ N · Σ_j C(b,j)(1 − j/b)^{2L} ≫ N. No family of constraints
makes both the inner counts cheap and the sum short; truncation is provably useless (identity
above), not just empirically.

## I4. Representation technique / dissection — accounting argument, dead

What a nice n has: one (prefix, residue) pair per shape (t, k), i.e. O(L²) representations
(nested digit sets, as the brief says), not exponentially many. The representation technique
(HGJ) gains because a random constraint of size R can be imposed **as a join key at an
intermediate merge level**, so lists shrink by R while each solution keeps ≥ 1 representation.
Our lists have no merge structure: prefixes and residues are built by digit extension (a tree),
and a certificate of a merged object is not a function of the certificates of its parts
(N5 §A.1: every output position ≥ j is moved by the cross term 2MB·b^j). The only merge is the
final pair join. With a single merge level, imposing a random per-shape restriction h_s
(filter or key) that keeps a 1/R_s fraction of shape s's work and catches n with probability
1/R_s needs Σ_s 1/R_s ≥ 1 for coverage, so total work Σ_s W_s/R_s ≥ min_s W_s: **never below
the best single shape.** Polynomially many representations can at most pay for choosing the
best shape per region (the "adaptive depth" constant of N5 §E). Dissection needs a
composition of bijective rounds with guessable intermediate states; the carry-state ladder
(2026-08, frontier states do not collapse) is exactly that attempt and is closed.

## I5. Constraint solving (CP-SAT, CDCL + lazy clause generation) — measured: same exponent, no hidden rule

Model: the 2026-08 digit/carry CP-SAT model (`code/cpsat_model_2608.py`, copied unchanged; its
fastest config redundant=False, residues=True), **1 worker**, enumerate-all (proves UNSAT /
finds 69). Comparators from `code/tree_counts.py` and `code/alt_tree.py` (exact counts):
A = admissible n; MSD = prefix-tree nodes created; PSJ = best flat prefix–suffix join cost
(tops + bottoms created + key-matched pairs, minimised over (t, k)); ALT = two-sided alternating
tree certified nodes (zeta-transform pair count; leaf level corrected to admissible n = B2L).

| b | A | MSD | PSJ | ALT | CP-SAT free: branches / conflicts / s | CP-SAT fixed alt order: branches / conflicts / s |
|---|---|---|---|---|---|---|
| 17 | 483 | 5,890 | 569 | 516 | 14,763 / 2,558 / 0.65 | 6,032 / 399 / 0.16 |
| 18 | 1,112 | 7,921 | 661 | 532 | 15,758 / 3,171 / 0.76 | 7,757 / 1,337 / 0.20 |
| 20 | 10,638 | 77,919 | 6,251 | 6,224 | 146,277 / 35,520 / 11.7 | 37,735 / 9,839 / 1.6 |
| 22 | 80,406 | 233,983 | 31,279 | 27,652 | 651,803 / 157,266 / 80 | 99,549 / 49,310 / 6.5 |
| 24 | 98,707 | 603,236 | 36,958 | 31,783 | 794,567 / 133,847 / 87 | 387,919 / 177,766 / 24 |
| 25 | 1,606,456 | 3,585,161 | 468,548 | 476,484 | >1.86e6 / >5.0e5 / >280 (timeout) | 655,709 / 341,549 / 73 |

(outputs: `code/solver_scaling.out`, `solver_scaling_2425.out`, `solver_fixed_alt.out`,
`tree_counts_small.out`, `tree_counts_2425.out`, `alt_tree.out`.)

Measured findings:
- Free CP-SAT branches / PSJ cost = 26, 24, 23, 21, 21.5 for b 17–24: **a constant ratio, i.e. the
  same growth exponent as the two-sided join**, not a smaller one. Conflicts / PSJ = 4.5, 4.8, 5.7,
  5.0, 3.6. (The 2026-08 note compared wall time with the scanner and saw a 4–6 order gap; the node
  counts show why: the solver does the PSJ's work ×20 in nodes and ×1e5 in time per node.)
- Forced to branch like the two-sided tree (a_{L−1}, a_0, a_{L−2}, a_1, …), CP-SAT is 3.6–12× faster
  than free search (b20–24) and its conflicts are 0.7–5.6× the certified ALT nodes (no trend with b);
  branches 1.4–15× (it tries every value of the last digit; the residue only bites at the leaf).
  **So propagation + clause learning prune nothing measurable beyond the prefix and suffix
  certificates and the residue**: if learnt clauses encoded a cross rule, branch/conflict counts
  would fall below ALT by a growing factor. They do not.
- Time per node 100–250 µs against ns for the tree: a solver is 5 orders of magnitude worse per
  node and not better in nodes. Item closed; no clause mining warranted (nothing to mine: the
  refutations are no shorter than the certificate tree's).

### I3 measurement + the Walsh (parity) form (`code/counting.py`)

Bonferroni truncation error Σ_{non-nice} C(f_n−1, m) (measured, all admissible n):
b14 (N 62): m = 0…9 → 62, 267, 492, 509, 330, 144, 44, 9, 1, 0. b18 (N 1112): 1112, 6368, 16164,
24040, 23333, 15567, 7303, 2406, 539, 75, 5, 0. The error is *larger than N* until m ≈ max f_n − 2
and reaches 0 only at m = max f_n − 1; max f_n = 6, 7, 7, 9, 12, 11 for b 10–18 (≈ b/e + O(√b)).
Truncated counting certifies nothing short of the full sum.

Walsh form (derived, verified exactly b10–18: gives 1, 0, 0, 0, 0, 0): because every n has
exactly b output digits, #nice = 2^{−b} Σ_{S ⊆ digits} (−1)^{|S|} F(S), F(S) = Σ_n f_S(n²)f_S(n³)
with f_S(x) = (−1)^{#digits of x in S}, a **b-multiplicative ±1 function**. This is the cleanest
statement of what "counting instead of finding" requires:
- 2^b terms. Even with F(S) free, 2^62 ≈ 4.6e18 ≈ today's whole-b62 AND count (≈ 2.5e18): no gain
  at the frontier; it would be a different exponent only for b ≳ 70, where 2^b ≥ 1e21 is beyond
  the program's lifetime compute anyway.
- F(S) is a Gelfond / Mauduit–Rivat-type sum (digital function of squares and cubes, e.g. the
  Thue–Morse-of-squares count). Known results are asymptotic equidistribution with non-effective
  or weak error terms; I know of no exact algorithm sub-linear in N, and the Fourier route
  (f̂ of a b-multiplicative f factorises digit-wise, then Weyl sums) needs ~ (c√b)^{5L} terms.
So the counting route is closed twice: truncations are provably useless (identity), and the full
sum has 2^b terms each as hard as the search. (Measured: median |F(S)| = 6 and 15 at b14 / b17
against √N = 7.9 / 22, p99 = 20 / 57: square-root cancellation, no sparse set of S carries the
answer.)

## I6. Optimal ADAPTIVE two-sided decision tree (exact DP) — measured: constant, and trees lose to the join

Question: the solver lives in the class "branch on digits of n, prune by certificates". What is
the best possible search in that class if each node may choose which end to refine (the most
constrained-first / adaptive-depth idea, Algorithm-X style)? `code/opt_tree.py` computes the
exact minimum node count by DP over (prefix, residue) nodes (cost 1 per created node, alive iff
both certificates distinct and disjoint, leaves t + k = L are one n, checked if admissible), and
the same count for fixed strategies. Output `code/opt_tree.out`.

| b | ALT (alternate) | TOP (MSD) | BOT (LSD first) | OPT (adaptive) | OPT/best fixed | PSJ flat join | OPT/PSJ |
|---|---|---|---|---|---|---|---|
| 17 | 5,565 | 5,890 | 7,070 | 4,775 | 0.86 | 569 | 8.4 |
| 18 | 4,731 | 7,921 | 6,505 | 3,903 | 0.82 | 661 | 5.9 |
| 20 | 58,144 | 77,919 | 43,807 | 42,626 | 0.97 | 6,251 | 6.8 |
| 22 | 208,826 | 233,983 | 205,021 | 159,814 | 0.78 | 31,279 | 5.1 |
| 24 | 379,789 | 603,236 | 448,768 | 242,046 | 0.64 | 36,958 | 6.5 |
| 25 | 3,139,457 | 3,585,161 | 2,021,109 | 2,018,065 | 1.00 | 468,548 | 4.3 |

Measured: adaptivity buys ×1.0–1.6 over the best fixed order with no trend in b (constant, as
N5 §E predicted). **The flat join beats the best possible tree by ×4–8** (×3.9–6.3 if the join is
also charged one full check per AND survivor: 763, 934, 9,739, 39,438, 43,485, 523,322 for the
six bases), because it shares each
bottom across all tops. So every digit-branching solver (CP-SAT, any CDCL on this encoding, DLX
with these certificates) is bounded below by OPT, i.e. at least ×4–8 the join's operation count,
before its 1e5× per-node overhead. Branch-and-bound / solver approaches are closed for this
problem in this sense; the join (list sharing) is the right algorithm class and the only one in
which a gain could live.

## I7. Output-side ("dual", exact-cover-first) branching in a solver — measured, much worse

Exact-cover-style branching decides *where digits go* (output digits) instead of n's digits.
`code/solver_outside.py`: CP-SAT 1 worker, fixed order over output digits first (cmid = cube
digits from the middle outwards; qcmid = middle digits of n² and n³ interleaved; clow = cube
digits from the bottom, Hensel-like), then n's digits. Output `code/solver_outside.out`.
Branches at b14: cmid 62,466, qcmid 93,706, clow 124,827 against OPT tree 310 and free CP-SAT
7,414 (×200–400 worse than the tree); at b17/18 all three hit 100 s with > 2.5e5–8e5 branches
(OPT tree 4,775 / 3,903). Reason (derived): a prescribed middle output digit restricts n to a
1/b-dense set that is a union of very short runs (run length b^p/(3n²) < 1 in the middle of n³),
so it carries no positional locality the propagator can use; it only bites once enough of n is
fixed, i.e. it degenerates to the tree with b^W extra guesses in front. Same conclusion as the
lattice-prescription item (N5 §C2) from the solver side.

### I5/I6 cross-check: CDCL conflicts ≈ the optimal digit tree

Free CP-SAT conflicts vs OPT tree nodes: b17 2,558 / 4,775; b18 3,171 / 3,903; b20 35,520 /
42,626; b22 157,266 / 159,814; b24 133,847 / 242,046 (ratio 0.55–1.0). The solver, choosing its own
variables (carries, outputs, digits), refutes the instance in about as many conflicts as the
optimal adaptive certificate tree has nodes: it rediscovers the best tree, nothing beyond it.
Model note (derived, crude uniform-digit asymptotics with L = b/5, ln b ≈ 4): any tree's
leaves ≈ A·P(2L) ≈ A·e^{−0.08b}, the flat join ≈ A·e^{−0.13b} (overlap lets it use t + k > L,
which a tree cannot), so the tree/join gap should grow like e^{0.05b} (≈ ×20 at b62); measured
×4–6 at b17–25 with no visible trend (L ≤ 5 there limits the overlap).

## I8. Multi-level bucketing for the disjointness join, measured inside transversal units

Setting: N1-style units (fixed overlap digits π; tops = certified prefixes ending in π, bottoms =
certified residues starting with π; key = mod b−1 root), random π, exact per-unit counts.
FLAT = key-matched pairs (today's AND count), IDEAL = disjoint ones (survivors).
IDEAL/FLAT = 0.12 (b30), 0.036 (b34), 0.078 (b37), 0.039 (b40): an output-sensitive oracle would
cut the pair term ×8–27 in these units. What real structures get:

- **Dual tree** (`code/dual_tree.py`; top groups by leading free digits, bottom groups by low
  digits, group masks = certificate of the group's interval / low digits, expand only disjoint
  group pairs, key at the last step): exact (its survivors = IDEAL) but **costs 6–10× FLAT**
  (b30: 186,936 vs 31,575; b34: 100,072 vs 9,961). Shallow group masks have 1–3 digits and almost
  never collide, so the tree pays b children per expanded pair for nothing.
- **Best two-level block prune** over all (j, i) (`code/block2.py`): FLAT/best = 1.00, 1.00,
  1.19, 1.09 (b30, 34, 37, 40); the optimum is always "single tops × bottom groups by 1 low digit".
- **Digit-key index** (N5 X1; `code/digitkey.py`; key = mask on the d digits with the highest
  top×bottom frequency): kept pairs / FLAT at d = 4, 8, 12, 16, 24 = 0.70, 0.50, 0.37, 0.29, 0.17
  (b37), 0.67, 0.48, 0.35, 0.26, 0.14 (b40); naive group-visit overhead 0.17–0.29 of FLAT at d 8,
  > 1 from d 12 in these small units. Net ×1.3–1.5 on the pair term here; larger units at b62
  amortise the visits better, consistent with N5's ×2–2.5.

Why (derived from the counts): a mask's colliding digits are its element-specific deep digits
(each certificate grows 2 digits per level and the last levels hold most of the collision
probability), so any grouping coarse enough to have few groups has masks too thin to collide.
The gap to IDEAL is real but sits in the per-element digits, i.e. it is the generic OV problem,
and the known OV tricks recover ×1.3–2.5 of a ×8–27 gap. Whole-base effect ≤ the pair-term share
(≤ ×1.35). Closed for this angle; X1 remains the director's engineering item, my numbers
support its "< ×1.2 on a base at today's shape" projection.

### Growth fits (least squares of ln(count) on b, b 17, 18, 20, 22, 24; checks included in PSJ)

| count | ln-slope per base | slope of count/PSJ | slope of count/A |
|---|---|---|---|
| A (admissible n) | 0.822 | +0.166 | 0 |
| PSJ flat join (+checks) | 0.656 | 0 | −0.166 |
| OPT adaptive tree | 0.648 | −0.008 | −0.175 |
| CP-SAT free, branches | 0.651 | −0.005 | −0.171 |
| CP-SAT free, conflicts | 0.654 | −0.002 | −0.168 |

Solver and best tree have the join's exponent to ±0.01 per base (noise); all three save
≈ e^{−0.17b} against the admissible count at these sizes (the baseline's e^{−0.094b} is the b62
fit of the same thing with real L). No method in this file changes the exponent.

## Model and negative (for the director)

**Model (exact-cover view of the PSJ model).** The algorithm holds prefixes and residues of n
(any adaptive order, any sharing), sees for each (i) the certified (position, digit) pairs and
(ii) any additive digit functional of n's own digits (n mod b−1, n mod b^j ± 1), and may discard
a set of candidates when this information rules out every completion of the exact cover.
Measured in this file: (a) completions consistent at the multiset level exist for 100 % of AND
survivors (mod b−1 split: b20–b62 incl. the frontier shape; with the mod b+1 splits too: b24–25;
I2), so (ii) adds nothing beyond the root
key; (b) digit-branching searches, including CDCL solvers that pick their own variables, need at
least the optimal certificate tree, which is ≥ ×4–6 the flat join with the same exponent (I5, I6);
(c) organising the pair tests by shared digits (dual tree, blocks, digit keys) recovers ≤ ×1.5 of
the pair term although an oracle would give ×8–27 inside a unit (I8); (d) counting formulas are
either useless when truncated (identity) or need 2^b digital-function sums of squares and cubes
(I3); (e) representations are polynomially many and there is no merge level (I4).
Hence in this model the work is the flat join's up to constants, except for the ideal-OV term,
whose in-model value grows with b but which is the generic orthogonal-vectors problem in
dimension ≈ 3–4 log₂(list size), where no known algorithm beats a bit-parallel AND at the
frontier (guess for where that changes: b ≈ 90+, from the 2^{0.3b} bucket-size condition).

## I9. Structured OV at the sibling level (AP digits) — derived, closed

Inside a unit, a top-sibling group (tops differing only in their lowest free digit e) and a
bottom-sibling group (bottoms differing only in their highest free digit d) meet in ≈ b·r
key-matched pairs (the key fixes e + d mod b−1 up to the r roots). The digits that vary with e
are the lowest ≈ ft certified digits of n² and n³ (digits of an arithmetic progression in e, step
≈ 2n·b^k resp. 3n²·b^k), those that vary with d are positions [f0−1, k) (digits of an AP in d mod
b^k). block2.py shows the shared parts almost never collide, so the ≈ 5 % pass rate is decided
here. But a sibling-group pair is only b·r ≈ 120–370 pairs at b62: one bit-parallel AND each is
already below any AP-digit machinery, and the best possible saving at this level is the pass
rate (×20) on the pair term only. Not worth a prototype; the a1 progression tools do not buy
anything at the pair level.

## What I would do with another day

1. A real CNF/CDCL run (kissat/cadical; column-wise encoding, one-hot all-different) at b14–20
   to close the "modern SAT solver" question beyond CP-SAT (expected: the I5/I6 picture).
2. A Rust OPT-tree / PSJ counter to b28–34 (states 1e7–1e8) to test whether OPT/PSJ grows like
   the derived e^{0.05b} and whether the weighted ideal-OV gap starts to grow (b17–25: ×1.01–1.06).
3. Otherwise stop this angle: nothing in it reaches ×10, and the one in-model exponent (ideal OV)
   is a known-hard problem whose known algorithms lose at the frontier.

## I10. Pure CNF + CDCL (CaDiCaL 1.9.5 via python-sat) — measured: ≈ the optimal tree, ×1–2

`code/cnf_model.py`: the same schoolbook digit/carry model bit-blasted (binary digits, Tseitin
multipliers and ripple adders, column equations s_j = q_j + b·r_{j+1}, final carry tied to the
top output digits, pairwise all-different by XOR clauses; **no residue constraint**), all
solutions enumerated by blocking clauses. Finds exactly 69 at b10. 10k–48k variables.
Comparator: OPT tree without the residue filter (`NORES=1 code/opt_tree.py`,
`code/opt_tree_nores.out`). b25 split by leading digit into 17 runs (`code/cnf_b25_perlead.out`;
OPT per leading digit in `code/opt_tree_nores_b25_perlead.out`, sum 2.91e6 = OPT).

| b | CaDiCaL conflicts | decisions | s | OPT tree (no residue) | conflicts / OPT |
|---|---|---|---|---|---|
| 17 | 26,265 | 59,985 | 1.8 | 5,856 | 4.5 |
| 18 | 33,263 | 81,835 | 2.4 | 5,510 | 6.0 |
| 20 | 129,125 | 249,950 | 14 | 66,163 | 1.95 |
| 22 | 328,867 | 583,743 | 48 | 213,877 | 1.54 |
| 24 | 325,405 | 542,948 | 55 | 339,972 | 0.96 |
| 25 | 4,973,454 | (17 runs) | 856 | 2,905,170 | 1.71 |

The ratio fell from ≈ 5 to ≈ 1 between b17 and b22 (fixed overhead amortising) and then sits at
1.0–1.7: **a bit-level CDCL solver, free to branch on bits, carries and outputs and to learn
clauses, refutes the instance in about as many conflicts as the optimal digit tree has nodes**, at
≈ 6k–10k conflicts/s (×1e5 per node against the tree). No evidence of shorter (resolution) proofs
than the certificate tree. b25's 17 sub-runs total 856 s for a base the tree clears in
milliseconds.

**Caveat found on the way (affects the 2026-08 CP-SAT model and my I5 numbers):**
`digit_splits` in `cpsat_model_2608.py` admits digit-count splits that cannot occur — (2d, 3d−2)
and (2d−1, 3d), e.g. (3, 5, 9) at b14 and (5, 9, 15) at b24 (`nicelib.real_splits` lists the
real ones) — and for (2d−1, 3d) it does not tie the final cube carry to the top cube digits, so
that split is under-constrained: my first CNF port found a bogus "solution" 359 at b14 from it
(n = 359 is outside the b14 range); in CP-SAT the residue constraint happened to mask it.
Results stay correct (the 2026-08 brute-force cross-check passed) but solver effort on the
phantom split inflates counts: CP-SAT free at b24 drops from 794,567 to 267,511 branches and
133,847 to 44,112 conflicts with real splits only (`code/real_splits_rerun.out`); b13, b14, b18
change little. The I5 table and fits are corrected below.
