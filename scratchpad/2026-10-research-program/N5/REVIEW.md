# N5 review: the no-shortcut argument (2026-11-10)

Scripts and outputs: `raw/psj_mc.py` (Monte Carlo over the whole (f0, k) plane, b62 and b64,
6000 admissible n each; `raw/psj_mc_b62.txt`, `raw/psj_mc_b64.txt`), `raw/model.py`
(uniform-digit model, per-find table, lattice variant; `raw/model_out.txt`), `raw/psj_floor.py`
(the prefix–suffix join model's optimum; `raw/psj_floor_out.txt`), `raw/gap64.py`
(lattice variant at b64; `raw/gap_out.txt`). About 25 CPU-seconds in total.

## Verdict in one table

| item | verdict | best number found |
|---|---|---|
| A: partial information about the middle | **No hole.** Every cheap view of n is a prefix or a suffix (or a partial digit at their edges, which prunes < 10 % of the last tree level). | — |
| B: > 2 output digits per fixed digit | **Yes, but only by the overlap the join already uses.** Per list entry ≤ 2 (proof below); per *free* digit 2(L+o)/(L−o) by fixing o shared middle digits = one partition of the join. | nothing beyond the join |
| C: algorithms that avoid enumeration | **No exponent change.** k-list, dissection and representations need additive structure that is not there; lattice prescription loses ×3000–5000 (b62/b64); an ideal output-sensitive disjointness join would be worth ×6 (b62) / ×10 (b64) over the best flat join *in the model*, of which digit-key indexing can get ×2–2.5 on the AND term only. | open (engineering): X1 |
| D: one nice number at b ≥ 150 | **Dead in every model I can state.** Cost per expected find depends on b only (range width cancels) and grows with b in every column, including the information floor: 1e22 at b62 today, 1e57 at b150 today-like, ≥ 1e34 at b150 even with free lists and a perfect join. Plentiful ≠ cheap. Searching the smallest open base is optimal. | — |
| E: tightened statement | Done (§E). **The director's formula is not the bound.** Step 1's "≈ 2L known digits at full n" is false for the join itself (overlap gives 2(L+o)); A·P(2L−2) = 1.8e18 is close to the right number at b62 only by coincidence of weights. The bound is a time–memory trade in the prefix–suffix join (PSJ) model. | flat floor ≈ 2e18 AND-units b62, 1.6e19 b64; output-sensitive floor 3.4e17 / 1.6e18 |

Yardstick used throughout: today's join spends ≈ **24 fs per admissible n** at b62 (≈ 2100
3080-hours over 3.13e20 admissible n) and ≈ 15 fs at b64 (×9 the cost over ×15 the admissible
count). Any method that spends one nanosecond on a candidate must keep fewer than 2.4e-5
candidates per admissible n to compete. The join's AND is 0.8 ps per pair and its survivor path
36 ps, so the question is never "is it sub-exhaustive?" (it is ×125 below brute force over
admissible n) but "does it beat a 0.8 ps bit-parallel test".

## The model checks out

`psj_mc` compares measured pass rates with the uniform-digit model P_m = b!/((b−m)! b^m) at the
measured certificate sizes, over f0 = 1…6 and k = 1…12, including deep overlap:

- tops: measured / model 0.87–0.94 (b62), 0.97–1.05 (b64); mean certificate = 2(L − f0) − 2.56
  (b62) / − 1.62 (b64): the leading digit of n is small (n/b^L ∈ [0.016, 0.064] at b62).
- bottoms: 0.76–0.95 (b62), 0.87–1.10 (b64) (the low digits of n², n³ are not uniform: squares
  mod b).
- joint survivors P_S(f0, k): within 10–20 % of P(cT + 2k) from 2e-1 down to ≈ 1e-6 (e.g. b62
  f0 1, k 8: 6.3e-7 vs 6.8e-7; f0 4, k 12: 1.1e-7 vs 9.8e-8); below ≈ 1e-7 the pairing sample
  (200k pairs) is too thin to say. Certificates of 40 digits still behave like uniform draws, so
  the counts below are trustworthy to about ±30 %.

## A. Partial information about the middle digits — dead

Every candidate view, with its yield:

