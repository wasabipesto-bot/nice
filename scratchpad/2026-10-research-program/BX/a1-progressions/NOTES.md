# A1 progressions / lattice angle: living notes (started 2026-11-16 16:28 UTC)

Code in `code/` (Python; run with `nice -n 19 uv run --with numpy python code/<script>`), outputs
`out_*.txt` next to this file. "Measured" = from a script here; "derived" = argument; "guess" = guess.
Notation: L digits of n; n = T·b^u + m (T top t digits, m bottom u = L − t digits); B = b^u.
D(digit | view) = 1 − H(digit | view)/H(digit), Miller–Madow corrected, minus the same with the view
shuffled (null). D = 1 means the view determines the digit, 0 means it says nothing.

## Status (2026-11-16 17:12 UTC) — verdict: negative for the whole A1 angle, one new exception recorded

- **Q2 (middle digit as a low-complexity function of partial information): no.** Measured at
  b20-b30 (E1, E1c) and the sensitivity map at b40 and b62 (E4): every middle output digit is a
  pseudo-random function of every single digit of n; no view of <= L−2 digits (any positions), no
  n mod q (q <= 1500), predicts it by more than 0.04 (noise floor 0.02).
- **Q3 (choose outputs first / mixed prescriptions): no.** No output digit predicts a middle digit,
  singly or in pairs (E2, max 0.033 over 2541 triples at b23). Counting identity (D1): any
  prescribe-and-solve method, any lattice dimension, cuts one digit per prescribed digit and costs at
  least one call per allowed prescription, so it loses to the tree at every node.
- **Q1 (joint lattice of the two progressions): no.** The AP digits from the top are the prefix
  view; the low AP digits need all of m; joint windows add their digits (D1). For fixed bottom the
  "linear congruential maps" are the suffix tree relabelled.
- **Q4 (condition on a top or bottom alone involving middle digits): none found**; the only
  multiset invariant with arithmetic meaning is the digit sum mod b − 1 (already the join key).
- **New, and the only exception to "<= 2 output digits per fixed digit of n" outside the join's
  overlap: ramified slices p^j | n (E3)** for b = p·q, q >= 3: there x mod q^c certifies 2c digits,
  2/log_b(q) per digit (7.7 at b69). Verified; p_nice lower only by a last-digit factor (0.33-0.6×, proxy); exact tree at b28 ×12 fewer
  nodes per member in the 49 | n slice. Useless for finding: each digit of slicing costs a factor b
  of λ and buys ≈ e^{1.2}; the best slices of b65/b68/b69 buy λ ×6-50 dearer than b62/b64 generic
  and hold 1e-13…1e-17 of it; b62 (2^j slices, 2.4 per digit) never gains, b64 can't slice.
- Model statement of the negative: section "Model statement" at the end of this file.

## Ideas, in order tried

### E1. Is any middle output digit a low-complexity function of partial information? (brief Q2) — NO
`code/e1_entropy.py`, outputs `out_e1_b{20,22,23,28,30}.txt`. Every subset S of n's digit positions
(not only prefix+suffix: scattered subsets too) with |S| <= L-2 (b20-23 exhaustive over the base's
range) or |S| <= 3 (b28, b30: 300k-sample, L = 6). Max null-corrected D over all views, per output
position (b30, L 6):
  sq: 1.00 1.00 .76 .23 .02 .00 .00 .00 .05 .65 .83 .99   cu: 1.00 1.00 .76 .31 .08 .01 .00 ×8 .06 .64 .83 .99
(b22: middle sq4 0.00, cu5-cu8 0.00-0.01; b23 the same.) Partial values only at the edge digit next to
a certified block (N5 A.3 crumbs: carries, gcd(2R0,b) parity) and on near-prefix views (n's leading
digit has few values, so "digits 1..3 without digit 4" acts as a prefix). Scattered views never beat
their own end part on a middle digit by more than 0.02.
`code/e1b_modq.py` (`out_e1b_b22.txt`): views n mod q, q = 2..1500, b22 exhaustive. Middle digits:
max D 0.000-0.014; the only nonzero hits are q | b^3 (968, 1331, 1452: suffix information in
disguise) on the edge digits sq3/cu3.
`code/e1c_size4.py` (`out_e1c_b28.txt`): b28 (L 6) with all 15 views of exactly L−2 = 4 positions,
3M-sample: middle sq5-sq6 <= 0.04, cu5-cu11 <= 0.04 (0.02 is the noise floor at 8 samples per cell).
**Outcome: measured negative.** No middle digit is even 5 % determined by any view of <= L-2 digits
of n, any n mod q, at b20-30. Nothing to build on.

