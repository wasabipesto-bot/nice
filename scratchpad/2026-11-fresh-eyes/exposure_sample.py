#!/usr/bin/env python3
"""Read-only sample of canonical nice-only submissions per base from the public API:
client version, date and (where telemetry says) backend. Small indexed queries only."""
import json, sys, urllib.request, random, collections
API = "https://data.nicenumbers.net"
def get(path):
    req = urllib.request.Request(API + path, headers={"User-Agent": "nice-audit-sample"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)
def main():
    base = int(sys.argv[1]); nsample = int(sys.argv[2])
    lo = get(f"/fields?base_id=eq.{base}&select=id&order=id.asc&limit=1")[0]["id"]
    hi = get(f"/fields?base_id=eq.{base}&select=id&order=id.desc&limit=1")[0]["id"]
    rng = random.Random(base)
    ids = sorted(rng.sample(range(lo, hi + 1), min(nsample, hi - lo + 1)))
    fields = []
    for i in range(0, len(ids), 100):
        chunk = ",".join(map(str, ids[i:i + 100]))
        fields += get(f"/fields?id=in.({chunk})&base_id=eq.{base}&select=id,range_size,check_level,canon_submission_id")
    print(f"base {base}: field ids {lo}..{hi} ({hi-lo+1} fields), sampled {len(fields)}")
    print(" check_level:", dict(collections.Counter(f["check_level"] for f in fields)))
    sids = [f["canon_submission_id"] for f in fields if f["canon_submission_id"]]
    subs = []
    for i in range(0, len(sids), 50):
        chunk = ",".join(map(str, sids[i:i + 50]))
        subs += get(f"/submissions?id=in.({chunk})&select=id,search_mode,submit_time,client_version,disqualified,elapsed_secs,username,telemetry")
    ver = collections.Counter((s["client_version"], s["search_mode"]) for s in subs)
    print(" canonical submissions by (version, mode):")
    for k, v in sorted(ver.items(), key=lambda kv: -kv[1]):
        print(f"   {k}: {v} ({100*v/len(subs):.1f} %)")
    # telemetry keys and backend for v3.4.6
    keys = collections.Counter()
    backs = collections.Counter()
    dates = collections.defaultdict(list)
    for s in subs:
        t = s.get("telemetry") or {}
        keys.update(t.keys() if isinstance(t, dict) else [])
        b = None
        if isinstance(t, dict):
            b = (t.get("gpu_backend") or t.get("backend") or t.get("niceonly_route") or t.get("route"))
            g = t.get("gpu") or t.get("gpu_name") or t.get("device")
        backs[(s["client_version"], str(b), bool(t))] += 1
        dates[s["client_version"]].append(s["submit_time"][:10])
    print(" telemetry keys seen:", dict(keys.most_common(25)))
    print(" (version, backend field, has telemetry):")
    for k, v in sorted(backs.items(), key=lambda kv: -kv[1])[:20]:
        print("   ", k, v)
    for v, d in dates.items():
        print(f"   {v}: {min(d)} .. {max(d)}  n={len(d)}")
    json.dump({"fields": fields, "subs": subs}, open(f"exposure_b{base}.json", "w"))
main()
