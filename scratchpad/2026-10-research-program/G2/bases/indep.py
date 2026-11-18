#!/usr/bin/env python3
"""Independent from-scratch enumeration of one transversal unit above base 64 (G2/bases).

Written from the definition (after review/unit_indep.py), Python big ints, masks as Python ints (any width):
unit = {n in the base range : digits [f0, k) of n = U}; tops = f0-prefix intervals (clipped to the range) whose
n^2, n^3 digits at positions >= k are constant over the interval and pairwise distinct; bottoms = residues
r mod b^k with digits [f0, k) = U whose 2k low digits of r^2, r^3 are pairwise distinct; survivor = top x bottom
with disjoint masks, n = lead*b^k + r inside the top's interval, n mod (b-1) an admissible class.
Optionally only leads in [lead_a, lead_b) (the prototype's dump is filtered to the same window).

usage: indep.py b f0 k U dumpfile [lead_a lead_b]
"""
import sys, time

def rng(b):
    def iroot_ceil(v, r):
        lo, hi = 0, 1 << (v.bit_length() // r + 2)
        while lo < hi:
            m = (lo + hi) // 2
            if m ** r >= v: hi = m
            else: lo = m + 1
        return lo
    k = b // 5; m = b % 5
    if m == 0: return iroot_ceil(b ** (3 * k - 1), 3), b ** k
    if m == 2: return b ** k, iroot_ceil(b ** (3 * k + 1), 3)
    if m == 3: return iroot_ceil(b ** (3 * k + 1), 3), iroot_ceil(b ** (2 * k + 1), 2)
    if m == 4: return iroot_ceil(b ** (2 * k + 1), 2), iroot_ceil(b ** (3 * k + 2), 3)

def classes(b):
    m = b - 1
    return sorted(r for r in range(m) if (r ** 2 + r ** 3 - b * (b - 1) // 2) % m == 0)

def digits(x, b):
    d = []
    while x:
        x, r = divmod(x, b); d.append(r)
    return d

def main():
    b, f0, k, U = map(int, sys.argv[1:5]); dump = sys.argv[5]
    lo, hi = rng(b); cls = classes(b); m = b - 1
    Bf, Bk = b ** f0, b ** k
    L0, L1 = lo // Bk, (hi - 1) // Bk + 1
    la, lb = (int(sys.argv[6]), int(sys.argv[7])) if len(sys.argv) > 7 else (L0, L1)
    la, lb = max(la, L0), min(lb, L1)
    t0 = time.time()
    tops = []; tested = 0
    for lead in range(la, lb):
        p0 = lead * Bk + U * Bf
        a = max(p0, lo); c = min(p0 + Bf - 1, hi - 1)
        if a > c: continue
        tested += 1
        seen = 0; ok = True
        for e in (2, 3):
            A = a ** e; C = c ** e
            dA = digits(A, b)
            if len(dA) != len(digits(C, b)): continue
            for j in range(len(dA) - 1, k - 1, -1):
                if A // b ** j != C // b ** j: break
                bit = 1 << dA[j]
                if seen & bit: ok = False; break
                seen |= bit
            if not ok: break
        if ok: tops.append((lead, a, c, seen))
    t1 = time.time()
    # bottoms by DFS over digit positions, each level recomputed from scratch with big ints (no incremental terms)
    forced = [(U // b ** (j - f0)) % b if j >= f0 else None for j in range(k)]
    bots = {}  # class -> list of (r, mask)
    stack = [(0, 0, 0)]  # (depth, r, mask over digits < depth of r^2 and r^3)
    nb = 0
    while stack:
        j, r, mk = stack.pop()
        if j == k:
            bots.setdefault(r % m, []).append((r, mk)); nb += 1
            continue
        ds = range(b) if forced[j] is None else (forced[j],)
        bj = b ** j; bj1 = bj * b
        for d in ds:
            nr = r + d * bj
            e2 = (nr * nr % bj1) // bj
            e3 = (nr * nr * nr % bj1) // bj
            if e2 == e3: continue
            add = (1 << e2) | (1 << e3)
            if mk & add: continue
            stack.append((j + 1, nr, mk | add))
    t2 = time.time()
    pairs = 0; surv = set()
    for lead, a, c, tm in tops:
        for x in cls:
            for r, bm in bots.get((x - lead) % m, ()):  # n = lead*b^k + r == lead + r mod (b-1)
                pairs += 1
                if bm & tm == 0:
                    n = lead * Bk + r
                    if a <= n <= c: surv.add(n)
    t3 = time.time()
    got = set()
    for line in open(dump):
        n = int(line)
        if la <= n // Bk < lb: got.add(n)
    print(f"INDEP b{b} (f0 {f0}, k {k}) U={U} leads [{la},{lb}) of [{L0},{L1}): tops {len(tops)}/{tested} bottoms {nb} "
          f"pairs {pairs} survivors {len(surv)} | prototype (same leads) {len(got)} equal={got == surv} "
          f"missing_in_proto {len(surv - got)} extra_in_proto {len(got - surv)} | max digit in any mask "
          f"{max([t[3].bit_length() - 1 for t in tops] + [0])} (tops), "
          f"{max([bm.bit_length() - 1 for v in bots.values() for _, bm in v] + [0])} (bottoms); "
          f"times tops {t1-t0:.0f}s bots {t2-t1:.0f}s pair {t3-t2:.0f}s")
    assert got == surv

if __name__ == '__main__':
    main()
