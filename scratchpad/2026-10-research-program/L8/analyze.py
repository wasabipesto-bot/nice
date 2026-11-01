#!/usr/bin/env python3
"""L8 near-miss tail test, step 2: compare observed num_uniques tails with the
models in data/models.csv, fit the depth trend, and test the digit-sum class
mechanism on the individually listed near misses (data/notable.json).

Writes data/tail_table.csv, data/pooled.csv, data/fits.csv, data/class_test.csv
and prints the tables used in RESULTS.md."""
import json, math, sys
import numpy as np, pandas as pd
from scipy.stats import chi2, norm

HERE = "/home/claude/projects/nice/scratchpad/2026-10-research-program/L8"
LAM_SEARCHED = 0.05606800736758983      # sum of searched lambda excl. base 10 (anim.json, 2026-10-09) -> 5.45 %

df = pd.read_csv(f"{HERE}/data/models.csv")
df = df[df.base >= 12].copy()            # base 10 (53 numbers, holds 69) excluded
for c in ["E_M1_1", "E_M1_2", "E_M1_3", "E_M1_4", "E_M2_1", "E_M2_2", "E_M2_3", "E_M0"]:
    if c in df: df[c + "xDS"] = df[c] * df["DS"]
MAIN = "E_M1_3xDS"
MODELS = [("E_M0", "M0 iid"), ("E_M0xDS", "M0 x DS"), ("E_M1_3", "M1 low-3 only"),
          ("E_M1_3xDS", "M1 low-3 x DS (project model)"), ("E_M1_4xDS", "M1 low-4 x DS"),
          ("E_M2_1xDS", "M2 top-1 + low-3 x DS"), ("E_M2_2xDS", "M2 top-2 + low-3 x DS"),
          ("E_M2_3xDS", "M2 top-3 + low-3 x DS")]
DEAD = {b for b in df.base.unique() if b % 4 == 3}

def garwood(o):
    lo = 0.0 if o == 0 else chi2.ppf(0.025, 2 * o) / 2
    hi = chi2.ppf(0.975, 2 * o + 2) / 2
    return lo, hi

def fmt(x, nd=3):
    if x is None or (isinstance(x, float) and (math.isnan(x))): return "–"
    if x == 0: return "0"
    if abs(x) >= 1e4 or abs(x) < 1e-2: return f"{x:.2e}"
    return f"{x:.{nd}g}" if abs(x) < 10 else f"{x:,.0f}" if abs(x) >= 100 else f"{x:.1f}"

# ---------------------------------------------------------------- per-base table
rows = []
for _, r in df[df.d <= 4].sort_values(["base", "d"]).iterrows():
    E = r[MAIN]; o = int(r.obs)
    lo, hi = garwood(o)
    rows.append({"base": int(r.base), "d": int(r.d), "k": int(r.k), "obs": o, "E_main": E,
                 "ratio": o / E if E > 0 else np.nan, "ci_lo": lo / E if E > 0 else np.nan,
                 "ci_hi": hi / E if E > 0 else np.nan, "E_M0": r.E_M0, "DS": r.DS,
                 "E_M2_1xDS": r.get("E_M2_1xDS", np.nan), "dead": int(r.base) in DEAD})
tab = pd.DataFrame(rows)
tab.to_csv(f"{HERE}/data/tail_table.csv", index=False)

# ---------------------------------------------------------------- pooled by depth
def pooled(sub, col):
    out = []
    for d in range(0, 7):
        s = sub[sub.d == d]
        O = int(s.obs.sum()); E = float(s[col].sum())
        lo, hi = garwood(O)
        out.append((d, O, E, O / E if E else np.nan, lo / E if E else np.nan, hi / E if E else np.nan))
    return out

groups = {"all 12-50": df.base >= 12, "12-24": (df.base <= 24), "25-34": (df.base >= 25) & (df.base <= 34),
          "35-44": (df.base >= 35) & (df.base <= 44), "45-50": df.base >= 45,
          "live (R>0)": df.R_b > 0, "dead (R=0)": df.R_b == 0, "25-50": df.base >= 25}
prow = []
for col, name in MODELS:
    if col not in df: continue
    for g, mask in groups.items():
        for d, O, E, rt, lo, hi in pooled(df[mask], col):
            prow.append({"model": name, "col": col, "group": g, "d": d, "obs": O, "E": E,
                         "ratio": rt, "ci_lo": lo, "ci_hi": hi})
pool = pd.DataFrame(prow)
pool.to_csv(f"{HERE}/data/pooled.csv", index=False)

# ---------------------------------------------------------------- Poisson GLM trend fits
def glm(O, E, X):
    """Poisson regression O ~ Pois(E exp(X beta)); Newton; quasi-Poisson SEs."""
    beta = np.zeros(X.shape[1])
    beta[0] = math.log(O.sum() / E.sum())
    for _ in range(100):
        mu = E * np.exp(X @ beta)
        g = X.T @ (O - mu)
        H = X.T @ (X * mu[:, None])
        step = np.linalg.solve(H, g)
        beta += step
        if np.abs(step).max() < 1e-12: break
    mu = E * np.exp(X @ beta)
    dof = max(len(O) - X.shape[1], 1)
    phi = float(((O - mu) ** 2 / mu).sum() / dof)
    cov = np.linalg.inv(H) * max(phi, 1.0)
    dev = 2 * float(np.sum(np.where(O > 0, O * np.log(np.where(O > 0, O, 1) / mu), 0) - (O - mu)))
    return beta, np.sqrt(np.diag(cov)), phi, dev, dof

