#!/usr/bin/env python3
"""Read-only: every nice-only join submission of one username over an id range, with build and timing,
to measure what each deployed build did on that device (regression discontinuity at build switches)."""
import json, sys, time, urllib.request, urllib.parse
API="https://data.nicenumbers.net"
def get(path, tries=4):
    for k in range(tries):
        try:
            req=urllib.request.Request(API+path, headers={"User-Agent":"nice-audit-census"})
            with urllib.request.urlopen(req, timeout=40) as r: return json.load(r)
        except Exception:
            if k==tries-1: raise
            time.sleep(2**(k+1))
user, lo, hi, out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
sel=urllib.parse.quote("id,field_id,submit_time,client_version,build:telemetry->>build_sha,secs:telemetry->pipeline->join->>run_secs,setup:telemetry->pipeline->join->>setup_secs,surv:telemetry->pipeline->join->>survivors,chk:telemetry->pipeline->join->>checked,slices:telemetry->pipeline->join->>slices", safe=",:>-")
rows=[]; t0=time.time()
for a in range(lo, hi, 100000):
    rows+=get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&username=eq.{user}&search_mode=eq.niceonly&select={sel}")
    time.sleep(0.12)
json.dump(rows, open(out,"w")); print(user, len(rows), f"{time.time()-t0:.0f}s")
