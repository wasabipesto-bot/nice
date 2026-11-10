#!/usr/bin/env python3
"""N5: certificate sizes and joint-disjointness over the whole (f0, k) plane, incl.
deep overlap (f0 small, k large), and a check of the uniform-digit model.
Top cert = common leading digits of lo^j, hi^j over the b^f0 block (as mc_counts.py).
Usage: psj_mc.py b N
"""
import random, sys, math
sys.path.insert(0, '/home/claude/projects/nice/scratchpad/2026-11-fresh-eyes')
from importlib.machinery import SourceFileLoader
# reuse helpers without running main(): copy the needed ones
def digits(x, b):
    out = []
    while x:
        x, r = divmod(x, b); out.append(r)
    return out
def roots(b):
    m = b - 1; c = (b*(b-1)//2) % m
    return [x for x in range(m) if (x*x + x*x*x) % m == c]
def iroot_ceil(x, k):
    lo, hi = 0, 1
    while hi**k < x: hi *= 2
    while lo < hi:
        mid = (lo+hi)//2
        if mid**k >= x: hi = mid
        else: lo = mid+1
    return lo
def base_range(b):
    best = None
    for d2 in range(1, b):
        d3 = b - d2
        lo = max(iroot_ceil(b**(d2-1), 2), iroot_ceil(b**(d3-1), 3))
        hi = min(iroot_ceil(b**d2, 2), iroot_ceil(b**d3, 3))
        if hi > lo: best = (lo, hi)
    return best
def top_cert(a, e, b, kmin):
    mask = 0; cnt = 0
    for j in (2, 3):
        da, de = digits(a**j, b), digits(e**j, b)
        if len(da) != len(de): continue
        i = len(da)-1
        while i >= kmin and da[i] == de[i]:
            bit = 1 << da[i]
            if mask & bit: return None, cnt
            mask |= bit; cnt += 1; i -= 1
    return mask, cnt
def bottom_mask(n, b, k):
    m = b**k; r = n % m; mask = 0
    for x in ((r*r) % m, (r*r*r) % m):
        for _ in range(k):
            x, d = divmod(x, b); bit = 1 << d
            if mask & bit: return None
            mask |= bit
    return mask
def Pm(b, m):  # P(m uniform digits distinct), fractional m by log-interp
    def lp(mi): return sum(math.log(1 - i/b) for i in range(mi))
    f = math.floor(m); fr = m - f
    return math.exp(lp(f)*(1-fr) + lp(f+1)*fr)

b = int(sys.argv[1]); N = int(sys.argv[2])
lo, hi = base_range(b); L = len(digits(hi-1, b)); rts = set(roots(b))
F0 = list(range(1, 7)); K = list(range(1, L))
rng = random.Random(7)
tops = {f: [] for f in F0}; cnts = {f: [] for f in F0}; bots = {k: [] for k in K}
nT = {f: 0 for f in F0}; nB = {k: 0 for k in K}
for _ in range(N):
    while True:
        n = rng.randrange(lo, hi)
        if n % (b-1) in rts: break
    for f in F0:
        w = b**f; a = (n//w)*w
        m_, c_ = top_cert(max(a, lo), min(a+w-1, hi-1), b, 0)
        if m_ is not None:
            nT[f] += 1; tops[f].append(m_); cnts[f].append(c_)
    for k in K:
        bm = bottom_mask(n, b, k)
        if bm is not None:
            nB[k] += 1; bots[k].append(bm)
print(f"b={b} L={L} range={hi-lo:.4e} roots={len(rts)} N={N}")
print("f0  P_T      meandigits  P_unif(meandigits)")
for f in F0:
    md = sum(cnts[f])/max(len(cnts[f]), 1)
    print(f"{f:2d}  {nT[f]/N:.4e}  {md:6.2f}  {Pm(b, md):.4e}")
print("k   P_B      P_unif(2k)")
for k in K:
    print(f"{k:2d}  {nB[k]/N:.4e}  {Pm(b, 2*k):.4e}")
# P(disjoint | both certified), independent pairing (top from sample i, bottom from others)
print("P_S(f0,k) = P_T*P_B*P(disj|both) [pairs from independent samples]; uniform model P_(cT+2k) in brackets")
rng2 = random.Random(1)
for f in F0:
    row = []
    md = sum(cnts[f])/max(len(cnts[f]), 1)
    for k in K:
        T = tops[f]; B = bots[k]
        if not T or not B: row.append("-"); continue
        trials = 200000; hit = 0
        for _ in range(trials):
            if (T[rng2.randrange(len(T))] & B[rng2.randrange(len(B))]) == 0: hit += 1
        pd = hit/trials
        ps = nT[f]/N * nB[k]/N * pd
        row.append(f"k{k}:{ps:.2e}[{Pm(b, md+2*k) if md+2*k < b else 0:.1e}]")
    print(f"f0={f} " + " ".join(row))
