#!/usr/bin/env python3
"""Monte Carlo operation counts for the overlap join at alternative shapes.

For random admissible n in a base's range, estimates
  P_T(f0)  : the block of b^f0 numbers around n has a passing top certificate
  P_B(k)   : n mod b^k has 2k distinct low output digits
  P_S(f0,k): both pass and the two masks are disjoint (an AND survivor)
  prune(m,k): a valid bottom avoids the certificate of the enclosing b^m block
Simplified certificate: common leading digits of a^j and e^j (no closure, no
d/d+1 domain), which is what decides pass/fail in almost every case.
"""
import random, sys, math

def digits(x, b):
    out = []
    while x:
        x, r = divmod(x, b)
        out.append(r)
    return out  # least significant first

def roots(b):
    m = b - 1
    c = (b * (b - 1) // 2) % m
    return [x for x in range(m) if (x * x + x * x * x) % m == c]

def base_range(b):
    # n with len(n^2)+len(n^3) == b ; search by integer roots
    # find all k: n^2 has d2 digits, n^3 has d3 digits, d2+d3=b
    best = None
    for d2 in range(1, b):
        d3 = b - d2
        lo = max(iroot_ceil(b ** (d2 - 1), 2), iroot_ceil(b ** (d3 - 1), 3))
        hi = min(iroot_ceil(b ** d2, 2), iroot_ceil(b ** d3, 3))  # exclusive
        if hi > lo:
            best = (lo, hi)
    return best

def iroot_ceil(x, k):
    # smallest r with r**k >= x
    r = int(round(x ** (1.0 / k)))
    lo, hi = 0, 1
    while hi ** k < x:
        hi *= 2
    while lo < hi:
        mid = (lo + hi) // 2
        if mid ** k >= x:
            hi = mid
        else:
            lo = mid + 1
    return lo

def top_cert(a, e, b):
    """mask and count of common leading digits of a^j,e^j (j=2,3); None if a repeat."""
    mask = 0
    cnt = 0
    for j in (2, 3):
        da, de = digits(a ** j, b), digits(e ** j, b)
        if len(da) != len(de):
            continue
        i = len(da) - 1
        while i >= 0 and da[i] == de[i]:
            bit = 1 << da[i]
            if mask & bit:
                return None, 0
            mask |= bit
            cnt += 1
            i -= 1
    return mask, cnt

def bottom_mask(n, b, k):
    m = b ** k
    r = n % m
    mask = 0
    for x in ((r * r) % m, (r * r * r) % m):
        for _ in range(k):
            x, d = divmod(x, b)
            bit = 1 << d
            if mask & bit:
                return None
            mask |= bit
    return mask

def main():
    b = int(sys.argv[1]); N = int(sys.argv[2])
    F0 = [3, 4, 5]; K = [6, 7, 8, 9, 10]; M = [8, 9, 10, 11, 12]
    lo, hi = base_range(b)
    rts = set(roots(b))
    rng = random.Random(12345)
    L = len(digits(hi - 1, b))
    print(f"base {b}: range [{lo}, {hi}) size {hi-lo:.4e} L={L} roots={len(rts)}/{b-1}")
    nT = {f: 0 for f in F0}; cT = {f: 0 for f in F0}
    nB = {k: 0 for k in K}
    nS = {(f, k): 0 for f in F0 for k in K}
    nTB = {(f, k): 0 for f in F0 for k in K}
    samples = []
    for _ in range(N):
        while True:
            n = rng.randrange(lo, hi)
            if n % (b - 1) in rts:
                break
        tm = {}
        for f in F0:
            w = b ** f
            a = (n // w) * w
            m_, c_ = top_cert(max(a, lo), min(a + w - 1, hi - 1), b)
            tm[f] = m_
            if m_ is not None:
                nT[f] += 1; cT[f] += c_
        bm = {}
        for k in K:
            bm[k] = bottom_mask(n, b, k)
            if bm[k] is not None:
                nB[k] += 1
        for f in F0:
            for k in K:
                if tm[f] is not None and bm[k] is not None:
                    nTB[(f, k)] += 1
                    if tm[f] & bm[k] == 0:
                        nS[(f, k)] += 1
        sm = {}
        for m in M:
            w = b ** m
            a = (n // w) * w
            sm[m] = top_cert(max(a, lo), min(a + w - 1, hi - 1), b)[0]
        samples.append((tm, bm, sm))
    print("P_T:", {f: round(nT[f] / N, 4) for f in F0}, "mean digits:", {f: round(cT[f] / max(nT[f], 1), 2) for f in F0})
    print("P_B:", {k: round(nB[k] / N, 5) for k in K})
    print("P(T&B) / (P_T*P_B):")
    for f in F0:
        print("  f0=%d " % f + " ".join("k=%d:%.3f" % (k, nTB[(f, k)] / N / max(nT[f] / N * nB[k] / N, 1e-30)) for k in K))
    print("P_S (AND survivors per admissible n):")
    for f in F0:
        print("  f0=%d " % f + " ".join("k=%d:%.3e" % (k, nS[(f, k)] / N) for k in K))
    # prune: independent pairing of slice certs (sample i) with bottoms (sample i+1)
    print("prune(m,k) = P(valid bottom avoids the b^m block's certificate) [block cert must pass]:")
    for m in M:
        row = []
        for k in K:
            ok = tot = 0
            for i in range(N):
                s = samples[i][2][m]; bmk = samples[(i + 1) % N][1][k]
                if s is None or bmk is None:
                    continue
                tot += 1
                ok += (s & bmk) == 0
            row.append("k=%d:%.3f" % (k, ok / max(tot, 1)))
        print("  m=%d " % m + " ".join(row))
    # pairs given top passes and bottom valid AND bottom survives prune at level m -> P(pair)/P(T)P(B) ~ prune * corr
    print("AND pairs fraction with prune at block m: P(T ok & B ok & B avoids slice cert(m)) per admissible n")
    for f in F0:
        for m in M:
            row = []
            for k in K:
                c = 0
                for (tm, bm, sm) in samples:
                    if tm[f] is not None and bm[k] is not None and sm[m] is not None and (sm[m] & bm[k]) == 0:
                        c += 1
                row.append("k=%d:%.3e" % (k, c / N))
            print("  f0=%d m=%d " % (f, m) + " ".join(row))

main()
