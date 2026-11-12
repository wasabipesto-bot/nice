#!/usr/bin/env python3
"""T2.3: group the b58/b60 nice-only submissions into cells (gpu family x build) and summarise."""
import json, collections, re, sys
F = {r["id"]: r for r in json.load(open("fields_b58_b60.json"))}
d = json.load(open("subs_b58_b60.json")); cols = d["cols"]
S = [dict(zip(cols, r)) for r in d["rows"]]
def family(s):
    g = s["gpu"]
    if g is None: return "CPU/none" if s["route"] or s["build"] else "no-telemetry"
    g2 = re.sub(r"^(NVIDIA GeForce |NVIDIA |AMD Radeon |AMD )", "", g)
    be = ""
    m = re.search(r"\((Vulkan|Metal|DX12)[^)]*\)", g2)
    if m: be = " [" + m.group(0).strip("()") + "]"
    g2 = re.sub(r"\s*\(.*$", "", g2).strip()
    return g2 + be
def cellkey(s): return (family(s), (s["build"] or "")[:8] or "none", s["client_version"])
if __name__ == "__main__":
    base = {fid: F[fid]["base_id"] for fid in F}
    per = collections.defaultdict(lambda: collections.Counter())
    for s in S:
        s["base"] = base[s["field_id"]]
    print("rows", len(S), "disqualified", sum(s["disqualified"] for s in S))
    print("routes", collections.Counter((s["base"], s["route"]) for s in S if not s["disqualified"]))
    for b in (58, 60):
        q = [s for s in S if s["base"] == b and not s["disqualified"]]
        fids = collections.Counter(s["field_id"] for s in q)
        nf = sum(1 for f in F.values() if f["base_id"] == b)
        print(f"\n== base {b}: {nf} fields, qualified subs {len(q)}, fields with >=1 qualified {len(fids)}, with >1 {sum(1 for v in fids.values() if v>1)}")
        cl = collections.Counter(F[f]["check_level"] for f in F if F[f]["base_id"] == b and f not in fids)
        print("   fields with no qualified sub, by check_level:", dict(cl))
        cells = collections.defaultdict(list)
        for s in q: cells[cellkey(s)].append(s)
        rng = sum(int(f["range_size"]) for f in F.values() if f["base_id"] == b)
        for k, v in sorted(cells.items(), key=lambda kv: -len(kv[1])):
            sz = sum(int(F[s["field_id"]]["range_size"]) for s in v)
            ne = sum(1 for s in v if s["surv"] not in (None, "0"))
            users = collections.Counter(s["username"] for s in v)
            print(f"  {k[0]:38s} {k[1]} {k[2]:8s} subs {len(v):6d} share {100*sz/rng:6.2f}% nonzero-surv {ne:6d} {min(s['submit_time'] for s in v)[:10]}..{max(s['submit_time'] for s in v)[:10]} {dict(users.most_common(3))}")
