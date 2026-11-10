#!/usr/bin/env python3
"""Summarise N1 UNIT lines (cpu_join::n1::n1_counts_and_timing) into per-admissible-n
counts and CPU seconds. Usage: analyze.py raw/*.log"""
import json, sys, statistics as st
from collections import defaultdict

MC = {  # mc_b*.txt (fresh-eyes), per admissible n
    60: {"f3k6": dict(PT=0.1041, PB=0.25421, pairs=2.711e-2, pairs_m9=1.057e-2, pairs_m10=1.679e-2, S=5.067e-4),
         "f4k9": dict(PT=0.1828, PB=0.04817, pairs=9.067e-3, S=2.667e-5)},
    62: {"f3k6": dict(PT=0.0696, PB=0.30505, pairs=2.167e-2, pairs_m9=6.317e-3, pairs_m10=1.015e-2, S=2.033e-4),
         "f4k9": dict(PT=0.1271, PB=0.06084, pairs=7.983e-3, S=2.667e-5)},
    64: {"f3k6": dict(PT=0.0621, PB=0.29035, pairs=1.549e-2, pairs_m9=4.453e-3, pairs_m10=7.200e-3, S=2.067e-4),
         "f4k9": dict(PT=0.1134, PB=0.06224, pairs=5.720e-3, S=6.667e-6)},
}

rows = []
for path in sys.argv[1:]:
    for line in open(path):
        if "N1 UNIT " in line:
            rows.append(json.loads(line.split("N1 UNIT ", 1)[1]))

groups = defaultdict(list)
for r in rows:
    groups[(r["base"], r["shape"])].append(r)

def jp_fkp(jp, L):
    import re
    t, k, p = map(int, re.findall(r"\d+", jp))
    return L - t, k, p

L = {60: 12, 62: 13, 64: 13, 54: 11, 50: 10}
out = {}
for (b, shape), rs in sorted(groups.items()):
    r0 = [r for r in rs if r["round"] == 0]
    f0, k, p = jp_fkp(rs[0]["jp"], L[b])
    adm = sum(r["admissible"] for r in r0)
    # all n (not only admissible) per unit: admissible * (b-1)/roots
    roots = {60: 2, 62: 2, 64: 8, 54: 2, 50: 8}[b]
    alln = adm * (b - 1) / roots
    c = lambda key: sum(r[key] for r in r0)
    w = b ** f0
    keyspace = b ** (k - f0 - p)  # 1 or b (key level)
    counts = {
        "units": len(r0),
        "top_tests": c("top_tests") / adm,
        "tops": c("tops") / adm,
        "P_T": c("tops") * w / alln,
        "bottom_cands": c("bottom_cands") / adm,
        "bottoms_ext": c("bottoms_ext") / adm,
        "bottoms": c("bottoms") / adm,
        "P_B(listed)": c("bottoms") / (len(r0) * b ** (k - p)),
        "ands": c("ands") / adm,
        "survivors": c("survivors") / adm,
        "checked": c("checked") / adm,
        "hits": c("hits"),
        "survivor_events": c("survivors"),
    }
    rounds = sorted(set(r["round"] for r in rs))
    per_round = {}
    for rd in rounds:
        rr = [r for r in rs if r["round"] == rd]
        a = sum(r["admissible"] for r in rr)
        s = lambda key: sum(r[key] for r in rr) / a
        full = s("t_total_full")
        split = all(r["t_total_nocheck"] > 0 for r in rr)
        nan = float("nan")
        scan_and = s("t_scan_andonly") if split else nan
        pre = s("t_scan_nocheck") - s("t_scan_andonly") if split else nan
        chk = s("t_scan_full") - s("t_scan_nocheck") if split else nan
        per_round[rd] = dict(total=full, tops=s("t_tops"), extend=s("t_extend"), list=s("t_list"),
                             scan=s("t_scan_full"), and_=scan_and, prefilter=pre, check=chk,
                             other=full - s("t_tops") - s("t_extend") - s("t_list") - s("t_scan_full"),
                             units=len(rr))
    out[(b, shape)] = dict(per_unit=[r["t_total_full"] / r["admissible"] for r in rs], jp=rs[0]["jp"], f0=f0, k=k, p=p, counts=counts, per_round=per_round,
                           setup=rs[0]["setup_s"], adm_unit=r0[0]["admissible"])

def med(xs):
    return st.median(xs)

