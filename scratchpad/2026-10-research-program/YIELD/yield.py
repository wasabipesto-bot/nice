#!/usr/bin/env python3
"""SUPERSEDED 2026-11-28 by yield2.py: E below leaves out the residue factor R_b (YIELD.2).
Which base is the best buy? Expected nice numbers per admissible n searched, by base (2026-11-26).
E_b = N_b * b!/b^b (the uniform model of CX/ecount.py; the residue filter moves candidates between classes, not
the total), work = admissible n = N_b * R_b/(b-1) (R_b = residues mod b-1 a nice number can have).
Exact ranges (integers), not the logarithmic approximation."""
import math
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
        if z > a: return a, z + 1
    return None
def roots(b):
    m = b - 1; t = (b * (b - 1) // 2) % m
    return sum(1 for n in range(m) if (n * n * (n + 1)) % m == t)
rows = []
for b in range(58, 81):
    r = rng(b); R = roots(b)
    if r is None or R == 0: continue
    N = r[1] - r[0]; adm = N * R / (b - 1)
    E = N * math.exp(math.lgamma(b + 1) - b * math.log(b))
    rows.append((b, R, N, adm, E))
ref = next(r for r in rows if r[0] == 64)
print("base  R/(b-1)   n in range  admissible n   E(nice)   E per admissible n (b64 = 1)   days at 1.0 fs   days at 3.0 fs")
for b, R, N, adm, E in rows:
    y = (E / adm) / (ref[4] / ref[3])
    print(f"{b:4d}  {R:2d}/{b-1:<3d}  {N:10.3e}  {adm:10.3e}  {E:9.2e}  {y:8.2f}                      {adm*1e-15/86400:10.0f}  {adm*3e-15/86400:10.0f}")
