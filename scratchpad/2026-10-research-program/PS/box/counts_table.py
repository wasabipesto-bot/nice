#!/usr/bin/env python3
"""counts_table.py RAW_DIR: the share counts (raw/count_<pip>.txt, lines 'C ...') as markdown tables, per slice and
the mean over the slices: loads per visit (listed (probe, round) entry) summed, and in lockstep per plane of 2 streams
(CUDA warp 32) and 4 streams (wave 64), and the lockstep cost against today's kernel (il, pad17)."""
import sys, glob, re, collections, statistics as st
d = sys.argv[1]
R = collections.defaultdict(dict)
pips = []
for f in sorted(glob.glob(f'{d}/count_*.txt')):
    pip = re.search(r'count_(\d+)', f).group(1); pips.append(pip)
    for l in open(f):
        if not l.startswith('C '):
            continue
        x = l.split()
        R[(x[2], x[3], x[4])][pip] = (float(x[6]), float(x[15]), float(x[17]), float(x[22]), float(x[24]), float(x[30]), float(x[32]))
ORD = sys.argv[2].split(',') if len(sys.argv) > 2 else ['today', 'asc', 'freq', 'pos', 'posi', 'pos_u', 'freq_u']
ASG = ['il', 'c32', 'c16x2', 'c16']
SCH = ['pad17', 'own', 'trie4', 'trie17', 'd1_4', 'd1_8', 'd1_17', 'g1', 'g2', 'g3', 'q2', 'q3', 'q4']
print(f'slices: {", ".join(pips)}; values are means over them (max spread between slices in the last column)\n')
print('| order | assignment | scheme | loads/visit (summed) | lockstep w32 per visit | lockstep w64 per visit | vs today w32 | vs today w64 | idle stream slots w32 / w64 | spread (vs today w64) |')
print('|---|---|---|---|---|---|---|---|---|---|')
for o in ORD:
    for a in ASG:
        for s in SCH:
            v = R.get((o, a, s))
            if not v:
                continue
            m = [st.mean(v[p][i] for p in v) for i in range(7)]
            sp = max(v[p][4] for p in v) - min(v[p][4] for p in v)
            print(f'| {o} | {a} | {s} | {m[0]:.3f} | {m[1]:.3f} | {m[2]:.3f} | {m[3]:.4f} | {m[4]:.4f} | {m[5]:.4f} / {m[6]:.4f} | {sp:.4f} |')
