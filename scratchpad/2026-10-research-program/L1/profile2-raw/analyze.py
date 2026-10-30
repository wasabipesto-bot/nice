#!/usr/bin/env python3
"""PROFILE-2 tables: python3 analyze.py DIR  (logs e14_{prof,noprof}_r*.log, e16_*)."""
import re, sys, glob, os, collections
import numpy as np

ROOTS = {58: 4, 60: 2, 62: 2, 64: 8}
STARTS = {58: 104400216587923470200, 60: 1366406074057412100454, 62: 7997740455941656911841, 64: 41242006262957161709568}
D = sys.argv[1]

def kvs(line):
    return {k: float(v) for k, v in re.findall(r"(\w+)=([0-9][0-9.e+-]*)", line)}

def prof_rows(path):
    rows = []
    for line in open(path):
        if "GPU_PROFILE" not in line: continue
        line = line[line.index("GPU_PROFILE"):]
        r = kvs(line)
        r["start_i"] = int(re.search(r"start=(\d+)", line).group(1))
        b = int(r["base"])
        if r["start_i"] < STARTS[b]:  # the warm-up field
            continue
        rows.append(r)
    return rows

def tput(path):
    out, over = {}, {}
    for line in open(path):
        if "JOIN THROUGHPUT" in line:
            r = kvs(line); out[int(r["base"])] = r
        if "EXP_OVERRAN" in line:
            r = kvs(line[line.index("EXP_OVERRAN"):]); over[int(r["base"])] = r
    return out, over

OTHER = ["upload", "inputs", "read", "unattributed"]  # probe excluded: it is the profiler's own readback
def summarize(size_tag):
    profs = sorted(glob.glob(f"{D}/{size_tag}_prof_r*.log"))
    noprofs = sorted(glob.glob(f"{D}/{size_tag}_noprof_r*.log"))
    P = collections.defaultdict(list)
    for p in profs:
        for r in prof_rows(p): P[int(r["base"])].append(r)
    NP = collections.defaultdict(list); OV = collections.defaultdict(list); PT = collections.defaultdict(list)
    for p in noprofs:
        t, o = tput(p)
        for b in t: NP[b].append(t[b])
        for b in o: OV[b].append(o[b])
    for p in profs:
        t, o = tput(p)
        for b in t: PT[b].append(t[b])
        for b in o: OV[b].append(o[b])
    return P, NP, PT, OV

def mean(xs): return sum(xs) / len(xs)

