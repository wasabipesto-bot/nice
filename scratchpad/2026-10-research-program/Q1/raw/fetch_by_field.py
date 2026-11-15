#!/usr/bin/env python3
"""Fetch claims and submissions for a field-id list from the public API (indexed field_id lookups, 100 per request, 0.15 s apart)."""
import json, sys, time, urllib.request
lo, hi = int(sys.argv[1]), int(sys.argv[2])
def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "nice-audit-census"})
    return json.load(urllib.request.urlopen(req, timeout=60))
claims, subs = [], []
for start in range(lo, hi + 1, 100):
    ids = ",".join(str(i) for i in range(start, min(start + 100, hi + 1)))
    claims += get(f"https://data.nicenumbers.net/claims?select=id,field_id,search_mode,claim_time&field_id=in.({ids})")
    time.sleep(0.15)
    subs += get(f"https://data.nicenumbers.net/submissions?select=id,claim_id,field_id,submit_time,username,search_mode,disqualified&field_id=in.({ids})")
    time.sleep(0.15)
json.dump(claims, open(f"claims_{lo}_{hi}.json", "w"))
json.dump(subs, open(f"submissions_{lo}_{hi}.json", "w"))
print(len(claims), len(subs))
