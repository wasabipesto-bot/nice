#!/usr/bin/env python3
"""L33 A/B analysis: python3 ab.py DIR. A = e9cdac4; variants of B by NICE_EXP_TOP_ER:
s = 1 (in-place skip), c = 2 (skip + compaction), t = 4 (trimmed division), ct = 6 (both)."""
import re, sys, glob, os, statistics as st

D = sys.argv[1] if len(sys.argv) > 1 else 'box'
PFX = sys.argv[2] if len(sys.argv) > 2 else 'ab'
med = st.median

def tp(path):
    for line in open(path, errors='replace'):
        if 'JOIN THROUGHPUT' not in line:
            continue
        d = {}
        for k in ['base', 'fields', 'secs', 'per_field', 'device', 'wall', 'setup', 'survivors', 'checked', 'found', 'slots', 'plan_mib']:
            m = re.search(r'\b' + k + r'=([0-9.e+]+)s?\b', line)
            if m:
                d[k] = float(m.group(1)) if any(c in m.group(1) for c in '.e') else int(m.group(1))
        return d
    return None

def smi(path):
    mhz, w, t = [], [], []
    if not os.path.exists(path):
        return None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        if len(p) < 8:
            continue
        try:
            if float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0])); t.append(float(p[5]))
        except ValueError:
            pass
    return (st.mean(mhz), st.mean(w), max(t)) if mhz else None

def spread(x):
    return 100 * (max(x) - min(x)) / med(x)

NAMES = {'A': 'A (e9cdac4)', 's': 'ER=1 in-place skip', 'c': 'ER=2 compaction', 't': 'ER=4 trimmed division', 'ct': 'ER=6 compaction + trim',
         'cp': 'ER=26 compaction + parent digits + queued state', 'cpt': 'ER=30 the same + trim'}
for prefix, label in [('e17_b62', 'b62 1e17, 1 field'), ('e16_b62', 'b62 1e16, 2 fields'), ('e16_b60', 'b60 1e16, 2 fields')]:
    rows = {}
    for v in NAMES:
        rs = []
        for f in sorted(glob.glob(f'{D}/{PFX}_{v}_{prefix}_r*.log')):
            d = tp(f)
            if d:
                rs.append((int(re.search(r'_r(\d+)\.log', f).group(1)), d, smi(f[:-4] + '.smi')))
        if rs:
            rows[v] = sorted(rs, key=lambda x: x[0])
    if 'A' not in rows:
        continue
    print(f'#### {label}')
    print()
    print('| variant | device s/field (rounds) | median | spread | speed-up (medians) | per round | MHz / W / max °C |')
    print('|---|---|---|---|---|---|---|')
    a = {r: d['device'] for r, d, _ in rows['A']}
    for v, rs in rows.items():
        x = [d['device'] for _, d, _ in rs]
        per = [a[r] / d['device'] for r, d, _ in rs if r in a]
        sm = [s for _, _, s in rs if s]
        clk = f"{st.mean(s[0] for s in sm):.0f} / {st.mean(s[1] for s in sm):.0f} / {max(s[2] for s in sm):.0f}" if sm else '-'
        print(f"| {NAMES[v]} | {', '.join(f'{y:.3f}' for y in x)} | **{med(x):.3f}** | {spread(x):.1f} % | **×{med(list(a.values())) / med(x):.3f}** | {', '.join(f'{p:.3f}' for p in per)} | {clk} |")
    print()
    for v, rs in rows.items():
        c = sorted(set((d['survivors'], d['checked'], d['found']) for _, d, _ in rs))
        print(f"- {NAMES[v]} counts (survivors / checked / found): {'; '.join(f'{s:,} / {k:,} / {f}' for s, k, f in c)}; slots {rs[0][1].get('slots')}, plan MiB {rs[0][1].get('plan_mib')}")
    print()
