"""Two-sided alternating tree node counts (prefix t, suffix k, t-k in {0,1}) via a subset-sum
(zeta) transform over 2^b masks: good(t,k) = #{(P,R): P certified prefix of depth t, R
certified residue mod b^k, masks disjoint}. Also counts certified tops/bottoms per depth.
No range/residue consistency check between P and R for t+k > L (upper bound there).
Usage: alt_tree.py b1,b2,..."""
import sys, json
import numpy as np
from nicelib import *


def lists(b):
    lo, hi = nice_range(b)
    L = ndig(lo, b)
    goodT = {0: {0: 0}}
    for t in range(1, L + 1):
        W = b ** (L - t)
        cur = {}
        for P0 in goodT[t - 1]:
            for d in range(b):
                P = P0 * b + d
                a, z = max(P * W, lo), min((P + 1) * W, hi) - 1
                if a > z:
                    continue
                m = mask_of(top_cert(a, z, b))
                if m is not None:
                    cur[P] = m
        goodT[t] = cur
    goodB = {0: {0: 0}}
    for k in range(1, L):
        cur = {}
        M = b ** (k - 1)
        for R0 in goodB[k - 1]:
            for d in range(b):
                R = R0 + d * M
                m = mask_of(bottom_cert(R, k, b))
                if m is not None:
                    cur[R] = m
        goodB[k] = cur
    return L, goodT, goodB


def disjoint_pairs(tops, bots, b):
    f = np.zeros(1 << b, dtype=np.int64)
    for m in bots:
        f[m] += 1
    # zeta: f[S] = # bottoms with mask ⊆ S
    for i in range(b):
        bit = 1 << i
        f2 = f.reshape(-1, 2 * bit)
        f2[:, bit:] += f2[:, :bit]
    full = (1 << b) - 1
    return int(sum(f[full ^ m] for m in tops))


for b in [int(x) for x in sys.argv[1].split(",")]:
    L, gT, gB = lists(b)
    levels = []
    total = 0
    for lvl in range(1, 2 * L):
        t, k = (lvl + 1) // 2, lvl // 2
        if t > L or k > L - 1:
            continue
        c = disjoint_pairs(list(gT[t].values()), list(gB[k].values()), b)
        levels.append((t, k, c))
        total += c
        if t + k >= L:
            break
    print(json.dumps(dict(b=b, L=L, alt_levels=levels, alt_total_good=total,
                          tops=[len(gT[t]) for t in range(1, L + 1)],
                          bots=[len(gB[k]) for k in range(1, L)])), flush=True)
