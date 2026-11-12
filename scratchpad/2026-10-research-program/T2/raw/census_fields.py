#!/usr/bin/env python3
"""T2.3 census step 1 (read-only, public API, bounded id ranges): field rows of bases 58 and 60."""
import json, time, urllib.request
API = "https://data.nicenumbers.net"
def get(path, tries=4):
    for k in range(tries):
        try:
            req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
            with urllib.request.urlopen(req, timeout=60) as r: return json.load(r)
        except Exception:
            if k == tries - 1: raise
            time.sleep(2 ** (k + 1))
out = []
# b58 ends just below b60's first id 206902034; b60 ends at 207064109 (brief). Scan 206700000..207100000.
for a in range(206700000, 207100000, 100000):
    rows = get(f"/fields?id=gte.{a}&id=lt.{a+100000}&base_id=in.(58,60)&select=id,base_id,range_start,range_size,check_level,canon_submission_id")
    out += rows; print(a, len(rows), flush=True); time.sleep(0.2)
json.dump(out, open("fields_b58_b60.json", "w"), separators=(",", ":"))
import collections
for b in (58, 60):
    ids = [r["id"] for r in out if r["base_id"] == b]
    print(b, len(ids), min(ids), max(ids), collections.Counter(r["check_level"] for r in out if r["base_id"] == b), sum(int(r["range_size"]) for r in out if r["base_id"] == b))
