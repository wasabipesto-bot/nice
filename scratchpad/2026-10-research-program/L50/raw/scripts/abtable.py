#!/usr/bin/env python3
"""Medians of ms/partition-thread (or wall s for whole fields) per binary and
shape from ab-runs.txt; ratio against plain; survivor/checked counts."""
import re, sys, statistics, collections
path = sys.argv[1]
cur = None
data = collections.defaultdict(list)
counts = collections.defaultdict(set)
for line in open(path):
    m = re.match(r"### \S+ r(\d+) (\S+) (\S+ \S+) \[", line)
    if m:
        cur = (m.group(2), m.group(3), int(m.group(1)))
        continue
    m = re.match(r"wall ([\d.]+)s; ([\d.]+) ms/partition/thread; survivors (\d+) checked (\d+) hits (\d+)", line)
    if m and cur:
        binname, shape, rnd = cur
        val = float(m.group(1)) if 'e14' in shape else float(m.group(2))
        data[(shape, binname)].append((rnd, val))
        counts[shape].add((m.group(3), m.group(4), m.group(5)))
        cur = None
shapes = []
for (sh, b) in data:
    if sh not in shapes:
        shapes.append(sh)
bins = sys.argv[2].split(",") if len(sys.argv) > 2 else ["plain", "scan2", "check", "scan2check"]
print(f"{'shape':16} " + " ".join(f"{b:>22}" for b in bins) + "  counts")
for sh in shapes:
    base = data.get((sh, 'plain'))
    bmed = statistics.median(v for _, v in base) if base else None
    cells = []
    for b in bins:
        d = data.get((sh, b))
        if not d:
            cells.append(f"{'-':>22}")
            continue
        med = statistics.median(v for _, v in d)
        vals = ",".join(f"{v:.0f}" if v > 100 else f"{v:.1f}" for _, v in sorted(d))
        r = f"×{bmed/med:.3f}" if bmed else ""
        cells.append(f"{med:8.1f} {r:>7} ({vals})"[:22].rjust(22))
    print(f"{sh:16} " + " ".join(cells) + f"  {sorted(counts[sh])}")
# per-round ratios
print("\nper-round ratios vs plain:")
for sh in shapes:
    for b in bins[1:]:
        d = dict(data.get((sh, b), []))
        p = dict(data.get((sh, 'plain'), []))
        rs = [f"{p[r]/d[r]:.3f}" for r in sorted(d) if r in p]
        if rs:
            print(f"  {sh:16} {b:11} " + " ".join(rs))
