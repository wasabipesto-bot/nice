#!/usr/bin/env python3
"""T2.8 census (ivory only, read-only): base-62 fields by id ranges of 10k ids, and nice-only submissions
with id > LO by id ranges of 100k ids; 0.2 s apart; User-Agent nice-audit-census.
usage: census.py fields OUT | census.py subs LO OUT"""
import json, sys, time, urllib.request, urllib.parse
API = "https://data.nicenumbers.net"
def get(path, tries=5):
    for k in range(tries):
        try:
            req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
            with urllib.request.urlopen(req, timeout=120) as r: return json.load(r)
        except Exception as e:
            print("retry", k, e, flush=True)
            if k == tries - 1: raise
            time.sleep(2 ** (k + 1))
mode = sys.argv[1]
if mode == "fields":
    out = sys.argv[2]; rows = []
    for a in range(207064110, 207159540, 10000):
        rows += get(f"/fields?id=gte.{a}&id=lt.{min(a+10000,207159540)}&select=id,base_id,range_start,range_end,range_size,check_level,last_claim_time,canon_submission_id&order=id")
        time.sleep(0.2)
    json.dump(rows, open(out, "w"), separators=(",", ":")); print("fields", len(rows))
elif mode == "b60tail":
    out = sys.argv[2]
    rows = get("/fields?id=gte.207054110&id=lt.207064110&select=id,base_id,range_start,range_end,check_level,last_claim_time,canon_submission_id&order=id")
    json.dump(rows, open(out, "w"), separators=(",", ":")); print("b60tail", len(rows))
else:
    lo, out = int(sys.argv[2]), sys.argv[3]
    sel = urllib.parse.quote("id,field_id,submit_time,elapsed_secs,username,client_version,disqualified,numbers,"
        "build:telemetry->>build_sha,gpu:telemetry->hardware->>gpu_model,backend:telemetry->hardware->>gpu_backend,"
        "route:telemetry->pipeline->>route,valid:telemetry->pipeline->>valid_numbers,total:telemetry->pipeline->>total_secs,"
        "launches:telemetry->pipeline->>launches,msd_secs:telemetry->pipeline->>msd_secs,"
        "join:telemetry->pipeline->join", safe=",:>-")
    rows = []; a = lo
    while True:
        r = get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&search_mode=eq.niceonly&field_id=gte.207054110&select={sel}&order=id")
        rows += r; print(a, len(r), flush=True); time.sleep(0.2)
        if not r: break
        a += 100000
    json.dump(rows, open(out, "w"), separators=(",", ":")); print("subs", len(rows))
