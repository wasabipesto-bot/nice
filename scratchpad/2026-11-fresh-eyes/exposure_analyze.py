#!/usr/bin/env python3
import json, sys, collections, subprocess, statistics
FIX = "7155c49c"  # #222
REPO = "/home/claude/projects/nice"
_anc = {}
def has_fix(sha):
    if not sha: return None
    if sha not in _anc:
        r = subprocess.run(["git", "-C", REPO, "merge-base", "--is-ancestor", FIX, sha], capture_output=True)
        _anc[sha] = (r.returncode == 0) if r.returncode in (0, 1) else None
    return _anc[sha]
def dev(hw):
    g = (hw.get("gpu_model") or "")
    if "Apple" in g: return "apple"
    if "AMD" in g or "Radeon" in g: return "amd"
    if "NVIDIA" in g: return "nvidia"
    return "other"
def main():
    subs = []
    for p in sys.argv[1:]:
        subs += json.load(open(p))["subs"]
    seen = set(); rows = collections.defaultdict(list)
    for s in subs:
        if s["id"] in seen or s["disqualified"]: continue
        seen.add(s["id"])
        t = s.get("telemetry") or {}; j = (t.get("pipeline") or {}).get("join") or {}; hw = t.get("hardware") or {}
        if not j: continue
        rows[s["field_id"]].append(dict(v=s["client_version"], u=s["username"], dev=dev(hw), be=hw.get("gpu_backend"),
            surv=j.get("survivors") or 0, chk=j.get("checked") or 0, fix=has_fix(t.get("build_sha")), sha=(t.get("build_sha") or "")[:8], t=s["submit_time"][:16]))
    allr = [r for v in rows.values() for r in v]
    print("submissions with join telemetry:", len(allr), "fields:", len(rows))
    print("by (device, has #222):", dict(collections.Counter((r["dev"], r["fix"]) for r in allr)))
    only = collections.Counter()
    for f, v in rows.items():
        only[tuple(sorted({(r["dev"], r["fix"]) for r in v}))] += 1
    print("fields by set of (device, fix) that searched them:")
    for k, c in only.most_common(): print("   ", k, c, f"{100*c/len(rows):.2f}%")
    PASS = 0.064
    res = collections.defaultdict(list)
    for f, v in rows.items():
        v = [r for r in v if r["surv"]]
        if len(v) < 2: continue
        for i in range(len(v)):
            for k in range(i + 1, len(v)):
                a, b = v[i], v[k]
                # order so that 'a' is the reference-like one (non-apple first)
                if a["dev"] == "apple" and b["dev"] != "apple": a, b = b, a
                R = (b["surv"] - a["surv"]) + (b["chk"] - a["chk"]) / (1 - PASS)
                key = ((a["dev"], a["fix"]), (b["dev"], b["fix"]))
                res[key].append((R / a["surv"], R, f, a, b))
    print("\nresidual R/survivors per pair, grouped (a = first, b = second; R<0: b accounts for fewer):")
    for key, lst in sorted(res.items(), key=lambda kv: str(kv[0])):
        rel = sorted(x[0] for x in lst)
        med = statistics.median(rel)
        print(f"  {key}: n={len(lst)} median={med:+.2e} min={rel[0]:+.2e} max={rel[-1]:+.2e}  |rel|>1e-6: {sum(abs(x)>1e-6 for x in rel)}")
    print("\npairs involving apple:")
    for key, lst in res.items():
        if "apple" not in (key[0][0], key[1][0]): continue
        for rel, R, f, a, b in sorted(lst, key=lambda x: x[4]["t"]):
            print(f"   field {f}: a=({a['dev']},{a['v']},{a['sha']},fix={a['fix']}) b=({b['dev']},{b['v']},{b['sha']},fix={b['fix']},{b['t']}) surv_a={a['surv']} R={R:+.0f} rel={rel:+.2e}")
    print("\nlargest |rel| among non-apple pairs:")
    na = [x for key, lst in res.items() if "apple" not in (key[0][0], key[1][0]) for x in lst]
    for rel, R, f, a, b in sorted(na, key=lambda x: -abs(x[0]))[:8]:
        print(f"   field {f}: a=({a['dev']},{a['be']},{a['sha']},fix={a['fix']}) b=({b['dev']},{b['be']},{b['sha']},fix={b['fix']}) surv_a={a['surv']} R={R:+.0f} rel={rel:+.2e}")
main()
