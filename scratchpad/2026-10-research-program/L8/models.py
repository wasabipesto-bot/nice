#!/usr/bin/env python3
"""L8 near-miss tail test, step 1: model distributions of num_uniques per base.

For every base with detailed data (bases.json from data.nicenumbers.net/bases),
compute the expected count of numbers with exactly k = b-d distinct digits in
n^2||n^3 under a ladder of models, and write models.csv.

  M0      iid uniform digits: classic occupancy, C(b,k) Surj(b,k) / b^b.
  M1_J    the low J digits of n^2 and of n^3 exact (residues n mod b^J, exact
          enumeration), the other b-2J digits iid. J=3 is the project's
          alpha_{b,3}/P6 factor, generalised to every k.
  DS      digit-sum factor: P(K=k | S = n^2+n^3 mod b-1) for iid strings,
          averaged over the residue classes n mod b-1 (exact DP). At k=b it is
          the project's R_b; at k<b it is ~1 + O(R_b/b) (math-reassessment 2.2).
  M2_t    as M1_3 plus the top t digits of n^2 and of n^3, taken from the
          actual numbers (all n for small ranges, 10^6 uniform samples
          otherwise; base 50 weighted by its detailed coverage per chunk).

A structural model with f fixed positions holding u distinct values and the
other m = b-f digits iid gives P(K=k) = sum_u P(u) Occ(k | u, m): by the
symmetry of the iid digits only the number of distinct fixed values matters.
The headline model is M1_3 x DS (= the project's lambda at k=b).
"""
import json, math, random, sys, csv, time
from math import comb
import numpy as np

HERE = "/home/claude/projects/nice/scratchpad/2026-10-research-program/L8"
SAMPLES = 1_000_000
ENUM_MAX = 2_000_000          # enumerate every n when the range is at most this
random.seed(20261101)

def base_range(b):
    """Mirror of common/src/base_range.rs (as in build.py)."""
    def croot(x, r):
        lo, hi = 0, 1
        while hi ** r < x: hi *= 2
        while lo < hi:
            m = (lo + hi) // 2
            if m ** r >= x: hi = m
            else: lo = m + 1
        return lo
    k, r = b // 5, b % 5
    if r == 1: return None
    if r == 0: return (croot(b**(3*k-1), 3), b**k)
    if r == 2: return (b**k, croot(b**(3*k+1), 3))
    if r == 3: return (croot(b**(3*k+1), 3), croot(b**(2*k+1), 2))
    if r == 4: return (croot(b**(2*k+1), 2), croot(b**(3*k+2), 3))

def ndig(x, b):
    d = 0
    while x: x //= b; d += 1
    return d

def occ_vec(b, m, u):
    """P(total distinct = k), k=0..b, when u symbols are already present and m
    further digits are iid uniform over b symbols. Exact integer arithmetic."""
    out = [0.0] * (b + 1)
    den = b ** m
    for j in range(0, min(m, b - u) + 1):
        s = sum((-1) ** i * comb(j, i) * (u + j - i) ** m for i in range(j + 1))
        out[u + j] = comb(b - u, j) * s / den
    return np.array(out)

