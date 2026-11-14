#!/usr/bin/env python3
"""Tables from ab-runs.txt: per case and binary every round's seconds, min,
median, spread (max/min - 1), and new/old speed-ups (median, min, per round);
checks the counts agree across binaries and rounds."""
import re, sys, statistics as st
from collections import defaultdict
runs = defaultdict(lambda: defaultdict(dict)); counts = defaultdict(set); flags = {}
cur = None
for line in open(sys.argv[1]):
    m = re.match(r'#### round (\d+) .* (OK|HIGHLOAD)', line)
    if m: flags[int(m.group(1))] = m.group(2)
    m = re.match(r'### r(\d+) (\S+) (\S+)', line)
    if m: cur = (int(m.group(1)), m.group(2), m.group(3)); continue
    m = re.match(r'AB .* secs ([\d.]+) survivors (\d+) checked (\d+) hits (.*)', line)
    if m and cur:
        r, case, b = cur
        runs[case][b][r] = float(m.group(1))
        counts[case].add((m.group(2), m.group(3), m.group(4).strip()))
print('round flags:', flags)
for case in runs:
    print(f'== {case}: counts {"IDENTICAL" if len(counts[case]) == 1 else "DIFFER"} {sorted(counts[case])}')
    bins = list(runs[case])
    for b in bins:
        v = runs[case][b]; xs = [v[r] for r in sorted(v)]
        print(f'  {b:6s} rounds {" ".join(f"{x:.2f}" for x in xs)} | min {min(xs):.2f} median {st.median(xs):.2f} spread {100*(max(xs)/min(xs)-1):.1f} %')
    base = runs[case].get('old')
    for b in bins:
        if b == 'old' or not base: continue
        v = runs[case][b]; rs = sorted(set(v) & set(base))
        per = [base[r] / v[r] for r in rs]
        print(f'  {b} vs old: x{st.median([base[r] for r in rs]) / st.median([v[r] for r in rs]):.3f} (medians), x{min(base[r] for r in rs) / min(v[r] for r in rs):.3f} (minimums); per round {" ".join(f"{x:.3f}" for x in per)} (range {min(per):.3f}-{max(per):.3f})')
    if 'new' in runs[case] and 'old12' in runs[case]:
        a = runs[case]['old12']; n = runs[case]['new']
        print(f'  new vs old12 (the skip alone): x{st.median(a.values()) / st.median(n.values()):.3f} (medians)')
