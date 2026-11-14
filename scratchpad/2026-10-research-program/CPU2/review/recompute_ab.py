# Reviewer's recomputation of the A/B ratios from the raw run logs.
# usage: python3 -I review/recompute_ab.py   (from CPU2/)
import re, statistics as st
for f, new in [("raw/ab3-runs.txt", "new3"), ("raw/ab2-runs.txt", "new2")]:
    d, counts, cur = {}, {}, None
    for line in open(f):
        m = re.match(r"### r(\d+) (\S+) (\S+)", line)
        if m:
            cur = (m.group(2), m.group(3)); continue
        m = re.match(r"AB .* secs ([\d.]+) survivors (\d+) checked (\d+) hits (.*)", line)
        if m and cur:
            d.setdefault(cur, []).append(float(m.group(1)))
            counts.setdefault(cur[0], set()).add(m.groups()[1:])
    print(f)
    for shape in sorted({k[0] for k in d}):
        n, o = d[(shape, new)], d[(shape, "old")]
        print(shape, len(n), len(o), "median x%.3f min x%.3f" % (st.median(o) / st.median(n), min(o) / min(n)),
              "per round", " ".join("%.3f" % (a / b) for a, b in zip(o, n)), "count sets", len(counts[shape]))