frows = []
def fitset(col, name, mask, dset, with_b=False, label=""):
    s = df[mask & df.d.isin(dset) & (df[col] > 0)]
    O = s.obs.values.astype(float); E = s[col].values
    cols = [np.ones(len(s)), s.d.values.astype(float)]
    if with_b: cols.append(s.base.values - 40.0)
    X = np.stack(cols, axis=1)
    beta, se, phi, dev, dof = glm(O, E, X)
    a, sa = beta[0], se[0]
    out = {"model": name, "col": col, "subset": label, "depths": ",".join(map(str, dset)),
           "base_term": with_b, "n_bins": len(s), "obs": int(O.sum()),
           "c_d0": math.exp(a), "c_d0_lo": math.exp(a - 1.96 * sa), "c_d0_hi": math.exp(a + 1.96 * sa),
           "per_step": math.exp(beta[1]), "per_step_lo": math.exp(beta[1] - 1.96 * se[1]),
           "per_step_hi": math.exp(beta[1] + 1.96 * se[1]), "phi": phi, "dev": dev, "dof": dof}
    if with_b:
        out["per_base"] = math.exp(beta[2])
    frows.append(out)
    return out

for col, name in MODELS:
    if col not in df: continue
    for label, mask in (("12-50", df.base >= 12), ("25-50", df.base >= 25)):
        fitset(col, name, mask, [1, 2, 3, 4], label=label)
        fitset(col, name, mask, [1, 2, 3], label=label)
        fitset(col, name, mask, [1, 2], label=label)
    fitset(col, name, df.base >= 12, [1, 2, 3, 4], with_b=True, label="12-50")
fits = pd.DataFrame(frows)
fits.to_csv(f"{HERE}/data/fits.csv", index=False)

# ---------------------------------------------------------------- digit-sum class test
def ds_joint(b):
    q = b - 1
    A = np.zeros((b + 1, b + 1, q)); A[0, 0, 0] = 1.0
    inv_fact = [1.0 / math.factorial(c) for c in range(b + 1)]
    for s in range(b):
        B = A.copy()
        for c in range(1, b + 1):
            B[c:, 1:, :] += np.roll(A[:b + 1 - c, :b, :], (s * c) % q, axis=2) * inv_fact[c]
        A = B
    return A[b] * (math.factorial(b) / b ** b)

notable = json.load(open(f"{HERE}/data/notable.json"))
crow = []
for b in sorted({x["base"] for x in notable}):
    if b < 12: continue
    q = b - 1; T = b * (b - 1) // 2 % q
    R = sum(1 for r in range(q) if (r * r + r ** 3) % q == T)
    if R == 0: continue
    P = ds_joint(b); Pc = P.sum(axis=0)
    r = np.arange(q); cls = (r * r + r ** 3) % q
    w = np.bincount(cls, minlength=q) / q
    for d in (1, 2):
        k = b - d
        cond = w * P[k] / Pc                       # sum over classes of w(c) P(K=k|c)
        share_good = cond[T] / cond.sum()
        nm = [int(x["number"]) for x in notable if x["base"] == b and x["off_by"] == d]
        if not nm: continue
        good = sum(1 for n in nm if (n * n + n ** 3) % q == T)
        extra = ""
        if d == 1:   # identity check: in good classes {repeated, missing} = {0, b-1}
            for n in nm:
                if (n * n + n ** 3) % q != T: continue
                ds = []
                for x in (n * n, n ** 3):
                    while x: ds.append(x % b); x //= b
                cnt = np.bincount(ds, minlength=b)
                extra += f"rep={list(np.where(cnt == 2)[0])} miss={list(np.where(cnt == 0)[0])};"
        crow.append({"base": b, "d": d, "R_b": R, "n_nearmiss": len(nm), "obs_good": good,
                     "exp_good": share_good * len(nm), "share_good_model": share_good,
                     "share_good_if_no_effect": R / q, "identity": extra})
ct = pd.DataFrame(crow)
ct.to_csv(f"{HERE}/data/class_test.csv", index=False)

# ---------------------------------------------------------------- print
pd.set_option("display.width", 250); pd.set_option("display.max_rows", 500)
print("=== pooled by depth, all bases 12-50 ===")
for col, name in MODELS:
    if col not in df: continue
    s = pool[(pool.col == col) & (pool.group == "all 12-50")]
    print(f"-- {name}")
    for _, r in s.iterrows():
        print(f"   d={r.d}  obs={r.obs:>12,}  E={r.E:>14.4g}  ratio={r.ratio:.4f}  [{r.ci_lo:.3f},{r.ci_hi:.3f}]")
print("\n=== pooled by group, main model ===")
for g in groups:
    s = pool[(pool.col == MAIN) & (pool.group == g) & (pool.d <= 4)]
    print(g, "  ".join(f"d{r.d}:{r.obs}/{r.E:.4g}={r.ratio:.3f}" for _, r in s.iterrows()))
print("\n=== GLM fits ===")
print(fits[["model", "subset", "depths", "base_term", "n_bins", "obs", "c_d0", "c_d0_lo", "c_d0_hi",
            "per_step", "phi"]].to_string(index=False, float_format=lambda x: f"{x:.4f}"))
print("\n=== class test (live bases) ===")
g = ct.groupby("d")[["n_nearmiss", "obs_good", "exp_good"]].sum()
print(g)
print(ct[ct.d == 1][["base", "n_nearmiss", "obs_good", "exp_good", "identity"]])
print("\n=== headline translation (sum lambda searched = %.5f -> %.2f%%) ===" % (LAM_SEARCHED, 100 * (1 - math.exp(-LAM_SEARCHED))))
for c in (0.5, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2):
    print(f"  c={c:.2f}: {100 * (1 - math.exp(-LAM_SEARCHED * c)):.2f}%")
