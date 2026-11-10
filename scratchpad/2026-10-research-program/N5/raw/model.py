#!/usr/bin/env python3
"""N5 model numbers: per-admissible-n budgets at b62/b64, the gap/lattice variant,
and per-find cost exponents (item D/E) for b = 62..300 under the uniform-digit model."""
import math
def lf(b, m):  # log P(m uniform digits distinct), fractional m interpolated
    def lp(mi): return sum(math.log(1 - i/b) for i in range(int(mi)))
    f = math.floor(m); fr = m - f
    return lp(f)*(1-fr) + lp(f+1)*fr
def P(b, m): return math.exp(lf(b, m))
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
def nroots(b):
    m = b-1; c = (b*(b-1)//2) % m
    return sum(1 for x in range(m) if (x*x + x**3) % m == c)
def L_of(b):
    lo, hi = base_range(b); x = hi-1; L = 0
    while x: x //= b; L += 1
    return L
L10 = math.log(10)
print("== basics ==")
for b in (62, 64):
    lo, hi = base_range(b); W = hi-lo; R = nroots(b); A = W*R/(b-1); L = L_of(b)
    lg = math.lgamma(b+1) - b*math.log(b)
    lam = W*math.exp(lg)*R
    pn = (b-1)*math.exp(lg)
    print(f"b={b} L={L} W={W:.3e} R={R} A={A:.3e} lambda={lam:.2e} p_nice/adm={pn:.2e}")
    for m in (2*L-2, 2*L, 2*L+6, 4*L-4):
        print(f"   P_{m} = {P(b,m):.3e}  -> A*P = {A*P(b,m):.2e}")

print("\n== D/E: log10 cost per expected nice number (uniform model, admissible n) ==")
print("b    L  log10(lambda) brute  o=0:2L  P(2L-2)^2  P(4L-4)  today-like(P_T*P_B, t=L-3,k=6)")
for b in (62, 64, 80, 100, 130, 150, 200, 300):
    lo, hi = base_range(b); W = hi-lo; R = nroots(b); L = L_of(b)
    lg = math.lgamma(b+1) - b*math.log(b)
    lpn = math.log(b-1) + lg              # ln p_nice per admissible n
    lam = math.log(W) + lg + math.log(R)
    brute = -lpn
    o0 = lf(b, 2*L-2) - lpn               # every n with 2L-2 known digits distinct is touched
    deep = 2*lf(b, 2*L-3) - lpn           # flat join, t=k=L-1, top cert 2t-1
    floor = lf(b, 4*L-5) - lpn            # output-sensitive disjointness: only jointly-distinct pairs
    today = lf(b, 2*(L-3)-2.5) + lf(b, 12) - lpn
    print(f"{b:3d} {L:3d} {lam/L10:8.1f} {brute/L10:7.1f} {o0/L10:7.1f} {deep/L10:9.1f} {floor/L10:8.1f} {today/L10:8.1f}")

print("\n== C: gap + lattice variant at b62 (t+k = L-g, one lattice call per AND-passing (T,R)) ==")
b = 62; L = 13; R = 2
for g in (1, 2, 3, 4):
    for (t, k) in [(L-g-kk, kk) for kk in (2, 4, 6) if L-g-kk >= 3]:
        cT = 2*t - 2.5
        pairs = (b-1)/R * P(b, cT) * P(b, 2*k) / b**g          # (T,R) pairs per admissible n
        calls = (b-1)/R * P(b, cT + 2*k) / b**g                   # AND passes -> lattice calls
        # each call: enumerate M (g digits) via window prescriptions; >= (b*q)^g*R/(b-1) outputs, q ~ 1-K/b
        K = cT + 2*k; q = max(1 - K/b, 0.05)
        outs = calls * max((b*q)**g * R/(b-1), 1.0)
        print(f"g={g} t={t} k={k}: pairs/n={pairs:.2e} lattice calls/n={calls:.2e} outputs/n={outs:.2e}"
              f"  time/n at 100ns/call+5ns/out = {(calls*100e-9+outs*5e-9)*1e15:.1f} fs (join: 24 fs)")
