#!/usr/bin/env python3
"""Census of nice-only join submissions from Apple GPUs (read-only, public API).
Pass 1: scan the submissions table by primary-key ranges with a telemetry filter.
Pass 2: for every field such a submission touched, fetch all its submissions and the field row.
Output: census_apple.json (+ summary printed by census_summary.py)."""
import json, sys, time, urllib.request, urllib.parse
API = "https://data.nicenumbers.net"
def get(path, timeout=40, tries=4):
    for k in range(tries):
        try:
            req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.load(r)
        except Exception as e:
            if k == tries - 1: raise
            time.sleep(2 ** (k + 1))
def main():
    lo, hi, step = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
    sel = "id,field_id,search_mode,client_version,submit_time,username,disqualified,build:telemetry->>build_sha,gpu:telemetry->hardware->>gpu_model,route:telemetry->pipeline->>route"
    flt = urllib.parse.quote("telemetry->hardware->>gpu_model") + "=like.*Apple*"
    apple = []
    t0 = time.time()
    for a in range(lo, hi, step):
        rows = get(f"/submissions?id=gte.{a}&id=lt.{a+step}&{flt}&select={urllib.parse.quote(sel, safe=',:>-')}")
        apple += rows
        if (a - lo) // step % 25 == 0:
            print(f"scan {a}: {len(apple)} apple rows, {time.time()-t0:.0f}s", flush=True)
        time.sleep(0.12)
    json.dump({"apple": apple}, open("census_apple.json", "w"))
    fids = sorted({r["field_id"] for r in apple if r["search_mode"] == "niceonly"})
    print("apple rows", len(apple), "niceonly fields", len(fids), flush=True)
    fields, subs = [], []
    sel2 = "id,field_id,search_mode,client_version,submit_time,username,disqualified,build:telemetry->>build_sha,gpu:telemetry->hardware->>gpu_model,route:telemetry->pipeline->>route"
    for i in range(0, len(fids), 80):
        chunk = ",".join(map(str, fids[i:i + 80]))
        fields += get(f"/fields?id=in.({chunk})&select=id,base_id,range_start,range_size,check_level")
        subs += get(f"/submissions?field_id=in.({chunk})&select={urllib.parse.quote(sel2, safe=',:>-')}")
        if i // 80 % 25 == 0:
            print(f"fields {i}/{len(fids)} {time.time()-t0:.0f}s", flush=True)
        time.sleep(0.12)
    json.dump({"apple": apple, "fields": fields, "subs": subs}, open("census_apple.json", "w"))
    print("done", len(fields), len(subs), f"{time.time()-t0:.0f}s", flush=True)
main()
