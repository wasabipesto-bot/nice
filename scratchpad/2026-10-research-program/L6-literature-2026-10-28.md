# L6 literature check: interior-digit theorems, 2026-10-28

Scope per LEDGER L6: does Bassily–Kátai (and descendants) or any 2020–2026 paper give
anything **explicit** about interior digits of n² and n³ at base b≈58–64, n with
12–13 digits, n² ≈2b/5 digits, n³ ≈3b/5 digits? And a two-line derivation of the
carry-interval certificate width. No subagents used; primary sources fetched directly
(arXiv/HAL/author pages) except where noted.

## 1. Bassily–Kátai and its joint extension

**N. L. Bassily, I. Kátai, "Distribution of the values of q-additive functions on
polynomial sequences," Acta Math. Hungar. 68 (1995), 353–361.** I could not reach the
Springer text itself (paywalled, DOI `10.1007/BF01874349`), but the theorem is quoted
verbatim in a source I *did* read in full:

**W. Steiner, "On the joint distribution of q-additive functions on polynomial
sequences," Theory Stoch. Process. 8(24) (2002), 336–357.** PDF:
https://www.irif.fr/~steiner/joint.pdf (fetched via `curl`, read with `pypdf`; WebFetch
itself got a 403).

Steiner's Theorem 1 restates Bassily–Kátai: for a q-additive f with f(bqᵏ)=O(1) and a
polynomial P of degree r, the normalized count f(P(n)) satisfies a CLT as N→∞. The
mechanism behind it — and the part that actually matters for us — is **Proposition 1**
(due to M. Drmota, *The joint distribution of q-additive functions*, Acta Arith. 100
(2001), 17–39, restated by Steiner as the shared engine of Theorems 1–4):

> For P₁,…,P_d of **different** degrees r₁,…,r_d with positive leading coefficients, any
> λ>0, and nonnegative integers h₁,…,h_d:
> (1/N)·#{n<N : ε_{q,kⱼ⁽ˡ⁾}(P_l(n)) = bⱼ⁽ˡ⁾, 1≤j≤h_l, 1≤l≤d} = 1/(q^{h₁}···q^{h_d}) + O((log N)^{−λ})
> uniformly for (log N^{r_l})^η ≤ k₁⁽ˡ⁾ < … < k_{h_l}⁽ˡ⁾ ≤ log_q N^{r_l} − (log N^{r_l})^η, some η>0.

This is **exactly our joint question** — n² and n³ have different degrees (2 and 3)
with the **same** base q=b, and the note right after Theorem 2 confirms the coprimality
of the q_l's assumed in older statements "is not used in the proof and therefore not
necessary," so q₁=q₂=b is covered. Read plainly: any *fixed, bounded* set of digit
positions of n² and of n³, provided each is at distance ≥(log N^{r})^η from both ends,
is asymptotically uniform and **jointly independent** across the two polynomials.

**Why this still gives nothing computable at our sizes:**

1. **Non-effective / "rather bad" error term.** Steiner's own text, two paragraphs after
   using Proposition 1 to build the net-equidistribution argument: *"Proposition 1 gives
   rather bad error terms if we want to calculate the number of w_k⁽ˢ⁾(n) in an arbitrary
   set."* The λ, η, and the implied constants come out of a moment-method proof
   (Billingsley-style convergence of moments); no numeric threshold "valid for N≥…" is
   given anywhere in the 1995, 2001, or 2002 papers I read.
2. **Fixed h_l, not all positions.** The statement is for *bounded* h_l as N→∞. Our
   rejection rule needs the *joint distinctness of all* digit positions of n² and n³
   together (h_l ≈ L_l, the full digit count) — a completely different regime from "h_l
   fixed, N large," and nothing in this line of work addresses it.
3. **No usable boundary width.** The exclusion zone has width (log N^{r})^η for
   arbitrary small η>0 and unspecified N-threshold. At our scale N is not large at all:
   n has 12–13 digits, so log_b(N^{2 or 3}) ≈ L₂ or L₃ ≈ 24–26 or 35–38 — the asymptotic
   regime the theorem is stated for has simply not started. There is no way to plug
   b≈60, L≈25 into "(log N^r)^η" and get a meaningful finite exclusion width or
   confidence level.

**Verdict for task 1: no.** Nothing in Bassily–Kátai (1995), Drmota (2001), or Steiner
(2002) is explicit enough to bound how many interior digits of n² or n³ are forced or
correlated at fixed b∈[58,64], D=12–13. This sharpens, rather than contradicts, the
September review's flag ("obtain the full theorem … before planning"): the full theorem
is now obtained, and it fails for the same structural reason Swaenepoel's did — an
asymptotic-in-digit-length statement whose free parameters have no assigned value at
D≈25–38.

