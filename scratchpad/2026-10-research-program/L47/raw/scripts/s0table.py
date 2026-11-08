#!/usr/bin/env python3
"""L47 step 0 table: check s per field by mode and field, per round and mean, from prof.py's parse."""
import subprocess, sys, re, collections, statistics as st
D = sys.argv[1]
out = subprocess.run([sys.executable, __file__.replace('s0table.py', 'prof.py'), D, sys.argv[2] if len(sys.argv) > 2 else 's0_'], capture_output=True, text=True).stdout
rows = collections.defaultdict(list)
for l in out.splitlines():
    m = re.match(r'(\S+?)_(F|G)(\d+)_(e1\d_b\d+)_r(\d)\s+check=\s*([0-9.]+)\s+join=\s*([0-9.]+)\s+device=\s*([0-9.]+)\s+MHz=\s*([0-9.]+)', l)
    if not m: continue
    rows[(m.group(4), m.group(2) + m.group(3))].append((int(m.group(5)), float(m.group(6)), float(m.group(8)), float(m.group(9))))
for k in sorted(rows):
    v = sorted(rows[k])
    print(f'{k[0]} {k[1]:6s} check rounds {[x[1] for x in v]} mean {st.mean(x[1] for x in v):.3f}  device {st.mean(x[2] for x in v):.2f}  MHz {st.mean(x[3] for x in v):.0f}')
