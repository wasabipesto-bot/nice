#!/usr/bin/env python3
"""benchtab.py DIR: table of NiceMark runs (NN-label.json) and per-label medians."""
import json, glob, os, sys, statistics as st
d = sys.argv[1]
rows = []
for p in sorted(glob.glob(os.path.join(d, "*.json"))):
    tag = os.path.basename(p)[:-5]
    label = tag.split("-", 1)[1]
    j = json.load(open(p))
    sc = {s["key"]: s for s in j["scenarios"]}
    rows.append((tag, label, j["build_sha"][:7], sc["b40_detailed"]["rate"], sc["b50_detailed"]["rate"], j["score"]))
print("| run | build | b40 n/s | b50 n/s | NiceMark |\n|---|---|---|---|---|")
for r in rows:
    print(f"| {r[0]} | {r[2]} | {r[3]:.4e} | {r[4]:.4e} | {r[5]:.0f} |")
labels = []
for r in rows:
    if r[1] not in labels:
        labels.append(r[1])
med = {}
print("\n| build | runs | b40 median | b50 median | NiceMark median | b40 spread | b50 spread |\n|---|---|---|---|---|---|---|")
for l in labels:
    rs = [r for r in rows if r[1] == l]
    b40 = [r[3] for r in rs]; b50 = [r[4] for r in rs]; s = [r[5] for r in rs]
    med[l] = (st.median(b40), st.median(b50), st.median(s))
    print(f"| {l} | {len(rs)} | {med[l][0]:.4e} | {med[l][1]:.4e} | {med[l][2]:.0f} | {(max(b40)-min(b40))/st.median(b40)*100:.2f} % | {(max(b50)-min(b50))/st.median(b50)*100:.2f} % |")
if "main" in med:
    print("\n| ratio to main | b40 | b50 | NiceMark |\n|---|---|---|---|")
    for l in labels:
        if l == "main":
            continue
        print(f"| {l} / main | {med[l][0]/med['main'][0]:.4f} | {med[l][1]/med['main'][1]:.4f} | {med[l][2]/med['main'][2]:.4f} |")
