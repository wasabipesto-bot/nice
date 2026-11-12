#!/usr/bin/env python3
"""T2.3: share of each base's range by the 95 % bound its cell reached (from compare.json)."""
import json
rows = json.load(open("compare.json"))["rows"]
for b in (58, 60):
    buckets = {"<=2.5%": 0, "<=5.5%": 0, "<=10%": 0, "<=20%": 0, ">20% (few fields)": 0, "not re-run": 0, "not checkable": 0}
    for x in rows:
        if x["base"] != b: continue
        if not x["checkable"]: k = "not checkable"
        elif x["run"] == 0: k = "not re-run"
        elif x["mismatched"]: k = "MISMATCH"; buckets.setdefault(k, 0)
        else:
            u = x["ub95"]; k = "<=2.5%" if u <= .025 else "<=5.5%" if u <= .055 else "<=10%" if u <= .10 else "<=20%" if u <= .20 else ">20% (few fields)"
        buckets[k] += x["share"]
    print(b, {k: f"{100*v:.2f} %" for k, v in buckets.items()})
