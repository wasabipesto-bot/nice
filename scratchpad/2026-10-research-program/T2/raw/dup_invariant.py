#!/usr/bin/env python3
"""T2.3: for builds before #236 the two counters are timing dependent: a survivor that overruns the stage
leaves `survivors` and is fully checked unfiltered, so I = survivors + checked/(1 - pass) is the
quantity a lossless run preserves (pass = checked/survivors of the field, taken from the pair itself).
For every pair of same-build submissions of one field: r = (I_a - I_b) / survivors. Lost candidates show as a
one-sided deficit; overrun churn as noise around 0."""
import json, collections, statistics
from census_cells import S, F, family
def I(s, p): return int(s["surv"]) + int(s["chk"]) / (1 - p)
by = collections.defaultdict(list)
for s in S:
    if s["build"] and s["surv"] not in (None, "0"): by[(s["field_id"], s["build"][:8])].append(s)
grp = collections.defaultdict(list)
for (fid, b), v in by.items():
    for i in range(len(v)):
        for j in range(i + 1, len(v)):
            a, c = v[i], v[j]
            p = (int(a["chk"]) + int(c["chk"])) / (int(a["surv"]) + int(c["surv"]))
            r = (I(a, p) - I(c, p)) / int(a["surv"])
            dq = a["disqualified"] or c["disqualified"]
            key = (F[fid]["base_id"], b, "M4-DQ involved" if dq else "qualified pair")
            exact = a["surv"] == c["surv"] and a["chk"] == c["chk"]
            grp[key].append((abs(r), exact, r, family(a), family(c), fid))
for k in sorted(grp):
    v = grp[k]; ab = sorted(x[0] for x in v)
    q = lambda f: ab[min(len(ab) - 1, int(f * len(ab)))]
    print(k, f"pairs {len(v)} exact {sum(x[1] for x in v)} |r| median {q(.5):.1e} p99 {q(.99):.1e} max {ab[-1]:.1e}  >3e-6: {sum(1 for x in ab if x > 3e-6)}")
    for x in sorted(v, reverse=True)[:3]:
        if x[0] > 3e-6: print("     ", f"r={x[2]:+.2e}", x[3], "vs", x[4], "field", x[5])