def tables(size_tag, label):
    P, NP, PT, OV = summarize(size_tag)
    print(f"\n### {label}\n")
    print(f"Profiled fields per base: {', '.join(f'b{b} {len(P[b])}' for b in sorted(P))}; unprofiled rounds: {', '.join(f'b{b} {len(NP[b])}' for b in sorted(NP))}\n")
    print("| base | device s/field, unprofiled (rounds) | profiled (rounds) | overhead | overhead without the probe | host setup s/field (CPU, overlapped) | top | bucket | join | check | other | batches | slots |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    S = {}
    for b in sorted(P):
        rs = P[b]
        dev_raw = mean([r["device_wall"] for r in rs])
        dev = mean([r["device_wall"] - r["probe"] for r in rs])
        un = [t["device"] for t in NP[b]]; pr = [t["device"] for t in PT[b]]
        u = float(np.median(un)) if un else float("nan")
        ph = {k: mean([r[k] for r in rs]) for k in ["top", "bucket", "join", "check", "setup"] + OTHER}
        oth = sum(ph[k] for k in OTHER)
        S[b] = dict(dev=dev, un=u, ph=ph, oth=oth, rs=rs)
        print(f"| {b} | **{u:.3f}** ({', '.join(f'{x:.3f}' for x in un)}) | {dev:.3f} ({', '.join(f'{x:.3f}' for x in pr)}) | {dev_raw/u-1:+.1%} | {dev/u-1:+.1%} | {ph['setup']:.3f} | "
              f"{ph['top']/dev:.1%} | {ph['bucket']/dev:.1%} | **{ph['join']/dev:.1%}** | {ph['check']/dev:.1%} | {oth/dev:.1%} | {mean([r['batches'] for r in rs]):.0f} | {mean([r['slots'] for r in rs]):.0f} |")
    print("\nOther, split (s/field): " + "; ".join(f"b{b}: " + ", ".join(f"{k} {S[b]['ph'][k]:.3f}" for k in OTHER) for b in sorted(S)))
    print("\n| base | prefixes/field | **µs/prefix unprofiled** | profiled | top | bucket | join | check | other |")
    print("|---|---|---|---|---|---|---|---|---|")
    for b in sorted(S):
        rs = S[b]["rs"]; n = mean([r["ntlay"] for r in rs]); ph = S[b]["ph"]
        f = 1e6 / n
        print(f"| {b} | {n:.4g} | **{S[b]['un']*f:.3f}** | {S[b]['dev']*f:.3f} | {ph['top']*f:.3f} | {ph['bucket']*f:.3f} | {ph['join']*f:.3f} | {ph['check']*f:.3f} | {S[b]['oth']*f:.3f} |")
    print("\n| base | tops/field | tops/prefix | bpre (bottoms) per slice | listed/field | pairs/field | padded lane-pairs/field | padded/pairs | entries per probed bucket | AND survivors/field | prefilter survivors/field | AND pass/pair | prefilter keeps | overran/field (share) |")
    print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
    for b in sorted(S):
        rs = S[b]["rs"]; m = lambda k: mean([r[k] for r in rs])
        nf = len(rs) / max(len(set(r["start_i"] for r in rs)), 1)
        ov = OV.get(b, [])
        # per-run overrun / fields per run
        nfields = mean([len([1 for r in rs if True])]) if False else None
        NF = {"e14": 20, "e16": 2}[size_tag]
        print(f"| {b} | {m('tops'):.4g} | {m('tops')/m('ntlay'):.0f} | {m('nbp'):.4g} | {m('listed'):.4g} | {m('pairs'):.4g} | {m('padded_pairs'):.4g} | {m('padded_pairs')/m('pairs'):.2f} | {m('pairs')/(m('tops')*ROOTS[b]):.0f} | {m('survivors'):.4g} | {m('checked'):.4g} | {m('survivors')/m('pairs'):.2%} | {m('checked')/m('survivors'):.2%} | "
              + (", ".join(f"{o['overran']/NF:.4g} ({o['share']:.1e})" for o in ov) if ov else "n/a") + " |")
    return S

S14 = tables("e14", "1e14 fields (20 per base)")
S16 = tables("e16", "1e16 fields (2 per base)")

# ---- join fit
print("\n### Join fit\n")
rows = []
for S, tag in [(S14, "1e14"), (S16, "1e16")]:
    for b in S:
        for r in S[b]["rs"]:
            if r["join"] > 0 and r["ntlay"] > 0:
                rows.append(dict(r, tag=tag))
print(f"{len(rows)} profiled fields with a non-empty top layer")
y = np.array([r["join"] for r in rows])
cols = {"padded": lambda r: r["padded_pairs"], "pairs": lambda r: r["pairs"], "surv": lambda r: r["survivors"],
        "tops": lambda r: r["tops"], "listed": lambda r: r["listed"], "batches": lambda r: r["batches"],
        "slots_x_batches": lambda r: r["batches"] * r["slots"], "tops_x_wave": lambda r: r["tops"] * ROOTS[int(r["base"])], "work": lambda r: r["buckets"]}
units = {"padded": 1e12, "pairs": 1e12, "surv": 1e12, "tops": 1e12, "listed": 1e12, "batches": 1e6, "slots_x_batches": 1e6, "tops_x_wave": 1e12, "work": 1e9}
uname = {1e12: "ps", 1e6: "µs", 1e9: "ns"}
def fit(combo, sel, label, show=False):
    idx = [i for i, r in enumerate(rows) if sel(r)]
    M = np.array([[cols[c](rows[i]) for c in combo] for i in idx]); yy = y[idx]
    # weight by 1/y so relative error is minimised
    w = 1 / yy
    c, *_ = np.linalg.lstsq(M * w[:, None], yy * w, rcond=None)
    pred = M @ c
    rel = (pred - yy) / yy
    s = f"{label} {'+'.join(combo)}: " + ", ".join(f"{cc*units[k]:.3f} {uname[units[k]]}/{k}" for k, cc in zip(combo, c)) + f" | rms rel {np.sqrt(np.mean(rel**2)):.1%}, max |rel| {np.max(np.abs(rel)):.1%}"
    print("- " + s)
    if show:
        print("\n| base | size | field start | join s | predicted | residual | " + " | ".join(f"{k} term s" for k in combo) + " |")
        print("|---|---|---|---|---|---|" + "---|" * len(combo))
        for j, i in enumerate(idx):
            r = rows[i]
            terms = [cols[k](r) * cc for k, cc in zip(combo, c)]
            print(f"| {int(r['base'])} | {r['tag']} | {r['start_i']} | {yy[j]:.3f} | {pred[j]:.3f} | {rel[j]:+.1%} | " + " | ".join(f"{t:.3f}" for t in terms) + " |")
        print()
    return c
for combo in [("padded", "surv", "work"), ("pairs", "surv", "work"), ("padded", "surv", "tops", "work"), ("pairs", "surv", "tops", "work"), ("padded", "pairs", "surv", "tops", "work"), ("padded", "surv"), ("pairs", "surv"), ("padded", "surv", "tops"), ("padded", "pairs", "surv"), ("pairs", "surv", "tops"), ("padded", "surv", "batches"), ("padded", "surv", "tops", "batches"), ("pairs", "surv", "tops", "batches")]:
    for sel, label in [(lambda r: r["tag"] == "1e16", "1e16 only"), (lambda r: r["tag"] == "1e14", "1e14 only"), (lambda r: True, "both")]:
        fit(combo, sel, label)
print()
fit(("padded", "surv"), lambda r: r["tag"] == "1e16", "1e16 only", show=True)
fit(("padded", "surv", "tops"), lambda r: r["tag"] == "1e16", "1e16 only", show=True)
fit(("padded", "surv", "work"), lambda r: True, "both", show=True)
fit(("padded", "surv", "tops", "work"), lambda r: True, "both", show=True)

# ---- the other phases
print("\n### Other phases\n")
pcols = {"certs": lambda r: r["ntlay"] * r["partitions"], "batches": lambda r: r["batches"], "work": lambda r: r["buckets"],
         "bpre_parts": lambda r: r["nbp"] * r["partitions"] * r["slices"], "listed": lambda r: r["listed"],
         "checked": lambda r: r["checked"], "tops": lambda r: r["tops"]}
def pfit(phase, combo):
    M = np.array([[pcols[c](r) for c in combo] for r in rows]); yy = np.array([r[phase] for r in rows])
    w = 1 / yy
    c, *_ = np.linalg.lstsq(M * w[:, None], yy * w, rcond=None)
    rel = (M @ c - yy) / yy
    print(f"- {phase} ~ " + " + ".join(f"{cc*({'batches': 1e6, 'work': 1e9}.get(k, 1e12)):.3f} { {'batches': 'µs', 'work': 'ns'}.get(k, 'ps') }/{k}" for k, cc in zip(combo, c)) + f": rms rel {np.sqrt(np.mean(rel**2)):.1%}, max {np.max(np.abs(rel)):.1%}; "
          + "; ".join(f"b{int(r['base'])} {r['tag']} {cols_s}" for r, cols_s in [(rows[i], f"{yy[i]:.3f}->{(M@c)[i]:.3f}") for i in sorted({next(j for j, q in enumerate(rows) if q['base'] == bb and q['tag'] == tt) for bb in (58, 60, 62, 64) for tt in ('1e14', '1e16')})]))
    return c
pfit("top", ("certs",)); pfit("top", ("certs", "batches")); pfit("top", ("certs", "tops", "batches"))
pfit("bucket", ("bpre_parts",)); pfit("bucket", ("bpre_parts", "batches")); pfit("bucket", ("listed", "batches"))
pfit("check", ("checked",)); pfit("check", ("checked", "batches"))
pfit("bucket", ("bpre_parts", "work")); pfit("top", ("certs", "tops", "work"))

# ---- per-field fixed cost at 1e14: per base, phase = F + m * prefixes over the 20 fields
print("\n### 1e14: per-field fixed cost (intercept) and per-prefix slope, per phase, profiled (probe excluded)\n")
print("| base | phase | fixed s/field | µs per prefix | mean s/field | fixed share of the phase | r² |")
print("|---|---|---|---|---|---|---|")
for b in sorted(S14):
    rs = [r for r in S14[b]["rs"] if r["ntlay"] > 0]
    x = np.array([r["ntlay"] for r in rs])
    for ph in ["device", "top", "bucket", "join", "check", "other"]:
        if ph == "device":
            y = np.array([r["device_wall"] - r["probe"] for r in rs])
        elif ph == "other":
            y = np.array([sum(r[k] for k in OTHER) for r in rs])
        else:
            y = np.array([r[ph] for r in rs])
        A = np.vstack([np.ones_like(x), x]).T
        (F, m), *_ = np.linalg.lstsq(A, y, rcond=None)
        pred = A @ np.array([F, m]); ss = ((y - y.mean())**2).sum()
        r2 = 1 - ((y - pred)**2).sum() / ss if ss > 0 else float("nan")
        print(f"| {b} | {ph} | {F:.3f} | {m*1e6:.2f} | {y.mean():.3f} | {F/y.mean():.0%} | {r2:.2f} |")
