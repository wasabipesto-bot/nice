#!/usr/bin/env python3
"""NiceMark over six rounds: A = main (r1-6); B = pr (r1-3, this PR) and
prb (r4-6, this PR + the flush barrier). python3 analyze_nm2.py box/"""
import json, sys, os, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else "box"
def load(t, rs):
    out = []
    for r in rs:
        p = f"{D}/nm_r{r}_{t}.json"
        if os.path.exists(p) and os.path.getsize(p) > 0:
            out.append(json.load(open(p)))
    return out
A = load("main", range(1, 7)); P = load("pr", (1, 2, 3)); Q = load("prb", (4, 5, 6))
A13 = load("main", (1, 2, 3)); A46 = load("main", (4, 5, 6))
def rates(ds, k): return [next(s for s in d["scenarios"] if s["key"] == k)["rate"] for d in ds]
def slots(ds, k): return sorted({next(s for s in d["scenarios"] if s["key"] == k).get("join", {}).get("slots") for d in ds})
def sp(xs): return (max(xs) - min(xs)) / st.median(xs) * 100
def cell(xs): return f"**{st.median(xs):.4g}** ({sp(xs):.1f} %, n={len(xs)})"
keys = [s["key"] for s in A[0]["scenarios"]]
print("| scenario | main, 6 rounds | B = pr r1-3 + prb r4-6 | **B / main (6)** | pr / main (r1-3) | prb / main (r4-6) | per launch main → B |")
print("|---|---|---|---|---|---|---|")
for k in keys:
    a, b = rates(A, k), rates(P, k) + rates(Q, k)
    r13 = st.median(rates(P, k)) / st.median(rates(A13, k)) if P and A13 else float("nan")
    r46 = st.median(rates(Q, k)) / st.median(rates(A46, k)) if Q and A46 else float("nan")
    print(f"| {k} | {cell(a)} | {cell(b)} | **×{st.median(b)/st.median(a):.3f}** | ×{r13:.3f} | ×{r46:.3f} | {slots(A,k)} → {slots(P+Q,k)} |")
sa = [d["score"] for d in A]; sb = [d["score"] for d in P + Q]
print(f"| **score** | {cell(sa)} | {cell(sb)} | **×{st.median(sb)/st.median(sa):.3f}** | | | |")
print("\nPer-round rates, b58_msd_weak: main " + ", ".join(f"{x:.4g}" for x in rates(A, "b58_msd_weak")) + "; B " + ", ".join(f"{x:.4g}" for x in rates(P, "b58_msd_weak") + rates(Q, "b58_msd_weak")))
