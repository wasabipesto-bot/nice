# A3 adversary: notes (living; started 2026-11-16 16:28 UTC)

Code: `code/enum` (Rust, incremental n, n², n³ digit arrays; one pass per base), analysis
scripts `code/an_*.py` (run with `uv run --with numpy --with scipy`). Data in `data/` (per base:
`b<B>_stats.json` aggregates, `b<B>_sample.bin` ~2e6 hash-sampled n, `b<B>_pos.bin` every n with
niceness >= b - slack). Record layout in `code/load.py`.

Definitions used everywhere below:
- niceness = number of distinct digits among the b output digits (nice = b).
- E ("end-determined") for a full n: split n into top t = ceil(L/2) and bottom k = L - t digits;
  E = low k digits of n² and of n³ + the prefix certificate of the top t digits (output digits
  constant over the whole interval of n sharing that prefix). e = |E| positions. "E-clean" =
  those e digits distinct. Middle = the other b - e positions.
- uniform-middle model: middle digits iid uniform on 0..b-1, independent of E.

## Summary (18:20 UTC; details below)
- **Job 1, measured: nothing.** Exhaustive b10-b33 (~7e9 n) + windows at b40, b45, b50, b55, b62. No residue (1,643
  moduli), digit/position feature, rational proximity or gradient-boosted combination of cheap
  features predicts near-niceness or the middle beyond the prefix/suffix views. Given the views,
  the middle is iid uniform: per digit to 1e-4 (b32, 2e8 n), pairwise (403 pairs, MI null), in an
  omnibus higher-order test (chi2 ≈ dof, b25-b40), and the near-nice tail to 2 %
  (0.977 ± 0.016). Every deviation sits at a view edge (known crumbs) or is a base-dependent
  constant on the ends (E-clean / uniform = 0.65-1.12). Middle collisions decorrelate between
  n and n+1.
- **Job 2: the model (VC), and its optimum computed exactly** (§2.6): the free-list floor
  (fractional cover over all prefix × suffix views) vs the exact flat join at b20-b33: ×1.5 →
  ×5.9, growing ≈ ×1.085 per base (unit weights); the ideal output-sensitive join lands on the
  floor. The only exponent left in VC is the disjointness (OV) pairing; with production weights
  the gap is ×1.03 → ×1.11 (b32), consistent with N5's ×6-10 at b62/64.
- Outside VC: generators (lattice/Coppersmith/any solver) dead by counting (A1 D1 + §2.2);
  CRT/p-adic digits dead (measured); pandigital congruences are only mod b-1 and the suffix
  (all pandigitals of b9/b10, m <= 1000); joint square/cube algebra leaves no trace in the
  interior.
