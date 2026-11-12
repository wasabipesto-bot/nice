#!/usr/bin/env python3
"""T2.3 comparison. Inputs: sample.json (the drawn originals), box/out_*.jsonl (what the client submitted to the
local stub). Three rules, by build:

EXACT (builds with #236, 6f060a94 and c0c357ae, whose counters are exact and deterministic): re-run with the
same build; match iff survivors and checked are both equal.

OVERRUN MODEL for 8bd154bc and 9bde4a87 (#222, not #236; counters mean what c0c357ae's do, census cross-build ratios ~1):
Their counters are timing dependent (a survivor that overruns the stage leaves `survivors` and
is fully checked without the prefilter), so the same build does not reproduce them even on one device. Reference
= the exact counts (T survivors, P checked) of c0c357ae on the same field. With p = P/T, a lossless run has
x = T - surv >= 0 overrun survivors and checked = P + x(1-p) +- binomial noise; d = chk - P - x(1-p),
sigma = sqrt(x p (1-p)). Verdict: match iff x >= 0 and |d| <= 5 sigma + 2.

INVARIANT vs OWN BUILD for 9a4f7406 8c088a28 c72e2c6f 18cba8bc cb38b917 (their counters mean something else:
census ratios 0.82-0.93 against later builds): re-run with the same build on the 3080 (itself timing dependent);
p = checked/survivors of the re-run, r = (I_orig - I_rerun)/survivors_rerun with I = surv + chk/(1-p);
match iff |r| <= 3e-7 + 0.06 p |dsurv|/T (the overrun survivors' own pass rate differs from p by a few
per cent from field to field; the same rule flags 3 of 11,087 census same-build pairs, dup_rule.py). D carries r.
"""
import json, glob, collections, math, sys
EXACT = {"6f060a94", "c0c357ae"}
# builds whose counters mean what c0c357ae's mean (census cross-build ratios ~1, consistent with overrun only)
ORACLE = {"8bd154bc", "9bde4a87"}
R_TOL = 3e-7
samp = json.load(open("sample.json"))
rerun = collections.defaultdict(list)
for fn in sorted(glob.glob("box/out_*.jsonl")):
    for line in open(fn):
        d = json.loads(line)
        if d["claim_id"] == 1: continue
        t = d.get("telemetry") or {}; p = t.get("pipeline") or {}; j = p.get("join") or {}
        rerun[(d["claim_id"], (t.get("build_sha") or "")[:8])].append(dict(src=fn.split("/")[-1][4:-6], surv=j.get("survivors"), chk=j.get("checked"),
            route=p.get("route"), nice=d.get("nice_numbers")))
def model(surv, chk, T, P):
    p = P / T; x = T - surv; dd = chk - P - x * (1 - p); sig = math.sqrt(max(x, 0) * p * (1 - p))
    ok = x >= 0 and abs(dd) <= 5 * sig + 2
    D = ((surv + chk / (1 - p)) - (T + P / (1 - p))) / T
    return ok, x, dd, sig, D
def judge(c, r):
    """-> (status, detail) with status in match / mismatch / none"""
    if c["build"] in EXACT:
        got = rerun.get((r["field_id"], c["build"]))
        if not got: return "none", None
        g = got[0]; ok = str(g["surv"]) == str(r["surv"]) and str(g["chk"]) == str(r["chk"])
        return ("match" if ok else "mismatch"), dict(rule="exact", reruns=[(x["src"], x["surv"], x["chk"]) for x in got])
    if c["build"] in ORACLE:
        got = rerun.get((r["field_id"], "c0c357ae"))
        if not got: return "none", None
        g = got[0]; ok, x, dd, sig, D = model(int(r["surv"]), int(r["chk"]), int(g["surv"]), int(g["chk"]))
        return ("match" if ok else "mismatch"), dict(rule="overrun-model vs c0c357ae", T=g["surv"], P=g["chk"], x=x, d=round(dd, 1), sigma=round(sig, 1), D=D,
            own=[(y["src"], y["surv"], y["chk"]) for y in rerun.get((r["field_id"], c["build"]), [])])
    # own build, timing-dependent counters: compare the lossless invariant I = surv + chk/(1-p), p from the re-run
    got = rerun.get((r["field_id"], c["build"]))
    if not got: return "none", None
    g = got[0]; Ts, Pc = int(g["surv"]), int(g["chk"]); p = Pc / Ts
    r_ = ((int(r["surv"]) + int(r["chk"]) / (1 - p)) - (Ts + Pc / (1 - p))) / Ts
    tol = R_TOL + 0.06 * p * abs(Ts - int(r["surv"])) / Ts
    return ("match" if abs(r_) <= tol else "mismatch"), dict(rule="invariant vs own-build re-run", T=Ts, P=Pc, x=Ts - int(r["surv"]), D=r_, tol=tol,
        reruns=[(y["src"], y["surv"], y["chk"]) for y in got])
rows = []; mism = []; detail = []
for c in samp:
    m = mm = 0; xs = []
    for r in c["drawn"]:
        st, det = judge(c, r)
        if st == "none": continue
        detail.append(dict(cell=f'{c["base"]}|{c["family"]}|{c["build"]}', field_id=r["field_id"], sub_id=r["sub_id"], orig_surv=r["surv"], orig_chk=r["chk"], status=st, **det))
        if st == "match": m += 1
        else: mm += 1; mism.append(detail[-1])
        if det.get("x") is not None: xs.append(abs(det["x"]) / int(det["T"]))
    n = m + mm
    rows.append(dict(base=c["base"], family=c["family"], build=c["build"], share=c["share"], subs=c["subs"], population=c["population"],
        target=c["n"], run=n, matched=m, mismatched=mm, ub95=(1 - 0.05 ** (1 / n)) if (n and mm == 0) else None,
        rule="exact" if c["build"] in EXACT else "model-c0c3" if c["build"] in ORACLE else "invariant-own", checkable=c["checkable"], max_overrun_frac=max(xs) if xs else None))
json.dump(dict(rows=rows, mismatches=mism), open("compare.json", "w"), indent=1)
with open("compare_detail.jsonl", "w") as o:
    for d in detail: o.write(json.dumps(d) + "\n")
for x in rows:
    ub = f'{100*x["ub95"]:.1f}%' if x["ub95"] is not None else "-"
    print(f'{x["base"]} {x["family"][:32]:32s} {x["build"]} {100*x["share"]:6.2f}% {x["rule"][:5]} n={x["run"]:3d}/{x["target"]:3d} match {x["matched"]:3d} mism {x["mismatched"]} ub95 {ub}')
for m in mism: print("MISMATCH", json.dumps(m))
