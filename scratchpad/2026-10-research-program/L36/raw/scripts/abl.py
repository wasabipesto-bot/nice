#!/usr/bin/env python3
"""L36 ablation analysis: python3 abl.py DIR [TAG]. Parses TOPFD TIMING lines of {TAG}_b{b}_a{cfg}_r{r}.log.
Per round: c = FD consecutive ns/(prefix, slot), g = FD every-other-partition (all seeds), k = slots;
stepped s = (k*c - g)/(k - 1). Also each relative to top_kernel's consecutive time in the same round
(clock drift cancels), scaled back by the median top_kernel time over all runs of the field."""
import re, sys, glob, os, statistics as st
D = sys.argv[1]; TAG = sys.argv[2] if len(sys.argv) > 2 else "abl"; SKIP0 = len(sys.argv) > 3 and sys.argv[3] == "skip0"
NAMES = {1: 'scan', 2: 'rem', 4: 'carry', 8: 'append', 16: 'step', 32: 'ndig'}
def label(c):
    c = int(c)
    if c == 0: return 'none'
    return '+'.join(n for b, n in NAMES.items() if c & b) + (' +diag' if c & 64 else '')
rx = re.compile(r'TOPFD TIMING b(\d+) \S+ round=(\d+) prefixes=(\d+) slots=(\d+) batches=(\d+) \| consecutive ns/slot: top=([\d.]+) fd=([\d.]+) ratio=([\d.]+) \| every other partition ns/slot: top=([\d.]+) fd=([\d.]+) ratio=([\d.]+)')
data = {}
for f in glob.glob(f'{D}/{TAG}_b*_a*_r*.log'):
    m = re.search(rf'{TAG}_b(\d+)_a(\d+)_r(\d+)\.log', f)
    b, c, r = m.groups()
    for line in open(f, errors='replace'):
        mm = rx.search(line)
        if mm and not (SKIP0 and mm.group(2) == "0"):
            g = mm.groups()
            k = int(g[3]); tc, fc, tg, fg = float(g[5]), float(g[6]), float(g[8]), float(g[9])
            s = (k * fc - fg) / (k - 1)
            data.setdefault((int(b), int(c)), []).append(dict(k=k, tc=tc, fc=fc, tg=tg, fg=fg, s=s, pre=int(g[2])))
for b in sorted(set(k[0] for k in data)):
    tref = st.median([x['tc'] for (bb, c), v in data.items() if bb == b for x in v])
    base = None
    print(f'b{b}: top_kernel consecutive median over all runs {tref:.4f} ns/slot; prefixes {data[(b, min(c for bb, c in data if bb == b))][0]["pre"]}, k={data[(b, min(c for bb, c in data if bb == b))][0]["k"]}')
    print(f'  {"config":24s} {"n":>3s} {"FD cons c":>10s} {"all-seed g":>10s} {"stepped s":>10s} {"s (norm)":>9s} {"s range":>15s} {"top cons":>9s}')
    rows = {}
    for c in sorted(c for bb, c in data if bb == b):
        v = data[(b, c)]
        sn = [x['s'] * tref / x['tc'] for x in v]
        row = dict(c=st.median(x['fc'] for x in v), g=st.median(x['fg'] for x in v), s=st.median(x['s'] for x in v), sn=st.median(sn), lo=min(sn), hi=max(sn), tc=st.median(x['tc'] for x in v), n=len(v))
        rows[c] = row
        print(f'  {label(c):24s} {row["n"]:3d} {row["c"]:10.4f} {row["g"]:10.4f} {row["s"]:10.4f} {row["sn"]:9.4f} {row["lo"]:7.4f}-{row["hi"]:.4f} {row["tc"]:9.4f}')
    if 0 in rows:
        s0 = rows[0]['sn']
        print(f'  removed part (stepped slot, normalised): cost = s(none) - s(config), share of s(none) = {s0:.4f}')
        for c, r in rows.items():
            if c:
                print(f'    {label(c):24s} {s0 - r["sn"]:+.4f} ns ({100 * (s0 - r["sn"]) / s0:+.1f} %)   seeded slot g: {rows[0]["g"] - r["g"]:+.4f}')
    if 8 in rows:
        s8 = rows[8]['sn']
        print(f'  on top of count-only append (config 8, s = {s8:.4f}):')
        for c, r in rows.items():
            if c & 8 and c != 8 and not c & 64:
                print(f'    {label(c):24s} {s8 - r["sn"]:+.4f} ns ({100 * (s8 - r["sn"]) / rows[0]["sn"]:+.1f} % of s(none))')
for f in sorted(glob.glob(f'{D}/*.log')):
    for line in open(f, errors='replace'):
        if 'TOPFD DIAG' in line:
            print(os.path.basename(f), line.strip())
