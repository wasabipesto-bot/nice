#!/usr/bin/env python3
"""SRA census, step 0 (read-only, light): the newest submission id, and by bisection on the primary key the
first submission id on or after 2026-08-28 (the day v3.4.0, the first release with the CubeCL stride kernel,
was tagged). One row per request."""
import json, time, urllib.request, urllib.parse
API = "https://data.nicenumbers.net"
def get(path):
    req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
    with urllib.request.urlopen(req, timeout=60) as r: return json.load(r)
top = get("/submissions?select=id,submit_time&order=id.desc&limit=1")[0]
print("newest", top)
lo, hi = 1, top["id"]
target = "2026-08-28T00:00:00"
n = 0
while hi - lo > 1000:
    mid = (lo + hi) // 2
    r = get(f"/submissions?id=gte.{mid}&id=lt.{mid+100000}&select=id,submit_time&order=id.asc&limit=1")
    n += 1; time.sleep(0.2)
    if not r: hi = mid; continue
    if r[0]["submit_time"][:19] >= target: hi = mid
    else: lo = mid
print("first id on/after", target, "is about", hi, "after", n, "requests")
r = get(f"/submissions?id=gte.{hi}&id=lt.{hi+100000}&select=id,submit_time,search_mode,client_version&order=id.asc&limit=3")
print(r)
