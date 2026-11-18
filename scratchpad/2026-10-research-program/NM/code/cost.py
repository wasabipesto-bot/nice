#!/usr/bin/env python3
"""NM: raw/cost.txt (run_cost.sh): per case and arm, median seconds over rounds, ratio to
the unmodified join (paired by round), and whether every arm's counters are identical."""
import re, sys, statistics
from collections import defaultdict

cur = None
secs = defaultdict(dict)  # (case, arm) -> {round: secs}
counts = defaultdict(set)  # case -> {(surv, checked, hits)}
for line in open(sys.argv[1]):
    m = re.match(r"### r(\d+) (\S+) (\S+) ", line)
    if m:
        cur = (int(m[1]), m[2], m[3]); continue
    m = re.match(r"RUN .* secs ([\d.]+) survivors (\d+) checked (\d+) hits (\[[^\]]*\])", line)
    if m and cur:
        r, case, arm = cur
        secs[(case, arm)][r] = float(m[1])
        counts[case].add((m[2], m[3], m[4]))
cases = sorted({c for c, _ in secs})
for case in cases:
    base = secs[(case, "base")]
    print(f"{case}: counters identical across arms and rounds: {len(counts[case]) == 1} {sorted(counts[case])[:1]}")
    for arm in ("base", "nm0", "nm2", "nm3"):
        s = secs.get((case, arm), {})
        if not s: continue
        rs = sorted(set(s) & set(base))
        ratios = [s[r] / base[r] for r in rs]
        print(f"  {arm}: n={len(s)} median {statistics.median(s.values()):.3f}s; vs base per round "
              f"{', '.join(f'{x:.4f}' for x in ratios)}; median x{statistics.median(ratios):.4f}")
