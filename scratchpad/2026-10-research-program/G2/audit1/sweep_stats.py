"""Summarise the audit sweeps (JSON lines from audit_sweep): slices, equal or not, and the limits' observed maxima."""
import json
import sys

rows = []
for f in sys.argv[1:]:
    for line in open(f):
        r = json.loads(line)
        r["_file"] = f
        rows.append(r)
pips = [r["pip"] for r in rows]
print(f"slices: {len(rows)} lines, {len(set(pips))} distinct; not equal: {sum(not r['ok'] for r in rows)}")
for r in rows:
    if not r["ok"]:
        print("  DIFF", r["pip"], r["why"])
# non-vacuous no-prefilter comparison: the device's whole list = the reference's survivors
print("no-prefilter list = survivors on every slice:", all(r["list_max_nopf"] == r["survivors"] for r in rows))
print("prefiltered list = checked on every slice:", all(r["list_max"] == r["checked"] for r in rows))
print("kept equal where keys agree:", sum(r["kept_dev"] == r["kept_cpu"] for r in rows), "of", len(rows))
for k in ["tops", "tested", "maxpop", "maxprobe", "probe_min", "zero_jobs", "parents", "cls_max", "cls_min",
          "bucket_max", "children", "chunks", "flat", "survivors", "checked", "slabs_max", "list_max",
          "list_max_nopf", "slabs_max_nopf", "flat_d_max", "surv_d_max", "cpu_s", "dev_s"]:
    v = [r[k] for r in rows]
    mx = max(rows, key=lambda r: r[k])
    mn = min(rows, key=lambda r: r[k])
    print(f"{k:15s} min {min(v):>14} (slice {mn['pip']})  max {max(v):>14} (slice {mx['pip']})  mean {sum(v)/len(v):.1f}")
print("slices with a job past PMAX (576):", sum(r["maxprobe"] > 576 for r in rows))
print("survivors total", sum(r["survivors"] for r in rows), "checked total", sum(r["checked"] for r in rows))
