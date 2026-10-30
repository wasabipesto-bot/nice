#!/usr/bin/env python3
"""Join-fit summaries for PROFILE-2: python3 fit_summary.py DIR (e14_prof_r*, e16_prof_r* logs)."""
import re, sys, glob, collections
import numpy as np
D = sys.argv[1]
STARTS = {58: 104400216587923470200, 60: 1366406074057412100454, 62: 7997740455941656911841, 64: 41242006262957161709568}
rows = []
for tag in ["e14", "e16"]:
    for p in sorted(glob.glob(f"{D}/{tag}_prof_r*.log")):
        for line in open(p):
            if "GPU_PROFILE" not in line: continue
            line = line[line.index("GPU_PROFILE"):]
            r = {k: float(v) for k, v in re.findall(r"(\w+)=([0-9][0-9.e+-]*)", line)}
            if int(re.search(r"start=(\d+)", line).group(1)) < STARTS[int(r["base"])] or r["join"] <= 0: continue
            r["tag"] = tag; rows.append(r)
X = {"padded": "padded_pairs", "pairs": "pairs", "surv": "survivors", "tops": "tops", "work": "buckets"}
U = {"padded": (1e12, "ps per padded lane-pair"), "pairs": (1e12, "ps per pair"), "surv": (1e12, "ps per AND survivor"), "tops": (1e12, "ps per top"), "work": (1e9, "ns per (partition, bucket)")}
def fit(combo, sel):
    rs = [r for r in rows if sel(r)]
    M = np.array([[r[X[c]] for c in combo] for r in rs]); y = np.array([r["join"] for r in rs]); w = 1 / y
    c, *_ = np.linalg.lstsq(M * w[:, None], y * w, rcond=None)
    rel = (M @ c - y) / y
    return rs, c, rel, M
models = [(("padded", "surv"), "e16"), (("padded", "surv", "tops"), "e16"), (("pairs", "surv"), "e16"),
          (("padded", "surv"), "e14"), (("padded", "surv", "work"), "e14"), (("pairs", "surv", "work"), "e14"),
          (("padded", "surv", "work"), "both"), (("pairs", "surv", "work"), "both"), (("padded", "pairs", "surv", "tops", "work"), "e16")]
for combo, which in models:
    sel = (lambda r: True) if which == "both" else (lambda r, w=which: r["tag"] == w)
    rs, c, rel, M = fit(combo, sel)
    print(f"\n**{' + '.join(combo)}**, fields {which} ({len(rs)}): " + ", ".join(f"{cc*U[k][0]:.3g} {U[k][1]}" for k, cc in zip(combo, c)) + f"; rms {np.sqrt(np.mean(rel**2)):.1%}, max {np.max(np.abs(rel)):.1%}")
    print("\n| base | size | fields | mean residual | min | max | " + " | ".join(f"{k} share of join" for k in combo) + " |")
    print("|---|---|---|---|---|---|" + "---|" * len(combo))
    g = collections.defaultdict(list)
    for i, r in enumerate(rs): g[(int(r["base"]), r["tag"])].append(i)
    for (b, t), ix in sorted(g.items(), key=lambda x: (x[0][1], x[0][0])):
        terms = (M[ix] * c).sum(axis=0); tot = terms.sum()
        print(f"| {b} | {'1e14' if t == 'e14' else '1e16'} | {len(ix)} | {np.mean(rel[ix]):+.1%} | {np.min(rel[ix]):+.1%} | {np.max(rel[ix]):+.1%} | " + " | ".join(f"{x/tot:.0%}" for x in terms) + " |")
