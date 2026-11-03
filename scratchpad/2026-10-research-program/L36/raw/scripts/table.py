#!/usr/bin/env python3
"""L36: markdown A/B table with the product of the per-PR ratios. python3 table.py DIR"""
import sys, glob, os, statistics as st, json, importlib.util
spec = importlib.util.spec_from_file_location('a', os.path.join(os.path.dirname(__file__), 'analyze.py'))
D = sys.argv[1]
# per-PR ratios per field: #235+#236 (L30 combined), #237 (L33 PR body), #240 (L35 §5, on all3; b64: FD off there),
# #239 (L34 §11 gate screen MIN=192 on all3)
PER = {
  'e17_b62': (1.365, 1.100, 1.143, 1.074),
  'e16_b62': (1.350, 1.098, 1.136, 1.063),
  'e16_b60': (1.379, 1.092, 1.084, 1.078),
  'e16_b64': (1.305, 1.019, 1.000, 1.173),
  'nm':      (1.325, 1.108, 1.000, 1.107),
}
import re
def tp(path):
    for line in open(path, errors='replace'):
        if 'JOIN THROUGHPUT' in line:
            d = {}
            for k in ['device', 'survivors', 'checked', 'found', 'per_field']:
                m = re.search(r'\b' + k + r'=([0-9.e+]+)s?\b', line)
                if m: d[k] = float(m.group(1))
            return d
def smi(path):
    mhz, w = [], []
    if not os.path.exists(path): return None, None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) >= 8 and float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
        except ValueError: pass
    return (st.mean(mhz), st.mean(w)) if mhz else (None, None)
med = st.median
def spread(x): return 100 * (max(x) - min(x)) / med(x)
print('| field | main s/field (rounds) | spread | all5 s/field (rounds) | spread | **speed-up** | per round | saving / field | product of per-PR ratios | clock main / all5 (MHz) | clock-normalised |')
print('|---|---|---|---|---|---|---|---|---|---|---|')
for key, label in [('e17_b62', 'b62 1e17, 1 field'), ('e16_b62', 'b62 1e16, 2 fields'), ('e16_b60', 'b60 1e16, 2 fields'), ('e16_b64', 'b64 1e16, 2 fields')]:
    A = [tp(f) for f in sorted(glob.glob(f'{D}/ab_A_{key}_r*.log'))]; B = [tp(f) for f in sorted(glob.glob(f'{D}/ab_B_{key}_r*.log'))]
    A = [x for x in A if x]; B = [x for x in B if x]
    if not A or not B: continue
    a = [x['device'] for x in A]; b = [x['device'] for x in B]
    ca = [smi(f[:-4] + '.smi')[0] for f in sorted(glob.glob(f'{D}/ab_A_{key}_r*.log'))]; cb = [smi(f[:-4] + '.smi')[0] for f in sorted(glob.glob(f'{D}/ab_B_{key}_r*.log'))]
    ca = [c for c in ca if c]; cb = [c for c in cb if c]
    prod = 1
    for r in PER[key]: prod *= r
    pr = ', '.join(f'{x / y:.3f}' for x, y in zip(a, b))
    cn = med(a) * st.mean(ca) / (med(b) * st.mean(cb)) if ca and cb else float('nan')
    print(f'| {label} | **{med(a):.2f}** ({", ".join(f"{x:.2f}" for x in a)}) | {spread(a):.1f} % | **{med(b):.2f}** ({", ".join(f"{x:.2f}" for x in b)}) | {spread(b):.1f} % | **×{med(a)/med(b):.3f}** | {pr} | −{med(a)-med(b):.2f} s | ×{prod:.3f} | {st.mean(ca):.0f} / {st.mean(cb):.0f} | ×{cn:.3f} |')
nm = {}
for s in 'AB':
    for f in sorted(glob.glob(f'{D}/nm_{s}_r*.json')):
        try: nm.setdefault(s, []).append(json.load(open(f)))
        except Exception: pass
if 'A' in nm and 'B' in nm:
    sa = [j['score'] for j in nm['A']]; sb = [j['score'] for j in nm['B']]
    prod = 1
    for r in PER['nm']: prod *= r
    print()
    print(f'NiceMark score: main {", ".join(f"{x:.1f}" for x in sa)} (median {med(sa):.1f}, spread {spread(sa):.1f} %) | all5 {", ".join(f"{x:.1f}" for x in sb)} (median {med(sb):.1f}, spread {spread(sb):.1f} %) | x{med(sb)/med(sa):.3f} per round {", ".join(f"{y/x:.3f}" for x, y in zip(sa, sb))} | product x{prod:.3f}')
    for k in [s['key'] for s in nm['A'][0]['scenarios']]:
        ra = [next(s for s in j['scenarios'] if s['key'] == k)['rate'] for j in nm['A']]
        rb = [next(s for s in j['scenarios'] if s['key'] == k)['rate'] for j in nm['B']]
        print(f'  {k}: main {med(ra):.4g} ({min(ra):.4g}-{max(ra):.4g}) all5 {med(rb):.4g} ({min(rb):.4g}-{max(rb):.4g}) x{med(rb)/med(ra):.3f}')