*Not independently verified*: I did not get the original Bassily–Kátai or Drmota PDF
directly (Springer paywall; numdam copy of Drmota's Acta Arith. 2001 paper not located).
Steiner's restatement, read in full, is the primary source used above.

## 2. 2020–2026 papers on digits of squares/cubes/polynomials, one line each

| Paper | What it gives | Rejection rule for our (prefix,suffix) pairs? |
|---|---|---|
| C. Wu, "Pandigital and penholodigital numbers," arXiv:[2403.20304](https://arxiv.org/abs/2403.20304) (v3, 2025) | n² pandigital ⇒ n≡m (mod b−1), m in a computable set; square-only, no cube | No — v3 HTML confirms it never treats n² and n³ jointly; project already has the analogous joint congruence |
| C. Swaenepoel, Math. Ann. 2025, HAL [hal-05236556](https://hal.science/hal-05236556v1) | Positive-proportion prescribed-digit asymptotic for squares, circle method | No — shown inadmissible at these lengths in the Sept review (digit budget < mandatory boundary count, every b in range) |
| Geißer–Körner–Kurz–Zahn, "Squares with three digits," arXiv:[2112.00444](https://arxiv.org/abs/2112.00444) (2021) | Carry-interval contraction (≈1/b per column), extracts one exact square digit from a carry bound | Already mined in Sept review as the carry-forgetting lemma; not new here |
| Kaneko–Stoll, "Products of integers with few nonzero digits," arXiv:[2112.03077](https://arxiv.org/abs/2112.03077) (2021) | Explicit bound on min(a,b) given s(ab)=k≤4, s(a)=ℓ, s(b)=m, binary | No — *few* nonzero digits of a *product*, opposite regime from all-distinct digits of one root's powers |
| Madritsch, "Effective Erdős–Wintner theorems," arXiv:[2009.05435](https://arxiv.org/abs/2009.05435) (2020) | Makes existence of a limiting distribution for q-additive f(n) effective | No — aggregate distribution function, not individual/interior digit positions |
| "Level of distribution of the sum-of-digits function in APs," arXiv:[2504.02784](https://arxiv.org/abs/2504.02784) (2025) | Explicit exponent in a Thue–Morse-style bound, generalizes Spiegelhofer 2020 | No — asymptotic in N, no threshold reachable at D≈25–38; aggregate statistic, not positional |
| "Explicit Surjectivity Threshold for Digit Sums of Primes," arXiv:[2606.04677](https://arxiv.org/abs/2606.04677) (2026) | Numeric threshold M<1.78×10³² (base 10) above which every admissible digit-sum is hit by a prime | No — illustrates the scale of "explicit" results here: 10³², nowhere near 25–38-digit numbers |
| Hare–Laishram–Stoll, "Sum of digits of n and n²," JNT 2011 (pre-2020, included as the clearest explicit precedent) | Finite computed tables of all odd n with s_q(n)=s_q(n²)=k, small k, via Lindström splitting (not B–K) | Right *shape* (explicit finite search + an algebraic non-interference criterion), but digit-sum equality, no cube, doesn't extend |
| Bérczes et al., "Binary digits of n and n²," arXiv:[2203.05451](https://arxiv.org/abs/2203.05451) (2022) | Resolves finiteness of {n odd: s(n)=s(n²)=k} for k∈{9,10,11}, algorithm + explicit solutions | No — aggregate digit-sum, binary only, no positional claim |

No 2020–2026 paper found gives a sound, explicit rejection rule for a (prefix, suffix)
pair at these lengths. The field's "explicit" results are either (a) aggregate digit-sum
statements, not positional/interior, or (b) genuinely numeric but at scales (10³²) far
above ours, or (c) asymptotic-only with unassigned constants, same failure mode as §1.

## 3. Carry-interval certificate width (elementary, two lines)

Let n have D digits in base b, and suppose the **top t** digits are fixed (the prefix),
leaving the low D−t digits (⊇ the 6-digit suffix) free, 0≤r<b^{D−t}:

1. n is determined up to relative error r/n < b^{D−t}/b^{D−1} = b^{1−t} (n≥b^{D−1}); for
   k=2,3: n^k = n^k·(1+O(k·b^{1−t})), by first-order expansion of (n+r)^k/n^k.
2. That relative error pushes the *absolute* uncertainty past the top t−1 digits of n^k
   into roughly one more place (⌈log_b k⌉=1 for b≥58>3). So **t known top digits of n
   pin down the top t−2 digits of both n² and n³ exactly** (one guard digit for the
   b^{1−t}→b^{D−t} rescaling, one more for the k-multiplier), with one further digit
   known only to a ±1 carry — matching the two-column contraction already proved in the
   Sept review (§3.1, from the GKKZ recurrence) from the other direction.

Concretely at b=58–64: the prefix is only the *top* part of a 12–13-digit n (the loop's
suffix already claims the low 6), so t≈6–7, and the certificate knows at most t−2≈4–5
leading digits of n² (of L₂≈24–26) and of n³ (of L₃≈35–38). The suffix fixes the low
digits exactly, with no carry loss. The uncovered interior — roughly L₂ and L₃ minus a
handful of digits at each end — is exactly what the task names, and §1–2 show no
literature result closes it.

## Bottom line for LEDGER L6

- Bassily–Kátai's joint extension (Drmota 2001 / Steiner 2002) is the strongest formal
  statement of "interior digits of n² and n³ are asymptotically independent," now read
  in full rather than by title. It gives **no finite, effective bound** at b≈60,
  D≈25–38: non-effective constants, a fixed-h_l asymptotic regime (not all-positions),
  and an unassigned boundary width.
- No 2020–2026 paper closes the gap either; every explicit numeric result found here
  operates at a scale (10³²+) with no bearing on 20–40-digit numbers.
- §3's carry-interval derivation is the one usable piece: it quantifies exactly how
  little the certificate can know, and sizes the interior gap the join must still handle
  unaided.
- Recommended verdict: **closed, no admissible hypothesis at our lengths** — the kill
  criterion, now on a primary-source basis rather than a missing reference.
