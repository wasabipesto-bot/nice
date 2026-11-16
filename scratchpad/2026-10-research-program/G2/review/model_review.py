#!/usr/bin/env python3
"""Reviewer's re-costing of G2 (4,10) top-driven, parent-sorted, pooled weights. Counts per admissible n are the
author's measured ones (re-measured in raw/sweep_tile_key.txt, raw/unit6*_indep.txt within 6 %); unit costs are the
reviewer's low / central / high (REVIEW.md §4 gives each reason). Pure Python."""
S = ('low', 'central', 'high')
CNT = {  # per admissible n
    62: dict(kept=3.533e-5, flat=6.08e-5, children=1.70e-4, bottoms=8.12e-5, parents=2.66e-6,
             tops_hier=4.39e-7, tops_all=2.064e-6, rederive=7.13e-5, surv=3.33e-6, pop=15.5),
    64: dict(kept=2.693e-5, flat=5.517e-5, children=1.67e-5, bottoms=7.54e-6, parents=2.53e-7,
             tops_hier=9.23e-8, tops_all=4.694e-7, rederive=6.38e-6, surv=2.61e-6, pop=16.4),
}
U = dict(  # seconds
    word_base=(3e-12, 5e-12, 7.1e-12),       # N1.G1 big-tile base 0.103 ps/pair x64 = 6.6; x1.07 production calibration
    lookup=(0.64e-12, 0.9e-12, 1.29e-12),    # N1.G1 u64 10-14 fs/pair/digit x64; x1.43 production calibration
    surv_word=(0, 2e-12, 8e-12),             # N1.G1 per-chunk survivor machinery floor 8.3-9.6 ps per 64 pairs today
    skip=(0.5e-12, 1e-12, 2e-12),
    child=(1.5e-12, 3e-12, 6e-12),           # ~30 integer instructions; Ampere INT32 at 64 lanes/clk/SM
    chunk=(4e-12, 7e-12, 12e-12),            # compaction + 64x64 transpose by shuffles + LDS store + common mask
    sort=(20e-12, 60e-12, 150e-12),          # per parent: coarse 8-bit counting sort + DRAM round trips (48-64 B)
    rederive=(3e-12, 5e-12, 8e-12),          # per depth-5..9 bottom extension (u64 modular steps)
    surv=(17e-12, 30e-12, 54e-12),           # N1.G1: 17.4 ps at today's density, 54 ps at low density
    check=(58e-12 * 0.06,) * 3,
    other=(0.03, 0.08, 0.12),
)
TOP = {62: 0.17e-9, 64: 0.104e-9}            # today's FD top test (N22 b62; B64.1 b64 with FD on)
BASE = {62: dict(author=13.2e-15, direct=12.1e-15, lo=11.0e-15, hi=15.9e-15),
        64: dict(author=4.5e-15, direct=5.3e-15, lo=4.5e-15, hi=5.45e-15)}
AUTHOR = {62: 1.308e-15, 64: 0.542e-15}

def cost(b, i):
    c = CNT[b]; u = {k: (v[i] if isinstance(v, tuple) else v) for k, v in U.items()}
    p = {}
    p['64-pair words'] = c['kept'] * (u['word_base'] + c['pop'] * u['lookup'] + u['surv_word'])
    p['skip tests'] = c['flat'] * u['skip']
    p['children'] = c['children'] * u['child']
    p['chunking'] = c['bottoms'] * u['chunk']
    p['parent sort'] = c['parents'] * u['sort']
    # tops: hierarchy needs digit 4 innermost (bottoms re-derived) or full top tests (bottom tree shared): take the cheaper
    a = c['tops_hier'] * TOP[b] + c['rederive'] * u['rederive']
    bb = c['tops_all'] * TOP[b]
    p['tops (+order)'] = min(a, bb)
    p['survivors+check'] = c['surv'] * (u['surv'] + u['check'])
    tot = sum(p.values()) / (1 - u['other'])
    p['other'] = tot * u['other']
    return tot, p

for b in (62, 64):
    print(f"b{b}: author's central {AUTHOR[b]*1e15:.3f} fs")
    res = []
    for i, s in enumerate(S):
        tot, p = cost(b, i)
        res.append(tot)
        print(f"  {s:8s} {tot*1e15:.3f} fs: " + ', '.join(f"{k} {v*1e15:.3f}" for k, v in p.items()))
    for name, v in BASE[b].items():
        print(f"  vs baseline {name} {v*1e15:.1f} fs: x{v/res[1]:.1f} central (x{v/res[2]:.1f} .. x{v/res[0]:.1f})")

