#!/usr/bin/env python3
"""Repeat-run consistency of the GPU join from public telemetry (read-only, pk / field_id lookups).
For fields with >= 2 qualified submissions, compare accounted AND survivors:
  accounted = survivors + (checked - C)/(1 - pass)   (the stage overrun moves a survivor from
  `survivors` to `checked`), so for two runs of one field
  R = d(survivors) + d(checked)/(1 - pass)  should be ~0 unless survivors were lost or miscounted.
"""
import json, sys, urllib.request, random, collections, time, subprocess
API = "https://data.nicenumbers.net"
def get(path, timeout=20):
    req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-sample"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.load(r)
def main():
    lo, hi, n, seed, out = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
    rng = random.Random(seed)
    ids = sorted(rng.sample(range(lo, hi + 1), n))
    fields = []
    for i in range(0, len(ids), 150):
        fields += get("/fields?id=in.(%s)&select=id,base_id,range_start,range_size,check_level" % ",".join(map(str, ids[i:i + 150])))
        time.sleep(0.2)
    done = [f["id"] for f in fields if f["check_level"] >= 1]
    subs = []
    for i in range(0, len(done), 60):
        subs += get("/submissions?field_id=in.(%s)&select=id,field_id,search_mode,submit_time,client_version,disqualified,username,telemetry" % ",".join(map(str, done[i:i + 60])))
        time.sleep(0.2)
    json.dump({"fields": fields, "subs": subs}, open(out, "w"))
    print("fields", len(fields), "searched", len(done), "submissions", len(subs))
main()