1. **Bilinear split n = A·b^j + B.** n² mod b^(j+m) = (2AB·b^j + B²) mod b^(j+m) depends on
   A mod b^m and B, i.e. on n mod b^(j+m): a suffix view. The "mirror image at the top" is the
   prefix view. At both ends of n³ the same (3AB²b^j + B³ is a suffix function; the top of
   A³b^(3j) + 3A²B b^(2j) a prefix one). No digit of n² or n³ is a function of
   (top part, bottom part) jointly that is not already a function of one of them: every position
   ≥ j is moved by the middle digits through 2MB·b^j or higher terms.
2. **Three-way / multi-level splits** n = A b^(2j) + M b^j + B: (A, B) together know exactly the
   prefix certificate of A and the suffix certificate of B. Middle-only views certify nothing.
3. **Partial digits at the view edges.** Top: the digit just under the certificate lies in a run
   of ≤ ⌈2n·b^f0 / b^p⌉ + 1 ≈ 6 consecutive values (b62, f0 3); all used with probability
   ≈ 0.27^6 ≈ 4e-4. Bottom: digit k of n² is c + 2R₀d (mod b) in the next digit d, so the depth-k
   residue fixes it modulo gcd(2R₀, b): its parity at b62, up to its low a+1 bits at b64 when
   2^a ‖ R₀. Pruning needs the whole coset used: coset ≥ 2 values, P ≤ (2k/b)² ≈ 3.5–8 % at the
   last bit level, and only for the tree, not the pairs. ≤ ×1.05 on list building (≤ 25 % of the
   time): **≤ ×1.01 on a base, b62 and b64.** The 2-adic special cases that do give a full extra
   digit (R₀ = b/2, n ≡ 0 mod 8 at b64) force a repeated last digit (both n² and n³ end in b/2
   or 0) and are never nice.
4. **b = 64 = 2^6 = 4^3 = 8^2.** Bits, base-4 or base-8 digits give a finer tree with the same
   leaves: a suffix of 6k + r bits certifies the low k digits plus partial digits (item 3); a
   prefix likewise. Mixed radix at b62 = 2·31 (n mod 2^a·31^c) yields digit parities only.
   Same ≤ ×1.01.
5. **n mod m for other m.** Only divisors of b^k (suffixes) and b^k ± 1 carry digit meaning; for
   b^k ± 1 the relation is a weighted block sum Σ d_j b^(j mod k), which is not a multiset
   invariant, so it is evaluable only once n is fixed (and then useless). Power-sum hashes
   Σ g^d (mod p) are additive over digits but the middle digits are not a sum of functions of
   parts of n. The digit sum mod b−1 is the one exception and the join already keys on it.
6. **n as a product** u·v: no positional locality at all. Dead.

## B. More than 2 output digits per fixed digit — only via the overlap

*Per list entry, 2 is a ceiling.* A prefix of t digits leaves n free over an interval of width
b^(L−t); n² then spans ≥ 2·n·b^(L−t) and n³ ≥ 3n²·b^(L−t), so at most ≈ t digits of each are
constant: ≤ 2t (measured: 2t − 2.6 at b62, 2t − 1.6 at b64). A suffix of k digits fixes exactly
n², n³ mod b^k; digit k of n² moves with the next digit d by 2R₀d (mod b), which is ≠ 0 unless
2R₀ ≡ 0, the never-nice case above. So ≤ 2k, with partial-digit crumbs.

*Per free digit, any ratio you like on a sub-family.* Fix the o middle digits π that a top and a
bottom share: the top of a + o digits and the bottom of β + o digits certify 2(L + o) − δ digits
from a + β = L − o free digits, e.g. o = 5: ≈ 4.5 per free digit. The sub-family has density
b^(−o) and is cheap to enumerate. This is exactly a partition value of the overlap join (the
"transversal unit" of N1), and covering all n means covering all b^o values of π. The
"sparse n" family I tried first (n = A·b^(2a) + B with a zero block, n² = [A²][2AB][B²]
exactly) gives 4 digits per free digit on each side and is the special case π = 0.
Nothing else gives more than 2 per entry, so B is answered by the join as built. Its correct
consequence is for E: the pairing step sees 2(L + o) digits, not 2L.

## C. Algorithms that avoid enumeration

