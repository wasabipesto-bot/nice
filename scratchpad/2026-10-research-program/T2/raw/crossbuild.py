#!/usr/bin/env python3
"""T2.3: counter ratios between different builds on the same field (qualified census pairs)."""
import collections
from census_cells import S, F
by = collections.defaultdict(list)
for s in S:
    if s["build"] and s["surv"] not in (None, "0") and not s["disqualified"]: by[s["field_id"]].append(s)
st = collections.defaultdict(list)
for fid, v in by.items():
    for i in range(len(v)):
        for j in range(i + 1, len(v)):
            a, c = v[i], v[j]; ba, bc = a["build"][:8], c["build"][:8]
            if ba == bc: continue
            if ba > bc: a, c, ba, bc = c, a, bc, ba
            st[(F[fid]["base_id"], ba, bc)].append((int(a["surv"]) / int(c["surv"]), int(a["chk"]) / int(c["chk"])))
for k, v in sorted(st.items()):
    rs = sorted(x[0] for x in v); rc = sorted(x[1] for x in v)
    print(k, len(v), f"surv ratio median {rs[len(rs)//2]:.6f} [{rs[0]:.6f},{rs[-1]:.6f}]  chk ratio median {rc[len(rc)//2]:.6f} [{rc[0]:.6f},{rc[-1]:.6f}]")
