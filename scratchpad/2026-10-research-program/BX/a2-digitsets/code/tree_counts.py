"""Baseline op counts per base (exact, small bases):
 - A: admissible candidates (range ∩ residue roots)
 - MSD tree: created / certified prefix nodes over all depths (clipped to range)
 - LSD tree: created / certified residue nodes over depths 1..L-1
 - PSJ flat cost: min over (t,k), t+k>=L, of tops created to depth t + bottoms created to
   depth k + key-matched pairs (= admissible n whose prefix_t and residue_k are both certified)
 - B2L: admissible n with distinct digits on cert(prefix ceil(L/2)) ∪ cert(residue floor(L/2))
Output: one JSON line per base."""
import sys, json
from nicelib import *

def run(b):
    lo, hi = nice_range(b)
    roots = set(residues(b))
    L = ndig(lo, b)
    assert ndig(hi - 1, b) == L
    # MSD tree
    goodT = {}
    createdT = 0
    goodT[0] = {0: 0}
    for t in range(1, L + 1):
        W = b ** (L - t)
        cur = {}
        for P0 in goodT[t - 1]:
            for d in range(b):
                P = P0 * b + d
                a, z = max(P * W, lo), min((P + 1) * W, hi) - 1
                if a > z:
                    continue
                createdT += 1
                c = top_cert(a, z, b)
                m = mask_of(c)
                if m is not None:
                    cur[P] = m
        goodT[t] = cur
    # LSD tree
    goodB = {0: {0: 0}}
    createdB = 0
    for k in range(1, L):
        cur = {}
        M = b ** (k - 1)
        for R0 in goodB[k - 1]:
            for d in range(b):
                R = R0 + d * M
                createdB += 1
                m = mask_of(bottom_cert(R, k, b))
                if m is not None:
                    cur[R] = m
        goodB[k] = cur
    # per-n
    A = 0
    pairs = {}
    surv = {}
    tH, kH = (L + 1) // 2, L // 2
    B2L = 0
    for n in range(lo, hi):
        if n % (b - 1) not in roots:
            continue
        A += 1
        tm = {}
        for t in range(1, L + 1):
            m = goodT[t].get(n // b ** (L - t))
            if m is None:
                break
            tm[t] = m
        bm = {}
        for k in range(1, L):
            m = goodB[k].get(n % b ** k)
            if m is None:
                break
            bm[k] = m
        for t in tm:
            for k in bm:
                if t + k >= L:
                    pairs[(t, k)] = pairs.get((t, k), 0) + 1
                    if tm[t] & bm[k] == 0:
                        surv[(t, k)] = surv.get((t, k), 0) + 1
        if tH in tm and kH in bm and (tm[tH] & bm[kH]) == 0:
            B2L += 1
    # cumulative created counts per depth
    cT = {}
    acc = 0
    for t in range(1, L + 1):
        # created at depth t = children of good parents in range; recompute cheaply
        pass
    # recompute created per depth
    crT = [0] * (L + 1)
    for t in range(1, L + 1):
        W = b ** (L - t)
        for P0 in goodT[t - 1]:
            for d in range(b):
                P = P0 * b + d
                if max(P * W, lo) <= min((P + 1) * W, hi) - 1:
                    crT[t] += 1
    crB = [0] + [len(goodB[k - 1]) * b for k in range(1, L)]
    best = None
    for (t, k), pc in pairs.items():
        cost = sum(crT[1:t + 1]) + sum(crB[1:k + 1]) + pc
        if best is None or cost < best[0]:
            best = (cost, t, k, pc, surv.get((t, k), 0))
    ideal = None
    for (t, k), pc in pairs.items():
        sv = surv.get((t, k), 0)
        cost = sum(crT[1:t + 1]) + sum(crB[1:k + 1]) + sv
        if ideal is None or cost < ideal[0]:
            ideal = (cost, t, k, pc, sv)
    flatc = None
    for (t, k), pc in pairs.items():
        sv = surv.get((t, k), 0)
        cost = sum(crT[1:t + 1]) + sum(crB[1:k + 1]) + pc + sv
        if flatc is None or cost < flatc[0]:
            flatc = (cost, t, k, pc, sv)
    WL, WP, WS = 50, 1, 45  # N5 weights in AND units: list entry, pair, survivor
    wf = min(WL * (sum(crT[1:t + 1]) + sum(crB[1:k + 1])) + WP * pc + WS * surv.get((t, k), 0) for (t, k), pc in pairs.items())
    wi = min(WL * (sum(crT[1:t + 1]) + sum(crB[1:k + 1])) + WS * surv.get((t, k), 0) for (t, k), pc in pairs.items())
    return dict(b=b, L=L, A=A, weighted_flat=wf, weighted_ideal=wi, flat_with_checks=flatc, ideal_OV=ideal, createdT=createdT, certT=sum(len(goodT[t]) for t in range(1, L + 1)),
                createdB=createdB, B2L=B2L, crT=crT, crB=crB, psj_best=best,
                full_msd_leaves=len(goodT[L]))

for b in [int(x) for x in sys.argv[1].split(",")]:
    print(json.dumps(run(b)), flush=True)