### E2. Hidden redundancy among OUTPUT digits (brief Q3, "choose outputs first", general form) — NO
`code/e2_outred.py`, `out_e2_b{20,23}.txt`. If some output digits predicted others beyond the
prefix/suffix structure, prescribing outputs first could certify > 2 digits per digit of n. Measured
null-corrected D(d_q | d_p) for every ordered pair of output digits and D(d_q | d_p, d_r) for every
triple onto a middle target (b23 exhaustive: 2541 triples). Pairs: only top-top (sq8 -> cu13 0.93,
cu12 0.49) and bottom-bottom (sq0 <-> cu0, sq1 <-> cu1 0.20) correlations, i.e. the prefix/suffix
views themselves. Best triple onto any middle digit: D = 0.033 (b23), 0.061 (b20, L = 4, where the
"middle" is one digit from an edge). **Outcome: measured negative.** Any prescription of output
digits narrows n by one digit per prescribed middle digit; mixed prescriptions (top of n^2 with
bottom of n^3 etc.) are just a prefix view plus a suffix view, ratio <= 2 per list entry.

### E3. Ramified p-adic slices: a real exception to "<= 2 output digits per fixed digit" — useless for finding
Idea (new, not in N5): for b = p·q with p prime, p ∤ q, the slice F_j = {n : p^j | n} has
n^2 ≡ 0 mod p^{2j} and n^3 ≡ 0 mod p^{3j} for free (the p-adic derivative of x^2, x^3 vanishes at 0).
So x = n/p^j mod q^c (q^c classes, c <= 2j) determines the low c digits of BOTH n^2 and n^3:
2c output digits from c·log_b q digits of entropy inside the slice. Ratio 2/log_b(q): 7.7 at b69
(q = 3), 5.2 at b65 (q = 5), 6.1 at b68 (q = 4). (q = 2 is dead: b = 2p with p | n forces equal
last digits of n^2, n^3; at b62 that kills 31 | n, while 2^j | n (p = 2, q = 31) is allowed but weak,
see below. Prime-power b (64) dies at j >= 2 on repeated zeros.)
Checks (`code/e3_family.py`, `out_e3_family.txt`, 100k-200k samples per base, b28/33/39/65/69):
- certification verified (x mod q^c determines n^2, n^3 mod b^c) in every sample;
- the last digits of n^2 and n^3 are both ≡ 0 mod p, so they collide unless n mod q is right
  (keeps 1/3 at q = 3, 0.6 at b65): a constant;
- given that, the slice is *more* distinct than the range, not less: P(low 8 digits distinct)
  0.92 vs 0.67 at b69, 0.81 vs 0.65 at b65 (the p-residues of consecutive digits are forced by the
  digit below, which separates n^2 from n^3); mean #distinct digits of all b equal or higher. So
  p_nice per member is lower only by the last-digit factor (proxy below: 0.33-0.6×; not a count of
  nice numbers).
