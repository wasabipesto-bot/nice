#!/usr/bin/env python3
"""Split re-issued base-62 fields by route: re-claimed while queued vs after hand-out, before submission."""
import json, collections, statistics
from datetime import datetime, timezone
T = lambda s: datetime.fromisoformat(s) if s and s != "None" else None
out = json.load(open("refissued_fields.json"))
refills = sorted({T(o["lct"]) for o in out})
cnt = collections.Counter(); realcnt = collections.Counter(); ages = []; ages2 = []
pos = []
for o in out:
    R2 = T(o["lct"]); a, b = o["claims"][0], o["claims"][1]
    c1, s1, c2 = T(a["claim_time"]), T(a["sub_time"]), T(b["claim_time"])
    if R2 <= c1: route = "A re-claimed while still queued"
    elif s1 is None or R2 < s1: route = "B re-claimed after hand-out, before submission"
    else: route = "?"
    real = (a["run"] or 0) > 1 and (b["run"] or 0) > 1
    o["route"] = route; cnt[route] += 1
    if real: realcnt[route] += 1
    # age of the first copy at hand-out: c1 - R1, R1 = latest refill stamp before c1 among all refill times
    ages2.append((c2 - R2).total_seconds() / 60)
print("all re-issued fields:", dict(cnt)); print("both searches real:", dict(realcnt))
print("second copy: minutes from its refill to its hand-out: median %.1f p10 %.1f p90 %.1f" % (
    statistics.median(ages2), *[statistics.quantiles(ages2, n=10)[i] for i in (0, -1)]))
by_refill = collections.Counter(o["lct"] for o in out)
for k, v in sorted(by_refill.items()): print("  re-claimed by refill", k, v)
json.dump(out, open("refissued_fields.json", "w"), default=str, indent=1)
