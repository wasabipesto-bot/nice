"""E8c: digit-key index (N5 X1) inside transversal units: index both lists by their mask restricted
to D = the d digits most frequent in (top mask freq * bottom mask freq); a top visits only bottom
key-groups disjoint from it on D. Report kept fraction of key-matched pairs and group-combo
overhead. Usage: digitkey.py b f0 k units seed"""
import sys, random
from nicelib import *
b, f0, k, nunits, seed = map(int, sys.argv[1:6])
rnd = random.Random(seed)
lo, hi = nice_range(b); L = ndig(lo, b); t = L - f0; o = t + k - L
roots = set(residues(b)); ft = t - o; fb = f0
res = {}
FLAT = IDEAL = 0
for _ in range(nunits):
    pi = rnd.randrange(b ** o); W = b ** f0
    tops = []
    for u in range(b ** ft):
        P = u * b ** o + pi
        a, z = max(P * W, lo), min((P + 1) * W, hi) - 1
        if a > z: continue
        m = mask_of([x for x in top_cert(a, z, b) if x[1] >= k])
        if m is not None: tops.append((P, m))
    bots = []
    for v in range(b ** fb):
        m = mask_of(bottom_cert(v + pi * b ** f0, k, b))
        if m is not None: bots.append((v, m))
    if not tops or not bots: continue
    ft_ = [sum(1 for _, m in tops if m >> d & 1) / len(tops) for d in range(b)]
    fb_ = [sum(1 for _, m in bots if m >> d & 1) / len(bots) for d in range(b)]
    order = sorted(range(b), key=lambda d: -ft_[d] * fb_[d])
    for P, m in tops:
        for v, mb in bots:
            if (P + v) % (b - 1) in roots:
                FLAT += 1; IDEAL += not (m & mb)
    for d in (4, 8, 12, 16, 24, b):
        D = sum(1 << x for x in order[:d])
        bg = {}
        for v, mb in bots:
            bg.setdefault(mb & D, {}).setdefault(v % (b - 1), 0)
            bg[mb & D][v % (b - 1)] += 1
        kept = combos = 0
        for P, m in tops:
            for key, kk in bg.items():
                combos += 1
                if key & m: continue
                for r in roots:
                    kept += kk.get((r - P) % (b - 1), 0)
        a_ = res.setdefault(d, [0, 0, 0])
        a_[0] += kept; a_[1] += combos; a_[2] += len(bg)
print(f"b={b} f0={f0} k={k} o={o} FLAT={FLAT} IDEAL={IDEAL} ideal/flat={IDEAL/FLAT:.3f}")
for d, (kept, combos, ng) in sorted(res.items()):
    print(f"   d={d:2d}: kept/flat={kept/FLAT:.3f}  key-groups per unit={ng/nunits:.0f}  group visits/flat={combos/FLAT:.3f}")
