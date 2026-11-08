#!/usr/bin/env python3
"""PR-body rows from an A/B log: per case, #248 and PR medians over the OK
rounds with the rounds in order, spread, speed-up, per-round ratios."""
import re, os, sys, statistics as st
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LABEL = {
 'b60e16_1t': ('**b60 1e16**, 4 partitions', 1), 'b62e17s0_1t': ('**b62 1e17** slice 0, 4 partitions', 1),
 'b60e16_4t': ('**b60 1e16**, 16 partitions', 4), 'b62e17s0_4t': ('**b62 1e17** slice 0, 16 partitions', 4),
 'b58e15_1t': ('b58 1e15 (NiceMark\'s field), 32 partitions', 1), 'b58e15_4t': ('b58 1e15, 128 partitions', 4),
 'b60e14_4t': ('b60 1e14, whole field (3600 partitions)', 4), 'b62e14_4t': ('b62 1e14, whole field (3844 partitions)', 4),
 'b64e14_4t': ('b64 1e14, whole field (4096 partitions)', 4),
 'b60e14_1t': ('b60 1e14, whole field', 1), 'b62e14_1t': ('b62 1e14, whole field', 1), 'b64e14_1t': ('b64 1e14, whole field', 1),
}
rounds, runs, cur = {}, {}, None
for line in open(os.path.join(R, sys.argv[1])):
    m = re.match(r'#### round (\d+) start (\S+) load (\S+) .* (OK|DISCARD)', line)
    if m: rounds[int(m[1])] = m[4]; continue
    m = re.match(r'### r(\d+) (\S+) (\S+) ', line)
    if m: cur = (int(m[1]), m[2], m[3]); continue
    m = re.match(r'wall (\S+)s; (\S+) ms/partition/thread', line)
    if m and cur:
        r, c, b = cur
        runs.setdefault((c, b), {})[r] = (float(m[1]), float(m[2])); cur = None
good = sorted(r for r, v in rounds.items() if v == 'OK')
cases = []
for c, b in runs:
    if c not in cases: cases.append(c)
for c in cases:
    whole = 'e14' in c
    i = 0 if whole else 1
    unit = ' s' if whole else ' ms'
    bs, ps = runs.get((c, 'base'), {}), runs.get((c, 'pr'), {})
    rs = [r for r in good if r in bs and r in ps]
    a = [bs[r][i] for r in rs]; p = [ps[r][i] for r in rs]
    ma, mp = st.median(a), st.median(p)
    f = (lambda x: f'{x:.1f}') if whole else (lambda x: f'{x:.0f}')
    lab, th = LABEL[c]
    print(f"| {lab} | {th} | **{f(ma)}**{unit} ({', '.join(f(x) for x in a)}) | {100*(max(a)-min(a))/ma:.1f} % | **{f(mp)}**{unit} ({', '.join(f(x) for x in p)}) | {100*(max(p)-min(p))/mp:.1f} % | **×{ma/mp:.3f}** | {', '.join(f'{x/y:.3f}' for x, y in zip(a, p))} |")
