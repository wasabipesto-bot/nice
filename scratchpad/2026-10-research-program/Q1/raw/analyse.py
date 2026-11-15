#!/usr/bin/env python3
"""Reconstruct the nice-only queue's refills at base 62 and classify every re-issued field."""
import json, collections, statistics
from datetime import datetime, timezone
T = lambda s: datetime.fromisoformat(s).astimezone(timezone.utc)
fields = {r["id"]: r for r in json.load(open("fields_207060000_207090000.json")) if r["base_id"] == 62}
claims = [c for c in json.load(open("claims_207064110_207073600.json")) if c["search_mode"] == "niceonly"]
subs = [s for s in json.load(open("submissions_207064110_207073600.json")) if s["search_mode"] == "niceonly"]
tel = {t["id"]: t for t in json.load(open("../b62_niceonly_submissions_to_0929utc.json"))}
CUT = datetime(2026, 11, 15, 9, 29, tzinfo=timezone.utc)
subs = [s for s in subs if T(s["submit_time"]) <= CUT]
for s in subs:
    t = tel.get(s["id"]); s["run"] = float(t["run"]) if t and t["run"] else None
claims_by_field = collections.defaultdict(list)
for c in claims: claims_by_field[c["field_id"]].append(c)
subs_by_claim = {s["claim_id"]: s for s in subs}
subs_by_field = collections.defaultdict(list)
for s in subs: subs_by_field[s["field_id"]].append(s)

# Refill batches: fields sharing one last_claim_time stamp (only the latest stamp survives).
batches = collections.defaultdict(list)
for f in fields.values():
    if f["last_claim_time"]: batches[f["last_claim_time"]].append(f["id"])
print("stamps with >=20 fields (refills), as of fetch:")
bl = sorted((T(k), sorted(v)) for k, v in batches.items() if len(v) >= 20)
for t, ids in bl: print(f"  {t:%H:%M:%S} n={len(ids):3d} ids {ids[0]}..{ids[-1]}")

real = [s for s in subs if s["run"] is not None and s["run"] > 1]
rf = collections.Counter(s["field_id"] for s in real)
dup = [f for f, n in rf.items() if n >= 2]
print(f"\nreal submissions {len(real)}, distinct fields {len(rf)}, fields searched twice {len(dup)}")
print("submissions without telemetry:", sum(1 for s in subs if s['id'] not in tel))
multi = {f: cs for f, cs in claims_by_field.items() if len(cs) >= 2}
print("fields with >=2 nice-only claims (any, to fetch time):", len(multi), collections.Counter(len(c) for c in multi.values()))
out = []
for f in sorted(multi):
    cs = sorted(multi[f], key=lambda c: c["id"])
    ss = sorted(subs_by_field.get(f, []), key=lambda s: s["submit_time"])
    rows = []
    for c in cs:
        s = subs_by_claim.get(c["id"])
        rows.append(dict(claim=c["id"], claim_time=T(c["claim_time"]), sub_time=T(s["submit_time"]) if s else None,
                         user=s["username"] if s else None, run=s["run"] if s else None))
    out.append(dict(field=f, lct=T(fields[f]["last_claim_time"]), cl=fields[f]["check_level"], claims=rows))
# Classify: the field's first hand-out (claim 1) and second (claim 2). Was claim 2 handed out after the
# first submission (=> the field was queued twice and the first copy was submitted while the second sat queued),
# or before it (=> re-claimed after hand-out but before submission, both copies live)?
cls = collections.Counter(); gaps = []
for o in out:
    a, b = o["claims"][0], o["claims"][1]
    if a["sub_time"] is None: k = "first copy never submitted (to 09:29)"
    elif b["claim_time"] >= a["sub_time"]: k = "2nd hand-out after 1st submit"
    else: k = "2nd hand-out before 1st submit"
    cls[k] += 1
    gaps.append((b["claim_time"] - a["claim_time"]).total_seconds() / 60)
    o["kind"] = k
print(cls)
q = statistics.quantiles(gaps, n=10); print(f"hand-out gap minutes: p10 {q[0]:.1f} median {statistics.median(gaps):.1f} p90 {q[-1]:.1f}")
json.dump(out, open("refissued_fields.json", "w"), default=str, indent=1)
