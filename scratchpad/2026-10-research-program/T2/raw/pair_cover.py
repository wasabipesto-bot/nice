#!/usr/bin/env python3
"""T2.3: per cell, how many of its submissions have an independent same-build second submission of the same field
(qualified, any device), and how many such pairs disagree (exact rule for 6f060a94/c0c357ae, dup_rule.py's
invariant rule otherwise). Not a random sample: these are mostly re-issued or re-searched fields."""
import json, collections
from census_cells import S, F, cellkey
from dup_rule import rule
by = collections.defaultdict(list)
for s in S:
    if s["build"] and s["surv"] not in (None, "0") and not s["disqualified"]: by[(s["field_id"], s["build"][:8])].append(s)
cov = collections.Counter(); bad = collections.Counter()
for (fid, b), v in by.items():
    if len(v) < 2: continue
    for a in v:
        k = (F[fid]["base_id"],) + cellkey(a)[:2]
        agree = True
        for c in v:
            if c is a: continue
            if b in ("6f060a94", "c0c357ae"): ok = a["surv"] == c["surv"] and a["chk"] == c["chk"]
            else:
                r, tol = rule(int(a["surv"]), int(a["chk"]), int(c["surv"]), int(c["chk"])); ok = abs(r) <= tol
            agree &= ok
        cov[k] += 1; bad[k] += (not agree)
for k in sorted(cov, key=lambda k: (k[0], -cov[k])): print(k, "subs with a same-build partner:", cov[k], "disagreeing:", bad[k])