# ---- (4, 9) top-driven, trie-clustered (author's kept_cl; skip tests on 1.4x flat leaves), same unit costs
import math
def P(b, m): return math.prod(1 - i / b for i in range(m))
A = {62: 3.129e20, 64: 4.797e21}
for b, kept, flat, ch, bot, surv, pop in ((62, 6.238e-5, 1.218e-4, 5.07e-6, 2.66e-6, 1.61e-5, 15.5),
                                          (64, 6.044e-5, 1.108e-4, 4.73e-7, 2.33e-7, 1.26e-5, 16.4)):
    red = b ** 4 * b ** 4 * sum(P(b, 2 * j) * 0.95 for j in range(4, 8)) / A[b]
    CNT[('k9', b)] = dict(kept=kept, flat=flat * 1.4, children=ch, bottoms=bot, parents=bot / 30, tops_hier=CNT[b]['tops_hier'],
                          tops_all=CNT[b]['tops_all'], rederive=red, surv=surv, pop=pop)
    TOP[('k9', b)] = TOP[b]
    res = [cost(('k9', b), i)[0] for i in range(3)]
    tot, p = cost(('k9', b), 1)
    print(f"b{b} (4,9): central {res[1]*1e15:.3f} fs (" + ', '.join(f"{k} {v*1e15:.3f}" for k, v in p.items()) + ")")
    for name in ('author', 'direct'):
        v = BASE[b][name]
        print(f"  vs {name} {v*1e15:.1f}: x{v/res[1]:.1f} (x{v/res[2]:.1f} .. x{v/res[0]:.1f})")

# ---- break-even: all-in cost of a kept 64-pair word (base + lookups + survivor machinery) and of a bottom
#      (child share + chunking), other terms at the reviewer's central, against the direct baselines
print()
for b in (62, 64):
    c = CNT[b]
    tot, p = cost(b, 1)
    o = U['other'][1]
    word_now = p['64-pair words'] / c['kept']
    bottom_now = (p['children'] + p['chunking']) / c['bottoms']
    rest = sum(v for k, v in p.items() if k not in ('64-pair words', 'other'))
    for target in (5, 8, 10):
        budget = BASE[b]['direct'] / target * (1 - o)
        w = (budget - rest) / c['kept']
        print(f"b{b} x{target} vs {BASE[b]['direct']*1e15:.1f} fs needs an all-in word <= {w*1e12:.1f} ps (reviewer central {word_now*1e12:.1f}, author {(c['pop']*0.7e-12+4e-12)*1e12 if b==62 else 12.69:.1f})")
    rest2 = sum(v for k, v in p.items() if k not in ('children', 'chunking', 'other'))
    for target in (5, 8):
        budget = BASE[b]['direct'] / target * (1 - o)
        bb = (budget - rest2) / c['bottoms']
        print(f"b{b} x{target} needs all-in per stored bottom (its ~{c['children']/c['bottoms']:.1f} child tests + chunking) <= {bb*1e12:.1f} ps (reviewer central {bottom_now*1e12:.1f})")
    for wps in (10, 15, 20, 25):
        q = dict(p); q['64-pair words'] = c['kept'] * wps * 1e-12
        t = sum(v for k, v in q.items() if k != 'other') / (1 - o)
        print(f"   b{b} word {wps} ps, rest central: {t*1e15:.2f} fs -> x{BASE[b]['direct']/t:.1f} (x{BASE[b]['author']/t:.1f} vs author's baseline)")
# mid-base switch: bottom-side terms are paid for the whole base, tops/pairs only for the remaining fraction f
print()
for f in (1.0, 0.7, 0.5, 0.3):
    tot, p = cost(62, 1)
    o = U['other'][1]
    bot = p['children'] + p['chunking'] + p['parent sort']
    t = (sum(v for k, v in p.items() if k != 'other') - bot + bot / f) / (1 - o)
    print(f"b62 mid-base switch, remaining fraction {f}: reviewer central {t*1e15:.2f} fs per remaining adm -> x{BASE[62]['direct']/t:.1f}"
          f"; author's central {(1.308 - 0.515 + 0.515 / f):.2f} fs -> x{13.2/(1.308 - 0.515 + 0.515 / f):.1f}")
