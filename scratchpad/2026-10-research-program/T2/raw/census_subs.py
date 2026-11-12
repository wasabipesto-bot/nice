#!/usr/bin/env python3
"""T2.3 census step 2 (read-only): every nice-only submission to a b58/b60 field, by bounded
submission-id ranges (100k ids per request, 0.2 s apart). Compact columns only.
usage: census_subs.py LO HI OUT"""
import json, sys, time, urllib.request, urllib.parse
API = "https://data.nicenumbers.net"
def get(path, tries=5):
    for k in range(tries):
        try:
            req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
            with urllib.request.urlopen(req, timeout=60) as r: return json.load(r)
        except Exception as e:
            print("retry", k, e, flush=True)
            if k == tries - 1: raise
            time.sleep(2 ** (k + 1))
lo, hi, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
sel = urllib.parse.quote("id,field_id,username,client_version,submit_time,disqualified,"
    "build:telemetry->>build_sha,gpu:telemetry->hardware->>gpu_model,backend:telemetry->hardware->>gpu_backend,"
    "route:telemetry->pipeline->>route,surv:telemetry->pipeline->join->>survivors,"
    "chk:telemetry->pipeline->join->>checked,valid:telemetry->pipeline->>valid_numbers,"
    "secs:telemetry->pipeline->join->>run_secs", safe=",:>-")
rows = []; t0 = time.time()
for a in range(lo, hi, 100000):
    r = get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&search_mode=eq.niceonly&field_id=gte.206808461&field_id=lte.207064109&select={sel}")
    rows += r
    if (a - lo) // 100000 % 20 == 0: print(a, len(rows), f"{time.time()-t0:.0f}s", flush=True)
    time.sleep(0.2)
# compact: list of lists
cols = ["id","field_id","username","client_version","submit_time","disqualified","build","gpu","backend","route","surv","chk","valid","secs"]
json.dump({"cols": cols, "rows": [[x.get(c) for c in cols] for x in rows]}, open(out, "w"), separators=(",", ":"))
print("done", len(rows), f"{time.time()-t0:.0f}s", flush=True)
