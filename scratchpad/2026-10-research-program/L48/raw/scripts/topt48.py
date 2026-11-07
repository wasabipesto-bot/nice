#!/usr/bin/env python3
"""L48 (from L36's abl.py): #240's kernel-alone timing per NICE_EXP_TOPFD level. python3 topt48.py DIR [PREFIX]
Files DIR/{PREFIX}_l{L}_{field}_r{R}.log, TOPFD TIMING lines (three rounds per process). Per round: c = FD consecutive
ns/(prefix, slot), g = FD every-other-partition (every slot seeds), k = slots a batch; stepped s = (k*c - g)/(k - 1),
also normalised by top_kernel's consecutive time in the same round (s x median top time over the field's runs / this
round's). Seeded slot = g. Rounds whose process index is 0 (warm-up) are kept (L36: skip0 moves shares <= 2 points)."""
import re, sys, glob, statistics as st
D = sys.argv[1]; P = sys.argv[2] if len(sys.argv) > 2 else 'topt'
rx = re.compile(r'TOPFD TIMING b(\d+) \S+ round=(\d+) prefixes=(\d+) slots=(\d+) batches=(\d+) \| consecutive ns/slot: top=([\d.]+) fd=([\d.]+) ratio=([\d.]+) \| every other partition ns/slot: top=([\d.]+) fd=([\d.]+) ratio=([\d.]+)')
data = {}
for f in glob.glob(f'{D}/{P}_l*_*_r*.log'):
    m = re.search(rf'{P}_l(\d+)_(e\d+_b\d+)_r(\d+)\.log', f)
    if not m: continue
    lv, fld, r = m.groups()
    for line in open(f, errors='replace'):
        mm = rx.search(line)
        if mm:
            g = mm.groups(); k = int(g[3]); tc, fc, tg, fg = float(g[5]), float(g[6]), float(g[8]), float(g[9])
            data.setdefault((fld, int(lv)), []).append(dict(k=k, tc=tc, fc=fc, tg=tg, fg=fg, s=(k * fc - fg) / (k - 1), pre=int(g[2])))
for fld in sorted(set(k[0] for k in data), reverse=True):
    tref = st.median([x['tc'] for (f, l), v in data.items() if f == fld for x in v])
    print(f'{fld}: top_kernel consecutive median {tref:.4f} ns/slot')
    print(f'| level | n | k | FD consecutive c | all-seed g | stepped s | s normalised (range) | vs level 0 | top_kernel cons |')
    print('|---|---|---|---|---|---|---|---|---|')
    s0 = None
    for lv in sorted(l for f, l in data if f == fld):
        v = data[(fld, lv)]
        sn = [x['s'] * tref / x['tc'] for x in v]
        row = (st.median(x['fc'] for x in v), st.median(x['fg'] for x in v), st.median(x['s'] for x in v), st.median(sn), min(sn), max(sn))
        if lv == 0: s0 = row[3]
        rel = f'{100 * (row[3] - s0) / s0:+.1f} %' if s0 else ''
        ks = sorted(set(x['k'] for x in v))
        print(f'| {lv} | {len(v)} | {ks} | {row[0]:.4f} | {row[1]:.4f} | {row[2]:.4f} | **{row[3]:.4f}** ({row[4]:.4f}-{row[5]:.4f}) | {rel} | {st.median(x["tc"] for x in v):.4f} |')
    print()