**C1. k-list (Wagner), dissection, representation techniques — dead.** All three need the
constraint to be a group equation f₁(x₁) ⊕ … ⊕ f_k(x_k) ∈ target with the f_i computable on
independent parts (or a composition of bijective rounds for dissection). The only additive
constraint in the problem is the digit sum mod b−1, and the join already uses it as its hash key
(it is a 2-list birthday match on that part). Distinctness of the middle digits is not a function
of separable parts of n (A.1). No exponent, nothing to estimate.

**C2. Lattice / Coppersmith prescription in a gap — dead by ×3000+.** Give the pair (T, R) a gap
of g free middle digits M (t + k = L − g). Above position 2(L−t) of n² and L + 2(L−t) of n³ the
digits are affine in M (2t of them), so a lattice step can prescribe g of them and return the M
that fit. Best case over g = 1…4 and k = 2, 4, 6 (`model.py`, `gap64.py`), with an optimistic
100 ns per lattice call and 5 ns per output:

| | best shape | lattice calls / adm. n | outputs / adm. n | time / adm. n | join |
|---|---|---|---|---|---|
| b62 | g 2, t 9, k 2 | 3.1e-4 | 1.8e-2 | ≈ 120,000 fs | 24 fs |
| b64 | g 2, t 9, k 2 | 6.0e-5 | 1.4e-2 | ≈ 78,000 fs | 15 fs |

Even at zero overhead it loses: its outputs per admissible n (1.4–1.8e-2) exceed the join's AND
survivors (2–3e-4) by ×60, because a prescribed affine digit filters by q ≈ 1 − K/b per free digit
where the top tree filters by q² *and* shares that filter across every bottom. Step 2 of the
argument is right; the reason is amortisation as much as the 1-vs-2 count.

**C3. Output-sensitive disjointness (orthogonal vectors) — the only real gap; open as
engineering, capped.** Within the PSJ model (§E), let a pairing algorithm skip non-disjoint
pairs for free. `psj_floor.py` optimises the shape in both cases (weights in AND units: list entry
50, survivor 45, from the 1e17 calibration):

| | flat-join optimum | ideal output-sensitive optimum | ceiling of any pairing trick |
|---|---|---|---|
| b62 | 2.0e18 (f0 3, k 9) | 3.4e17 (f0 4, k 9) | ×6 |
| b64 | 1.6e19 (f0 3, k 10) | 1.6e18 (f0 3, k 9) | ×10 |

