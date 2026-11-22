#!/usr/bin/env python3
"""table.py SHARE MICRO_DIR...: the 3080 table by kernel variant from cyc.py's output (MICRO_DIR/cyc.md) of each
timing pass: means over the slices of phase 3b (full - no-3b) in ms and Mcycles, ps per pair (pairs per slice:
Counts::pairs of CW/RESULTS.md), the ratio against the plain w64 loop of the same pass (in cycles), and the whole
main kernel's gain with phase 3b's in-situ share SHARE (main' = 1 - SHARE * (1 - 1/x3b))."""
import sys, re, collections, statistics as st
share = float(sys.argv[1])
PAIRS = {'s4977728': 16.03e9, 's4977729': 16.00e9, 's712012851': 15.97e9}
print(f'| pass | variant | full ms | 3b ms | 3b Mcycles | 3b ps per pair | x3b vs w64 (cycles) | main kernel x (3b share {share}) |')
print('|---|---|---|---|---|---|---|---|')
for d in sys.argv[2:]:
    R = collections.defaultdict(dict)
    for l in open(f'{d}/cyc.md'):
        f = [x.strip() for x in l.strip().strip('|').split('|')]
        if len(f) < 11 or not re.fullmatch(r's\d+', f[0]):
            continue
        R[f[1]][f[0]] = (float(f[2]), float(f[5]), float(f[9]))
    base = R['w64']
    order = ['w64'] + sorted(v for v in R if v != 'w64')
    for v in order:
        r = R[v]
        full = st.mean(x[0] for x in r.values())
        ms = st.mean(x[1] for x in r.values())
        mc = st.mean(x[2] for x in r.values())
        ps = st.mean(r[s][1] * 1e-3 / PAIRS[s] * 1e12 for s in r)
        x = st.mean(base[s][2] / r[s][2] for s in r)
        g = 1 / (1 - share * (1 - 1 / x))
        print(f'| {d.split("/")[-1]} | {v} | {full:.3f} | {ms:.3f} | {mc:.3f} | {ps:.4f} | x{x:.3f} | x{g:.3f} |')
