#!/usr/bin/env python3
"""NM model: near misses of n^2 || n^3 under the uniform-digit model, with the
digit-sum (mod b-1) constraint exact, and the join's coverage (positions known
before the check) from the real geometry of sampled n.

usage: model.py <base> [samples] [k f0 mid]
"""
import sys, random, itertools
from math import comb, factorial
from fractions import Fraction

def iroot(x, k):
    r = int(round(x ** (1 / k)))
    while r ** k > x: r -= 1
    while (r + 1) ** k <= x: r += 1
    return r

def croot(x, k):
    r = iroot(x, k); return r if r ** k == x else r + 1

def base_range(b):
    k = b // 5; m = b % 5
    if m == 0: return croot(b ** (3 * k - 1), 3), b ** k
    if m == 2: return b ** k, croot(b ** (3 * k + 1), 3)
    if m == 3: return croot(b ** (3 * k + 1), 3), croot(b ** (2 * k + 1), 2)
    if m == 4: return croot(b ** (2 * k + 1), 2), croot(b ** (3 * k + 2), 3)
    return None

def nd(x, b):
    n = 0
    while x: x //= b; n += 1
    return n

def digits(x, b, n):
    out = []
    for _ in range(n):
        x, r = divmod(x, b); out.append(r)
    return out

MAXJ = 4  # missing digits tracked: 0..MAXJ

def occupancy(b):
    """{(j, pattern, sum mod b-1): number of strings of length b over b symbols}
    for j = b - distinct <= MAXJ; pattern = sorted counts >= 2."""
    M = b - 1
    st = {(0, 0, 0, ()): 1}  # used, sum, zeros, pattern
    for d in range(b):
        nxt = {}
        for (u, s, z, pat), w in st.items():
            ex = sum(c - 1 for c in pat)
            for c in range(0, b - u + 1):
                nz = z + (c == 0)
                npat = pat + ((c,) if c >= 2 else ())
                nex = ex + max(c - 1, 0)
                if nex > MAXJ: break
                if nz > MAXJ: continue
                key = (u + c, (s + c * d) % M, nz, tuple(sorted(npat)))
                nxt[key] = nxt.get(key, 0) + w * comb(b - u, c)
        st = nxt
    out = {}
    for (u, s, z, pat), w in st.items():
        if u == b:
            out[(z, pat, s)] = out.get((z, pat, s), 0) + w
    return out

def known_positions(n, b, l, s2, s3, lo, hi, k=6, mid=2, f0=3):
    """Positions (power, pos) the join knows before the check for n, and
    whether its top certificate is clean is NOT tested here (only geometry)."""
    blk = b ** f0
    p = n // blk
    a = max(p * blk, lo); z = min(p * blk + blk - 1, hi - 1)
    K = set()
    for j, (e, s) in enumerate([(2, s2), (3, s3)]):
        xa, xz = a ** e, z ** e
        for pos in range(k, s):
            if xa // b ** pos == xz // b ** pos:
                K.add((j, pos))
        for pos in range(0, k + mid):
            K.add((j, pos))
    return K

def main():
    b = int(sys.argv[1]); samples = int(sys.argv[2]) if len(sys.argv) > 2 else 4000
    # optional join shape: k f0 mid (production: 6 3 2)
    k, f0, mid = (int(x) for x in sys.argv[3:6]) if len(sys.argv) > 5 else (6, 3, 2)
    lo, hi = base_range(b)
    l, s2, s3 = nd(lo, b), nd(lo * lo, b), nd(lo ** 3, b)
    M = b - 1
    S0 = b * (b - 1) // 2 % M
    roots = [c for c in range(M) if (c * c + c ** 3) % M == S0]
    R = len(roots)
    N = hi - lo
    occ = occupancy(b)
    tot = b ** b
    # P(sum == t) for each t
    # (all strings, not only j <= MAXJ): sum of b uniform digits mod M
    dist = [1] + [0] * (M - 1)
    for _ in range(b):
        nd_ = [0] * M
        for s, w in enumerate(dist):
            if w:
                for d in range(b):
                    nd_[(s + d) % M] += w
        dist = nd_
    ps = [Fraction(w, tot) for w in dist]
    print(f"b{b}: range {N:.4e}, L {l}, s2 {s2}, s3 {s3}, R {R} roots {roots}")
    # expected counts over the whole base, by j and pattern: all n, and n in root classes
    allc, rootc = {}, {}
    # class sizes ~ N / M each
    for (j, pat, s), w in occ.items():
        p = Fraction(w, tot)
        # all classes: sum over c of N/M * P(pat, sum = t(c)) / P(sum = t(c))
        for c in range(M):
            t = (c * c + c ** 3) % M
            if s == t:
                v = float(N) / M * float(p / ps[t])
                allc[(j, pat)] = allc.get((j, pat), 0) + v
                if c in roots:
                    rootc[(j, pat)] = rootc.get((j, pat), 0) + v
    # coverage by pattern from sampled n geometry
    rnd = random.Random(1)
    pats = sorted({pat for (j, pat) in allc})
    cov = {pat: 0.0 for pat in pats}
    ksz = []
    pos_all = [(0, i) for i in range(s2)] + [(1, i) for i in range(s3)]
    assert len(pos_all) == b
    pclean = 0.0
    for _ in range(samples):
        n = rnd.randrange(lo, hi)
        K = known_positions(n, b, l, s2, s3, lo, hi, k=k, mid=mid, f0=f0)
        kk = len(K); ksz.append(kk)
        # P(K digits distinct) under uniform digits
        q = 1.0
        for i in range(kk): q *= (b - i) / b
        pclean += q
        for pat in pats:
            if not pat: cov[pat] += 1; continue
            # exact-ish by Monte Carlo over positions of the groups
            hits = 0; T = 200
            for _ in range(T):
                pos = rnd.sample(range(b), sum(pat))
                i = 0; ok = True
                for c in pat:
                    g = pos[i:i + c]; i += c
                    if sum(1 for x in g if pos_all[x] in K) > 1: ok = False; break
                hits += ok
            cov[pat] += hits / T
    for pat in pats: cov[pat] /= samples
    pclean /= samples
    print(f"known positions |K|: mean {sum(ksz)/len(ksz):.2f}, min {min(ksz)}, max {max(ksz)}")
    print(f"model P(reach check) per n = R/(b-1) * E[P(K distinct)] = {R/M*pclean:.3e}  (x 1e17 = {R/M*pclean*1e17:.3e} per 1e17 field)")
    print("j pattern        all_n(base)     root_classes   coverage   by-product(base)")
    tj = {}
    for (j, pat) in sorted(allc):
        a = allc[(j, pat)]; r = rootc.get((j, pat), 0.0); c = cov[pat]
        tj.setdefault(j, [0, 0, 0]); tj[j][0] += a; tj[j][1] += r; tj[j][2] += r * c
        print(f"{j} {str(pat):14s} {a:14.4e} {r:14.4e} {c:9.3f} {r*c:14.4e}")
    print("by j (missing digits = b - distinct):  all n | in root classes | reaches check (variant A)")
    for j in sorted(tj):
        a, r, x = tj[j]
        print(f"  b-{j}: {a:.4e} | {r:.4e} ({r/a if a else 0:.4f}) | {x:.4e} ({x/a if a else 0:.5f} of all)")

if __name__ == "__main__":
    main()
