#!/usr/bin/env python3
"""Per-partition counters from perfstat-runs.txt: each count x (ms/partition)
/ task-clock (ms), i.e. scaled from the counted window (3.5 s on) to one
partition. Medians over the rounds per side and shape."""
import re, os, statistics as st, collections
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cur, runs = None, collections.defaultdict(list)
for line in open(os.path.join(R, 'perfstat-runs.txt')):
    m = re.match(r'### \S+ r(\d+) perfstat (\S+) (\S+)', line)
    if m: cur = dict(side=m[2], shape=m[3]); continue
    m = re.match(r'wall \S+s; (\S+) ms/partition/thread', line)
    if m and cur is not None: cur['ms'] = float(m[1]); continue
    m = re.match(r'([\d.]+),[^,]*,([a-z-]+),', line)
    if m and cur is not None:
        cur[m[2]] = float(m[1])
        if m[2] == 'task-clock':
            runs[(cur['shape'], cur['side'])].append(cur); cur = None
print('| shape | side | instructions | branches | branch misses (% of branches) | cycles | IPC | ms/partition |')
print('|---|---|---|---|---|---|---|---|')
for (shape, side), rs in sorted(runs.items(), key=lambda x: (x[0][0], x[0][1] != 'base')):
    f = lambda k: st.median(r[k] * r['ms'] / r['task-clock'] for r in rs)
    ins, br, bm, cy = f('instructions'), f('branches'), f('branch-misses'), f('cycles')
    print(f"| {shape} | {side} ({len(rs)} runs) | {ins:.3e} | {br:.3e} | {bm/1e6:.1f} M ({100*bm/br:.2f} %) | {cy:.3e} | {ins/cy:.2f} | {st.median(r['ms'] for r in rs):.0f} |")