- Peers: no errors in A1/A2 conclusions; one artefact (A2's e^(-0.17b) slope; exact b20-b33 gives
  -0.108) and one caution (A1's planned Weyl-sum lemma would be ×100 looser than the data at b62).

## With another day
1. Measure the OV gap where it matters: exact flat vs ideal-OV vs floor in sampled transversal
   units at b40-b62 with production weights, fit its exponent, and try structured OV
   (random-subset bucketing tuned to the real per-digit densities) on real masks.
2. The VC optimum *with* list creation costs as an LP (prefix/suffix creation constraints), to
   show the join is within a constant of every VC algorithm except through OV.
3. Omnibus test at b62 with windows spanning many prefix blocks (strided sampling of n rather
   than contiguous windows), to cover the top-of-middle region at the frontier too.

## Log (in order)

### 1. Exhaustive enumeration, bases 10-30 (+32, 33 running)
All n in each base's range. 69 recovered at b10, no other nice number (as expected).
Runtime 7.5e6 n/s on one thread (b30, 4.9e8 n, ~70 s).

### 2. Features predicting near-niceness (`code/an_feat.py`)
Positive class = n with niceness >= b - j, j chosen so the class is ~1e-3 of the base
(b22-b30: 3e-4 to 7e-3; 2,000-240,000 positives per base).
- **Residues n mod m, every m in 2..300 with gcd(m, b) = 1, bases 20-30 (1573 tests): null.**
  Fraction of tests with p < 0.01 = 0.0095 (null 0.01), p < 0.001 = 0.0013; smallest
  Bonferroni p = 0.58. The b-1, b+1, b²-1 divisors included: nothing. (m sharing a factor with b
  reduces by CRT to the coprime part plus a suffix residue, which is the suffix view.)
- Digit features of n (all-n class): has-zero, min digit, lead digit, position x, digit sum
  show lifts of 0.5-2 at |z| up to 48, **all explained by the views**: conditioned on E-clean
  and weighted by the uniform-middle model's probability given e, every one falls to the null
  range (max |z| over bins 1-3, no consistent sign across bases): see the "eclean" run.
  Residues are also null in that conditioning (smallest Bonferroni p 0.47).

### 3. Is the middle uniform given the ends? (`code/an_middle.py`, `code/an_pos.py`, `code/an_core.py`)
Measured, all n of bases 17-33 (b32/b33 7e9 n together).
- **Near-nice tail vs the uniform-middle model, pooled b17-b33, E-clean n:**
  P(niceness >= b-3 | E-clean, e) observed/model = **0.977 ± 0.016** (3573 n);
  >= b-4: **1.001 ± 0.004** (57,055 n); >= b-2: 0.93 ± 0.08 (128 n). The product formula
  predicts the tail to 2 %.
- Full distribution chi2/dof grows with b (1 at b20, 175 at b30, 360 at b33) — **entirely from
  the view edges**: per-position stats at b30 (7.0e7 E-clean n): interior positions (n² 5-7,
  n³ 5-13) have P(digit in E) = e/b within 2 sd and digit-value chi2/29 = 0.4-1.6; the edge
  positions deviate by 15-190 sd: the first digit above the low block collides *more*
  (P(in E) +0.4 % abs.; the c + 2R₀d crumb), the digits just under the top certificate *less*
  (0.30 vs 0.33: the run-of-consecutive-values crumb, N5 A.3). Known class.
- **Pairwise independence of interior digits** (`an_core.py`, E2 = E + 2-digit buffers clean):
  403 interior position pairs over b25-b30 (incl. every n²×n³ cross pair): z mean +0.05, sd
  1.15; the only |z| > 4 are positions that are interior only in blocks with short certificates
  (top region). Mutual information of interior digit pairs (`an_mi.py`, 2e6 sample): MI/null
  = 1.025 (b28), 1.004 (b30); at b22/b25 the pair nearest the low block still carries x3-5 (the
  low-edge crumb reaches 2 digits in at L = 5).
- **Ends vs product formula:** E-clean fraction / uniform P(e) = 0.65-1.01 (b20-b30, mostly
  0.75-0.87): the ends are *less* clean than uniform (squares mod b, small leading digits). The
  baseline's "N·P(2L)" is ~×0.8 optimistic on the ends, a constant.
- **Autocorrelation** (`an_autocorr.py`): corr(interior collisions of n, of n+δ) for δ = 1, 2,
  3, b±1, b, b^k, b^k+1, b^(k+1), b^(L-2), 12345 at b28/30/33: all |r| <= 0.010 (null sd 0.004).
  Moving n by one decorrelates the middle completely: no smoothness for local search.
- **Near-nice collision geometry** (`an_nearpairs.py`, n with niceness >= b-3, b22-b33, ~4,000
  n, 12,500 colliding pairs) vs odds-weighted pair rates: mid-mid pairs obs/exp 1.008 (n³-n³),
  0.965 (n²-n³); only lo-lo pairs are depleted (0.70, 0.77; z -6, -7.5): near-nice n avoid the
  correlated low-digit collision clusters (S0=C0 drags S1=C1 along), a suffix-view fact.

### 4. Square vs cube digit-set dependence (`code/an_sqcube.py` + §3 cross pairs)
Mean |A ∩ C| matched vs shuffled within (n mod b) or (n mod b², position) strata: differences
<= 0.3 %, sign varies by base and stratification (end-digit effects). Interior n²×n³ digit pairs:
no excess (above). The "both internally distinct" set-level test is too thin in a 2e6 sample
(200-1200 n per base, 0 disjoint) and is subsumed by the pair test. **No dependence beyond the
views.**

### 5. CRT / p-adic decomposition of the base (`code/crt_check.py`) — dead, measured
Question: for b = p·q, is digit j of n² mod p a function of n mod p^(j+1) (which would split
the views into independent p- and q-lists)? Measured agreement of d_j mod p between n and
n + p^M·r (M >= j+1): b30 p=2 digit 1 0.59 (chance 0.50), b62 p=31 digit 1 0.49 / digit 4 0.25
(chance 0.03), never ~1. Reason: a digit < pq is not determined by its residue mod a power of
one factor; x mod p^(j+1) mixes d_0..d_j and needs each lower digit exactly, i.e. the q-part
too. Digit j needs n mod b^(j+1) — the suffix view, no factorisation. For b = p^a the CRT is
empty (bits/base-p digits = finer tree, N5 A.4).

### 6. More residue families (`code/an_resbig.py`) — null
Near-nice classes (two thresholds) at b25-b33 against m = b²+1, b³-1, b³+1, b²+b+1, b²-b+1,
(b-1)², (b+1)²: chi2 z-scores all within ±3.3 (70 tests, one at 3.3). Block-sum moduli carry
nothing about near-niceness either.

### 7. The lottery constant (all n, no conditioning)
P(niceness >= b-j) / (same for b iid uniform digits), j = 3..5, b17-b33: 0.74-0.99; odd bases
(23, 29, 33) 0.92-0.99, even bases mostly 0.77-0.88 (squares mod 2 at the low end). So real
numbers are slightly *worse* than the lottery, by a constant; λ estimates that use the plain
lottery are ~×0.85 high. Heuristic λ summed over b10-b60 = 0.15; the one find (69, λ = 0.077 at
b10) is a ~7 % event under it. Not anomalous.

### 8. b32 with the core analysis (2.2e8 E-clean n)
Interior positions (n² 4-8, n³ 4-14): P(digit in E) = e/b within 2.4 sd (sd 3e-5 absolute,
1e-4 relative), digit-value chi2/31 = 0.55-1.15. Top-region positions (n² >= 9, n³ >= 15) and
the first digit above the low block carry all deviations (prefix/suffix crumbs). **Conditional
uniformity of the middle holds to 1e-4 per digit at 2e8 samples.**

### 9. Closeness of x = n/b^L to small rationals (`code/an_rational.py`) — null
E-clean near-nice n vs model-weighted E-clean sample, indicator |q·x - p| < 1e-3·q for some
q <= Q (Q = 2…34), b25-b33: lifts 0.89-1.19, all |z| < 2.6, no consistent sign. (Brief N5
item "closeness of n/b^L to small rationals": nothing.)

### 10. Omnibus higher-order test of the middle (`code/an_e3.py`, Rust `hist_e3`)
Fixed interior core = n² positions [k+2, l2-t-3] and n³ [k+2, l3-t-3] (same set for every n).
Condition on ALL other b - core digits being distinct; compare the full distribution of the
number of distinct digits with "core digits iid uniform" (exact DP). Exhaustive n:
| b | core | N conditioned | chi2 / dof | mean distinct obs vs model |
|---|---|---|---|---|
| 25 | 7 | 1,068 | 2.6 / 4 | 19.766 vs 19.740 (sd 0.031) |
| 27 | 7 | 1,216 | 1.7 / 4 | 21.634 vs 21.625 (sd 0.029) |
| 28 | 8 | 2,821 | 2.1 / 5 | 22.016 vs 22.020 (sd 0.020) |
| 29 | 9 | 11,602 | 9.9 / 6 | 22.443 vs 22.437 (sd 0.011) |
| 30 | 10 | 79,932 | 3.2 / 8 | 22.878 vs 22.875 (sd 0.004) |
| 32 | 10 | 96,118 | 9.2 / 7 | 24.724 vs 24.720 (sd 0.004) |
| 33 | 11 | 248,472 | 7.1 / 8 | 25.161 vs 25.159 (sd 0.003) |
| 40 (4 windows, 1.6e9 n) | 16 | 236,796 | 16.8 / 12 | 29.330 vs 29.329 (sd 0.003) |
**Given everything outside the interior, the interior is
an iid uniform draw, including all higher-order (not just pairwise) dependence, at these sizes.**

### 11. Ends among admissible n vs the product formula (`code/an_ends_adm.py`)
E-clean fraction / uniform product P(e), admissible (residue-pass) n vs all n: identical within
1 % in every base (b20-b40), and base-dependent 0.65 (b24) … 1.01 (b29) … 1.12 (b40). The
baseline's ends formula is right to a base-dependent constant (±35 %), set by squares/cubes mod
b and the leading-digit range; admissibility does not interact with it.

### 12. Does the outer digit set's *composition* steer the core? (`code/an_composition.py`) — null
Residual core hits on the outer set (obs - core·|outer|/b), grouped by the outer set's mean
digit, presence of 0 / b-1, parity balance, small-digit count (quintiles), b28/b30 2e6 n each:
all |z| <= 2.4, signs inconsistent between bases. Which digits are used at the ends does not
change how the middle fills.

### 13. Square/cube digit SETS, exhaustive, given each is internally distinct (`sc` histogram)
For every n whose n² and n³ each have no repeated digit (N = 269 … 133,519 per base, b20-b33),
overlap |A ∩ C| vs the hypergeometric of independent uniform sets of the same sizes: mean
excess +0.00 … +0.06 digits; z = +10.7 (b30), +14.2 (b32), +4.4 (b33), within ±3 at the small
bases; the low-overlap tail (ov = 4, i.e. niceness b-4) is 10-15 % short at b30/b32. Direction:
the square and cube share *slightly more* digits than independence predicts, i.e. slightly worse
for niceness. Not isolated (the histogram has no positional split), but the interior pair and
omnibus tests (§3, §10) show no excess, so it must sit in the end digits (S0/C0 = r², r³ mod b,
small leading digits of both) — the same constants as §7/§11.
Checked (`code/an_overlap_pos.py`, n from the near-nice file with both sides internally distinct,
b30 4,951 n / b32 6,403 n): the shared digits sit at the last digit of n² and n³ (obs/exp 1.22
and 1.39 at b30, 1.10/1.12 at b32) and at the leading digits (1.07/1.16 at b32); every interior
position 0.91-1.02. **The excess is an end effect; attribution confirmed.**

### 14. "Anything cheap", by machine (`code/an_ml.py`, sklearn HistGradientBoosting, 1 thread)
Features: every digit of n (categorical), n mod each prime <= 47, n mod b±1, position x.
Targets on the fixed interior core: (a) collisions among core digits; (b) core digits hitting
the outer digit set, as a residual after the null expectation core·|outer set|/b. 600k n
(b28, b30), 75/25 split, shuffled-target control. Held-out R²: (a) -0.0004/-0.0005 vs control
-0.0004; (b) -0.0003/-0.0004 vs control -0.0003. (Without the residualisation (b) shows R² 0.011
— entirely the size of the outer set, which the ends determine: a reminder that every "lift"
must be measured against the views' own prediction.) **No interaction of cheap features
predicts the middle.**

### 15. Large bases, windows (`code/run_big.sh`; enumerator now computes n², n³ by digit-vector
multiplication, so any b <= 64 with n < 2^128; validated bit-identical on b28)
4 windows × 1.5e8 n at b45, b50, b55, b62 (`data/big/`).
- Omnibus test (§10): b45 core 19, N 89,829, chi2 6.0/12, mean distinct 32.604 vs 32.603;
  b50 core 22, N 32,815, 8.2/12; b55 core 25, N 64,224, 17.5/14, 39.197 vs 39.198.
- **b62 (the frontier base, L = 13)**: 3.2e6 E-clean n. Interior positions n² 6-15 and n³ 6-27:
  P(digit in E) = e/b within 2.7 sd, digit-value chi2/61 = 0.56-1.40 (32 positions). The top
  positions (n² >= 16, n³ >= 28) are near-constant only because a 1.5e8 window sits inside one
  prefix block (width b^6 = 5.7e10) — a sampling artefact of narrow windows, not structure; it
  also makes the fixed-core omnibus empty at b62 (N = 0).
- Mean niceness vs b iid digits: 28.71/28.63 (b45), 31.72/31.79 (b50), 35.08/34.95 (b55),
  39.50/39.38 (b62).
- b62 again on 2,000 random windows × 3e5 n (`data/big62s/`, 172 s): omnibus test core 28,
  N 6,105, chi2 8.6/13, mean distinct 44.221 vs 44.241 (sd 0.026). Positions n² 15-18 and n³
  28-31 still non-uniform: in a 3e5-wide window the upper middle digits move slowly (a digit at
  position p of n³ changes every ~b^p/(3n²) steps), so narrow windows cannot sample them; a
  proper test there needs one n per window (another day, item 3).
**The conditional uniformity of the middle holds at the production base.**

## Verdict on job 1 (measured)
Nothing. Hunted: 1,573 coprime residues m <= 300 + 70 structured moduli (b^k±1 family,
(b±1)²); 11 digit/position features of n; rationals p/q, q <= 34; position-pair collision rates
(all pairs, 2e6 n per base); interior per-digit uniformity at 1e8-2e8 n; pairwise MI; an omnibus
higher-order test (b25-b40); composition of the end set; autocorrelation in n; near-nice
collision geometry; square/cube set overlap. Every deviation found is located at the edge of a
prefix or suffix view (the known crumbs) or is a base-dependent constant on the ends. **The
uniform-middle assumption holds: per digit to 1e-4 (b32, 2e8 n), the near-nice tail to 2 %
(b17-b33), and in distribution (omnibus chi2 ≈ dof at b25-b40).**

## Part 2: the adversary

### 2.1 The weakest model I can defend (and what the data above adds to it)
**View-certificate model (VC).** An algorithm touches the range only through *views*: sets
S of candidates described by fixing digits of n (any positions) and/or a residue of n mod m.
Creating or testing a view costs >= 1. A view returns its certificate C(S) — the (position,
digit) pairs of n², n³ constant on S — and nothing else; a candidate may be discarded only
inside a view whose certificate repeats a digit (or whose residue class fails mod b-1).
Soundness: every nice n reaches a fully fixed view.
Within VC the cost is a covering number (computed exactly at b17-b33 in §2.6: the flat join is
×1.5-5.9 above the free-list optimum at unit weights, the gap growing ≈ ×1.085 per base and
lying entirely in the pairing step), and prefix × suffix views are the only ones that matter, because:
- (measured, A1 E1 + my §2) fixing digits anywhere but the ends, or n mod m for m coprime to
  b (m <= 300 here, <= 1500 in A1), certifies nothing about the middle (<= 2 % of a digit's
  entropy) — so the useful views are prefix × suffix pairs (+ the mod b-1 key);
- (measured, §3, §8) given the certificate of the best views, the rest is the uniform lottery:
  per-digit uniform to 1e-4, pairwise independent, near-nice tail predicted to 2 %, no cheap
  feature of n with lift, no autocorrelation. So the VC lower bound is not just "the model I
  could think of": inside the views, the data leave no statistical lever for even an unsound
  (probabilistic) skip rule.
**What VC excludes** (each must be either ruled out or tried):
(a) generators — methods that output candidates by solving for n given prescribed output
digits (lattices, Coppersmith, Hensel/real roots) instead of testing views;
(b) predicates on sets of n that are not certificates — algebraic identities, counting
(inclusion-exclusion, characters), joint square/cube algebra;
(c) different alphabets for the views (CRT/p-adic digits of the base);
(d) number-level structure of the concatenation n²·b^l3 + n³ or n³·b^l2 + n² = n²(n·b^l2 + 1).

### 2.2 (a) Generators: a counting lemma (derived) that covers lattices
Fix a view (top T, context with e distinct certified digits) leaving x free digits y of n,
and let a generator prescribe a pattern on a set W of w output positions and return the y that
realise it. Its cost is >= (number of patterns it must try) + (number of y it returns).
- Patterns that can be part of a nice n: (b-e)(b-e-1)…(b-e-w+1) <= (b-e)^w = (bq)^w, q = 1-e/b.
- Returned y: >= b^x · q^w-ish (the fraction of y whose window is clean), and >= 1 per tried
  pattern when w > x only if the pattern is realised.
So cost >= min_w [ (bq)^w , b^x q^w ] >= (bq)^x = b^x q^x (at w = x). The tree on the same x
digits costs about b·(b q²)^(x-1) (two certified digits per fixed digit). Generator / tree
>= q^-(x-2): **the generator loses by (1/q)^(x-2) however patterns are solved**, i.e. it can
certify at most one output digit per free digit. Grouping patterns into boxes (a lattice with
interval constraints per digit) reduces the pattern term but not the returned-y term, which is
already the binding one at w <= x.
For non-affine windows (the true middle, degree d = 2 for n², 3 for n³) small-root methods
additionally need X^d · Z < M, i.e. w >= d·x prescribed digits per x free digits; then the
pattern term (bq)^(d x) beats b^x only if (bq)^d < b, i.e. **b - e < b^(1/d)**: fewer than √b
(n²) or b^(1/3) (n³) digits still unknown. Any digit-local state knows at most ~4L-4 ≈ 0.8b
digits, so b - e >= 0.2b + 4 > √b for every base. **Lattice/Coppersmith on the middle is dead
in every base, independent of lattice cost.** (N5 C2 measured the affine case at ×3000-5000
loss.) A1's D1 identity (Σ_v |F^-1(v)| = #{m : F(m) allowed}) is the cleaner form of the
first half and kills even a free solver oracle; A1 E5 measures it at b40. The degree condition
above only adds that the solver would not exist anyway.
Mixed prescriptions (A1 Q3) are covered: the lemma does not care which windows W is made of.

### 2.3 (b) Joint square/cube algebra
- n³ = n·n²: every partial knowledge of n² is a view of n (low digits of n² ↔ n mod b^k up to
  square-root ambiguity; top digits ↔ prefix of n), so "knowing part of n² and using
  multiplication by n" is VC again. Measured: interior n²×n³ digit pairs are independent
  (§3: z sd 1.15 over 403 pairs; MI = null), so the product structure leaves no statistical
  trace in the middle either.
- Counting / characters (sums over n of products of digit functions of n²): no transfer
  matrix of bounded size exists (carry state from the low end = n mod b^j); A2 I3 shows the
  inclusion–exclusion truncation error is exactly Σ_non-nice C(f_n - 1, m), so truncations are
  useless — agreed, checked their identity: for m = 0 it gives Σ_n 1 = N, correct.
- Symmetric-function invariants beyond Σd mod b-1: A2 shows digit-class sums collapse to the
  b-1 root; Σd², Σd·d' have no expression in n. Measured confirmation: no residue mod
  m <= 300 (coprime to b) or in the b^k ± 1 families has lift on near-niceness (§2, §6).

### 2.4 (c) CRT / p-adic alphabets — measured dead (§5)
Digit j of n² mod p is not a function of n mod p^(j+1) for b = p·q (agreement 0.49-0.59 vs 1);
the base-b digit needs n mod b^(j+1). For b = p^a, base-p digits are a finer tree over the same
leaves (N5 A.4).

### 2.5 (d) The concatenated pandigital number P = n²(n·b^l2 + 1)
- Searching from the P side: pandigitals number ~b! ≫ N ≈ b^(b/5); dead by count.
- Congruences on P: P mod m is a function of n mod m; a filter exists only if pandigitals miss
  residues mod m. They do so only for m | b-1 (digit sum); mod b+1, b^k ± 1 etc. the
  pandigital set covers every residue as soon as b >= ~10 (the alternating/block sums range
  over far more than m values). Measured proxy: §6 (no lift for those moduli).
- Divisibility P ≡ 0 mod n² is the definition, not a filter; the cofactor n·b^l2 + 1 ≡ 1 mod
  b^l2 restates that the low digits of P are n². Nothing new.
- Measured (`code/pandigital_res.py`, all pandigitals of b9 and b10, m = 2..1000): residues are
  missing **only** for m sharing a factor with b-1 (digit-sum class; b10: every multiple of 3,
  b9: every even m) or for m with a factor b^2-type (b9: 81, 243, 729…; b10: 100, 200, 250, 400,
  …: the last two digits of P = of n² must differ — the suffix view). No other modulus up to
  1000 constrains a pandigital. So P's congruences = {mod b-1, suffix}: already used.


### 2.6 The VC model's optimum, computed exactly at small bases (`code/enum/src/bin/{floor,psj,psj2,psj3}.rs`, `code/an_floor.py`)
Three exact counts over every admissible n of b17-b33 (data `data/floor_*.txt`, `data/psj2.txt`):
- **flat PSJ**: min over (t, k), t + k >= L, of tops created + bottoms created + key-matched pairs
  of individually certified prefix_t and residue_k (A2's `tree_counts.py` definition; my Rust
  port reproduces A2's b20/b22/b24/b25 numbers exactly);
- **ideal-OV PSJ**: same, but only pairs that pass the AND are paid (a perfect output-sensitive
  disjointness join, N5 C3);
- **VC floor with free lists**: Σ_n 1/μ(n), μ(n) = size of the largest prefix_t × residue_k view
  (t + k <= L, any gap) containing n whose revealed certificate repeats a digit (μ = 1 if none).
  A fractional-cover argument makes this a lower bound on the number of tested views of ANY
  sound VC algorithm, however adaptive, even if every list were free.

| b | A (admissible) | flat PSJ | ideal-OV PSJ | VC floor (free lists) | n with μ = 1 | flat / floor |
|---|---|---|---|---|---|---|
| 20 | 10,638 | 6,251 | 4,054 | 4,052 | 2,001 | 1.54 |
| 22 | 80,406 | 31,279 | - | 14,471 | 10,216 | 2.16 |
| 24 | 98,707 | 36,958 | 16,843 | 13,936 | 7,475 | 2.65 |
| 25 | 1,606,456 | 468,548 | 181,017 | 170,504 | 108,179 | 2.75 |
| 28 | 5,749,318 | 1,348,129 | 433,800 | 390,398 | 237,144 | 3.45 |
| 29 | 5,939,393 | 1,586,611 | 487,326 | 498,786 | 220,118 | 3.18 |
| 30 | 34,095,592 | 6,438,700 | 1,552,052 | 2,293,863 | 658,800 | 2.81 |
| 32 | 150,656,514 | 22,164,444 | 3,901,989 | 4,600,121 | 1,644,655 | 4.82 |
| 33 | 511,951,689 | 62,020,883 | 10,081,802 | 10,486,511 | 6,202,945 | 5.91 |

Floor extended on windows (4 × 2.5e8 n each, `data/floor_win.txt`): floor / A = 0.0163 (b34),
0.0041 (b37), 0.0100 (b38), 0.0029 (b40); fit b20-b40: ln(floor/A) slope -0.230 per base.
Fitted slopes of ln(cost / A) against b, b20-b33 (unit weights): **flat PSJ -0.108 per base**
(the baseline's e^(-0.094 b), confirmed exactly), **ideal-OV -0.219, free-list floor -0.190,
μ = 1 count -0.219.** Measured conclusions:
1. The flat join's ratio to the best conceivable view algorithm is not a constant: it grows
   ≈ ×1.085 per base (1.5 at b20 → 5.9 at b33). In VC the exponent of cost/A can at most
   roughly double (e^(-0.1b) → e^(-0.2b)), and not more: the floor itself falls only e^(-0.19b).
2. **The whole of that in-model gap is the pairing step.** The ideal output-sensitive join (lists
   paid in full, only passing pairs paid) lands on the free-list floor (within ×0.7-1.04 at
   b20-b33). Nothing else in VC — not adaptivity (A2 I6: ×1-1.6), not free lists — is worth an
   exponent. Equivalently: building lists is never the asymptotic problem; testing pairs that
   fail is.
3. This sharpens N5 C3 / A2 I1 (which priced the OV gap at today's shape as a constant ×6-10 or
   ×1.35): as a function of b the gap is exponential. Whether it is reachable is the
   Orthogonal-Vectors question with d = b and set density ~0.3-0.5; known OV algorithms win
   only at d ≲ c·log n (galactic constants) or for very skewed densities.
4. **With N5's weights** (list entry 50 AND-units, pair 1, survivor 45; `psj3`, `data/psj3.txt`)
   lists dominate at small b and flat / ideal-OV is only 1.03 (b20-b24), 1.06-1.09 (b25-b30),
   1.11 (b32) — rising slowly, consistent with N5's ×6 at b62 / ×10 at b64. So: in today's
   frontier the gap is a constant ×6-10, asymptotically it is the one exponent in VC.

## Part 3: attacks on A1 and A2 (read 17:25 UTC, re-read 18:15 and 18:35; A1 unchanged since 17:15)

### A1 (progressions)
- **D1 / E5 (prescribe-and-solve counting identity)** = my §2.2, found independently; theirs is
  the stronger form (it kills even a free oracle via Σ_v |F^-1(v)| = #{m : F(m) allowed}), and
  E5 measures it at b40. My Coppersmith-degree condition (b - e < b^(1/d)) is therefore
  redundant; keep it only as "even the solver is unavailable". Hole I looked for: grouping
  prescriptions into digit-interval boxes (one lattice call per box, (#intervals)^w calls instead
  of b^w·P_w) cuts the call term but not the output term #{m: window avoids E}, which is >=
  b^u·P_w and already loses at w <= u. D1 survives. Its premise "F equidistributed" was measured
  by them at b20-b23 with entropy D; my §3/§8/§10 give the stronger version (per digit 1e-4 at
  2e8 n; omnibus higher-order test b25-b40).
- **E3 (ramified slices p^j | n)**: independently re-measured from my exhaustive data
  (`code/check_a1_e3.py`, every n of b28/b30/b32/b33): niceness >= b-4 rate in the slice / whole
  range = 0.51 (b28, 7|n), 0.49 (b33, 11|n), 0.56 (b30, 5|n), 0.89-1.02 for p = 2, 3 at b30/b33,
  and 0.87 → 0.70 → 0.19 for 2|, 4|, 8| n at b32 = 2^5 (prime-power death, as they say). Their
  tail proxy is right. Objection to the framing "a real exception to <= 2 per digit": N5 §B
  already notes that on any sub-family (fixed shared digits π) the ratio per *free* digit is
  arbitrary; the slice is one more sub-family, distinguished only by being described by a residue
  of n instead of digits. The difference that matters is that the π-families tile the range (the
  join's partitions) while the ramified slices cannot be translated (non-zero classes are
  unramified), so E3 is strictly a thin sub-family — agreed dead, with their exchange-rate numbers.
- **"With another day" #1 (turn equidistribution into a lemma, error O(b^-1/2) per digit)**:
  an additive error ε per digit on P(digit allowed) ≈ (b-e)/b is a relative error ε·b/(b-e)
  ≈ 2ε per digit; over the ~3L ≈ 0.6b middle digits that is a factor e^(1.2·b·ε). With
  ε = c·b^-1/2 this is e^(1.2c·√b): at b62, c = 0.5, ×100 in either direction (derived). So the
  lemma could not exclude a ×10-100 constant. The measured bound (per digit 1e-4 relative at b32,
  near-nice tail 2 %, omnibus) is far tighter than any such theorem would be. Recommend: state
  the A1 negative as measured + D1 identity; a Weyl-sum lemma would add rigour but *weaken* the
  quantitative claim.
- E1 / E2 / E4 agree with my data in every overlap (residues mod q: their q <= 1500 at b22,
  mine m <= 300 coprime at b20-b30 for near-niceness; both null). No disagreement found.

### A2 (digit sets)
- I3 identity Σ_{j<=m} (-1)^j C(f, j) = (-1)^m C(f-1, m): checked (f = 0 gives 1 for every m).
  Correct, and it does make truncated inclusion–exclusion provably useless.
- I4 (representations): Σ_s 1/R_s >= 1 for coverage holds for independent random restrictions;
  a *deterministic* partition (hash h(n) assigns each n to one shape) gives Σ = 1 exactly, and
  then work = Σ_s W_s·(share_s), which is still >= min_s W_s only if the restriction can be
  imposed on both lists at full rate — it can, by residues of n (bottoms) or leading blocks (tops),
  which is exactly N5's adaptive-depth constant. Their conclusion holds.
- I5/I6 (solvers, optimal adaptive tree): their OPT tree is ×4-8 above the flat join in *node
  counts*; with N5's weights (list entry ≈ 50 AND-units) trees lose by more. The CP-SAT result
  (branches/PSJ constant ≈ 21-26, no trend) is the cleanest empirical evidence I have seen that
  no learnable cross-rule exists — consistent with my omnibus test from the opposite side.
- I1 ceiling (≤ ×1.35 from a perfect OV oracle at today's shape) is right for today's shape; at
  N1's deep shape the pair term is a larger share (N5 C3: ×1.3-1.6). Their "realistic ×1.1"
  should say "at today's shape".
- I2: S1 (subset-sum mod b-1) 0/4400 — consistent with my §12 (the composition of the end set
  does not steer the middle at all), which is the statistical version of their algebraic result.
- **Re-read 18:15 (A2 now has I8, I9, growth fits, a model).** Their "another day" #2 asks for
  a Rust PSJ counter to b28-b34 and whether the weighted ideal-OV gap starts to grow: done here
  (§2.6, `psj2`/`psj3`, reproduces their b20-b25 PSJ exactly): weighted flat / ideal-OV =
  1.03 (b20-24) → 1.06-1.09 (b25-30) → 1.11 (b32); unit-weight 1.5 → 6.2 (b33). It grows, as
  they guessed, and the free-list VC floor lands on ideal-OV — so their model statement ("work is
  the flat join's up to constants except the ideal-OV term") is confirmed with the refinement
  that nothing else in VC, not even free lists, has an exponent.
- **Objection to their growth table:** "all three save ≈ e^(-0.17b) against A" is fitted on
  b17-b24 (5 bases, A = 483 … 98,707, ranges so small that b17/b18 dominate the slope). On the
  exact counts b20-b33 (9 bases) flat PSJ / A falls as e^(-0.108 b) — the baseline's -0.094 is
  right, -0.17 is a small-base artefact. Their solver/tree "same exponent as the join" conclusion
  is unaffected (it is a ratio).
- I8 (dual tree costs 6-10× FLAT; digit keys ×1.3-1.5 of a ×8-27 in-unit gap) is the empirical
  counterpart of my statement that the gap is real and lives in per-element deep digits; agree.
- A2 I10 (CaDiCaL ≈ optimal tree ×1-2, added 18:29): consistent with I5/I6; no objection.
- Nothing in A2 that I could break.
