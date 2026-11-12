#!/usr/bin/env python3
"""T2.3: the own-build invariant rule applied to every census pair of same-build qualified submissions of a field
(builds with timing-dependent counters). r = (I_a - I_b)/T with p = chk_b/surv_b; tolerance
tol = 3e-7 + 0.06 p |surv_a - surv_b| / T (the overrun survivors' own pass rate q differs from p by a few
per cent field to field: census q/p p10-p90 0.973-1.005 at 9a4f7406). Lists every pair beyond tol."""
import json, collections
from census_cells import S, F, family
def rule(sa, ca, sb, cb):
    p = cb / sb; r = ((sa + ca / (1 - p)) - (sb + cb / (1 - p))) / sb
    tol = 3e-7 + 0.06 * p * abs(sa - sb) / sb
    return r, tol
if __name__ == "__main__":
    by = collections.defaultdict(list)
    for s in S:
        if s["build"] and s["surv"] not in (None, "0") and not s["disqualified"]: by[(s["field_id"], s["build"][:8])].append(s)
    n = collections.Counter(); flagged = []
    for (fid, b), v in by.items():
        if b in ("6f060a94", "c0c357ae"): continue
        for i in range(len(v)):
            for j in range(i + 1, len(v)):
                a, c = v[i], v[j]
                r, tol = rule(int(a["surv"]), int(a["chk"]), int(c["surv"]), int(c["chk"]))
                n[(F[fid]["base_id"], b)] += 1
                if abs(r) > tol: flagged.append((F[fid]["base_id"], b, fid, f"r={r:+.2e} tol={tol:.1e}", a["id"], family(a), a["username"], a["surv"], a["chk"], a["submit_time"][:16], c["id"], family(c), c["username"], c["surv"], c["chk"], c["submit_time"][:16]))
    print("pairs per (base, build):", dict(n))
    print("flagged:", len(flagged))
    for f in flagged: print(f)
