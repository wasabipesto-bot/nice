#!/usr/bin/env python3
"""Markdown rows from ab-runs.txt: per case, base and PR medians over the OK
rounds (ms per partition-thread for sampled partitions, wall seconds for
whole fields), spread = (max - min) / median, speed-up = base median / PR
median, per-round ratios, counts (and whether every run agrees), and loads."""
import re, os, sys, statistics as st
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rounds, runs, cur = {}, {}, None
for line in open(os.path.join(R, sys.argv[1] if len(sys.argv) > 1 else 'ab-runs.txt')):
    m = re.match(r'#### round (\d+) start (\S+) load (\S+) .* (OK|DISCARD)', line)
    if m: rounds[int(m[1])] = (m[2], float(m[3]), m[4]); continue
    m = re.match(r'### r(\d+) (\S+) (\S+) \S+ load (\S+)', line)
    if m: cur = (int(m[1]), m[2], m[3], float(m[4])); continue
    m = re.match(r'wall (\S+)s; (\S+) ms/partition/thread; survivors (\d+) checked (\d+) hits (\d+)', line)
    if m and cur:
        r, c, b, l = cur
        runs.setdefault((c, b), {})[r] = dict(wall=float(m[1]), ms=float(m[2]), s=int(m[3]), k=int(m[4]), h=int(m[5]), load=l)
        cur = None
good = sorted(r for r, v in rounds.items() if v[2] == 'OK')
print('rounds', rounds)
cases = []
for c, b in runs:
    if c not in cases: cases.append(c)
for c in cases:
    whole = 'e14' in c
    key = 'wall' if whole else 'ms'
    bs, ps = runs.get((c, 'base'), {}), runs.get((c, 'pr'), {})
    rs = [r for r in good if r in bs and r in ps]
    if not rs: continue
    a = [bs[r][key] for r in rs]; p = [ps[r][key] for r in rs]
    ma, mp = st.median(a), st.median(p)
    fmt = (lambda x: f'{x:.1f}') if whole else (lambda x: f'{x:.0f}')
    cnt = {(v['s'], v['k'], v['h']) for d in (bs, ps) for v in d.values()}
    cs = ', '.join(f'{s:,} / {k:,}' for s, k, h in cnt) + ('' if len(cnt) == 1 else ' DIFFER')
    loads = ', '.join(f"{bs[r]['load']:.2f}/{ps[r]['load']:.2f}" for r in rs)
    print(f"| {c} | {fmt(ma)} ({', '.join(fmt(x) for x in a)}) | {100*(max(a)-min(a))/ma:.1f} % | {fmt(mp)} ({', '.join(fmt(x) for x in p)}) | {100*(max(p)-min(p))/mp:.1f} % | **{ma/mp:.3f}** | {', '.join(f'{bs[r][key]/ps[r][key]:.3f}' for r in rs)} | {cs} | loads {loads} |")
