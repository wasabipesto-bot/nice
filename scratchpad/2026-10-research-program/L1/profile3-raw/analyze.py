#!/usr/bin/env python3
"""PROFILE-3 tables and fits: uv run --with numpy python3 analyze.py DIR
Logs: e17_b62_{prof,noprof}_r*.log, e16_b{60,62,64}_{prof,noprof}_r*.log (run.sh NAME BASE FIELDS SIZE PROF)."""
import re, sys, glob, os, collections
import numpy as np

ROOTS = {58: 4, 60: 2, 62: 2, 64: 8}
STARTS = {60: 1366406074057412100454, 62: 7997740455941656911841, 64: 41242006262957161709568}
D = sys.argv[1]
OTHER = ["upload", "inputs", "read", "unattributed"]  # probe excluded (the profiler's own readback)

def kvs(line):
    return {k: float(v) for k, v in re.findall(r"(\w+)=([0-9][0-9.e+-]*)", line)}

def parse(path):
    """GPU_PROFILE rows (measured fields only), JOIN THROUGHPUT, EXP_OVERRAN, warm-up rows."""
    rows, warm, tp, ov = [], [], None, None
    for line in open(path):
        if "GPU_PROFILE" in line:
            line = line[line.index("GPU_PROFILE"):]
            r = kvs(line)
            r["start_i"] = int(re.search(r"start=(\d+)", line).group(1))
            r["run"] = os.path.basename(path)
            (warm if r["start_i"] < STARTS[int(r["base"])] else rows).append(r)
        elif "JOIN THROUGHPUT" in line:
            tp = kvs(line[line.index("JOIN THROUGHPUT"):])
        elif "EXP_OVERRAN" in line and "base=" in line:
            ov = kvs(line[line.index("EXP_OVERRAN"):])
    return rows, warm, tp, ov


def load_clock(log_path):
    """Mean SM clock (MHz), power (W) and temperature over the run's samples at >= 90 % utilisation."""
    smi = log_path[:-4] + ".smi"
    if not os.path.exists(smi): return float("nan"), float("nan"), float("nan")
    c = []
    for line in open(smi):
        f = [x.strip() for x in line.split(",")]
        try:
            if len(f) >= 8 and float(f[6].split()[0]) >= 90: c.append((float(f[1].split()[0]), float(f[3].split()[0]), float(f[5])))
        except ValueError: pass
    if not c: return float("nan"), float("nan"), float("nan")
    return tuple(sum(x[i] for x in c) / len(c) for i in range(3))

def mean(xs): return sum(xs) / len(xs) if xs else float("nan")

groups = {}  # (size, base) -> dict
for path in sorted(glob.glob(f"{D}/e1[67]_b*_*prof_r*.log")):
    m = re.match(r"(e1[67])_b(\d+)_(prof|noprof)_r(\d+)\.log", os.path.basename(path))
    size, base, kind, rnd = m.group(1), int(m.group(2)), m.group(3), int(m.group(4))
    rows, warm, tp, ov = parse(path)
    if tp is None:
        print(f"(skipping incomplete {path})"); continue
    g = groups.setdefault((size, base), dict(P=[], NP=[], PT=[], OV=[], WARM=[]))
    if kind == "prof":
        g["P"] += rows; g["PT"].append(tp); g["WARM"] += warm
    else:
        g["NP"].append(tp)
    if ov: g["OV"].append(dict(ov, kind=kind, nf=tp["fields"]))

