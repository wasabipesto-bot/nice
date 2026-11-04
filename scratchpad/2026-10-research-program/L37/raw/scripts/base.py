#!/usr/bin/env python3
"""L37: the base split (modes 4, 9, 10, 11 from base_*, 11/12 from base4_*, main and z from the 3-round ablation).
python3 base.py DIR"""
import sys, glob, os, statistics as st, re
D = sys.argv[1]
med = st.median
def joins(pat):
    out = []
    for f in sorted(glob.glob(f'{D}/{pat}')):
        js = []
        for line in open(f, errors='replace'):
            if 'GPU_PROFILE' in line:
                m = re.search(r'size=(\d+)', line); j = re.search(r' join=([0-9.]+)', line)
                if m and int(m.group(1)) > 10**14 and j:
                    js.append(float(j.group(1)))
        if js:
            out.append(sum(js) / len(js))
    return out
rows = [('c: full (main), 3-round ablation', 'abl_c_{f}_r*.log'), ('4 (z): no AND', 'base_m4_{f}_r*.log'),
        ('9: 4 without the transposed copy', 'base_m9_{f}_r*.log'), ('10: 9 without the entry loads', 'base_m10_{f}_r*.log'),
        ('11: 10 without the waves (tree A3)', 'base_m11_{f}_r*.log'), ('11 (tree A4, beside 12)', 'base4_m11_{f}_r*.log'),
        ('12: 11 without the top loads', 'base4_m12_{f}_r*.log'),
        ('11 (tree A5, beside 12–14)', 'base5_m11_{f}_r*.log'), ('13: 11 gathering only `top_m` (1 sector per top)', 'base5_m13_{f}_r*.log'),
        ('14: 11 reading only `tl`', 'base5_m14_{f}_r*.log'), ('12 (tree A5)', 'base5_m12_{f}_r*.log')]
F = ['e17_b62', 'e16_b60']
print('| mode | b62 1e17 join s/field (runs) | % of main\'s join | b60 1e16 join s/field (runs) | % of main\'s join |')
print('|---|---|---|---|---|')
ref = {f: med(joins(f'abl_c_{f}_r*.log')) for f in F}
for name, pat in rows:
    cells = []
    for f in F:
        j = joins(pat.format(f=f))
        cells.append(f'{med(j):.2f} ({", ".join(f"{x:.2f}" for x in j)}) | {100 * med(j) / ref[f]:.1f} %' if j else '– | –')
    print(f'| {name} | ' + ' | '.join(cells) + ' |')
