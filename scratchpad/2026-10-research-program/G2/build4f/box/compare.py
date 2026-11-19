#!/usr/bin/env python3
"""Compare the route's recorded submissions with the library's own results for the same fields, and the cost.
usage: compare.py E2E_DIR LIB_DIR"""
import json, re, sys
e2e, lib = sys.argv[1], sys.argv[2]
subs = [json.loads(l) for l in open(f"{e2e}/state/submissions.jsonl")]
claims = {json.loads(l)["claim_id"]: json.loads(l) for l in open(f"{e2e}/state/claims.jsonl")}
libr = {}
pat = re.compile(r"^(FIELD|WIDE b65) t (\d+) v \[(\d+), \+(\d+)\) n (\d+): ([\d.]+) s = ([\d.]+) fs per admissible n \| slices (\d+) survivors (\d+) checked (\d+) nice \[([^\]]*)\]")
for f, b in ((f"{lib}/lib64.log", 64), (f"{lib}/lib65.log", 65)):
    for line in open(f):
        m = pat.match(line)
        if m:
            nice = [int(x) for x in m.group(11).split(",") if x.strip()]
            libr[(b, int(m.group(3)))] = dict(t=int(m.group(2)), wall=float(m.group(6)), fs=float(m.group(7)),
                                              slices=int(m.group(8)), surv=int(m.group(9)), checked=int(m.group(10)), nice=nice)
ok = True; rows = []
for s in subs:
    d = s["submission"]; p = d["telemetry"]["pipeline"]; j = p["join"]
    b = p["field"]["base"]; v = int(p["field"]["v_start"])
    L = libr.get((b, v))
    nice = sorted(int(x["number"]) for x in d["nice_numbers"])
    eq = L is not None and (j["survivors"], j["checked"], j["slices"], nice) == (L["surv"], L["checked"], L["slices"], sorted(L["nice"]))
    ok &= eq and s["accepted"]
    adm = L["wall"] / L["fs"] * 1e15 if L else float("nan")
    route_wall = d["telemetry"]["processing_secs"]
    ctime = claims[s["claim_id"]]["time"]
    rows.append((b, int(p["field"]["t0"]), s["accepted"], eq, j["survivors"], j["checked"], j["slices"], nice,
                 (j.get("sampled_check") or {}).get("slice"), route_wall, s["recv"] - ctime, L and L["wall"], adm))
print("base t accepted equal survivors checked slices nice sampled_slice route_wall claim_to_submit lib_wall")
for r in rows:
    print(*r[:12])
print("ALL EQUAL AND ACCEPTED:", ok, "| submissions", len(subs), "| library fields", len(libr))
for b in (64, 65):
    R = [r for r in rows if r[0] == b]
    if not R: continue
    for lab, sel in (("all", R), ("warm (first excluded)", R[1:])):
        if not sel: continue
        adm = sum(r[12] for r in sel)
        rw = sum(r[9] for r in sel); cs = sum(r[10] for r in sel); lw = sum(r[11] for r in sel)
        print(f"b{b} {lab} {len(sel)} fields: library {lw:.2f} s = {lw/adm*1e15:.4f} fs | route search {rw:.2f} s = {rw/adm*1e15:.4f} fs "
              f"| claim-to-submit {cs:.2f} s = {cs/adm*1e15:.4f} fs | route/library {cs/lw:.4f}")
# whole run: first claim to last submit, over all b64 fields
b64 = sorted([s for s in subs if s["submission"]["telemetry"]["pipeline"]["field"]["base"] == 64], key=lambda s: s["recv"])
if b64:
    t0 = min(claims[s["claim_id"]]["time"] for s in b64); t1 = b64[-1]["recv"]
    adm = sum(libr[(64, int(s["submission"]["telemetry"]["pipeline"]["field"]["v_start"]))]["wall"] / libr[(64, int(s["submission"]["telemetry"]["pipeline"]["field"]["v_start"]))]["fs"] * 1e15 for s in b64)
    lw = sum(libr[(64, int(s["submission"]["telemetry"]["pipeline"]["field"]["v_start"]))]["wall"] for s in b64)
    print(f"b64 first claim to last submit: {t1-t0:.2f} s = {(t1-t0)/adm*1e15:.4f} fs (library {lw:.2f} s, x{(t1-t0)/lw:.4f})")
