#!/usr/bin/env python3
"""Fetch fields rows for an id range from the public API, read-only, lightly."""
import json, sys, time, urllib.request
lo, hi, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
assert hi - lo <= 100_000
rows, start = [], lo
while start <= hi:
    url = (f"https://data.nicenumbers.net/fields?select=id,base_id,chunk_id,range_size,last_claim_time,canon_submission_id,check_level"
           f"&id=gte.{start}&id=lte.{hi}&order=id.asc&limit=5000")
    req = urllib.request.Request(url, headers={"User-Agent": "nice-audit-census"})
    page = json.load(urllib.request.urlopen(req, timeout=60))
    rows += page
    if len(page) < 5000:
        break
    start = page[-1]["id"] + 1
    time.sleep(0.15)
json.dump(rows, open(out, "w"))
print(len(rows), rows[0]["id"], rows[-1]["id"])
