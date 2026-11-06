#!/usr/bin/env python3
"""Summarise ab-runs.txt and the NiceMark JSONs: medians per side, per-round
ratios (main time / PR time in the same round), spreads, count equality."""
import json, re, statistics as st, glob, os, sys
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rounds = {}   # round -> (load, flag)
runs = {}     # (case, bin) -> list of (round, ms, survivors, checked, wall)
cur = None
for line in open(os.path.join(R, 'ab-runs.txt')):
    m = re.match(r'#### round (\d+) start \S+ load (\S+) .* (OK|DISCARD)', line)
    if m:
        rounds[int(m[1])] = (float(m[2]), m[3]); continue
    m = re.match(r'### r(\d+) (\S+) (\S+) \S+ load (\S+)', line)
    if m:
        cur = (int(m[1]), m[2], m[3]); continue
    m = re.match(r'wall (\S+)s; (\S+) ms/partition/thread; survivors (\d+) checked (\d+) hits (\d+)', line)
    if m and cur:
        r, case, b = cur
        runs.setdefault((case, b), []).append((r, float(m[2]), int(m[3]), int(m[4]), float(m[1])))
        cur = None
good = {r for r, (l, f) in rounds.items() if f == 'OK'}
print('rounds:', {r: rounds[r] for r in sorted(rounds)})
cases = []
for (c, b) in runs:
    if c not in cases: cases.append(c)
print(f"{'case':14} {'main ms (rounds)':40} {'spr':>5} {'PR ms (rounds)':40} {'spr':>5} {'ratio':>6}  per round   counts")
for c in cases:
    m = {r: x for (r, *x) in runs.get((c, 'main'), []) if r in good}
    p = {r: x for (r, *x) in runs.get((c, 'pr'), []) if r in good}
    rs = sorted(set(m) & set(p))
    if not rs: continue
    mm = [m[r][0] for r in rs]; pp = [p[r][0] for r in rs]
    med_m, med_p = st.median(mm), st.median(pp)
    spr = lambda v, md: 100 * (max(v) - min(v)) / md
    per = [m[r][0] / p[r][0] for r in rs]
    same = all(m[r][1:3] == p[r][1:3] for r in rs) and len({(m[r][1], m[r][2]) for r in rs}) == 1
    cnt = f"{m[rs[0]][1]:,} / {m[rs[0]][2]:,}" + ('' if same else ' DIFFER')
    print(f"{c:14} {med_m:9.1f} ({', '.join(f'{x:.1f}' for x in mm)}){'':5} {spr(mm, med_m):4.1f}% {med_p:9.1f} ({', '.join(f'{x:.1f}' for x in pp)}){'':5} {spr(pp, med_p):4.1f}% x{med_m / med_p:.3f}  {', '.join(f'{x:.3f}' for x in per)}  {cnt}")
# NiceMark
nm = {}
for f in sorted(glob.glob(os.path.join(R, 'nicemark-r*-*.json'))):
    mm = re.search(r'nicemark-r(\d+)-(\w+)\.json', f)
    try:
        d = json.load(open(f))
    except Exception as e:
        print('bad', f, e); continue
    nm[(int(mm[1]), mm[2])] = d
loads = {}
p = os.path.join(R, 'nicemark-runs.txt')
if os.path.exists(p):
    for line in open(p):
        m = re.match(r'### r(\d+) (\w+) start \S+ load (\S+) .* (OK|DISCARD)', line)
        if m: loads[(int(m[1]), m[2])] = (float(m[3]), m[4])
if nm:
    print('\nNiceMark (loads:', loads, ')')
    rs = sorted({r for r, b in nm if (r, 'main') in nm and (r, 'pr') in nm and loads.get((r, 'main'), (0, 'OK'))[1] == 'OK' and loads.get((r, 'pr'), (0, 'OK'))[1] == 'OK'})
    keys = [s['key'] for s in nm[(rs[0], 'main')]['scenarios']] if rs else []
    def row(name, f):
        a = [f(nm[(r, 'main')]) for r in rs]; b = [f(nm[(r, 'pr')]) for r in rs]
        print(f"{name:18} main {st.median(a):.4g} ({', '.join(f'{x:.4g}' for x in a)})  PR {st.median(b):.4g} ({', '.join(f'{x:.4g}' for x in b)})  x{st.median(b) / st.median(a):.3f}  per round {', '.join(f'{y / x:.3f}' for x, y in zip(a, b))}")
    row('score', lambda d: d['score'])
    for k in keys:
        row(k, lambda d, k=k: next(s['rate'] for s in d['scenarios'] if s['key'] == k))
