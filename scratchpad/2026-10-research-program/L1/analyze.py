#!/usr/bin/env python3
"""Tables for L1/RESULTS.md from the CSVs the l1_selectivity test writes."""
import csv, os, sys, statistics as st
from collections import defaultdict

D = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
P = list(csv.DictReader(open(f"{D}/partitions.csv")))
W = {(r["base"], r["window"]): r for r in csv.DictReader(open(f"{D}/windows.csv"))}
PC = list(csv.DictReader(open(f"{D}/popcount.csv")))
GPU = {"58": "11.2", "60": "6.8–7.3", "62": "9.2–9.6", "64": "19.5"}  # µs/prefix, 9070 XT

def f(r, k): return float(r[k])
bases = sorted({r["base"] for r in P}, key=int)

def group(rows, key):
    g = defaultdict(list)
    for r in rows: g[key(r)].append(r)
    return g

by_base = group([r for r in P if int(r["tops"]) > 0], lambda r: r["base"])
by_win = group([r for r in P if int(r["tops"]) > 0], lambda r: (r["base"], r["window"]))

def tot(rows, k): return sum(f(r, k) for r in rows)
def wmean(rows, k):  # per-top quantity, weighted by tops
    t = tot(rows, "tops"); return sum(f(r, k) * f(r, "tops") for r in rows) / t

def prefix_scale(rows):
    # per top-layer prefix: per-partition sums × partitions / prefixes, field by field
    out = []
    for r in rows:
        w = W[(r["base"], r["window"])]
        out.append(int(w["nparts"]) / int(w["tlay"]))
    return out

