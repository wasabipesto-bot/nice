#!/usr/bin/env python3
"""L8: markdown tables for RESULTS.md (per-base top-5 k, pooled ladder, extra fits)."""
import math
import numpy as np, pandas as pd
from scipy.stats import chi2, poisson

HERE = "/home/claude/projects/nice/scratchpad/2026-10-research-program/L8"
df = pd.read_csv(f"{HERE}/data/models.csv"); df = df[df.base >= 12].copy()
df["P"] = df.E_M1_3 * df.DS          # project model generalised to every k
df["T1"] = df.E_M2_1 * df.DS         # + leading digit of n^2 and n^3
df["T3"] = df.E_M2_3 * df.DS
out = []

def g(o, e):
    if e <= 0: return "–"
    lo = 0.0 if o == 0 else chi2.ppf(0.025, 2 * o) / 2
    hi = chi2.ppf(0.975, 2 * o + 2) / 2
    return f"{o/e:.2f} [{lo/e:.2f}–{hi/e:.2f}]"

def e(x):
    if x == 0: return "0"
    if x < 0.01: return f"{x:.1e}"
    if x < 10: return f"{x:.2f}"
    return f"{x:,.0f}"

# per-base table
out.append("### Per base: observed / expected (project model M1×DS) for the top five k\n")
out.append("| base | R_b | N searched | k=b | k=b−1 | k=b−2 | k=b−3 | k=b−4 | ratio b−2 | ratio b−3 | ratio b−4 | ratio b−4, lead-digit model | lead-digit factor at k=b |")
out.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for b, s in df.groupby("base"):
    s = s.set_index("d")
    cells = [f"{int(s.loc[d].obs)} / {e(s.loc[d].P)}" for d in range(5)]
    r2 = s.loc[2].obs / s.loc[2].P; r3 = s.loc[3].obs / s.loc[3].P; r4 = s.loc[4].obs / s.loc[4].P
    r4t = s.loc[4].obs / s.loc[4].T1
    lf = s.loc[0].E_M2_1 / s.loc[0].E_M1_3 if s.loc[0].E_M1_3 > 0 else float("nan")
    out.append(f"| {b} | {int(s.loc[0].R_b)} | {s.loc[0].N:.2e} | " + " | ".join(cells) +
               f" | {r2:.2f} | {r3:.3f} | {r4:.3f} | {r4t:.3f} | {'–' if math.isnan(lf) else f'{lf:.3f}'} |")

# pooled ladder
out.append("\n### Pooled over bases 12–50: observed / expected and ratio [95 % CI] by model\n")
cols = [("E_M0", "M0 iid"), ("P", "project (low-3 × DS)"), ("T1", "+ lead digit (top-1)"), ("T3", "+ top-3")]
out.append("| d = b−k | observed | " + " | ".join(f"{n}: E" for _, n in cols) + " | " + " | ".join(f"{n}: ratio" for _, n in cols) + " |")
out.append("|---|---|" + "---|" * (2 * len(cols)))
for d in range(0, 7):
    s = df[df.d == d]
    O = int(s.obs.sum())
    Es = [s[c].sum() for c, _ in cols]
    # T3 undefined at b12/b13: compare on its own bases
    s3 = s[s.T3.notna()]
    rat = [g(O, Es[0]), g(O, Es[1]), g(O, Es[2]), g(int(s3.obs.sum()), s3.T3.sum())]
    out.append(f"| {d} | {O:,} | " + " | ".join(e(x) for x in Es) + " | " + " | ".join(rat) + " |")

# groups for project and top-1
out.append("\n### By base group (ratio obs/E; project model / with leading digit)\n")
out.append("| group | d=1 | d=2 | d=3 | d=4 |")
out.append("|---|---|---|---|---|")
groups = {"12–24": df.base <= 24, "25–34": (df.base >= 25) & (df.base <= 34), "35–44": (df.base >= 35) & (df.base <= 44),
          "45–50": df.base >= 45, "live (R_b>0)": df.R_b > 0, "dead (R_b=0)": df.R_b == 0}
for gname, m in groups.items():
    cells = []
    for d in range(1, 5):
        s = df[m & (df.d == d)]
        O = int(s.obs.sum())
        cells.append(f"{O:,}: {O/s.P.sum():.3f} / {O/s.T1.sum():.3f}")
    out.append(f"| {gname} | " + " | ".join(cells) + " |")

# high-statistics depth trend d=3..6
def glm(O, E, X):
    beta = np.zeros(X.shape[1]); beta[0] = math.log(O.sum() / E.sum())
    for _ in range(100):
        mu = E * np.exp(X @ beta); gr = X.T @ (O - mu); H = X.T @ (X * mu[:, None])
        st = np.linalg.solve(H, gr); beta += st
        if np.abs(st).max() < 1e-12: break
    mu = E * np.exp(X @ beta); phi = ((O - mu) ** 2 / mu).sum() / max(len(O) - X.shape[1], 1)
    se = np.sqrt(np.diag(np.linalg.inv(H)) * max(phi, 1))
    return beta, se, phi
out.append("\n### Depth-trend fits (Poisson GLM, ratio = c·s^d, quasi-Poisson CI), bases 12–50\n")
out.append("| model | depths | c (d=0) [95 %] | s per step | dispersion φ |")
out.append("|---|---|---|---|---|")
for c, n in cols[1:3]:
    for ds in ([3, 4, 5, 6], [1, 2, 3, 4], [1, 2, 3], [1, 2]):
        s = df[df.d.isin(ds) & (df[c] > 0)]
        X = np.stack([np.ones(len(s)), s.d.values.astype(float)], 1)
        bt, se, phi = glm(s.obs.values.astype(float), s[c].values, X)
        out.append(f"| {n} | {','.join(map(str, ds))} | {math.exp(bt[0]):.3f} [{math.exp(bt[0]-1.96*se[0]):.2f}–{math.exp(bt[0]+1.96*se[0]):.2f}] | {math.exp(bt[1]):.4f} | {phi:.2f} |")

# scenario likelihoods for the tail below d=3, top-1 model
out.append("\n### Three readings of the d ≤ 2 bins (leading-digit model), and their fit to d=1 and d=2\n")
out.append("| reading | ratio at d=2 | at d=1 | at d=0 (c) | E d=2 | E d=1 | log-lik vs best |")
out.append("|---|---|---|---|---|---|---|")
s1 = df[df.d == 1]; s2 = df[df.d == 2]
O1, O2 = int(s1.obs.sum()), int(s2.obs.sum()); E1, E2 = s1.T1.sum(), s2.T1.sum()
sc = {"no tail effect": (1.0, 1.0, 1.0), "constant step below d=3": (0.88, 0.88, 0.88),
      "compounding ×0.88 per step": (0.88, 0.88 ** 2, 0.88 ** 3)}
ll = {k: poisson.logpmf(O2, v[0] * E2) + poisson.logpmf(O1, v[1] * E1) for k, v in sc.items()}
best = max(ll.values())
for k, v in sc.items():
    out.append(f"| {k} | {v[0]} | {v[1]:.2f} | {v[2]:.2f} | {v[0]*E2:.0f} | {v[1]*E1:.1f} | {ll[k]-best:+.2f} |")
out.append(f"\nObserved: d=2 {O2}, d=1 {O1}.")
open(f"{HERE}/tables.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
