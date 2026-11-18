# Proposal (for the maintainer): report near misses from the nice-only search — recommendation: do not build

**The idea.** The nice-only search's last stage (the overlap join's full check, CPU and GPU) already
computes every digit of n² and n³ for each candidate that reaches it. If it counted repeated digits
instead of stopping at the first, it could report "near misses" — numbers whose square and cube use
all but one or two of the base's digits — as a free by-product, giving bases 62 and 64 their
"nicest numbers" even though a second nice number is very unlikely there.

**What it would find: almost nothing at b − 1 or b − 2.** Every candidate the nice-only search looks
at has already passed the digit-sum test (n² + n³ ≡ b(b − 1)/2 mod b − 1, the "residue filter").
The digit sum of n² ‖ n³ is fixed by that, so a number missing one digit y and doubling one digit x
only passes when x ≡ y (mod b − 1), i.e. 0 and b − 1 swapped. Among candidates, numbers with b − 1
distinct digits are exactly as rare as nice numbers; at b − 2 only ≈ 1/30 (b62) or 1/8 (b64) of them
are candidates. Measured on real base-62 and base-64 fields (2.2 billion checked candidates, the
model confirmed to within 3–9 %), the expected haul is:

| | 61/62 or 63/64 digits | b − 2 | b − 3 |
|---|---|---|---|
| rest of base 62 + all of base 64 | ≈ 0.0005 | **≈ 5 (3–9)** | ≈ 600–950 |

Bases 58 and 60 (done) would have given ≈ 1–3 numbers at b − 2 each and a few hundred at b − 3.

**What it would cost.** CPU join (measured): +5–7 % of a field against today's code (+1–4 % for the counting itself). GPU: the check kernel's early exit (the "gate" after n²)
would have to let ≈ 8 % of candidates through instead of 0.14 %; done naively that makes every
warp compute the whole cube (+7 % of a base-62 field, +11 % at base 64); done with a compacted second
pass, ≈ +1 %. Plus: every nice-only backend (CPU join, CubeCL join, the stride paths, hand CUDA)
must implement it or results depend on who ran a field; clients must send the real digit count
(today hard-coded to b); the server stores nice-only numbers unchecked (it should verify the count);
and the jobs only publish a base's numbers once 20 % of it is searched in detailed mode, so nothing
would appear on the site without a jobs change.

**What is lost each day it is not running during base 62:** ≈ 0.01–0.03 numbers at b − 2.

**Recommendation.** Do not build it: the research program's bar was at least 30 numbers at
≥ b − 2 for ≤ 3 % of a field, and the yield is ~6× under it, for a reason (the residue filter) that
no change to the check can remove. The only regime with real numbers is b − 3 (≈ 600–950 numbers,
59/62 and 61/64 digits, about 1–2 % of all such numbers in those bases) at m = 3, which costs more
than m = 2 (gate pass rate 25 %). If you would like the "nicest numbers found so far" for base 62/64
on the site anyway, say so and I will price that variant properly (GPU compacted pass + client +
jobs + server check); otherwise this line is closed. No pull request has been or will be opened.
