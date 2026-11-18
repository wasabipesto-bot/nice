#!/usr/bin/env python3
"""NM: the repeat histogram of checked survivors on sampled production partitions
(raw/hist*.txt, `nm_join run ... 64` lines) against the uniform-middle model, and
the checked-survivor rate per field.

Model, given K digits known distinct at the check's start (bottom 12, prefilter 4,
the certificate's common digits): the other u = b - K positions take uniform digits;
a repeat is a position whose digit is already present. P(repeats = j | K) by a DP over
the draws (the digit-sum constraint ignored: it matters only for j <= 1).
"""
import re, sys
from collections import defaultdict

def model(b, K, maxr=64):
    u = b - K
    # dp[h] = P(h new distinct values after the draws so far)
    dp = [0.0] * (u + 1); dp[0] = 1.0
    for i in range(u):
        nd = [0.0] * (u + 1)
        for h, p in enumerate(dp):
            if p == 0: continue
            pn = (b - K - h) / b
            nd[h + 1] += p * pn
            nd[h] += p * (1 - pn)
        dp = nd
    out = [0.0] * (maxr + 1)
    for h, p in enumerate(dp):
        out[u - h] += p
    return out

def main(paths):
    runs = defaultdict(list)
    for path in paths:
        for line in open(path):
            if not line.startswith("RUN"): continue
            m = re.search(r"RUN b(\d+) start (\d+) size (\S+) slice (\d+)/(\d+) v (\d+)\.\.(\d+) tol 64 .*? survivors (\d+) checked (\d+) .*?reps \[([0-9, ]*)\](?: pre \[([0-9, ]*)\])? kreps (\S*)", line)
            if not m: continue
            b = int(m[1]); ns = int(m[5]); v0, v1 = int(m[6]), int(m[7])
            reps = [int(x) for x in m[10].split(",")] if m[10] else []
            pre = [int(x) for x in m[11].split(",")] if m[11] else []
            kreps = defaultdict(int)
            if m[12]:
                for t in m[12].split(","):
                    k, r, c = (int(x) for x in t.split(":"))
                    kreps[(k, r)] += c
            runs[b].append(dict(start=int(m[2]), slices=ns, parts=v1 - v0, surv=int(m[8]),
                                checked=int(m[9]), reps=reps, pre=pre, kreps=kreps))
    for b in sorted(runs):
        rs = runs[b]
        nparts = b * b
        per_field = [r["checked"] / r["parts"] * nparts * r["slices"] for r in rs]
        mean = sum(per_field) / len(per_field)
        var = sum((x - mean) ** 2 for x in per_field) / max(len(per_field) - 1, 1)
        tot = sum(r["checked"] for r in rs)
        print(f"b{b}: {len(rs)} sampled (field, slice) runs of 32 partitions, {tot:.4e} checked survivors")
        print(f"  checked per 1e17 field (slice-sampled): mean {mean:.3e}, sd of a run {var**0.5:.2e}, se {(var/len(rs))**0.5:.2e}")
        surv = sum(r["surv"] for r in rs)
        print(f"  AND survivors per checked: {surv/tot:.2f}")
        pre = [0] * 5
        for r in rs:
            for i, c in enumerate(r["pre"]): pre[i] += c
        if sum(pre):
            print(f"  AND survivors by prefilter repeats 0..4: {pre} (x{pre[1]/pre[0]:.2f}, x{pre[2]/pre[0]:.2f} the checked load for 1, 2 repeats)")
        reps = defaultdict(int); kh = defaultdict(int)
        for r in rs:
            for i, c in enumerate(r["reps"]): reps[i] += c
            for (k, rr), c in r["kreps"].items(): kh[k] += c
        ktot = sum(kh.values())
        kmean = sum(k * c for k, c in kh.items()) / ktot
        print(f"  known digits at the check: mean {kmean:.2f}, range {min(kh)}..{max(kh)}")
        mp = [0.0] * 65
        for k, c in kh.items():
            for j, p in enumerate(model(b, k)):
                mp[j] += p * c / ktot
        print("  j  measured  model(expected)  ratio")
        for j in range(0, 20):
            meas = reps.get(j, 0); exp = mp[j] * tot
            if meas or exp > 0.1:
                print(f"  {j:2d} {meas:9d} {exp:14.2f}  {meas/exp if exp else float('nan'):.3f}")
        # model P(j | checked) at small j for extrapolation (no residue constraint)
        print("  model P(j|checked), j=1..4:", ", ".join(f"{mp[j]:.3e}" for j in range(1, 5)))

if __name__ == "__main__":
    main(sys.argv[1:])
