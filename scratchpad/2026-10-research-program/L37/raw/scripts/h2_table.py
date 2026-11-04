#!/usr/bin/env python3
"""L37: H2 table. python3 h2_table.py DIR. Full fields from ab2_S{0,1}_* (+ the screen scr_S*_e16_b62), AND-only join
seconds per field from andabl_S{0,1}_* (+ scrabl_S*_e16_b62), profiled."""
import sys, glob, re, os, statistics as st, importlib.util
D = sys.argv[1]
med = st.median
spec = importlib.util.spec_from_file_location('ab', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'clocks.py'))
def mhz(f):
    v = []
    for line in open(f, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) >= 8 and float(p[6].split()[0]) >= 90: v.append(float(p[1].split()[0]))
        except ValueError: pass
    return st.mean(v) if v else None
def dev(f):
    m = re.search(r'JOIN THROUGHPUT.*?device=([0-9.]+)s', open(f, errors='replace').read()); return float(m.group(1)) if m else None
def join(f):
    js = []
    for line in open(f, errors='replace'):
        if 'GPU_PROFILE' in line:
            m = re.search(r'size=(\d+)', line); j = re.search(r' join=([0-9.]+)', line)
            if m and int(m.group(1)) > 10**14: js.append(float(j.group(1)))
    return sum(js) / len(js) if js else None
print('| | NICE_EXP_JOIN_SHFL=0 s/field (runs) | =1 (runs) | 1 vs 0 (per run) | cycles | MHz 0 / 1 |')
print('|---|---|---|---|---|---|')
for label, pats, fn in [('b62 1e17 full field', ['ab2_S{s}_e17_b62_r*'], dev), ('b62 1e16 full field', ['scr_S{s}_e16_b62', 'ab2_S{s}_e16_b62_r*'], dev),
                        ('b60 1e16 full field', ['ab2_S{s}_e16_b60_r*'], dev), ('b62 1e17 AND-only join', ['andabl_S{s}_e17_b62_r*'], join),
                        ('b62 1e16 AND-only join', ['scrabl_S{s}_e16_b62'], join), ('b60 1e16 AND-only join', ['andabl_S{s}_e16_b60_r*'], join)]:
    v = {}
    for s in '01':
        fs = sorted(sum((glob.glob(f'{D}/{p.format(s=s)}.log') for p in pats), []))
        v[s] = [(fn(f), mhz(f[:-4] + '.smi')) for f in fs if fn(f)]
    if not v['0'] or not v['1']: continue
    a = [x[0] for x in v['0']]; b = [x[0] for x in v['1']]
    ca = [x[0] * x[1] for x in v['0'] if x[1]]; cb = [x[0] * x[1] for x in v['1'] if x[1]]
    print(f'| {label} | {med(a):.3f} ({", ".join(f"{x:.2f}" for x in a)}) | {med(b):.3f} ({", ".join(f"{x:.2f}" for x in b)}) | '
          f'**×{med(a) / med(b):.3f}** ({", ".join(f"{x / y:.3f}" for x, y in zip(a, b))}) | ×{med(ca) / med(cb):.3f} | '
          f'{st.mean([x[1] for x in v["0"] if x[1]]):.0f} / {st.mean([x[1] for x in v["1"] if x[1]]):.0f} |')