(The same crude model puts today's shape at 1.2e19 / 1.5e20 without the block prune, i.e. it
overstates N1's ×2.4–3.2 as ×6–9; quote it for the *ratio* flat → ideal only.)
The ×6–10 is not reachable with known methods:
- Pass rate per digit is thin: a digit lies in a top mask with p ≈ 0.28 and in a bottom mask with
  p ≈ 0.29, so restricting to d indexed digits keeps (1 − 0.28)^(0.29 d) of the tops for a given
  bottom. A digit-key index on d = 10–14 digits keeps 31–43 % of the tops at ≈ 137–1000 key
  groups per bottom: **×2–2.5 on the pair-test term** (90k tops × 900k bottoms per N1 unit).
  d = 28 would be needed for ×10, at 10^6 groups per bottom. This matches step 5's "< ×2" within
  the precision of either estimate.
- Colour-coding / random-splitting OV algorithms cost ≈ n_T·2^(w_B) + n_B·2^(w_T) with
  w ≈ 17–18, and need per-colouring indexes to avoid rescanning: they win only for buckets
  ≫ 2^18 on both sides (N1 units: 9e4 × 9e5). Polynomial-method OV (Abboud–Williams–Yu) has
  galactic constants at d = 62, n ≈ 1e5–1e6.
- The pair-test term is 15–27 % of today's time; survivors (30 %) are untouched by any pairing
  trick. **Projected on a whole base: ≤ ×1.2 at today's shape; ×1.3–1.6 at N1's deep shape, where
  pairs carry more of the cost.** That is kernel-trim class unless N1 lands. → experiment X1.

**C4. Hierarchical (dual-tree) pairing** — testing disjointness of coarse (block, residue-class)
groups before their children is the same lever as C3 in another form (the block prune already
takes ≈ ×2 of it). Same cap. **C5. Grover**: the one known exponent change (square root of the
pair count, ≈ 1.6e9 iterations of a squaring+cubing circuit at b62), on hardware that does not
exist. Not actionable.

## D. One nice number in a large base — dead

Cost per expected nice number = (work per admissible n) / p_nice, with p_nice = (b−1)·b!/b^b per
admissible n. **The range width cancels**: a large λ only means you may stop early, it does not
make a find cheaper. log10 of the cost per expected find (`model.py`):

| b | L | log10 λ | brute force | 2L known (o = 0) | today-like (f0 3, k 6) | flat join, free lists, t = k = L−1 | information floor (4L−4 known) |
|---|---|---|---|---|---|---|---|
| 62 | 13 | −3.3 | 23.8 | 21.6 | 22.2 | 19.8 | 13.0 |
| 64 | 13 | −3.0 | 24.7 | 22.5 | 23.1 | 20.8 | 14.4 |
| 100 | 20 | −1.2 | 40.0 | 36.5 | 37.4 | 33.4 | 22.8 |
| 130 | 26 | 0.5 | 52.9 | 48.2 | 49.2 | 43.8 | 29.5 |
| 150 | 30 | 1.8 | 61.5 | 55.9 | 57.0 | 50.8 | 34.0 |
| 200 | 40 | 7.0 | 83.0 | 75.4 | 76.6 | 68.3 | 45.2 |

(Calibration: the "today-like" b62 entry, 1e22.2, against the real 2.5e18 ANDs / 4.5e-4 = 5.6e21.)
Every column rises monotonically with b. Asymptotically, with x = fraction of the b output digits
known per touched candidate, cost per find ≈ e^{b(1 − φ(x))}, φ(x) = (1−x)ln(1−x) + x: x = 0.4
(2L) gives e^{0.91b}, two independent deep lists e^{0.81b}, the information floor (x = 0.8)
e^{0.52b}. The director's "e^{−4.5L} lottery" is the x = 0.4 case; the true in-model floor is
much lower but still exponential, and even it is 1e34 per find at b = 150 — beyond any budget
(the whole program's lifetime compute is ~1e21–1e22 AND-equivalents). Local search fails for
the same reason: beyond the views, the landscape is the uniform lottery the Monte Carlo
confirms. Constructions: the repetend families stay closed (their digit blocks are orbits of ×b
mod s², s³; small denominators make the leading digits periodic, which repeats digits — the
opposite of what is needed); n³ near an AP-digit rational (denominator (b−1)²) only prescribes
the top L digits, which is the prefix view again. **The cheapest place to find a nice number is
the smallest open base, i.e. what the program does.**

## E. The tightened statement

**Correction first.** Step 1 says every digit-local search reaches full n with ≈ 2L known
digits. It does not: a top of t digits and a bottom of k digits with t + k = L + o meet at a single
n with 2(L + o) − δ certified digits (b62 today: o = 3, 29.5 digits, survivors 2.0e-4 per n, which
is *below* the formula's A·P(2L−2) per n = 5.8e-3 by ×29). With t = k = L − 1 the pair would know
4L − 4 − δ ≈ 45 of 62 digits and only 1.2e-10 of admissible n (≈ 4e10 at b62, 5e11 at b64)
survive. So the information available to digit-local methods is not the bottleneck; **the cost of
materialising the views is.** The right statement:

**Prefix–suffix join (PSJ) model.** The algorithm learns about n only through
- *prefix nodes* P (the t leading digits; certificate = output digits constant on P's interval),
  created from their parent at unit cost;
- *suffix nodes* S (n mod b^k; certificate = low k digits of n², n³), created from their parent
  at unit cost;
- *pair tests* (P, S) at unit cost, which reveal C(P) ∪ C(S) and, when t + k ≥ L and the shared
  digits agree, identify one n (the mod b−1 class may be used as a key);
- *full checks* of an identified n.
It may discard n only when a created node or a tested pair containing n shows a repeated digit
(or n fails the mod b−1 test). Soundness: every nice n is fully checked.

**Bounds (uniform-digit heuristic, validated to ±20 % above).** With N_T(t) = W·b^(t−L)·P(cT(t−1))
created tops, N_B(k) = b^k·P(2k−2) created bottoms (once per base, transversal),
pairs = A·P(cT(t))·P(2k), survivors = A·P(cT(t) + 2k):
- **Flat PSJ** (every key-matching pair of certified entries is tested):
  cost ≥ min over (t, k) of N_T + N_B + pairs + survivors ≈ 2e18 AND-units at b62, 1.6e19 at b64.
  This is what the director's argument really asserts; A·P(2L−2) (1.8e18 at b62, 3.4e19 at b64)
  happens to land near it at b62 and ×2 high at b64.
- **Output-sensitive PSJ** (non-disjoint pairs skipped for free):
  cost ≥ min N_T + N_B + survivors ≈ 3.4e17 at b62, 1.6e18 at b64.
- **Information floor** (lists free): survivors at t = k = L − 1, ≈ 4e10 / 5e11. Unreachable,
  because creating the depth-(L−1) lists costs W/b and b^(L−1) nodes.
Adaptive depths (different (t, k) in different regions) change only constants here: the digit
model is homogeneous over the range except for the leading digit, which the measured δ absorbs.

**What escaping the model requires** (one of):
1. a predicate on output digits outside both views (the middle) that discards a *set* of n at
   less than one operation per member — i.e. an algebraic handle (a lattice or congruence) on the
   middle; C2 shows the affine handle certifies ≤ 1 digit per free digit and cannot be shared
   across pairs, and A.5 shows no further congruence;
2. views that are cheaper than prefixes and suffixes to create (implicit lists): none found;
3. an output-sensitive disjointness join beating digit-key indexing (C3; worth ≤ ×6/×10);
4. a construction (D): none known, and the families tried are provably bad.

## Open items and experiments

**X1 (C3, open, engineering): digit-key indexed pairing.** Sort a unit's tops by their pattern on
d chosen digits (d = 10–14; choose the most frequent digits in that unit's top masks); for each
bottom visit only key groups disjoint from the bottom's digits on those d; transposed AND inside
groups. Measure on real N1-shape units (f0 4, k 9 and f0 3, k 9, b62 and b64) on CPU first:
fraction of 32-top chunk operations kept and partial-chunk waste, then wall time. **Kill if the
chunk-op reduction is < ×1.5 or the projected whole-base gain < ×1.10 (the N4 park line).**
Projection: b62 pair-test term ≈ 2.5e18 → 1.0–1.25e18, whole base ×1.1–1.2 today, ×1.3–1.6 at
N1's shape; b64 ≈ 4e19 → 1.6–2e19, same ratios. Cost: < 1 day on ivory, CPU only. Do it only
after N1's GPU tile result: if N1 dies, X1 is below the line.

No other idea survived to the experiment stage. X2 would be redundant: N1's CPU prototype already
produces exact operation counts that test this review's model (flag > 30 % off).

## Strongest objections to my own conclusion

1. **The model class is mine.** "Every cheap predicate is a prefix or suffix certificate" is a
   claim about what I could think of, not a theorem. A number-theoretic handle on the middle
   digits — a congruence beyond mod b−1 that constrains the *arrangement* cheaply, or an algebraic
   family in which the middle of n³ is structured but not periodic — would escape PSJ entirely, and
   69 shows nice numbers exist without any visible structure, which also means none is known
   *with* structure. I tested no new congruences (step 4's saturation result was taken as given).
2. **The ×6–10 output-sensitive gap is real and I only beat on the obvious indexes.** The masks
   are not random sets: top masks in a contiguous field share their leading-block digits, and
   bottom masks are images of an affine map in the last digit. An index that exploits that
   structure could get closer to the ceiling than ×2.5; my estimate assumes independent digits.
3. **Weights.** The PSJ optimum depends on list-entry cost (I used 50 AND-units from the full-top
   calibration). If child-only certificates cost a third (L35-style finite differences), the flat
   optimum moves deeper and the flat/ideal ratio changes — constants, not exponents, but the
   ranking of X1 against N1 could change.
4. **D's floor is per-find in a model, not a theorem.** An exponentially small chance of a
   construction is not excluded; I only showed that no search in the views does better than
   e^{0.52b} per find and that every practical one does e^{0.8–0.9b}.
