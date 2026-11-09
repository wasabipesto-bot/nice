#!/usr/bin/env python3
"""Medians per case and binary from ab-variants.txt, the speed-up over the
base (1cce00d) and the PR's over each variant, with per-round values and the
counts (which must agree across binaries)."""
import re, os, statistics as st
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
runs, cur = {}, None
for line in open(os.path.join(R, 'ab-variants.txt')):
    m = re.match(r'### r(\d+) (\S+) (\S+) ', line)
    if m: cur = (int(m[1]), m[2], m[3]); continue
    m = re.match(r'wall \S+s; (\S+) ms/partition/thread; survivors (\d+) checked (\d+) hits (\d+)', line)
    if m and cur:
        r, c, b = cur
        runs.setdefault(c, {}).setdefault(b, {})[r] = (float(m[1]), (int(m[2]), int(m[3]), int(m[4])))
        cur = None
for c, d in runs.items():
    counts = {v[1] for b in d.values() for v in b.values()}
    print(f"{c}: counts {'agree' if len(counts) == 1 else 'DIFFER'} {sorted(counts)}")
    med = {b: st.median(v[0] for v in d[b].values()) for b in d}
    for b in ['base', 'pr', 'notop', 'v3']:
        if b not in d: continue
        rs = sorted(d[b])
        print(f"| {c} | {b} | {med[b]:.0f} ({', '.join(f'{d[b][r][0]:.0f}' for r in rs)}) | x{med['base']/med[b]:.3f} over base | PR x{med[b]/med['pr']:.3f} over it |")