for (b, shape), o in out.items():
    c = o["counts"]
    print(f"\n== b{b} {shape} {o['jp']} (f0 {o['f0']}, k {o['k']}, p {o['p']}); units {c['units']}, "
          f"admissible/unit {o['adm_unit']:.4e}, setup {o['setup']:.2f}s")
    print("  per admissible n: top tests %.3e  tops %.3e  (P_T %.4f)  bottom cands %.3e  ext %.3e  bottoms %.3e (P_B %.4f)"
          % (c["top_tests"], c["tops"], c["P_T"], c["bottom_cands"], c["bottoms_ext"], c["bottoms"], c["P_B(listed)"]))
    print("                    ANDs %.3e  AND survivors %.3e (%d events)  prefilter survivors = full checks %.3e  hits %d"
          % (c["ands"], c["survivors"], c["survivor_events"], c["checked"], c["hits"]))
    key = "f3k6" if (o["f0"], o["k"]) == (3, 6) else ("f4k9" if (o["f0"], o["k"]) == (4, 9) else None)
    if key and b in MC:
        m = MC[b][key]
        def cmp(name, got, want):
            d = got / want - 1
            flag = "  <-- >30%" if abs(d) > 0.30 else ""
            return f"{name} {got:.3e} vs MC {want:.3e} ({d:+.0%}){flag}"
        print("   MC: " + cmp("P_T", c["P_T"], m["PT"]))
        print("       " + cmp("P_B", c["P_B(listed)"], m["PB"]))
        print("       " + cmp("pairs(no prune)", c["ands"], m["pairs"]))
        if "pairs_m9" in m:
            print("       " + cmp("pairs(prune m9)", c["ands"], m["pairs_m9"]) + "; " + cmp("m10", c["ands"], m["pairs_m10"]))
        print("       " + cmp("AND survivors", c["survivors"], m["S"]))
    pr = o["per_round"]
    tot = [v["total"] for v in pr.values()]
    print("  CPU s per admissible n (rounds: %s): median %.3e  min %.3e  max %.3e"
          % (len(tot), med(tot), min(tot), max(tot)))
    per_unit = o["per_unit"]
    if len(per_unit) > 1:
        print("  per unit (all rounds): min %.3e  median %.3e  max %.3e  CV %.1f%%"
              % (min(per_unit), med(per_unit), max(per_unit), 100 * st.pstdev(per_unit) / st.mean(per_unit)))
    ph = {k2: med([v[k2] for v in pr.values()]) for k2 in ["tops", "extend", "list", "scan", "and_", "prefilter", "check", "other"]}
    T = med(tot)
    print("  phases (median, %% of total): " + "  ".join(f"{k2.rstrip('_')} {v:.2e} ({100*v/T:.0f}%)" for k2, v in ph.items()))

# ratios new/today per round
print("\n== ratios (shape / today), CPU s per admissible n, per round")
for b in sorted(set(b for b, _ in out)):
    base_keys = [sh for (bb, sh) in out if bb == b and sh.startswith("today")]
    if len(base_keys) != 1:
        continue
    t = out[(b, base_keys[0])]["per_round"]
    for (bb, shape), o in out.items():
        if bb != b or shape.startswith("today"):
            continue
        rs = [o["per_round"][r]["total"] / t[r]["total"] for r in o["per_round"] if r in t]
        if rs:
            print(f"  b{b} {shape}: ratio median {med(rs):.3f} (min {min(rs):.3f}, max {max(rs):.3f}) -> speed-up x{1/med(rs):.2f} (x{1/max(rs):.2f}-x{1/min(rs):.2f})")

# location spread of today's shape (today@x): per-location cost and counts, and the mean
print("\n== today's shape by field location (today@x), CPU s and counts per admissible n")
for b in sorted(set(b for b, _ in out)):
    locs = sorted((float(sh.split("@")[1]), o) for (bb, sh), o in out.items() if bb == b and "@" in sh)
    if not locs:
        continue
    costs = []
    for x, o in locs:
        c = o["counts"]; T = med([v["total"] for v in o["per_round"].values()])
        costs.append(T)
        print(f"  b{b} @{x:.2f}: {T:.3e} s  P_T {c['P_T']:.4f}  ANDs {c['ands']:.3e}  AND surv {c['survivors']:.3e}  checks {c['checked']:.3e}  tops {c['tops']:.3e}")
    mean = sum(costs) / len(costs)
    keys = ["P_T", "ands", "survivors", "checked", "tops", "top_tests"]
    avg = {k3: sum(o["counts"][k3] for _, o in locs) / len(locs) for k3 in keys}
    print(f"  b{b} mean over {len(locs)} locations: {mean:.3e} s; " + "  ".join(f"{k3} {v:.3e}" for k3, v in avg.items()))
    for (bb, sh), o in out.items():
        if bb == b and not sh.startswith("today"):
            T = med([v["total"] for v in o["per_round"].values()])
            print(f"    {sh}: {T:.3e} s -> ratio to the location mean {T/mean:.3f} (x{mean/T:.2f})")
