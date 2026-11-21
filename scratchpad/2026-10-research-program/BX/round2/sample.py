#!/usr/bin/env python3
"""BX round 3, item 3: is the uniform model biased at large bases? For random n in a base's range, count equal
digit pairs among the b output digits (within n^2, within n^3, and across), against b-uniform digits.
A shift D in the mean number of equal pairs moves P(nice) by about exp(-D) (Poisson heuristic)."""
import random, sys, math
from collections import Counter
def icbrt(x):
    lo, hi = 0, 1 << ((x.bit_length() + 2) // 3 + 1)
    while lo < hi:
        m = (lo + hi + 1) // 2
        if m * m * m <= x: lo = m
        else: hi = m - 1
    return lo
def rng(b):
    for L2 in range(1, b):
        L3 = b - L2
        a = max(math.isqrt(b ** (L2 - 1) - 1) + 1, icbrt(b ** (L3 - 1) - 1) + 1)
        z = min(math.isqrt(b ** L2 - 1), icbrt(b ** L3 - 1))
        if z > a: return a, z, L2, L3
def digs(x, b):
    d = []
    while x: x, r = divmod(x, b); d.append(r)
    return d
def pairs(c): return sum(v * (v - 1) // 2 for v in c.values())
def run(b, N, seed):
    rnd = random.Random(seed); a, z, L2, L3 = rng(b)
    s22 = s33 = s23 = 0; q22 = q33 = q23 = 0; sx2 = 0
    for _ in range(N):
        n = rnd.randrange(a, z + 1)
        c2 = Counter(digs(n * n, b)); c3 = Counter(digs(n * n * n, b))
        x22 = pairs(c2); x33 = pairs(c3); x23 = sum(v * c3.get(k, 0) for k, v in c2.items())
        s22 += x22; s33 += x33; s23 += x23; x = x22 + x33 + x23; sx2 += x * x
    e22 = L2 * (L2 - 1) / 2 / b; e33 = L3 * (L3 - 1) / 2 / b; e23 = L2 * L3 / b
    tot = (s22 + s33 + s23) / N; sd = math.sqrt(sx2 / N - tot * tot); se = sd / math.sqrt(N)
    print(f"b={b} N={N}: equal pairs, measured / uniform: within n^2 {s22/N:.4f} / {e22:.4f}; within n^3 {s33/N:.4f} / {e33:.4f}; "
          f"across {s23/N:.4f} / {e23:.4f}; total {tot:.4f} / {e22+e33+e23:.4f}  (difference {tot-(e22+e33+e23):+.4f}, standard error {se:.4f})", flush=True)
for b, N in ((62, 400000), (64, 400000), (100, 300000), (140, 200000), (200, 100000)):
    run(b, N, 20261121 + b)
