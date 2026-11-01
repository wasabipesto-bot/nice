#!/usr/bin/env python3
"""L8 supplementary checks:
  1. brute-force recount of small bases (b20, b22, b24) against the API tail;
  2. d=2 deficit: heterogeneity across bases, and replication on the bases the
     August tail test did not have (12-19, 47-50);
  3. the leading-digit factor at k=b (top-1 digit of n^2 and n^3, on top of the
     project's low-3 factor) for bases 20-64, and what folding it in would do to
     the 5.45 % headline. Writes data/top_factor.csv."""
import json, math, random, csv, sys
import numpy as np, pandas as pd
from scipy.stats import chi2, poisson
sys.path.insert(0, "/home/claude/projects/nice/scratchpad/2026-10-research-program/L8")
from models import base_range, low_u_dist, top_u_dists, occ_vec

HERE = "/home/claude/projects/nice/scratchpad/2026-10-research-program/L8"
random.seed(7)
bases = {r["id"]: r for r in json.load(open(f"{HERE}/data/bases.json"))}

# 1. brute force
print("== 1. brute-force recount (d = b - num_uniques) ==")
for b in (20, 22, 24):
    lo, hi = int(bases[b]["range_start"]), int(bases[b]["range_end"])
    cnt = {}
    for n in range(lo, hi):
        s = set()
        for x in (n * n, n * n * n):
            while x: s.add(x % b); x //= b
        d = b - len(s)
        if d <= 3: cnt[d] = cnt.get(d, 0) + 1
    api = {b - x["num_uniques"]: x["count"] for x in bases[b]["distribution"] if b - x["num_uniques"] <= 3}
    print(f"  b{b}: brute {dict(sorted(cnt.items()))}  api {dict(sorted(api.items()))}  match={cnt == {k: v for k, v in api.items() if v}}")

# 2. d=2 deficit structure
df = pd.read_csv(f"{HERE}/data/models.csv"); df = df[df.base >= 12]
print("\n== 2. d=2 deficit ==")
for col in ("E_M1_3", "E_M2_1", "E_M2_3"):
    s = df[(df.d == 2) & df[col].notna()].copy()
    s["E"] = s[col] * s.DS
    O, E = s.obs.values, s.E.values
    chi = ((O - E) ** 2 / E).sum(); k = len(s)
    # heterogeneity after scaling by the pooled ratio
    rho = O.sum() / E.sum()
    chi_h = ((O - rho * E) ** 2 / (rho * E)).sum()
    p_low = poisson.cdf(O.sum(), E.sum())
    print(f"  {col}xDS: bases={k} O={O.sum()} E={E.sum():.1f} ratio={rho:.3f} "
          f"P(O<=obs)={p_low:.4f}  chi2(vs model)={chi:.1f}/{k}  chi2(vs pooled ratio)={chi_h:.1f}/{k-1} p={chi2.sf(chi_h, k-1):.2f}")
    for name, m in (("bases in the Aug test (20-45)", (s.base >= 20) & (s.base <= 45)),
                    ("new since Aug (12-19, 47-50)", (s.base < 20) | (s.base > 45))):
        o, e = s[m].obs.sum(), s[m].E.sum()
        lo, hi = chi2.ppf(0.025, 2 * o) / 2 / e, chi2.ppf(0.975, 2 * o + 2) / 2 / e
        print(f"      {name}: O={o} E={e:.1f} ratio={o/e:.3f} [{lo:.3f},{hi:.3f}] P(O<=obs)={poisson.cdf(o, e):.3f}")
    # depth-1 and 2 combined
    s1 = df[(df.d == 1) & df[col].notna()]
    o1, e1 = s1.obs.sum(), (s1[col] * s1.DS).sum()
    print(f"      d=1: O={o1} E={e1:.2f};  d=1+2: O={o1+O.sum()} E={e1+E.sum():.1f} ratio={(o1+O.sum())/(e1+E.sum()):.3f}")

# 3. leading-digit factor at k=b
print("\n== 3. leading-digit factor at k = b (M2 top-1 / project low-3) ==")
anim = json.load(open("/home/claude/projects/nice/scratchpad/2026-08-cost-probability/anim.json"))
lam_past = {}
for sg in anim["segs"]:
    if sg["src"] == "past": lam_past[sg["base"]] = lam_past.get(sg["base"], 0) + sg["l1"] - sg["l0"]
rows = []
models = df[df.d == 0].set_index("base")
for b in list(range(12, 65)):
    rg = base_range(b)
    if rg is None or b % 4 == 3: continue
    if b in models.index:
        r = models.loc[b]
        f1 = r.E_M2_1 / r.E_M1_3; f2 = r.E_M2_2 / r.E_M1_3
        f3 = r.E_M2_3 / r.E_M1_3 if not math.isnan(r.E_M2_3) else float("nan")
        src = "models.csv"
    else:
        lo, hi = rg
        if b in bases: lo, hi = int(bases[b]["range_start"]), int(bases[b]["range_end"])
        import models as M
        M.SAMPLES = 400_000
        pus, ns, D2, D3 = M.top_u_dists(b, lo, hi, None, T=(1, 2))
        pl = low_u_dist(b, 3)
        m1 = pl[6] * occ_vec(b, b - 6, 6)[b]
        f1 = pus[1][8] * occ_vec(b, b - 8, 8)[b] / m1
        f2 = pus[2][10] * occ_vec(b, b - 10, 10)[b] / m1
        f3 = float("nan"); src = f"sampled {ns}"
    rows.append({"base": b, "top1": f1, "top2": f2, "top3": f3, "lam_past": lam_past.get(b, 0.0), "src": src})
    print(f"  b{b}: top1 {f1:.3f}  top2 {f2:.3f}  top3 {f3:.3f}  lam_past {lam_past.get(b,0):.2e}  ({src})", flush=True)
tf = pd.DataFrame(rows); tf.to_csv(f"{HERE}/data/top_factor.csv", index=False)
L = sum(lam_past.values())
for col in ("top1", "top2"):
    for lo_b, label in ((12, "all searched bases"), (20, "searched bases >= 20 (12-18 at 1.0)")):
        fac = {r.base: (getattr(r, col) if r.base >= lo_b else 1.0) for r in tf.itertuples()}
        Lc = sum(l * fac.get(b, 1.0) for b, l in lam_past.items())
        print(f"  {col}, {label}: sum lambda {L:.5f} -> {Lc:.5f} (x{Lc/L:.3f}); headline {100*(1-math.exp(-L)):.2f}% -> {100*(1-math.exp(-Lc)):.2f}%")
