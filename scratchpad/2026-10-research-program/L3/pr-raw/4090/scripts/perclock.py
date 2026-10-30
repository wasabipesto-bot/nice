#!/usr/bin/env python3
"""Per-round NiceMark rates with the median SM clock/power from dmon (first half of each run =
b40_detailed, second half = b50_detailed; samples with sm >= 90 %). usage: perclock.py NMDIR"""
import re, sys, os, statistics as st
d = sys.argv[1]
rows = []
for l in open(os.path.join(d, 'dmon.log')):
    if l.startswith('#'):
        continue
    f = l.split()
    if len(f) < 13 or not f[2].isdigit():
        continue
    rows.append((f[0], int(f[2]), int(f[3]), int(f[5]), int(f[12])))
iv, s = {}, {}
for l in open(os.path.join(d, 'times.log')):
    t, k, r, tree = l.split()
    if k == 'start':
        s[(r, tree)] = t
    else:
        iv[(r, tree)] = (s[(r, tree)], t)
for (r, tree), (a, b) in sorted(iv.items(), key=lambda x: x[1][0]):
    sel = [x for x in rows if a < x[0] <= b and x[3] >= 90]
    log = open(os.path.join(d, f'{r}_{tree}.log')).read()
    m40 = float(re.search(r'b40_detailed.*?(\S+)\s+-\n', log).group(1))
    m50 = float(re.search(r'b50_detailed.*?(\S+)\s+-\n', log).group(1))
    n = len(sel)
    h1, h2 = sel[:n // 2], sel[n // 2:]
    pc1, pc2 = st.median(x[4] for x in h1), st.median(x[4] for x in h2)
    print(f"{a} {r} {tree:5} b40 {m40:.3e} @ {pc1:.0f} MHz {st.median(x[1] for x in h1):.0f} W | "
          f"b50 {m50:.3e} @ {pc2:.0f} MHz {st.median(x[1] for x in h2):.0f} W | temp {st.median(x[2] for x in sel):.0f} C | "
          f"per GHz b40 {m40 / pc1 * 1e3:.3e} b50 {m50 / pc2 * 1e3:.3e}")
