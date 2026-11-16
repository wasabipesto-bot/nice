"""E3: inclusion-exclusion / parity (Walsh) counting on small bases.
(1) Bonferroni: S_m = #nice ± sum_{non-nice} C(f_n-1, m); report the bound vs m.
(2) Parity identity: #nice = 2^-b sum_S (-1)^|S| F(S), F(S) = sum_n (-1)^{#output digits in S};
    verify exactly and report the cancellation (max |F(S)| / N, sum |F|)."""
import sys
from math import comb
from nicelib import *
for b in [int(x) for x in sys.argv[1].split(",")]:
    lo, hi = nice_range(b)
    roots = set(residues(b))
    ns = [n for n in range(lo, hi) if n % (b - 1) in roots]
    hist = {}
    cnt = {}  # count vector -> multiplicity (digit counts tuple) for Walsh
    for n in ns:
        c = [0] * b
        for x in (n * n, n ** 3):
            while x:
                c[x % b] += 1
                x //= b
        f = sum(1 for v in c if v == 0)
        hist[f] = hist.get(f, 0) + 1
        par = sum(((v & 1) << d) for d, v in enumerate(c))  # parity vector
        cnt[par] = cnt.get(par, 0) + 1
    nice = hist.get(0, 0)
    bon = []
    for m in range(0, max(hist) + 1):
        err = sum(h * comb(f - 1, m) for f, h in hist.items() if f >= 1)
        bon.append((m, err))
    # Walsh: F(S) = sum_par cnt * (-1)^{popcount(par & S)}; nice = 2^-b sum_S (-1)^{|S|} F(S)
    tot = 0
    maxF = 0
    if b <= 18:
        for S in range(1 << b):
            F = 0
            for par, h in cnt.items():
                F += -h if bin(par & S).count("1") & 1 else h
            if S:
                maxF = max(maxF, abs(F))
            tot += -F if bin(S).count("1") & 1 else F
        walsh = tot / (1 << b)
    else:
        walsh = None
    print(f"b={b} N_adm={len(ns)} nice={nice} f_n hist={dict(sorted(hist.items()))}")
    print(f"   Bonferroni error by m: {bon}")
    print(f"   parity-identity count={walsh}  max_S!=0 |F(S)|/N={maxF/len(ns) if ns else 0:.3f}")
