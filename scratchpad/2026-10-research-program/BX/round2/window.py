#!/usr/bin/env python3
"""BX round 2: how much of (n^2, n^3) survives a one-digit change of n? (the 'window lemma', checked)
Also the uniform-model expected count per base and the uncontrolled fraction a feasible search may leave."""
import random, sys
from math import lgamma, log, exp
def digits(x, b):
    d = []
    while x: x, r = divmod(x, b); d.append(r)
    return d
def rng_n(b, rnd):
    # a random n whose square and cube have b digits in all (the base's range), if the base has one
    for L2 in range(1, b):
        L3 = b - L2
        lo = max((b ** (L2 - 1)), 1); 
        import math
        # n in [ceil(sqrt(b^(L2-1))), floor(sqrt(b^L2 - 1))] and [cbrt(b^(L3-1)), cbrt(b^L3 - 1)]
        a = max(math.isqrt(b ** (L2 - 1) - 1) + 1, int(round((b ** (L3 - 1)) ** (1 / 3))) if L3 < 40 else icbrt(b ** (L3 - 1) - 1) + 1)
        z = min(math.isqrt(b ** L2 - 1), icbrt(b ** L3 - 1))
        if z > a: return rnd.randrange(a, z + 1), L2, L3
    return None
def icbrt(x):
    lo, hi = 0, 1 << ((x.bit_length() + 2) // 3 + 1)
    while lo < hi:
        m = (lo + hi + 1) // 2
        if m * m * m <= x: lo = m
        else: hi = m - 1
    return lo
def kept(b, trials, rnd):
    tot = same = 0; per = {}
    for _ in range(trials):
        r = rng_n(b, rnd)
        if not r: return None
        n, L2, L3 = r
        dn = digits(n, b); L = len(dn)
        s2, s3 = digits(n * n, b), digits(n ** 3, b)
        for i in range(L):
            delta = rnd.choice([d for d in range(-dn[i] + (1 if i == L - 1 else 0), b - dn[i]) if d != 0])
            m = n + delta * b ** i
            t2, t3 = digits(m * m, b), digits(m ** 3, b)
            if len(t2) != len(s2) or len(t3) != len(s3): continue
            k = sum(x == y for x, y in zip(s2, t2)) + sum(x == y for x, y in zip(s3, t3))
            tot += len(s2) + len(s3); same += k
            per.setdefault(round(10 * i / L), []).append(k / (len(s2) + len(s3)))
    return same / tot, {k: sum(v) / len(v) for k, v in sorted(per.items())}
rnd = random.Random(20261121)
for b in (60, 100, 150, 200):
    r = kept(b, 40, rnd)
    if r: print(f"b={b}: outputs unchanged by a one-digit change of n: {r[0]:.3f}  (by position decile of the changed digit: " + " ".join(f"{v:.2f}" for v in r[1].values()) + ")")
def logE(b):
    best = None
    for L2 in range(1, b):
        L3 = b - L2; lo = max((L2 - 1) / 2, (L3 - 1) / 3); hi = min(L2 / 2, L3 / 3)
        if hi > lo: best = hi * log(b) + log(1 - exp((lo - hi) * log(b)))
    return None if best is None else best + lgamma(b + 1) - b * log(b)
print("expected nice numbers per base (uniform model), log10:", " ".join(f"{b}:{logE(b)/log(10):.1f}" for b in (64, 65, 70, 80, 100, 120, 130, 140, 150, 200) if logE(b) is not None))
def lottery(u, b):   # log10 of 1/P(the uncontrolled u*b digits come out as the missing values)
    k = round(u * b); return -(lgamma(k + 1) - k * log(b)) / log(10)
for b in (140, 200):
    print(f"b={b}: log10(trials per success) when a fraction u of the outputs is left to chance:", " ".join(f"u={u}:{lottery(u,b):.0f}" for u in (0.6, 0.47, 0.3, 0.2, 0.1, 0.05)))
