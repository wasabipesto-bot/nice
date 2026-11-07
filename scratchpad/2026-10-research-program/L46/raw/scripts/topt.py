#!/usr/bin/env python3
"""L46 (L38's): the top stage alone (cubecl_cuda_top_fd_timing), base A against B. python3 topt.py DIR A B
Files DIR/topt_{A,B}_{field}_r{N}.log, TOPFD TIMING lines (three rounds per process); medians over all rounds."""
import re, sys, glob, statistics as st
D, VA, VB = sys.argv[1], sys.argv[2], sys.argv[3]
pat = re.compile(r'TOPFD TIMING b(\d+) (\S+) round=(\d+).*consecutive ns/slot: top=([0-9.]+) fd=([0-9.]+).*every other partition ns/slot: top=([0-9.]+) fd=([0-9.]+)')
rows = {}
for f in sorted(glob.glob(f'{D}/topt_*_r*.log')):
    v, fld = f.split('/')[-1].split('_')[1], '_'.join(f.split('/')[-1].split('_')[2:4])
    for line in open(f, errors='replace'):
        m = pat.search(line)
        if m:
            rows.setdefault((fld, v), []).append(tuple(float(x) for x in m.groups()[3:]))
print(f'| field | kernel | {VA} ns/slot (median of runs) | {VB} ns/slot | {VB} vs {VA} |')
print('|---|---|---|---|---|')
for fld in sorted(set(k[0] for k in rows)):
    for i, name in enumerate(['top_kernel, consecutive', 'top_fd_kernel, consecutive', 'top_kernel, every other', 'top_fd_kernel, every other']):
        m = [r[i] for r in rows.get((fld, VA), [])]; p = [r[i] for r in rows.get((fld, VB), [])]
        if m and p:
            print(f'| {fld} | {name} | {st.median(m):.4f} ({len(m)}) | {st.median(p):.4f} ({len(p)}) | ×{st.median(m) / st.median(p):.3f} |')