SIZE = {"e16": "1e16", "e17": "1e17"}
effsl = lambda r: r["buckets"] / (r["partitions"] * r["base"] * (r["base"] - 1))
S = {}
print("### 1. Device seconds per field and phase shares\n")
print("| size | base | **device s/field, unprofiled** (rounds) | profiled, probe excluded (rounds incl. probe) | overhead incl. probe | excl. probe | host setup s/field | top | bucket | **join** | check | other | slices (with prefixes) | partitions | batches | partitions/launch: mean (first plan per field) | plan MiB |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for key in sorted(groups, key=lambda k: (k[0] != "e17", k[1])):
    g = groups[key]; rs = g["P"]
    if not rs: continue
    un = [t["device"] for t in g["NP"]]; pr = [t["device"] for t in g["PT"]]
    u = float(np.median(un)) if un else float("nan")
    dev = mean([r["device_wall"] - r["probe"] for r in rs]); dev_raw = mean([r["device_wall"] for r in rs])
    ph = {k: mean([r[k] for r in rs]) for k in ["top", "bucket", "join", "check", "setup"] + OTHER}
    oth = sum(ph[k] for k in OTHER)
    S[key] = dict(dev=dev, un=u, ph=ph, oth=oth, rs=rs, g=g)
    m = lambda k: mean([r[k] for r in rs])
    print(f"| {SIZE[key[0]]} | {key[1]} | **{u:.2f}** ({', '.join(f'{x:.2f}' for x in un)}) | {dev:.2f} ({', '.join(f'{x:.2f}' for x in pr)}) | {dev_raw/u-1:+.1%} | {dev/u-1:+.1%} | {ph['setup']:.2f} | "
          f"{ph['top']/dev:.1%} | {ph['bucket']/dev:.1%} | **{ph['join']/dev:.1%}** | {ph['check']/dev:.1%} | {oth/dev:.1%} | {m('slices'):.0f} ({mean([effsl(r) for r in rs]):.0f}) | {m('partitions'):.0f} | {m('batches'):.0f} | {mean([r['partitions']*effsl(r) for r in rs])/m('batches'):.2f} ({', '.join(sorted(set(f'{r[chr(115)+chr(108)+chr(111)+chr(116)+chr(115)]:.0f}' for r in rs)))}) | {max(t['plan_mib'] for t in g['PT']+g['NP']):.0f} |")
print("\nOther, split (s/field): " + "; ".join(f"{SIZE[k[0]]} b{k[1]}: " + ", ".join(f"{o} {S[k]['ph'][o]:.3f}" for o in OTHER) for k in S))
print("\nSM clock / power / temperature under load per run: " + "; ".join(f"{os.path.basename(p)[:-4]} {load_clock(p)[0]:.0f} MHz {load_clock(p)[1]:.0f} W {load_clock(p)[2]:.0f} C" for p in sorted(glob.glob(f"{D}/e1[67]_*.log"))))
print("\nPer field (profiled rows):\n")
print("| size | base | run | start | ntlay | slices | batches | slots | device (probe excl.) | top | bucket | join | check | upload | inputs | setup |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for k in S:
    for r in S[k]["rs"]:
        print(f"| {SIZE[k[0]]} | {k[1]} | {r['run']} | {r['start_i']} | {r['ntlay']:.0f} | {r['slices']:.0f} | {r['batches']:.0f} | {r['slots']:.0f} | {r['device_wall']-r['probe']:.2f} | {r['top']:.2f} | {r['bucket']:.3f} | {r['join']:.2f} | {r['check']:.2f} | {r['upload']:.3f} | {r['inputs']:.3f} | {r['setup']:.2f} |")
print("\nUnprofiled per run (JOIN THROUGHPUT): " + "; ".join(f"{SIZE[k[0]]} b{k[1]}: " + ", ".join(f"dev {t['device']:.2f} batches {t['batches']:.0f} slots {t['slots']:.0f} plan {t['plan_mib']:.0f} MiB surv {t['survivors']:.6g} checked {t['checked']:.6g}" for t in S[k]['g']['NP']) for k in S))
print("Profiled per run (JOIN THROUGHPUT): " + "; ".join(f"{SIZE[k[0]]} b{k[1]}: " + ", ".join(f"dev {t['device']:.2f} surv {t['survivors']:.6g} checked {t['checked']:.6g}" for t in S[k]['g']['PT']) for k in S))

print("\n### 2. µs per top-layer prefix\n")
print("| size | base | prefixes/field | **µs/prefix unprofiled** | profiled | top | bucket | join | check | other |")
print("|---|---|---|---|---|---|---|---|---|---|")
for k in S:
    rs = S[k]["rs"]; n = mean([r["ntlay"] for r in rs]); ph = S[k]["ph"]; f = 1e6 / n
    print(f"| {SIZE[k[0]]} | {k[1]} | {n:.4g} | **{S[k]['un']*f:.3f}** | {S[k]['dev']*f:.3f} | {ph['top']*f:.3f} | {ph['bucket']*f:.3f} | {ph['join']*f:.3f} | {ph['check']*f:.3f} | {S[k]['oth']*f:.3f} |")

print("\n### 3. Counts per field\n")
effsl = lambda r: r["buckets"] / (r["partitions"] * r["base"] * (r["base"] - 1))
print("| size | base | tops/field | tops/prefix | bpre (bottoms) per slice | listed/field | AND pairs/field | wave-padded lane-pairs/field | padded/pairs | entries per probed bucket | work items | AND survivors/field | prefilter survivors (full checks)/field | AND pass/pair | prefilter keeps | overran/field (share), per run |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for k in S:
    rs = S[k]["rs"]; m = lambda q: mean([r[q] for r in rs])
    ovs = S[k]["g"]["OV"]
    print(f"| {SIZE[k[0]]} | {k[1]} | {m('tops'):.4g} | {m('tops')/m('ntlay'):.0f} | {m('nbp')/mean([effsl(r) for r in rs]):.4g} | {m('listed'):.4g} | {m('pairs'):.4g} | {m('padded_pairs'):.4g} | {m('padded_pairs')/m('pairs'):.2f} | {m('pairs')/(m('tops')*ROOTS[k[1]]):.0f} | {m('buckets'):.4g} | {m('survivors'):.4g} | {m('checked'):.4g} | {m('survivors')/m('pairs'):.2%} | {m('checked')/m('survivors'):.2%} | "
          + ", ".join(f"{o['overran']/o['nf']:.3g} ({o['share']:.1e}, {o['kind']})" for o in ovs) + " |")

# ---------------- join fit
print("\n### 4. Join fits (weighted least squares on relative error)\n")
rows = [dict(r, tag=SIZE[k[0]]) for k in S for r in S[k]["rs"] if r["join"] > 0]
print(f"{len(rows)} profiled field-runs ({len(set((r['base'], r['start_i'], r['tag']) for r in rows))} distinct fields)")
cols = {"padded": lambda r: r["padded_pairs"], "pairs": lambda r: r["pairs"], "empty": lambda r: r["padded_pairs"] - r["pairs"],
        "surv": lambda r: r["survivors"], "tops": lambda r: r["tops"], "work": lambda r: r["buckets"], "batches": lambda r: r["batches"]}
units = {"padded": 1e12, "pairs": 1e12, "empty": 1e12, "surv": 1e12, "tops": 1e12, "work": 1e9, "batches": 1e6}
uname = {1e12: "ps", 1e9: "ns", 1e6: "µs"}
def fit(combo, sel, label, show=False, rows=rows, y=None, quiet=False):
    idx = [i for i, r in enumerate(rows) if sel(r)]
    yy = np.array([rows[i]["join"] if y is None else y(rows[i]) for i in idx])
    M = np.array([[cols[c](rows[i]) for c in combo] for i in idx])
    w = 1 / yy
    c, *_ = np.linalg.lstsq(M * w[:, None], yy * w, rcond=None)
    allM = np.array([[cols[q](r) for q in combo] for r in rows]); ally = np.array([r["join"] if y is None else y(r) for r in rows])
    rel_all = (allM @ c - ally) / ally
    rel = (M @ c - yy) / yy
    s = f"{label} {'+'.join(combo)}: " + ", ".join(f"{cc*units[k]:.3f} {uname[units[k]]}/{k}" for k, cc in zip(combo, c)) + f" | in-fit rms {np.sqrt(np.mean(rel**2)):.1%}, max {np.max(np.abs(rel)):.1%}"
    oos = [i for i in range(len(rows)) if i not in idx]
    if oos:
        s += " | out of fit: " + ", ".join(f"{rows[i]['tag']} b{int(rows[i]['base'])} {rel_all[i]:+.1%}" for i in oos)
    if not quiet: print("- " + s)
    if show:
        print("\n| base | size | run | join s | predicted | residual | " + " | ".join(f"{k} term s (share)" for k in combo) + " |")
        print("|---|---|---|---|---|---|" + "---|" * len(combo))
        for i, r in enumerate(rows):
            terms = [cols[k](r) * cc for k, cc in zip(combo, c)]
            print(f"| {int(r['base'])} | {r['tag']} | {r['run']} | {ally[i]:.3f} | {(allM@c)[i]:.3f} | {rel_all[i]:+.1%} | " + " | ".join(f"{t:.3f} ({t/ally[i]:.0%})" for t in terms) + " |")
        print()
    return c
e16 = lambda r: r["tag"] == "1e16"; allr = lambda r: True
for combo in [("padded", "surv"), ("pairs", "surv"), ("padded", "surv", "tops"), ("pairs", "surv", "tops"), ("pairs", "empty", "surv"),
              ("pairs", "empty", "surv", "tops"), ("padded", "surv", "work"), ("padded", "surv", "tops", "work"), ("pairs", "surv", "tops", "work")]:
    fit(combo, e16, "1e16 only"); fit(combo, allr, "1e16+1e17")
print()
print("**Two-term form, all fields:**"); fit(("padded", "surv"), allr, "1e16+1e17", show=True)
print("**With tops, all fields:**"); fit(("padded", "surv", "tops"), allr, "1e16+1e17", show=True)
print("**pairs + empty + surv + tops, all fields:**"); fit(("pairs", "empty", "surv", "tops"), allr, "1e16+1e17", show=True)

# ---------------- other phases
print("\n### 5. Other phases per unit\n")
print("| size | base | top: ps per (prefix, partition) | top: ns per certified top | bucket: ps per (bpre, partition) | check: ps per full check | upload s | inputs µs/batch | per-slice fixed (upload+bucket) s |")
print("|---|---|---|---|---|---|---|---|---|")
for k in S:
    rs = S[k]["rs"]; m = lambda q: mean([r[q] for r in rs])
    print(f"| {SIZE[k[0]]} | {k[1]} | {m('top')/(m('ntlay')*m('partitions'))*1e12:.1f} | {m('top')/m('tops')*1e9:.2f} | {m('bucket')/(m('nbp')*m('partitions'))*1e12:.1f} | {m('check')/m('checked')*1e12:.1f} | {m('upload'):.3f} | {m('inputs')/m('batches')*1e6:.0f} | {(m('upload')+m('bucket'))/m('slices'):.3f} |")

# ---------------- per-phase fits with a per-batch term, including the 1e14 warm-up fields
print("\n### 6. Per-phase fits with a per-batch term (1e16 + 1e17 profiled fields; the 1e14 warm-ups hold the kernels' JIT compile, so they are left out)\n")
W = [dict(r, tag="1e14") for k in S for r in S[k]["g"]["WARM"]]
R2 = [dict(r, tag=SIZE[k[0]]) for k in S for r in S[k]["rs"]]
pc = {"certs": lambda r: r["ntlay"] * r["partitions"], "batches": lambda r: r["batches"], "bpre_parts": lambda r: r["nbp"] * r["partitions"],
      "checked": lambda r: r["checked"], "tops": lambda r: r["tops"], "work": lambda r: r["buckets"], "slices": lambda r: effsl(r),
      "slots_batches": lambda r: r["partitions"] * effsl(r)}
pu = {"certs": (1e12, "ps"), "batches": (1e6, "µs"), "bpre_parts": (1e12, "ps"), "checked": (1e12, "ps"), "tops": (1e12, "ps"), "work": (1e9, "ns"), "slices": (1, "s"), "slots_batches": (1e6, "µs")}
PF = {}
def pfit(phase, combo, sel=lambda r: True, label="all"):
    rr = [r for r in R2 if sel(r)]
    M = np.array([[pc[c](r) for c in combo] for r in rr]); yy = np.array([r[phase] for r in rr])
    w = 1 / yy
    c, *_ = np.linalg.lstsq(M * w[:, None], yy * w, rcond=None)
    rel = (M @ c - yy) / yy
    print(f"- {phase} ({label}, {len(rr)} rows) ~ " + " + ".join(f"{cc*pu[k][0]:.3f} {pu[k][1]}/{k}" for k, cc in zip(combo, c)) + f": rms {np.sqrt(np.mean(rel**2)):.1%}, max {np.max(np.abs(rel)):.1%}")
    PF[(phase, combo, label)] = c
    return c
pfit("top", ("certs",)); pfit("top", ("certs", "batches")); pfit("top", ("certs", "tops", "batches"))
pfit("bucket", ("bpre_parts",)); pfit("bucket", ("bpre_parts", "batches")); pfit("bucket", ("batches",))
pfit("check", ("checked",)); pfit("check", ("checked", "batches"))
pfit("inputs", ("batches",)); pfit("upload", ("slices",)); pfit("unattributed", ("batches",))
for ph in ["top", "bucket", "check", "join", "inputs"]:
    print(f"  {ph} per batch (ms): " + ", ".join(f"{r['tag']} b{int(r['base'])} {r[ph]/r['batches']*1e3:.2f}" for r in R2))

# ---------------- decomposition of each (size, base) field's device time
print("\n### 7. Where the time goes, per size and base (model terms on the profiled means; shares of profiled time, probe excluded)\n")
JF = fit(("pairs", "empty", "surv", "tops"), allr, "decomposition fit", quiet=True)
JF3 = fit(("padded", "surv", "tops"), allr, "decomposition fit (3-term)", quiet=True)
CF = PF[("check", ("checked", "batches"), "all")]
BF = PF[("bucket", ("bpre_parts", "batches"), "all")]
print(f"Join terms: {JF[0]*1e12:.3f} ps per real lane-pair, {JF[1]*1e12:.3f} ps per empty (padding) lane-pair, {JF[2]*1e12:.1f} ps per AND survivor, {JF[3]*1e12:.0f} ps per top. "
      f"Check: {CF[0]*1e12:.1f} ps per full check + {CF[1]*1e6:.0f} µs per batch. Bucket: {BF[0]*1e12:.0f} ps per (bpre, partition) + {BF[1]*1e6:.0f} µs per batch.\n")
print("| size | base | device s (profiled, probe excl.) | unprofiled s | top cert. | AND lanes (real pairs) | padding (empty lanes) | survivor handling | per-top chunk cost | join residual | check kernel | of which per-batch part | overrun's extra checks | bucket | upload | inputs+read+unattributed |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
DEC = {}
for k in S:
    rs = S[k]["rs"]; m = lambda q: mean([r[q] for r in rs]); ph = S[k]["ph"]
    tot = S[k]["dev"]
    pairs, empty, surv, tops = m("pairs"), m("padded_pairs") - m("pairs"), m("survivors"), m("tops")
    jt = [JF[0] * pairs, JF[1] * empty, JF[2] * surv, JF[3] * tops]
    jres = ph["join"] - sum(jt)
    ovs = S[k]["g"]["OV"]; ov_pf = mean([o["overran"] / o["nf"] for o in ovs])
    keep = m("checked") / m("survivors")
    pc_cost = ph["check"] / m("checked")
    ov_cost = ov_pf * (1 - keep) * pc_cost
    chk_batch = min(CF[1] * m("batches"), ph["check"])
    misc = ph["inputs"] + ph["read"] + ph["unattributed"]
    parts = dict(top=ph["top"], lanes=jt[0], pad=jt[1], surv=jt[2], tops=jt[3], jres=jres, check=ph["check"], bucket=ph["bucket"], upload=ph["upload"], misc=misc)
    DEC[k] = dict(parts, tot=tot, un=S[k]["un"], chk_batch=chk_batch, ov_cost=ov_cost, batches=m("batches"))
    f = lambda x: f"{x:.2f} s ({x/tot:.1%})"
    print(f"| {SIZE[k[0]]} | {k[1]} | {tot:.2f} | {S[k]['un']:.2f} | {f(ph['top'])} | {f(jt[0])} | {f(jt[1])} | {f(jt[2])} | {f(jt[3])} | {f(jres)} | {f(ph['check'])} | {f(chk_batch)} | {ov_cost:.3f} s ({ov_cost/tot:.3%}) | {f(ph['bucket'])} | {f(ph['upload'])} | {f(misc)} |")
print("\nSame with the 3-term join fit (padded + surv + tops): " + "; ".join(
    f"{SIZE[k[0]]} b{k[1]}: padded {JF3[0]*mean([r['padded_pairs'] for r in S[k]['rs']])/S[k]['dev']:.1%}, surv {JF3[1]*mean([r['survivors'] for r in S[k]['rs']])/S[k]['dev']:.1%}, tops {JF3[2]*mean([r['tops'] for r in S[k]['rs']])/S[k]['dev']:.1%}" for k in S))

# ---------------- the frontier field and the lever runs (b62 1e17)
print("\n### 8. Frontier field and lever runs at b62 1e17\n")
print("| run | binary | knobs | device s | SM MHz under load | device s × MHz / 1500 | host setup s | slices | batches | first-plan partitions/launch | plan MiB | AND survivors | full checks | overran | survivors + overran |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
ctl = None
for path in sorted(glob.glob(f"{D}/e17_b62_noprof_r*.log")) + sorted(glob.glob(f"{D}/x17_*.log")) + sorted(glob.glob(f"{D}/e17f_*.log")):
    head = open(path).readline()
    tp = ov = None; gp = []
    for line in open(path):
        if "JOIN THROUGHPUT" in line: tp = kvs(line[line.index("JOIN THROUGHPUT"):])
        if "EXP_OVERRAN" in line and "base=" in line: ov = kvs(line[line.index("EXP_OVERRAN"):])
        if "GPU_PROFILE" in line and "size=100000000000000000" in line: gp.append(kvs(line[line.index("GPU_PROFILE"):]))
    if tp is None: print(f"| {os.path.basename(path)} | incomplete |"); continue
    name = os.path.basename(path)[:-4]
    knobs = re.search(r"exp_env=(.*?) commit", head).group(1).strip() or "unset"
    md5 = re.search(r"bin_md5=(\w+)", head).group(1)
    if name == "x17_ctl_r1": ctl = tp["device"]
    sl = f"{gp[0]['slices']:.0f}" if gp else "-"
    mhz = load_clock(path)[0]
    print(f"| {name} | {md5} | {knobs} | {tp['device']:.2f} | {mhz:.0f} | {tp['device']*mhz/1500:.2f} | {tp['setup']:.2f} | {sl} | {tp['batches']:.0f} | {tp['slots']:.0f} | {tp['plan_mib']:.0f} | {tp['survivors']:.13g} | {tp['checked']:.11g} | {ov['overran']:.4g} | {tp['survivors']+ov['overran']:.13g} |")
    for g in gp:
        dev = g["device_wall"] - g["probe"]
        print(f"|  ↳ profile | | | {dev:.2f} (probe excl.) | | | | {g['slices']:.0f} | {g['batches']:.0f} | | | ntlay {g['ntlay']:.0f}, tops {g['tops']:.4g}, pairs {g['pairs']:.4g}, padded {g['padded_pairs']:.4g} | top {g['top']:.2f}, bucket {g['bucket']:.2f}, join {g['join']:.2f}, check {g['check']:.2f}, upload {g['upload']:.2f}, inputs {g['inputs']:.2f}, read {g['read']:.2f}, unattr. {g['unattributed']:.2f} | work items {g['buckets']:.4g} | |")

# ---------------- lever summary: clock-normalised medians per configuration
print("\n### 9. Lever summary (unprofiled, device s × SM MHz / 1500; controls = knob binary unset and the main runs' unprofiled 1e17 rounds)\n")
cfg = collections.defaultdict(list)
for path in sorted(glob.glob(f"{D}/x17_*.log")) + sorted(glob.glob(f"{D}/e17_b62_noprof_r*.log")):
    name = os.path.basename(path)[:-4]
    if "_prof_" in name: continue
    tp = None
    for line in open(path):
        if "JOIN THROUGHPUT" in line: tp = kvs(line[line.index("JOIN THROUGHPUT"):])
    if tp is None: continue
    key = "control" if (name.startswith("e17_") or "_ctl_" in name) else re.sub(r"^x17_|_r\d+$", "", name)
    cfg[key].append((name, tp["device"] * load_clock(path)[0] / 1500, tp["device"], tp["batches"]))
c0 = float(np.median([x[1] for x in cfg["control"]])) if cfg["control"] else float("nan")
print("| configuration | runs (normalised s) | median | vs control median | raw device s | batches |")
print("|---|---|---|---|---|---|")
for k in ["control"] + sorted(x for x in cfg if x != "control"):
    xs = cfg[k]; med = float(np.median([x[1] for x in xs]))
    print(f"| {k} | " + ", ".join(f"{x[0]} {x[1]:.1f}" for x in xs) + f" | {med:.1f} | ×{med/c0:.3f} | " + ", ".join(f"{x[2]:.1f}" for x in xs) + f" | {xs[0][3]:.0f} |")
