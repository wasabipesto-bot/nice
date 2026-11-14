#!/usr/bin/env python3
"""Markdown rows for the NiceMark rounds: medians per side, per-round ratios
(branch / main; adapted from L52), and a count check: runs of one scenario that sampled the same
number of partitions (the same bit-reversed prefix) must agree on join
survivors and full checks."""
import json, glob, os, re, statistics as st
import sys
R = sys.argv[1]
nm = {}
for f in sorted(glob.glob(os.path.join(R, 'nicemark-r*-*.json'))):
    m = re.search(r'nicemark-r(\d+)-(\w+)\.json', f)
    try:
        nm[(int(m[1]), m[2])] = json.load(open(f))
    except ValueError:
        print("incomplete:", f)
rs = sorted({r for r, _ in nm if (r, 'main') in nm and (r, 'br') in nm})
def row(name, f, fmt):
    a = [f(nm[(r, 'main')]) for r in rs]; b = [f(nm[(r, 'br')]) for r in rs]
    print(f"| {name} | {fmt(st.median(a))} ({', '.join(fmt(x) for x in a)}) | {fmt(st.median(b))} ({', '.join(fmt(x) for x in b)}) | **×{st.median(b) / st.median(a):.3f}** | {', '.join(f'{y / x:.3f}' for x, y in zip(a, b))} |")
row('score', lambda d: d['score'], lambda x: f'{x:.1f}')
keys = [s['key'] for s in nm[(rs[0], 'main')]['scenarios']]
for k in keys:
    row(k, lambda d, k=k: next(s['rate'] for s in d['scenarios'] if s['key'] == k), lambda x: f'{x:.4g}')
print()
for k in keys:
    seen = {}
    for (r, b), d in sorted(nm.items()):
        s = next(s for s in d['scenarios'] if s['key'] == k)
        j = s.get('join') or {}
        seen.setdefault((j.get('sampled'), j.get('partitions')), set()).add((j.get('survivors'), j.get('checked'), j.get('hits'), b))
    for (smp, parts), v in sorted(seen.items(), key=lambda x: str(x)):
        counts = {(s, c, h) for s, c, h, _ in v}
        sides = sorted({b for *_, b in v})
        print(f"{k}: sampled {smp}/{parts}: {len(v)} runs ({', '.join(sides)}), counts {'AGREE' if len(counts) == 1 else 'DIFFER'} {sorted(counts)}")
