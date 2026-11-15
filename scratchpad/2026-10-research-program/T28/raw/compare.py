#!/usr/bin/env python3
"""T2.8 comparison (rules of T2/raw/compare.py, reference build = current upstream main 54d0aac4, which differs from
demoux's a7a59c11 only by CI/toolchain/cc bumps). Originals: every census submission (subs_0615.json, extended by
subs_*.json) on a field the box re-ran with main; plus the box's own v3.4.7 runs.
  EXACT (a7a59c11, and main's own repeat runs): survivors and checked equal to main's re-run, and the same nice numbers.
  OVERRUN MODEL (8bd154bc = v3.4.7, #222 without #236): T, P = main's exact counts, p = P/T, x = T - surv >= 0 and
  |d| = |chk - P - x(1-p)| <= 5 sqrt(x p (1-p)) + 2 + 0.06 p (1-p) x  (a bound, not an equality)."""
import json, glob, math, collections, sys
MAIN = "54d0aac4"
subs = {}
for fn in sorted(glob.glob("subs_*.json")):
    for s in json.load(open(fn)): subs[s["id"]] = s
rerun = collections.defaultdict(list)
for fn in sorted(glob.glob("box/out_*.jsonl")):
    for line in open(fn):
        d = json.loads(line)
        if d["claim_id"] == 1: continue
        t = d.get("telemetry") or {}; p = t.get("pipeline") or {}; j = p.get("join") or {}
        rerun[(d["claim_id"], (t.get("build_sha") or "")[:8])].append(dict(src=fn.split("/")[-1][4:-6], surv=int(j["survivors"]), chk=int(j["checked"]),
            nice=sorted(int(x["number"]) if isinstance(x, dict) else int(x) for x in (d.get("nice_numbers") or [])), secs=j.get("run_secs"), gpu=(t.get("hardware") or {}).get("gpu_model")))
def model(surv, chk, T, P):
    p = P / T; x = T - surv; dd = chk - P - x * (1 - p); sig = math.sqrt(max(x, 0) * p * (1 - p))
    tol = 5 * sig + 2 + 0.06 * p * (1 - p) * x
    return (x >= 0 and abs(dd) <= tol), x, dd, sig, tol
samp = json.load(open("sample.json")); sampled = set(samp["demoux"]) | set(samp["fleet"])
fields_main = {f for (f, b) in rerun if b == MAIN}
out = []; mism = []
def ref_of(f):
    g = rerun[(f, MAIN)]
    return g[0]
for f in sorted(fields_main):
    ref = ref_of(f)
    # main's own repeats
    for g in rerun[(f, MAIN)][1:]:
        ok = (g["surv"], g["chk"], g["nice"]) == (ref["surv"], ref["chk"], ref["nice"])
        out.append(dict(field_id=f, orig="box main repeat " + g["src"], rule="exact", ok=ok, surv=g["surv"], chk=g["chk"], T=ref["surv"], P=ref["chk"]))
    for g in rerun.get((f, "8bd154bc"), []):
        ok, x, dd, sig, tol = model(g["surv"], g["chk"], ref["surv"], ref["chk"])
        out.append(dict(field_id=f, orig="box v3.4.7 " + g["src"], rule="overrun-model", ok=ok, surv=g["surv"], chk=g["chk"], T=ref["surv"], P=ref["chk"], x=x, d=round(dd, 1), sigma=round(sig, 1), tol=round(tol, 1)))
    for s in subs.values():
        if s["field_id"] != f: continue
        j = s["join"] or {}; b = (s["build"] or "")[:8]
        sv, ck = int(j["survivors"]), int(j["checked"])
        nice = sorted(int(x["number"]) if isinstance(x, dict) else int(x) for x in (s.get("numbers") or []))
        base = dict(field_id=f, orig=f'{s["username"]} sub {s["id"]}', build=b, gpu=s["gpu"], in_sample=s["id"] in sampled, surv=sv, chk=ck, T=ref["surv"], P=ref["chk"], nice=nice)
        if b == "a7a59c11":
            ok = sv == ref["surv"] and ck == ref["chk"] and nice == ref["nice"]
            out.append(dict(base, rule="exact", ok=ok))
        elif b == "8bd154bc":
            ok, x, dd, sig, tol = model(sv, ck, ref["surv"], ref["chk"])
            ok = ok and nice == ref["nice"]
            out.append(dict(base, rule="overrun-model", ok=ok, x=x, d=round(dd, 1), sigma=round(sig, 1), tol=round(tol, 1)))
        else:
            out.append(dict(base, rule="no rule", ok=None))
with open("compare_detail.jsonl", "w") as o:
    for r in out: o.write(json.dumps(r) + "\n")
c = collections.Counter((r["rule"], r["orig"].split(" ")[0] + (" (sample)" if r.get("in_sample") else ""), r["ok"]) for r in out)
for k, v in sorted(c.items(), key=str): print(v, k)
print("sample subs re-run:", len([r for r in out if r.get("in_sample")]), "of", len(sampled), "; main-re-run fields:", len(fields_main))
xs = [r["x"] / r["T"] for r in out if r["rule"] == "overrun-model"]
if xs: print("overrun x/T max", max(xs), "median", sorted(xs)[len(xs)//2], "max |d|/tol", max(abs(r["d"]) / r["tol"] for r in out if r["rule"] == "overrun-model"))
for r in out:
    if r["ok"] is False: print("MISMATCH", json.dumps(r))