def low_u_dist(b, J, n_lo=None, n_hi=None):
    """Distribution of the number of distinct values among the low J digits of
    n^2 and of n^3. Uniform residues mod b^J, or the actual n in [n_lo, n_hi)."""
    m = b ** J
    if n_lo is None:
        r = np.arange(m, dtype=np.int64)
    else:
        r = (np.arange(n_lo, n_hi, dtype=np.int64) % m)
    r2 = (r * r) % m
    r3 = (r2 * r) % m
    digs = []
    for x in (r2, r3):
        for i in range(J):
            digs.append((x // b ** i) % b)
    D = np.stack(digs, axis=1)               # (N, 2J)
    D.sort(axis=1)
    u = 1 + (np.diff(D, axis=1) != 0).sum(axis=1)
    h = np.bincount(u, minlength=2 * J + 1).astype(float)
    return h / h.sum()

def ds_joint(b):
    """P(K=k, S=c mod b-1) for b iid uniform digits; exact-ish EGF DP in float."""
    q = b - 1
    A = np.zeros((b + 1, b + 1, q)); A[0, 0, 0] = 1.0
    inv_fact = [1.0 / math.factorial(c) for c in range(b + 1)]
    for s in range(b):
        B = A.copy()
        for c in range(1, b + 1):
            sh = (s * c) % q
            B[c:, 1:, :] += np.roll(A[:b + 1 - c, :b, :], sh, axis=2) * inv_fact[c]
        A = B
    return A[b] * (math.factorial(b) / b ** b)      # (k=0..b, c)

def class_weights(b, n_lo=None, n_hi=None):
    q = b - 1
    if n_lo is None:
        r = np.arange(q)
    else:
        r = np.arange(n_lo, n_hi, dtype=np.int64) % q
    c = (r * r % q + r * r % q * r % q) % q
    w = np.bincount(c, minlength=q).astype(float)
    return w / w.sum()

def sample_ns(b, lo, hi, chunks=None):
    """Yield the n to use for the top-digit model."""
    if hi - lo <= ENUM_MAX and chunks is None:
        return range(lo, hi)
    if chunks is None:
        return (random.randrange(lo, hi) for _ in range(SAMPLES))
    # base 50: weight chunks by their detailed coverage
    tot = sum(c["checked_detailed"] for c in chunks)
    out = []
    for c in chunks:
        k = round(SAMPLES * c["checked_detailed"] / tot)
        out.extend(random.randrange(int(c["range_start"]), int(c["range_end"])) for _ in range(k))
    return out

def top_u_dists(b, lo, hi, chunks=None, T=(1, 2, 3)):
    """Distinct-count distributions over {top t digits of n^2, n^3} + low 3 of each."""
    D2a, D2b = ndig(lo * lo, b), ndig((hi - 1) ** 2, b)
    D3a, D3b = ndig(lo ** 3, b), ndig((hi - 1) ** 3, b)
    assert D2a == D2b and D3a == D3b and D2a + D3a == b, (b, D2a, D2b, D3a, D3b)
    D2, D3 = D2a, D3a
    tmax = max(t for t in T if t + 3 <= D2)
    p2, p3 = b ** (D2 - tmax), b ** (D3 - tmax)
    b3 = b ** 3; bb = b * b
    hist = {t: np.zeros(2 * t + 7) for t in T if t <= tmax}
    nsamp = 0
    for n in sample_ns(b, lo, hi, chunks):
        n2 = n * n; n3 = n2 * n
        l2 = n2 % b3; l3 = n3 % b3
        low = (l2 % b, l2 // b % b, l2 // bb, l3 % b, l3 // b % b, l3 // bb)
        t2 = n2 // p2; t3 = n3 // p3          # tmax top digits
        tops2 = []; tops3 = []
        for i in range(tmax):                # most significant first
            tops2.append(t2 // b ** (tmax - 1 - i) % b)
            tops3.append(t3 // b ** (tmax - 1 - i) % b)
        for t in hist:
            u = len(set(low).union(tops2[:t], tops3[:t]))
            hist[t][u] += 1
        nsamp += 1
    return {t: h / h.sum() for t, h in hist.items()}, nsamp, D2, D3

def main():
    bases = json.load(open(f"{HERE}/data/bases.json"))
    chunks50 = json.load(open(f"{HERE}/data/chunks50.json"))
    only = [int(x) for x in sys.argv[1:]]
    rows = []
    udist_rows = []
    for rec in bases:
        b = rec["id"]
        if not rec["distribution"] or b < 10: continue
        if only and b not in only: continue
        t0 = time.time()
        # the searched range is the stored one; it ends one below base_range.rs
        # at 27 bases (known off-by-one in the stored range_end), harmless here
        lo, hi = int(rec["range_start"]), int(rec["range_end"])
        assert hi - lo == rec["range_size"] and base_range(b)[0] == lo, b
        dist = {x["num_uniques"]: x["count"] for x in rec["distribution"]}
        N = sum(dist.values())
        small = (hi - lo) <= ENUM_MAX
        chunks = None
        if b == 50:
            chunks = [c for c in chunks50 if c["checked_detailed"] > 0]
        # ---- M0
        m0 = occ_vec(b, b, 0)
        # ---- M1_J (J=1..4)
        m1 = {}
        pu_low = {}
        for J in (1, 2, 3, 4):
            if J >= 4 and b ** 4 > 2e7: continue
            pu = low_u_dist(b, J, *( (lo, hi) if small else (None, None)))
            pu_low[J] = pu
            v = np.zeros(b + 1)
            for u, p in enumerate(pu):
                if p > 0: v += p * occ_vec(b, b - 2 * J, u)
            m1[J] = v
            udist_rows.append({"base": b, "model": f"low{J}", **{f"u{u}": p for u, p in enumerate(pu)}})
        # ---- DS
        P = ds_joint(b)
        w = class_weights(b, *((lo, hi) if small else (None, None)))
        Pk = P.sum(axis=1); Pc = P.sum(axis=0)
        ds = np.array([(w * P[k] / Pc).sum() / Pk[k] if Pk[k] > 0 else np.nan for k in range(b + 1)])
        # sanity: DP marginal equals occupancy
        assert np.allclose(Pk[b-8:], m0[b-8:], rtol=1e-9), b
        # ---- M2_t
        pus, nsamp, D2, D3 = top_u_dists(b, lo, hi, chunks)
        m2 = {}
        for t, pu in pus.items():
            v = np.zeros(b + 1)
            for u, p in enumerate(pu):
                if p > 0: v += p * occ_vec(b, b - 6 - 2 * t, u)
            m2[t] = v
            udist_rows.append({"base": b, "model": f"top{t}+low3", **{f"u{u}": p for u, p in enumerate(pu)}})
        # project lambda (build.py formula), as a check of M1_3 x DS at k=b
        R = sum(1 for r in range(b - 1) if (r * r + r ** 3) % (b - 1) == b * (b - 1) // 2 % (b - 1))
        alpha = pu_low[3][6] if len(pu_low[3]) > 6 else 0.0
        p6 = math.prod((b - i) / b for i in range(6))
        lam_proj = N * m0[b] * R * alpha / p6
        for d in range(0, 7):
            k = b - d
            row = {"base": b, "d": d, "k": k, "N": N, "obs": dist.get(k, 0),
                   "R_b": R, "D2": D2, "D3": D3, "nsamp": nsamp,
                   "E_M0": N * m0[k], "DS": ds[k],
                   "E_proj_k_eq_b": lam_proj if d == 0 else None}
            for J, v in m1.items():
                row[f"E_M1_{J}"] = N * v[k]
            for t, v in m2.items():
                row[f"E_M2_{t}"] = N * v[k]
            rows.append(row)
        print(f"b{b}: N={N:.3e} D2={D2} D3={D3} R={R} samples={nsamp} "
              f"DS(b-1..b)={ds[b-1]:.4f},{ds[b]:.3f} "
              f"M1_3/M0 at d=0..4: {[round(m1[3][b-d]/m0[b-d],3) for d in range(5)]} "
              f"M2_1/M1_3: {[round(m2[1][b-d]/m1[3][b-d],3) if 1 in m2 else None for d in range(5)]} "
              f"({time.time()-t0:.1f}s)", flush=True)
    keys = sorted({k for r in rows for k in r}, key=lambda k: list(rows[0].keys()).index(k) if k in rows[0] else 99)
    suffix = ("_" + "_".join(map(str, only))) if only else ""
    with open(f"{HERE}/data/models{suffix}.csv", "w", newline="") as f:
        wr = csv.DictWriter(f, fieldnames=keys); wr.writeheader(); wr.writerows(rows)
    ukeys = ["base", "model"] + [f"u{u}" for u in range(0, 13)]
    with open(f"{HERE}/data/udist{suffix}.csv", "w", newline="") as f:
        wr = csv.DictWriter(f, fieldnames=ukeys, restval=""); wr.writeheader(); wr.writerows(udist_rows)

if __name__ == "__main__":
    main()
