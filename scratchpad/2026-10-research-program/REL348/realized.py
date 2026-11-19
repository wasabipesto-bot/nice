#!/usr/bin/env python3
"""Realized gain of v3.4.8 from production telemetry (read-only, light: primary-key ranges of 100k ids).
Per (user, card, client version): fields, join seconds per non-empty field (median), survivors per second, and
new fields per hour in the hours the client was submitting."""
import json, time, urllib.request, urllib.parse, collections, statistics as st, sys
API = "https://data.nicenumbers.net"
def get(path):
    req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
    with urllib.request.urlopen(req, timeout=120) as r: return json.load(r)
sel = urllib.parse.quote("id,field_id,username,client_version,submit_time,gpu:telemetry->hardware->>gpu_model,"
    "backend:telemetry->hardware->>gpu_backend,secs:telemetry->pipeline->join->>run_secs,"
    "surv:telemetry->pipeline->join->>survivors,chk:telemetry->pipeline->join->>checked", safe=",:>-")
lo, hi = int(sys.argv[1]), int(sys.argv[2]); rows = []
for a in range(lo, hi, 100000):
    rows += get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&search_mode=eq.niceonly&field_id=gte.207064110&select={sel}"); time.sleep(0.25)
json.dump(rows, open("subs.json", "w"))
print("rows", len(rows), rows[0]["submit_time"][:16] if rows else "", rows[-1]["submit_time"][:16] if rows else "")
seen = set(); grp = collections.defaultdict(list)
for x in sorted(rows, key=lambda r: r["id"]):
    new = x["field_id"] not in seen; seen.add(x["field_id"])
    grp[(x["username"], (x["gpu"] or "cpu")[:34], x["client_version"])].append((x, new))
print(f'{"user":18s} {"card":34s} {"ver":10s} {"n":>6s} {"dup%":>5s} {"med join s":>10s} {"Msurv/s":>8s} {"hours":>6s} {"new/h":>6s}')
for k, v in sorted(grp.items(), key=lambda kv: (kv[0][1], kv[0][2])):
    if len(v) < 20: continue
    secs = [float(x["secs"]) for x, _ in v if x["secs"] and float(x["secs"]) > 1 and x["surv"] and int(x["surv"]) > 0]
    rate = [int(x["surv"]) / float(x["secs"]) / 1e6 for x, _ in v if x["secs"] and float(x["secs"]) > 1 and x["surv"] and int(x["surv"]) > 0]
    hours = collections.Counter(x["submit_time"][:13] for x, _ in v)
    newc = sum(1 for _, n in v if n)
    print(f'{k[0][:18]:18s} {k[1]:34s} {k[2]:10s} {len(v):6d} {100*(1-newc/len(v)):5.1f} {st.median(secs) if secs else 0:10.1f} {st.median(rate) if rate else 0:8.1f} {len(hours):6d} {newc/max(len(hours),1):6.1f}')