print("## Table 1: counts per base (both fields, tops-weighted)\n")
print("| base | b−1 | roots | L | t | digits n²/n³ | bottoms after the partition digits | bottoms per key list | per class | ANDs/top | roots×class | top popcount mean (p10–p90) | known n² / n³ | AND pass rate | uniform model | AND survivors/top | prefilter survivors (= full checks)/top |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for b in bases:
    rows = by_base[b]; w = W[(b, rows[0]["window"])]
    m1 = int(w["m1"]); roots = int(w["roots"])
    lst = st.mean(f(r, "list_mean") for r in rows)
    ands = wmean(rows, "ands_per_top"); passt = wmean(rows, "and_pass_per_top")
    model = wmean(rows, "model_pass_per_top")
    p10 = min(int(r["pc_p10"]) for r in rows); p90 = max(int(r["pc_p90"]) for r in rows)
    print(f"| {b} | {m1} | {roots} | {w['L']} | {w['t']} | {w['s2']}/{w['s3']} | {st.mean(f(r,'ext_rows') for r in rows):,.0f} | {lst:,.0f} | {lst/m1:,.0f} | {ands:,.0f} | {roots*lst/m1:,.0f} | {wmean(rows,'pc_mean'):.2f} ({p10}–{p90}) | {wmean(rows,'n2_known_mean'):.2f} / {wmean(rows,'n3_known_mean'):.2f} | {100*passt/ands:.3f}% | {100*model/ands:.3f}% | {passt:.1f} | {wmean(rows,'checked_per_top'):.2f} |")

print("\n## Table 2: per top-layer prefix (all b^p partitions of a prefix), field by field\n")
print("| base | field | size | prefixes | tops/prefix | ANDs/prefix | AND survivors/prefix | prefilter survivors/prefix | GPU µs/prefix (9070 XT) |")
print("|---|---|---|---|---|---|---|---|---|")
for (b, wn), rows in sorted(by_win.items(), key=lambda x: (int(x[0][0]), x[0][1])):
    w = W[(b, wn)]; sc = int(w["nparts"]) / int(w["tlay"])
    mt = st.mean(f(r, "tops") for r in rows)
    print(f"| {b} | {wn} | {float(w['size']):.0e} | {int(w['tlay']):,} | {mt*sc:,.0f} | {mt*sc*wmean(rows,'ands_per_top')/1e6:.2f}M | {mt*sc*wmean(rows,'and_pass_per_top')/1e3:.1f}k | {mt*sc*wmean(rows,'checked_per_top')/1e3:.2f}k | {GPU[b]} |")

print("\n## Table 3: CPU stage times per partition (one thread, EPYC Rome, nice 19, 3 partitions at a time), mean over the sample\n")
print("| base | field | tops s | extend s | list s | scan s | of which AND only | full check | range test + prefilter + dispatch | scan share | scan excl. full check (item 23's scan) | ns per prefix tried (tops stage) | ns/AND | ns/AND survivor (excl. full check) |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for (b, wn), rows in sorted(by_win.items(), key=lambda x: (int(x[0][0]), x[0][1])):
    m = {k: st.mean(f(r, k) for r in rows) for k in ["tops_s","extend_s","list_s","scan_s","and_only_s","fullcheck_s","tops"]}
    ands = st.mean(f(r,"ands_per_top")*f(r,"tops") for r in rows)
    surv = st.mean(f(r,"survivors_per_top")*f(r,"tops") for r in rows)
    total = m["tops_s"]+m["extend_s"]+m["list_s"]+m["scan_s"]
    rest = m["scan_s"]-m["and_only_s"]-m["fullcheck_s"]
    print(f"| {b} | {wn} | {m['tops_s']:.2f} | {m['extend_s']:.3f} | {m['list_s']:.3f} | {m['scan_s']:.2f} | {m['and_only_s']:.2f} ({100*m['and_only_s']/total:.0f}%) | {m['fullcheck_s']:.2f} ({100*m['fullcheck_s']/total:.0f}%) | {rest:.2f} ({100*rest/total:.0f}%) | {100*m['scan_s']/total:.0f}% | {100*(m['scan_s']-m['fullcheck_s'])/total:.0f}% | {1e9*m['tops_s']/int(W[(b,wn)]['tlay']):.0f} | {1e9*m['and_only_s']/ands:.2f} | {1e9*rest/surv:.0f} |")

print("\n## Table 3b: CPU cost per top-layer prefix (all b^p partitions, one core), ms, by stage\n")
print("| base | field | tops | list + extend | ANDs | range test + prefilter + dispatch | full check | total | vs b60 item23 | GPU µs/prefix |")
print("|---|---|---|---|---|---|---|---|---|---|")
ref = None
rowsout = []
for (b, wn), rows in sorted(by_win.items(), key=lambda x: (int(x[0][0]), x[0][1])):
    w = W[(b, wn)]; sc = int(w["nparts"]) / int(w["tlay"]) * 1e3
    m = {k: st.mean(f(r, k) for r in rows) for k in ["tops_s","extend_s","list_s","scan_s","and_only_s","fullcheck_s"]}
    rest = m["scan_s"]-m["and_only_s"]-m["fullcheck_s"]
    parts = [m["tops_s"], m["extend_s"]+m["list_s"], m["and_only_s"], rest, m["fullcheck_s"]]
    total = sum(parts)
    if (b, wn) == ("60", "item23"): ref = total*sc
    rowsout.append((b, wn, [x*sc for x in parts], total*sc))
for b, wn, parts, total in rowsout:
    print(f"| {b} | {wn} | " + " | ".join(f"{x:.2f}" for x in parts) + f" | {total:.2f} | ×{total/ref:.2f} | {GPU[b]} |")

sig = [c[5:] for c in P[0].keys() if c.startswith("skip_") and not c.startswith("skip_prune")]
pr = [c[5:] for c in P[0].keys() if c.startswith("skip_prune")]
print("\n## Table 4: ANDs skipped (fraction of all ANDs), ANDs-weighted over the sample\n")
def skip(rows, name):
    a = sum(f(r,"ands_per_top")*f(r,"tops") for r in rows)
    return sum(f(r,"skip_"+name)*f(r,"ands_per_top")*f(r,"tops") for r in rows)/a
def visits(rows, name, col="visits_"):
    t = tot(rows, "tops"); return sum(f(r,col+name)*f(r,"tops") for r in rows)/t
print("| base | field | " + " | ".join(sig) + " | " + " | ".join(pr) + " |")
print("|---|---|" + "---|"*(len(sig)+len(pr)))
for (b, wn), rows in sorted(by_win.items(), key=lambda x: (int(x[0][0]), x[0][1])):
    print(f"| {b} | {wn} | " + " | ".join(f"{100*skip(rows,n):.1f}%" for n in sig) + " | " + " | ".join(f"{100*skip(rows,n):.1f}%" for n in pr) + " |")
print("\n## Table 4b: ANDs skipped per base (mean of the two fields)\n")
names = ["low", "top", "coll"]
print("| base | " + " | ".join(f"{n}{k}" for n in names for k in (4, 6, 8)) + " | prune by field cert | prune by key AND |")
print("|---|" + "---|"*11)
for b in bases:
    wins = [(k, v) for k, v in by_win.items() if k[0] == b]
    cell = lambda n: st.mean(skip(v, n) for _, v in wins)
    print(f"| {b} | " + " | ".join(f"{100*cell(f'{n}{k}'):.0f}%" for n in names for k in (4, 6, 8)) + f" | {100*cell('prune_window'):.0f}% | {100*cell('prune_key'):.0f}% |")

print("\nSub-buckets visited per (top, root) [non-empty ones in brackets]; class size for scale:\n")
print("| base | field | class size | " + " | ".join(sig) + " |")
print("|---|---|---|" + "---|"*len(sig))
for (b, wn), rows in sorted(by_win.items(), key=lambda x: (int(x[0][0]), x[0][1])):
    w = W[(b, wn)]; cls = st.mean(f(r,"list_mean") for r in rows)/int(w["m1"])
    print(f"| {b} | {wn} | {cls:,.0f} | " + " | ".join(f"{visits(rows,n):.1f} [{visits(rows,n,'nevisits_'):.1f}]" for n in sig) + " |")

print("\n## Table 5: what skipping saves on the CPU (upper bound: AND-only time × skipped fraction, no sub-bucket overhead), share of a partition\n")
print("| base | field | AND-only share | low8 | top4 | top8 | coll8 | prune_1e16 | prune_key |")
print("|---|---|---|---|---|---|---|---|---|")
for (b, wn), rows in sorted(by_win.items(), key=lambda x: (int(x[0][0]), x[0][1])):
    total = st.mean(f(r,"tops_s")+f(r,"extend_s")+f(r,"list_s")+f(r,"scan_s") for r in rows)
    a = st.mean(f(r,"and_only_s") for r in rows)/total
    print(f"| {b} | {wn} | {100*a:.0f}% | " + " | ".join(f"{100*a*skip(rows,n):.0f}%" for n in ["low8","top4","top8","coll8","prune_1e16","prune_key"]) + " |")

print("\n## Table 6: AND pass rate by top popcount (both fields), measured vs uniform model C(b−pc,12)/C(b,12)\n")
g = defaultdict(lambda: [0,0,0,0.0])
for r in PC:
    x = g[(r["base"], int(r["popcount"]))]
    x[0]+=int(r["tops"]); x[1]+=int(r["ands"]); x[2]+=int(r["and_pass"]); x[3]=float(r["model_rate"])
pcs = sorted({k[1] for k in g})
print("| popcount | " + " | ".join(f"b{b} tops share, measured / model" for b in bases) + " |")
print("|---|" + "---|"*len(bases))
for pc in pcs:
    cells = []
    for b in bases:
        x = g.get((b, pc))
        tb = sum(v[0] for k, v in g.items() if k[0]==b)
        if not x or x[0] < 0.005*tb: cells.append("")
        else: cells.append(f"{100*x[0]/tb:.0f}%: {100*x[2]/max(1,x[1]):.2f}% / {100*x[3]:.2f}%")
    if any(cells): print(f"| {pc} | " + " | ".join(cells) + " |")

print("\n## Windows\n")
print("| base | field | start | size | prefixes | field cert digits | 1e16 cert digits | S top8 | S coll8 |")
print("|---|---|---|---|---|---|---|---|---|")
for (b, wn), w in sorted(W.items(), key=lambda x: (int(x[0][0]), x[0][1])):
    print(f"| {b} | {wn} | {w['start']} | {float(w['size']):.0e} | {int(w['tlay']):,} | {w['cert_window_pc']} | {w['cert_1e16_pc']} | {w['S_top8']} | {w['S_coll8']} |")
