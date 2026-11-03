#!/usr/bin/env python3
"""L36: markdown table of stepped-slot costs. python3 abl_table.py DIR TAG CONFIGS (comma list)"""
import re, sys, glob, statistics as st
D, TAG = sys.argv[1], sys.argv[2]
CF = [int(x) for x in sys.argv[3].split(',')]
NAMES = {1: 'scan', 2: 'rem', 4: 'carry', 8: 'append', 16: 'step', 32: 'ndig', 128: 'inrun', 256: 'above', 512: 'LSCAN (fast path)', 1024: 'LC0 (carried c0, b^c0 - d)', 2048: 'LCLIP (no a, e on steps)'}
def label(c):
    return 'none' if c == 0 else ' + '.join(n for b, n in NAMES.items() if c & b)
rx = re.compile(r'TOPFD TIMING b(\d+) \S+ round=(\d+) prefixes=(\d+) slots=(\d+) batches=(\d+) \| consecutive ns/slot: top=([\d.]+) fd=([\d.]+) ratio=([\d.]+) \| every other partition ns/slot: top=([\d.]+) fd=([\d.]+) ratio=([\d.]+)')
data = {}
for f in glob.glob(f'{D}/{TAG}_b*_a*_r*.log'):
    b, c, r = re.search(rf'{TAG}_b(\d+)_a(\d+)_r(\d+)\.log', f).groups()
    for line in open(f, errors='replace'):
        m = rx.search(line)
        if m:
            g = m.groups(); k = int(g[3]); tc, fc, fg = float(g[5]), float(g[6]), float(g[9])
            data.setdefault((int(b), int(c)), []).append(((k * fc - fg) / (k - 1), tc, fc, fg))
res = {}
for b in (62, 60):
    tref = st.median(x[1] for (bb, c), v in data.items() if bb == b for x in v)
    for c in CF:
        v = data.get((b, c))
        if v:
            res[(b, c)] = (st.median(x[0] * tref / x[1] for x in v), len(v), st.median(x[2] for x in v), st.median(x[3] for x in v))
print('| removed | b62 1e17: stepped s, ns | saves | % of s | b60 1e16: stepped s, ns | saves | % of s | rounds |')
print('|---|---|---|---|---|---|---|---|')
for c in CF:
    row = f'| {label(c)} |'
    for b in (62, 60):
        if (b, c) in res and (b, 0) in res:
            s0 = res[(b, 0)][0]; s = res[(b, c)][0]
            row += f' {s:.4f} | {s0 - s:.4f} | {100 * (s0 - s) / s0:.1f} % |' if c else f' **{s:.4f}** | | |'
        else:
            row += ' | | |'
    row += f' {res.get((62, c), (0, 0))[1]} / {res.get((60, c), (0, 0))[1]} |'
    print(row)
