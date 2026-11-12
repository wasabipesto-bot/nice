#!/usr/bin/env python3
"""T2.3 free cross-check from the census: fields with two or more nice-only submissions of the SAME build
(any devices, qualified or disqualified): do survivors/checked agree?"""
import json, collections
from census_cells import S, F, family
by = collections.defaultdict(list)
for s in S:
    if s["build"] and s["surv"] is not None: by[(s["field_id"], s["build"][:8])].append(s)
res = collections.Counter(); ex = []
for (fid, b), v in by.items():
    if len(v) < 2: continue
    for i in range(len(v)):
        for j in range(i + 1, len(v)):
            a, c = v[i], v[j]
            same = a["surv"] == c["surv"] and a["chk"] == c["chk"]
            key = (F[fid]["base_id"], b, " vs ".join(sorted([family(a) + ("[DQ]" if a["disqualified"] else ""), family(c) + ("[DQ]" if c["disqualified"] else "")])), same)
            res[key] += 1
            if not same and len(ex) < 40 and not (a["disqualified"] or c["disqualified"]): ex.append((fid, b, family(a), a["surv"], a["chk"], family(c), c["surv"], c["chk"]))
for k, v in sorted(res.items()): print(k, v)
print("qualified-vs-qualified disagreements (first 40):")
for e in ex: print(e)
