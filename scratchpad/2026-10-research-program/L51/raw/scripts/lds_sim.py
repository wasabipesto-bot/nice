#!/usr/bin/env python3
"""L51: shared-memory wavefronts of the transposed AND's digit loads (t_tr[(cb + c)·64 + p], p = the entry's mask bit,
bit-reversed under `lean`; bank = p mod 32). A warp's 32 lanes each walk their entry's set bits lowest first, one
LDS.32 per (digit, chunk of the group); an LDS costs as many wavefronts as the most distinct addresses in one bank
(1 or 2 here: p and p + 32 share a bank). Entries: `nd` distinct digits drawn uniformly from the `free` digits the
field certificate leaves (digits in the certificate are pruned with their entries). Prints mean wavefronts per LDS and
LDS per (warp, group) at each setting, and the 128-bit alternative (t_tr digit-major: one LDS.128 per digit for the
group's 4 chunks; quarter-warp phases, 8 lanes x 4 banks)."""
import random, statistics as st
random.seed(51)
def sim(nd, free, trials=4000):
    wf = []; its = []; wf128 = []
    for _ in range(trials):
        digs = random.sample(range(62), free)
        lanes = [sorted(63 - d for d in random.sample(digs, nd)) for _ in range(32)]  # bit positions, lowest first
        n = max(len(l) for l in lanes); its.append(n)
        for i in range(n):
            ps = [l[i] for l in lanes if i < len(l)]
            banks = {}
            for p in set(ps): banks.setdefault(p % 32, set()).add(p)
            wf.append(max(len(v) for v in banks.values()))
            # digit-major 128-bit: address 4p..4p+3 words; phase q = lanes 8q..8q+7; banks (4p + j) mod 32 = 4(p mod 8) + j
            w = 0
            for q in range(4):
                pq = [l[i] for l in lanes[8 * q:8 * q + 8] if i < len(l)]
                b = {}
                for p in set(pq): b.setdefault(p % 8, set()).add(p)
                w += max((len(v) for v in b.values()), default=0)
            wf128.append(w)
    return st.mean(wf), st.mean(its), st.mean(wf128)
print('nd free | wavefronts per LDS.32 | digit iterations per warp | LDS.32 wavefronts per digit (4 chunks) | LDS.128 wavefronts per digit')
for nd in (12, 14):
    for free in (62, 50, 40):
        w, it, w128 = sim(nd, free)
        print(f'{nd:2d} {free:2d} | {w:.3f} | {it:.2f} | {4 * w:.2f} | {w128:.2f}')
