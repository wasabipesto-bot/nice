#!/usr/bin/env python3
"""NiceMark nice-only table: python3 analyze_nm.py box/"""
import json, sys, os, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else "box"
trees = ("main", "pr")
data = {t: [] for t in trees}
for r in (1, 2, 3):
    for t in trees:
        p = f"{D}/nm_r{r}_{t}.json"
        if os.path.exists(p) and os.path.getsize(p) > 0:
            data[t].append(json.load(open(p)))
keys = [s["key"] for s in data["main"][0]["scenarios"]] if data["main"] else []
print("| scenario | main rates (median) | PR rates (median) | **PR / main** | partitions per launch main → PR | routes |")
print("|---|---|---|---|---|---|")
for k in keys:
    row = {}
    for t in trees:
        rates = [next(s for s in d["scenarios"] if s["key"] == k)["rate"] for d in data[t]]
        slots = sorted({next(s for s in d["scenarios"] if s["key"] == k).get("join", {}).get("slots") for d in data[t]})
        routes = sorted({next(s for s in d["scenarios"] if s["key"] == k)["route"] for d in data[t]})
        row[t] = (rates, slots, routes)
    m, p = st.median(row["main"][0]), st.median(row["pr"][0])
    sp = lambda xs: (max(xs) - min(xs)) / st.median(xs) * 100
    print(f"| {k} | {', '.join(f'{x:.3e}' for x in row['main'][0])} (**{m:.3e}**, {sp(row['main'][0]):.1f} %) | {', '.join(f'{x:.3e}' for x in row['pr'][0])} (**{p:.3e}**, {sp(row['pr'][0]):.1f} %) | **×{p/m:.3f}** | {row['main'][1]} → {row['pr'][1]} | {row['main'][2]} / {row['pr'][2]} |")
for t in trees:
    sc = [d.get("score") for d in data[t]]
    print(f"\nscore {t}: {sc}")
