#!/usr/bin/env python3
"""Summarise the interleaved A/B detailed benchmark runs in this directory."""
import json, glob, os, statistics, sys

here = os.path.dirname(os.path.abspath(__file__))
keys = ["b40_detailed", "b50_detailed", "b50_detailed_1t"]

def load(tag):
    with open(os.path.join(here, f"{tag}.json")) as f:
        d = json.load(f)
    rates = {s["key"]: s for s in d["scenarios"]}
    return rates, d["score"], d["build_sha"]

def fmt_rate(r):
    return f"{r/1e6:.2f}"

def spread(v):
    m = statistics.median(v)
    return f"{(min(v)/m-1)*100:+.1f}/{(max(v)/m-1)*100:+.1f} %"

for T in sys.argv[1:] or ["15", "64", "1"]:
    tags = sorted(os.path.basename(p)[:-5] for p in glob.glob(os.path.join(here, f"t{T}-*.json")))
    rounds = sorted({t.split("-")[1] for t in tags if t.count("-") == 2}) or [None]
    print(f"\n## --threads {T}: {len(rounds)} rounds\n")
    data = {"A": {k: [] for k in keys + ["score"]}, "B": {k: [] for k in keys + ["score"]}}
    meta = {}
    for r in rounds:
        for tree in "AB":
            tag = f"t{T}-{r}-{tree}" if r else f"t{T}-{tree}"
            if tag not in tags:
                continue
            rates, score, sha = load(tag)
            meta[tree] = sha[:7]
            for k in keys:
                data[tree][k].append(rates[k]["rate"])
                meta[(tree, k)] = (rates[k]["threads"], rates[k]["window_size"], rates[k]["repetitions"], rates[k]["seconds"])
            data[tree]["score"].append(score)
    print(f"A = {meta.get('A')}, B = {meta.get('B')}\n")
    print("| scenario | threads | A rounds (M/s) | A median | A spread | B rounds (M/s) | B median | B spread | B/A |")
    print("|---|---|---|---|---|---|---|---|---|")
    for k in keys + ["score"]:
        a, b = data["A"][k], data["B"][k]
        if not a or not b:
            continue
        f = (lambda x: f"{x:.0f}") if k == "score" else fmt_rate
        thr = meta.get(("B", k), ("",))[0] if k != "score" else ""
        print(f"| {k} | {thr} | {' '.join(f(x) for x in a)} | {f(statistics.median(a))} | {spread(a)} | "
              f"{' '.join(f(x) for x in b)} | {f(statistics.median(b))} | {spread(b)} | "
              f"**{statistics.median(b)/statistics.median(a):.2f}x** |")
    print()
    for k in keys:
        for tree in "AB":
            if (tree, k) in meta:
                th, w, reps, secs = meta[(tree, k)]
                print(f"  {tree} {k}: threads {th}, window {w}, repetitions {reps} (last round), timed {secs:.1f} s")
