"""E8b: two-level (block) disjointness prune inside one transversal unit, all (j, i) levels.
Cost(j,i) = #(top group, bottom group) tests + key-matched element pairs inside disjoint groups.
Compares with FLAT (key-matched pairs) and IDEAL (disjoint key-matched pairs). Usage as dual_tree.py"""
import sys, random
from nicelib import *

b, f0, k, nunits, seed = map(int, sys.argv[1:6])
rnd = random.Random(seed)
lo, hi = nice_range(b); L = ndig(lo, b); t = L - f0; o = t + k - L
roots = set(residues(b)); ft = t - o; fb = f0
agg = {}
FLAT = IDEAL = 0
for _ in range(nunits):
    pi = rnd.randrange(b ** o)
    W = b ** f0
    tops = []
    for u in range(b ** ft):
        P = u * b ** o + pi
        a, z = max(P * W, lo), min((P + 1) * W, hi) - 1
        if a > z: continue
        m = mask_of([x for x in top_cert(a, z, b) if x[1] >= k])
        if m is not None: tops.append((u, P, m))
    bots = []
    for v in range(b ** fb):
        m = mask_of(bottom_cert(v + pi * b ** f0, k, b))
        if m is not None: bots.append((v, m))
    for u, P, m in tops:
        for v, mb in bots:
            if (P + v) % (b - 1) in roots:
                FLAT += 1
                IDEAL += not (m & mb)
    for j in range(0, ft + 1):
        tg = {}
        for u, P, m in tops:
            up = u // b ** (ft - j)
            if j == 0: gm = 0
            else:
                Wj = b ** (L - j)
                gm = mask_of([x for x in top_cert(max(up * Wj, lo), min((up + 1) * Wj, hi) - 1, b) if x[1] >= k])
            tg.setdefault(up, [gm, []])[1].append((P, m))
        for i in range(0, fb + 1):
            bg = {}
            for v, mb in bots:
                vl = v % b ** i
                gm = 0 if i == 0 else mask_of(bottom_cert(vl, i, b))
                bg.setdefault(vl, [gm, []])[1].append((v, mb))
            cost = 0
            for gt in tg.values():
                for gb in bg.values():
                    cost += 1
                    if gt[0] is None or gb[0] is None or (gt[0] & gb[0]): continue
                    # key-matched element pairs inside
                    keys = {}
                    for v, mb in gb[1]:
                        keys[v % (b - 1)] = keys.get(v % (b - 1), 0) + 1
                    for P, m in gt[1]:
                        for r in roots:
                            cost += keys.get((r - P) % (b - 1), 0)
            agg[(j, i)] = agg.get((j, i), 0) + cost
best = min(agg.items(), key=lambda x: x[1])
print(f"b={b} L={L} f0={f0} k={k} o={o} ft={ft} fb={fb} FLAT={FLAT} IDEAL={IDEAL} flat/ideal={FLAT/max(1,IDEAL):.1f} "
      f"best block (j,i)={best[0]} cost={best[1]} flat/best={FLAT/best[1]:.2f}")
print("   all:", {kk: vv for kk, vv in sorted(agg.items())})
