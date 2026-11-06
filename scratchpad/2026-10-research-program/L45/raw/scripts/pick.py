#!/usr/bin/env python3
"""L45: from ptxjit.py output, for one field tag, print '<spill run> <nospill run>' among runs matching PATTERNS
(the field's join kernel = the last join entry of each run's cache); '-' where none.  python3 pick.py JIT FIELD PATTERN..."""
import re, sys
jit, fld, pats = sys.argv[1], sys.argv[2], sys.argv[3:]
last = {}
for line in open(jit):
    m = re.search(r'/ptx/([^/]+)/ #(\d+) (.*?) ptx=.*?stl=(\d+)', line)
    if m and 'join' in m.group(3) and fld in m.group(1) and any(re.search(p, m.group(1)) for p in pats):
        i = int(m.group(2))
        if m.group(1) not in last or last[m.group(1)][0] < i:
            last[m.group(1)] = (i, int(m.group(4)))
sp = [k for k, v in sorted(last.items()) if v[1] > 0]; ns = [k for k, v in sorted(last.items()) if v[1] == 0]
print(sp[0] if sp else '-', ns[0] if ns else '-', f'# spill {len(sp)} nospill {len(ns)}', file=sys.stdout)
