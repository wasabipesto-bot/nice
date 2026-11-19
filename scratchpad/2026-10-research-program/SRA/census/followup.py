#!/usr/bin/env python3
"""SRA census follow-up (read-only, light): the 451 fields whose nice-only submission ran CubeCL's stride kernel on
the CUDA runtime: (1) full telemetry of three of those submissions; (2) every submission to those fields
(field_id in batches of 50, primary-key style filters)."""
import json, time, urllib.request, urllib.parse, collections
API = "https://data.nicenumbers.net"
def get(path):
    req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-census"})
    with urllib.request.urlopen(req, timeout=120) as r: return json.load(r)
rows = [json.loads(l) for l in open("rows.jsonl")]
ids = [x["id"] for x in rows]
r = get(f"/submissions?id=in.({ids[0]},{ids[len(ids)//2]},{ids[-1]})&select=id,field_id,telemetry,numbers,elapsed_secs")
json.dump(r, open("sample_telemetry.json", "w"), indent=1)
print(json.dumps(r[0], indent=None)[:1500])
fields = sorted({x["field_id"] for x in rows}); allsubs = []
sel = urllib.parse.quote("id,field_id,search_mode,username,client_version,submit_time,disqualified,"
    "backend:telemetry->hardware->>gpu_backend,gpu:telemetry->hardware->>gpu_model,numbers", safe=",:>-")
for i in range(0, len(fields), 50):
    b = ",".join(map(str, fields[i:i+50]))
    allsubs += get(f"/submissions?field_id=in.({b})&select={sel}"); time.sleep(0.3)
json.dump(allsubs, open("fields_all_subs.json", "w"))
per = collections.defaultdict(list)
for s in allsubs: per[s["field_id"]].append(s)
print("fields", len(fields), "submissions to them", len(allsubs))
c = collections.Counter(tuple(sorted((s["search_mode"], s["client_version"], str(s["backend"]), s["username"]) for s in v)) for v in per.values())
for k, n in c.most_common(12): print(n, k)
only = [f for f, v in per.items() if all(s["backend"] == "cubecl-cuda" for s in v)]
print("fields whose ONLY submissions are CubeCL-CUDA stride ones:", len(only))
json.dump(only, open("fields_only_exposed.json", "w"))
fr = get(f"/fields?id=in.({','.join(map(str, fields[:3]))})&select=*")
print(json.dumps(fr[0])[:600])
