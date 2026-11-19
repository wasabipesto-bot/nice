#!/usr/bin/env python3
"""SRA census analysis: the (version, backend, route) table of all nice-only submissions, and the stored rows
(explicit non-join routes; CubeCL CUDA with no route field) by version, backend, route, base and field size."""
import json, collections
st = json.load(open("state.json"))
agg = collections.Counter()
for k, v in st["agg"].items():
    ver, backend, route = k.split("|"); agg[(ver, backend, route)] += v
print("nice-only submissions scanned:", st["total"], "; stored candidates:", st["rows"], "; next id", st["next"])
print("\n== all nice-only submissions by version, backend, route")
def vkey(v):
    import re
    return [int(x) if x.isdigit() else x for x in re.split(r"[.\-]", v or "")]
for (ver, backend, route), n in sorted(agg.items(), key=lambda kv: (vkey(kv[0][0]), kv[0][1], kv[0][2])):
    print(f"  {ver:12s} {backend:14s} {route:8s} {n:9d}")
rows = [json.loads(l) for l in open("rows.jsonl")]
print("\n== stored rows:", len(rows))
c = collections.Counter()
for x in rows:
    f = x.get("fields") or {}
    size = int(f.get("range_size") or 0)
    c[(x["client_version"], x["backend"], x["route"], x.get("reason"), f.get("base_id"), f"{size:.0e}" if size else "?")] += 1
for k, n in sorted(c.items(), key=lambda kv: -kv[1]): print("  ", k, n)
exp = [x for x in rows if x["backend"] == "cubecl-cuda" and x["route"] != "join"]
print("\n== the exposed combination (CubeCL CUDA runtime, not the join):", len(exp), "submissions,",
      len({x["field_id"] for x in exp}), "fields")
c = collections.Counter((x["client_version"], x["route"], x.get("reason"), (x.get("fields") or {}).get("base_id"),
                         x["username"], (x["gpu"] or "")[:40], x["disqualified"]) for x in exp)
for k, n in sorted(c.items(), key=lambda kv: -kv[1])[:40]: print("  ", k, n)
if exp:
    t = sorted(x["submit_time"] for x in exp); print("  from", t[0], "to", t[-1])
    json.dump(sorted({x["field_id"] for x in exp}), open("exposed_fields.json", "w"))
