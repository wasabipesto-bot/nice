#!/usr/bin/env python3
"""The AVX-512 box's runs (raw/avx512/runs*.txt): per case, medians of the
three binaries (#248 = base, this PR = pr with AVX-512, pr-avx2 = this PR
with the AVX-512 path switched off), ratios per round, and the counts."""
import re, os, sys, statistics as st, collections
D = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'avx512')
runs = collections.defaultdict(dict); cur = None
for f in sys.argv[1:]:
    for line in open(os.path.join(D, f)):
        m = re.match(r'### r(\d+) (\S+) (\S+) ', line)
        if m: cur = (int(m[1]), m[2], m[3]); continue
        m = re.match(r'wall (\S+)s; (\S+) ms/partition/thread; survivors (\d+) checked (\d+) hits (\d+)', line)
        if m and cur:
            r, c, b = cur; runs[(c, b)][r] = (float(m[1]), float(m[2]), int(m[3]), int(m[4]), int(m[5])); cur = None
cases = []
for c, b in runs:
    if c not in cases: cases.append(c)
B = ['base', 'pr', 'pr-avx2']
for c in cases:
    i = 0 if 'e14' in c else 1
    rs = sorted(runs[(c, 'pr')])
    vals = {b: [runs[(c, b)][r][i] for r in rs] for b in B}
    med = {b: st.median(vals[b]) for b in B}
    cnt = {(v[2], v[3], v[4]) for b in B for v in runs[(c, b)].values()}
    f = (lambda x: f'{x:.2f}') if i == 0 else (lambda x: f'{x:.0f}')
    print(f"| {c} | {f(med['base'])} ({', '.join(f(x) for x in vals['base'])}) | {f(med['pr'])} ({', '.join(f(x) for x in vals['pr'])}) | {f(med['pr-avx2'])} ({', '.join(f(x) for x in vals['pr-avx2'])}) | **×{med['base']/med['pr']:.3f}** ({', '.join(f'{a/b:.3f}' for a, b in zip(vals['base'], vals['pr']))}) | ×{med['pr-avx2']/med['pr']:.3f} ({', '.join(f'{a/b:.3f}' for a, b in zip(vals['pr-avx2'], vals['pr']))}) | {'; '.join(f'{s:,} / {k:,} / {h}' for s, k, h in cnt)}{'' if len(cnt) == 1 else ' DIFFER'} |")
