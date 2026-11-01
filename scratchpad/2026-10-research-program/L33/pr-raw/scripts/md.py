#!/usr/bin/env python3
"""Markdown tables for the PR body from the A/B logs. python3 md.py DIR"""
import re, sys, glob, os, json, statistics as st
D = sys.argv[1]
PR = '--pr' in sys.argv
med = st.median
def spread(x): return 100 * (max(x) - min(x)) / med(x)
def tp(path):
    for line in open(path, errors='replace'):
        if 'JOIN THROUGHPUT' in line:
            d = {}
            for k in ['device', 'per_field', 'survivors', 'checked', 'found', 'slots']:
                m = re.search(r'\b' + k + r'=([0-9.e+]+)s?\b', line)
                if m: d[k] = float(m.group(1))
            return d
# #235 vs main: b62 1e17 and b64 from L30 §4 (6e7475e alone, same machine); 1e16 b60/b62 and NiceMark from L29 (d6cc9da).
MAIN = {'e17_b62': 1.100, 'e16_b62': 1.089, 'e16_b60': 1.053, 'e16_b64': 0.996, 'nm': 1.071}
rows = []
print('| field | #235 s/field (rounds) | spread | this PR s/field (rounds) | spread | speed-up | per round |' + ('' if PR else ' implied vs main |'))
print('|---|---|---|---|---|---|---|' + ('' if PR else '---|'))
for key, label in [('e17_b62', 'b62 1e17, 1 field'), ('e16_b62', 'b62 1e16, 2 fields'), ('e16_b60', 'b60 1e16, 2 fields'), ('e16_b64', 'b64 1e16, 2 fields')]:
    A = [tp(f) for f in sorted(glob.glob(f'{D}/ab_A_{key}_r*.log'))]
    B = [tp(f) for f in sorted(glob.glob(f'{D}/ab_B_{key}_r*.log'))]
    A = [x for x in A if x]; B = [x for x in B if x]
    n = min(len(A), len(B))
    if n == 0:
        print(f'| {label} | missing | | | | | | |'); continue
    A, B = A[:n], B[:n]
    a = [x['device'] for x in A]; b = [x['device'] for x in B]
    r = med(a) / med(b)
    pr = ', '.join(f'{x / y:.3f}' for x, y in zip(a, b))
    fa = ', '.join(f'{x:.2f}' for x in a); fb = ', '.join(f'{x:.2f}' for x in b)
    print(f'| {label} | **{med(a):.2f}** ({fa}) | {spread(a):.1f} % | **{med(b):.2f}** ({fb}) | {spread(b):.1f} % | **×{r:.3f}** | {pr} |' + ('' if PR else f' ×{r * MAIN[key]:.3f} (#235 ×{MAIN[key]:.3f}) |'))
    def rng(X, k):
        v = [int(x[k]) for x in X]
        return f'{min(v):,}–{max(v):,}' if min(v) != max(v) else f'{v[0]:,}'
    fd = sorted(set(int(x['found']) for x in A + B))
    pf = med([x['per_field'] for x in A]) / med([x['per_field'] for x in B])
    rows.append(f'- {label}: per_field ratio ×{pf:.3f}; survivors #235 {rng(A, "survivors")} | PR {rng(B, "survivors")}; checked #235 {rng(A, "checked")} | PR {rng(B, "checked")}; found {fd}; slots {int(A[0]["slots"])}/{int(B[0]["slots"])}')
print()
print('\n'.join(rows))
print()
nm = {}
for side in ['A', 'B']:
    for f in sorted(glob.glob(f'{D}/nm_{side}_r*.json')):
        try: j = json.load(open(f))
        except Exception: continue
        nm.setdefault(side, []).append((j['score'], {s['key']: s for s in j['scenarios']}))
if 'A' in nm and 'B' in nm:
    n = min(len(nm['A']), len(nm['B']))
    sa = [x[0] for x in nm['A'][:n]]; sb = [x[0] for x in nm['B'][:n]]
    print(f'NiceMark score: #235 {med(sa):.0f} ({", ".join(f"{x:.0f}" for x in sa)}; spread {spread(sa):.1f} %) -> PR {med(sb):.0f} ({", ".join(f"{x:.0f}" for x in sb)}; spread {spread(sb):.1f} %): ×{med(sb)/med(sa):.3f}; per round {", ".join(f"{y/x:.3f}" for x, y in zip(sa, sb))}' + ('' if PR else f'; implied vs main ×{med(sb)/med(sa)*MAIN["nm"]:.3f}'))
    print()
    print('| scenario | #235 rate | spread | this PR rate | spread | speed-up |')
    print('|---|---|---|---|---|---|')
    for k in nm['A'][0][1]:
        ra = [x[1][k]['rate'] for x in nm['A'][:n]]; rb = [x[1][k]['rate'] for x in nm['B'][:n]]
        print(f'| {k.replace("_", " ")} | {med(ra):.4g} | {spread(ra):.1f} % | {med(rb):.4g} | {spread(rb):.1f} % | ×{med(rb)/med(ra):.3f} |')
