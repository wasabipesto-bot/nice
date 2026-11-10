#!/usr/bin/env python3
"""Cross-check for the disqualification list: every nice-only submission by the M4's username in the
join era (id-range scans), with or without telemetry, joined to its field's base."""
import json, sys, time, urllib.request, urllib.parse
API = "https://data.nicenumbers.net"
def get(path, timeout=40, tries=4):
    for k in range(tries):
        try:
            req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
            with urllib.request.urlopen(req, timeout=timeout) as r: return json.load(r)
        except Exception:
            if k == tries - 1: raise
            time.sleep(2 ** (k + 1))
lo, hi, step = int(sys.argv[1]), int(sys.argv[2]), 100000
sel = urllib.parse.quote("id,field_id,client_version,submit_time,disqualified,build:telemetry->>build_sha,gpu:telemetry->hardware->>gpu_model,route:telemetry->pipeline->>route", safe=",:>-")
rows = []; t0 = time.time()
for a in range(lo, hi, step):
    rows += get(f"/submissions?id=gte.{a}&id=lt.{a+step}&username=eq.mayalaran&search_mode=eq.niceonly&select={sel}")
    time.sleep(0.1)
print("mayalaran niceonly rows", len(rows), f"{time.time()-t0:.0f}s", flush=True)
fids = sorted({r["field_id"] for r in rows}); base = {}
for i in range(0, len(fids), 150):
    for f in get("/fields?id=in.(%s)&select=id,base_id,range_size,check_level" % ",".join(map(str, fids[i:i+150]))): base[f["id"]] = f
    time.sleep(0.1)
for r in rows: r["base"] = base[r["field_id"]]["base_id"]; r["check_level"] = base[r["field_id"]]["check_level"]
json.dump(rows, open("verify_m4_rows.json", "w"))
print("done", f"{time.time()-t0:.0f}s", flush=True)
