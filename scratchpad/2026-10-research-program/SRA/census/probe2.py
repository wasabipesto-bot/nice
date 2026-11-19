#!/usr/bin/env python3
"""SRA census, step 0b (read-only): what one 100k-id range returns, with and without the non-join filter, and
whether the field can be embedded."""
import json, time, urllib.request, urllib.parse, collections
API = "https://data.nicenumbers.net"
def get(path):
    req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
    try:
        with urllib.request.urlopen(req, timeout=90) as r: return json.load(r)
    except urllib.error.HTTPError as e:
        return {"error": e.code, "body": e.read()[:300].decode("utf8", "replace")}
sel = ("id,field_id,username,client_version,submit_time,disqualified,"
       "build:telemetry->>build_sha,gpu:telemetry->hardware->>gpu_model,backend:telemetry->hardware->>gpu_backend,"
       "route:telemetry->pipeline->>route,valid:telemetry->pipeline->>valid_numbers,"
       "launches:telemetry->pipeline->>launches,cfg_gpu:telemetry->config->>gpu")
q = urllib.parse.quote(sel, safe=",:>-")
for a in (297400000, 262000000, 246000000):
    t = time.time(); r = get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&search_mode=eq.niceonly&select={q}")
    if isinstance(r, dict): print(a, r); continue
    c = collections.Counter((x["client_version"], x["backend"], x["route"]) for x in r)
    print(a, len(r), f"{time.time()-t:.1f}s", c.most_common(8)); time.sleep(0.3)
    if r: print("  sample", {k: r[0][k] for k in ("gpu", "cfg_gpu", "valid", "launches", "submit_time")})
a = 297400000
f = urllib.parse.quote("(telemetry->pipeline->>route.is.null,telemetry->pipeline->>route.neq.join)", safe="(),.>-")
r = get(f"/submissions?id=gte.{a}&id=lt.{a+100000}&search_mode=eq.niceonly&or={f}&select=id,field_id")
print("or-filter:", (len(r) if isinstance(r, list) else r))
r = get(f"/submissions?id=gte.{a}&id=lt.{a+2000}&search_mode=eq.niceonly&select=id,field_id,fields(base_id,range_size)&limit=2")
print("embed:", r if isinstance(r, dict) else r[:2])