Cost (`code/e3_model.py`, `out_e3_model.txt`; N5's PSJ weights, uniform-digit model, tops built over
the range, family bottoms x mod q^c): per-member cost is *worse* than the generic flat join for small
j (the top list is built for the whole range but serves p^-j of it) and better only on very thin
slices: best ×13 at b65 (j = 8, slice 1e-9 of the range), ×22 at b69 (j = 9, 6e-13), ×22 at b68
(j = 9, 8e-12). (Corrected 17:10: the first version of the model counted only the last level of the
slice's bottom tree and gave ×108 at b69; every tree level is now counted.) Exchange rate (derived): each digit of p-adic restriction removes a factor b of
members (λ) and buys about e^{1.2} in per-member cost (P(D + 2)/P(D) at D ≈ 0.6b certified
digits). Expected nice numbers in the useful slices: λ_b × 1e-9…1e-14 ≈ 1e-13…1e-18.
**Outcome: derived + measured negative for finding.** The slice is the only construct I found that
certifies more than 2 output digits per digit of n *without* the join's overlap, and the "2 per
digit" ceiling in N5 §B should be read as "for non-ramified views". It cannot raise the reachable
expected count: it lowers the cost per member only on slices whose λ is ≤ 1e-9 of their base's.
Non-zero residues mod p^j are unramified (n^2 mod p^j only), and the global 2-adic/3-adic analogue
((n + 2^k)^2 ≡ n^2 mod 2^{k+1}) is N5 A.3's parity crumb.
Exact check on a small base (`code/e3_tree.py`, `out_e3_tree_b{20,28}.txt`; pure bottom-up tree,
prune on any repeated certified low digit of n^2, n^3, every node counted; slice bottoms walk q-adic
digits first, then full digits):

| b28 (= 7·4) | members | nodes / member | leaves (full checks) / member |
|---|---|---|---|
| whole range | 3.9e7 | 1.785 | 0.052 |
| slice 7 \| n | 5.5e6 | 0.916 | 0.0052 |
| slice 49 \| n | 7.9e5 | 0.144 | 0.0056 |
| slice 343 \| n | 1.1e5 | 0.158 | 0.0011 |

p_nice proxy (`code/e3_tail.py`, `out_e3_tail.txt`): P(#distinct >= b−3) is 0.33-0.6× the range's
in the slices (the last-digit collision), so cost per expected find in the 49 | n slice is ≈ ×7
better than the whole range at b28 — while the slice holds 1/49 of the range's λ. Same exchange
rate as the model: λ falls by p per step of j, cost per find improves by a small constant.
Also dead for *exhaustive* search: only the v_p(n) >= 1 part (1/p of the range) can gain, so a whole
base gains < ×(1 + 1/p) (b65: < 8 %).
Generalisation checked and dropped: any slice that fixes information gets that information "free"
(N5's partitions); only the zero class mod p^j gives *more* than it costs, because only there the
derivatives 2n, 3n^2 vanish p-adically. For every other class a mod p^j the excess is a single linear
relation n^3 − (3a/2)n^2 ≡ −a^3/2 (mod p^{2j}), which is the suffix view's own "next block of n^2
determines the next block of n^3" and certifies nothing new.

### D1. Brief Q1 ("does a joint lattice for the two progressions beat two per digit?") — no, by counting
Derived (no lattice details needed). Fix a top T and let F(m) be any w output digits that are not
certified by T (n^2 window, n^3 window, or both; any lattice dimension). A prescribe-and-solve method
makes one solver call per allowed prescription v and returns F^{-1}(v). Exactly,
  Σ_{v allowed} |F^{-1}(v)| = #{m : F(m) allowed},
so its cost is #allowed prescriptions + #{m whose w digits pass}. With equidistributed F (measured:
E1, E2, and N5's survivor counts), #allowed ≈ b^w·P_w and #pass ≈ b^u·P_w. For w <= u the second
term is ≥ b^u·P_u > b^u·P(2u) (the bottom tree's leaves); for w > u the first is ≥ b^w·P_w, which
grows with w. Either way it loses to the tree, whatever the solver costs, and joint windows
(n^2 + n^3) only add their digits to w: one digit of cut per prescribed digit, never two. The tree
gets two because one digit of m fixes one digit of n^2 and one of n^3 at the same position; no middle
window has that property (E2: no middle digit is predictable from any other one or two digits).
The same holds at any internal node of a tree (C2's hybrid): with r = u − d free digits left and w
prescribed, prescription only cuts deeper than the tree if w > 2r, and then the calls alone,
b^w·P_w >= b^{2r}·P_{2r}, exceed the tree's leaves b^r·P(2r) by a factor >= b^r.
The same counting kills unordered prescriptions (a digit *set* per window): no handle on "digits of
F(m) lie in S" beyond the digit sum mod b − 1, which the join already uses.
For fixed bottom m the low digits of H enter n^2, n^3 through the linear maps T ↦ 2mT, 3m^2 T mod b^K
(brief's "linear congruential maps"): that is the suffix tree relabelled (bijective when 2m, 3m^2 are
units), two digits per level, nothing more. For many tops at once the window condition is bilinear
(2Tm mod b^{u+s} in an interval): for each T it has one solution class in m, so there is no batch
enumeration below one operation per (T, solution).

### D2. Ideas recorded as dead without code (reason in one line each)
- Inclusion–exclusion over digit subsets S (#nice = Σ_S (−1)^{b−|S|} N(S)): 2^b < N for b > 32, but
  each N(S) is a digit-restricted count with no exact fast method, and the alternating sum needs
  every term exact. (A2's territory; noted for completeness.)
- Range exclusion by exponential-sum bounds (Weyl / van der Corput on the cubic in m): the bounds
  give counts ± error with error ≥ sqrt(set size) > 1, so they can never certify a count of 0.
- Exact digit sum s(n^2)+s(n^3) = b(b−1)/2 as an integer (stronger than mod b − 1): the middle block's
  sum is a function of the middle digits only; mod b − 1 it is already implied by the global residue.
- Middle prescription of n^3 (positions [L, 2L)): L prescribed digits leave ≈ 1 n on average
  (count b^L·b^L/b^{2L}), ratio 1, and a third list keyed on it has no cheap key into (top, bottom).
- Sparse/structured n (zero blocks so that n^2, n^3 are concatenations of products): density
  b^{−o} with o ≥ |B| needed for separation; λ_b > b^o only beyond b ≈ 1800 (derived).
- Families n = g(y) for a polynomial g with p-adic critical points: the gain needs g' ≡ 0 mod p^j,
  i.e. a set of density ~p^{−j} again (same exchange rate as E3).
Exchange rate in numbers (`code/e3_exchange.py`, `out_e3_exchange.txt`; same crude model, λ from the
program's curve, slice p_nice = 0.5×): expected nice numbers per AND-unit, generic flat join:
b62 2.6e-23, b64 1.2e-23, b65 6.6e-25, b68 1.4e-25, b69 5.0e-26. Best slice of each sliceable base:
b65 13^8 4.3e-24 (λ in it 2e-13), b68 17^9 1.5e-24 (1e-15), b69 23^9 5.5e-25 (8e-17). So even the
best slices of the next sliceable bases buy λ ×6-50 dearer than b62/b64 do today, and hold no λ.
b62 itself: the 2-adic slices 2^j | n are allowed (p = 2, q = 31; measured: no p_nice penalty at all,
P(low 12 distinct) 0.326 vs 0.327, `out_e3_b62_p2.txt`) but give 2/log_62(31) = 2.4 digits per digit
only, and the model never finds a per-member gain (best ×0.84 at j = 6). b64 = 2^6 dies at j >= 2.
**E3 closed.** (Worth one sentence in N5 §B: "≤ 2 per digit except on the ramified slices p^j | n".)

### E4. Sensitivity map: every middle output digit depends on every digit of n — measured
`code/e4_sensitivity.py`, `out_e4_b40.txt` (b40, L 8, 200 random n). For each output digit p and
each digit position i of n: vary n_i over all b values, count distinct values of digit p
(1 = independent of n_i; ≈ 0.63b = 25.3 = random function; b = bijection). The table has exactly
three kinds of cells: 1.0 (the suffix rule p < i, and the prefix rule for high p and low i),
edge crumbs (2.3 = carry across the prefix certificate's edge; 12.4 / 21.4 = digit i of n^2 / n^3
against n_i, i.e. 2n_0·d resp. 3n_0^2·d mod b, the gcd crumbs), and 25-32 everywhere else.
n^3 positions 8-16 (the middle) are 25-29 against *every* n_i, i = 0..7.
Same at the production base (`out_e4_b62.txt`, b62, L 13, 40 n): n^3 positions 12-24 (13 = L digits)
take 36.5-48 distinct values (random function: 39.2) against every one of the 13 digits of n; n^2
position 12 is the only other such row (min 30.2 = the parity crumb, gcd(2n_0, 62) = 2). No middle digit is even
partly insensitive to any single digit of n, so no view that omits any digit of n determines one.

## Model statement for the A1 class (the negative, as precisely as I can make it)

Why the ends give two digits per digit and the middle gives none, in one picture: from the bottom
the map n ↦ (n^2, n^3) is a p-adic analytic map, from the top a real analytic one. Away from critical
points both are local isometries up to a unit: one more digit of n fixes one more digit of each of
the two values (Hensel; Taylor) — two output digits per input digit, the prefix/suffix certificates.
The only critical point of x^2, x^3 is 0: on the reals it is outside every range, p-adically it is
the slice p^j | n of E3 (ramification index 2 and 3: 5 p-adic output digits per p-adic input digit).
The middle positions (n^2 near L, n^3 in [L, 2L)) are where neither expansion has converged; there
every output digit is a pseudo-random function of every digit of n (E4), carries no information
about any other output digit (E2), and no view of <= L−2 digits of n — any positions, or n mod q —
predicts it (E1). Prescribing it and solving (lattice, Coppersmith, any oracle) cuts one digit per
prescribed digit and cannot be amortised below one call per allowed prescription (D1).

**A1 model.** An algorithm may (a) create prefix and suffix nodes of n, (b) for any node or node pair
and any set W of output positions, call an oracle that returns every n consistent with the node(s)
whose digits on W equal a prescribed tuple, at unit cost per call plus per returned n, (c) restrict to
residue classes of n. Under the measured equidistribution (E1, E2, E4; N5's survivor counts),
each oracle call on uncertified positions certifies at most one output digit per prescribed digit
(counting identity in D1), so (b) never beats extending a prefix or suffix, and the class reduces to
N5's PSJ model plus slices; slices beat PSJ per member only on the ramified classes p^j | n, which
hold a fraction p^{-j} of λ and buy λ more dearly than the smallest open base (E3).
What would escape it: a predicate on uncertified digits that is not a prescription of their values
(e.g. "the window's digits form a set S" decided faster than |S|! prescriptions) — I found none:
the only multiset-invariant with arithmetic meaning is the digit sum mod b − 1 (already the join key).

### D3. Where AP structure does help, and by how much: child generation (kernel-trim class)
Derived. The only place where "digits of an arithmetic progression" are enumerable faster than
walking is one level down a tree: a bottom node's children d ↦ digit k of n^2 = c + 2R_0·d and
digit k of n^3 = c' + 3R_0^2·d (mod b) are affine in d, and a top node's children's new digits are
digits of an AP in d (three-distance). So children whose new digits are used can be skipped
without being generated. Saving: at most the pruned fraction of children per level, 1/(1 − 2t/b)^2
≈ ×2.8 on list building at t ≈ 0.2b, which is ≈ 25 % of the join's time: ≤ ×1.2 on a base. Probably
already partly done for bottoms ("cheap linear extensions" in fresh-eyes §3). Not pursued.

### E5. Prescribe-and-solve prototype with honest counts (backs D1) — loses at every w
`code/e5_prescribe.py`, `out_e5_b40.txt`. b40 (L 8), tops of t = 5 digits with distinct certificate,
u = 3 free digits (B = 64000), 20 random tops. The oracle is an exact index (the most generous
"lattice": unit cost per call and per returned m). Window digits = the uncertified positions just
under each top certificate, alternating n^2 / n^3 (the brief's two progressions, joint).
Per top: survivors |S| = 2.3; bottom tree 20,454 nodes + 9,118 leaves to check.
Prescription calls + outputs: w=1 48,086; w=2 41,662 (best); w=3 60,948; w=4 881,401; w=5 2.4e7;
w=8 4.2e11. Outputs fall only by the allowed fraction (≈ 0.75-0.85) per prescribed digit, calls grow
by ≈ b per digit — the counting identity of D1, measured. (And these top-of-window digits are the
prefix-like ones; the low AP digits would come later in w, where calls are already 1e7+.)

### D4. Two more pairing ideas from the AP structure, both consumed by the join key (derived)
- Sibling bottoms (last digit d of R varies) differ only by two affine digits c2 + 2R0·d, c3 + 3R0²·d,
  so a (top, parent) pair could yield all compatible children by permuting the complement of the top
  mask (one AND per parent instead of per child). But the bottom's last digit is a shared (key) digit
  whenever the overlap o >= 1, and with o = 0 the mod b − 1 key already pins d to #roots values:
  the key does this work already. Lower free digits of R are not affine-sibling (they move every
  higher digit of n^2, n^3).
- Top siblings: their last digit is the lowest shared digit, same story.

## With another day
1. Turn E1/E2/E4 into a lemma (complete exponential sums mod b^k for the suffix side, Weyl /
   van der Corput for the prefix side): conditional on any prefix + suffix with a gap, every middle
   digit is equidistributed and pairwise independent up to O(b^{-1/2}). That makes the A1 negative a
   theorem in the "views + prescription oracle" model, not only a measurement.
2. Put the ramified-slice exception into N5 §B, with E3's exchange rate.
3. If anyone wants to go on in this direction at all: the only escape the model leaves is a
   predicate on an *unordered* digit set of a window that is cheaper than reading the digits; the
   2026-08 b^r ± 1 result and A.5 say there is none with an arithmetic handle. I would not spend
   more on A1.
