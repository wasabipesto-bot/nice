#!/usr/bin/env python3
"""L30 tables: python3 analyze.py DIR (box logs). Run names: NAME = {st,pf,c0,ab<xm>}_e1x_b<base>[_r<k>|_p<k>]."""
import re, sys, glob, os, statistics as S
D = sys.argv[1]
STARTS = {60: 1366406074057412100454, 62: 7997740455941656911841, 64: 41242006262957161709568}

def kvs(line):
    return {k: float(v) for k, v in re.findall(r"(\w+)=([0-9][0-9.e+-]*)", line)}

def parse(path):
    rows, tp, ov, st = [], None, None, None
    for line in open(path):
        if "GPU_PROFILE base=" in line:
            line = line[line.index("GPU_PROFILE"):]
            r = kvs(line); s = int(re.search(r"start=(\d+)", line).group(1))
            if s >= STARTS[int(r["base"])]: rows.append(r)
        elif "JOIN THROUGHPUT" in line:
            tp = kvs(line[line.index("JOIN THROUGHPUT"):])
        elif "EXP_OVERRAN" in line and "base=" in line:
            ov = kvs(line[line.index("EXP_OVERRAN"):])
        elif "EXP_L30 xm=" in line and "stats=" in line:
            st = [int(x) for x in re.search(r"stats=\[([0-9,]*)\]", line).group(1).split(",")]
    return rows, tp, ov, st

def clock(path):
    smi = path[:-4] + ".smi"; c = []
    if os.path.exists(smi):
        for line in open(smi):
            f = [x.strip() for x in line.split(",")]
            try:
                if len(f) >= 8 and float(f[6].split()[0]) >= 90: c.append(float(f[1].split()[0]))
            except ValueError: pass
    return sum(c) / len(c) if c else float("nan")

runs = {}
for p in sorted(glob.glob(f"{D}/*.log")):
    n = os.path.basename(p)[:-4]
    if n.startswith(("smoke", "build", "dense", "setup")): continue
    rows, tp, ov, st = parse(p)
    if tp is None: continue
    runs[n] = dict(rows=rows, tp=tp, ov=ov, st=st, mhz=clock(p))

print("== runs: device s/field (unprofiled harness value), survivors, checked, overran, clock")
for n, r in runs.items():
    tp = r["tp"]; ov = r["ov"] or {}
    j = sum(x["join"] for x in r["rows"]) / max(1, len(r["rows"])) if r["rows"] else float("nan")
    ch = sum(x["check"] for x in r["rows"]) / max(1, len(r["rows"])) if r["rows"] else float("nan")
    print(f"{n:22s} device={tp['device']:8.3f} join(prof)={j:8.3f} check(prof)={ch:7.3f} surv={int(tp['survivors'])} checked={int(tp['checked'])} overran={int(ov.get('overran', -1))} MHz={r['mhz']:.0f}")

print("\n== stats (xm=1)")
names = ["AND surv (staged)", "overran", "main mid_pass", "pos k only (fine)", "pos k n2 only", "pos k,k+1 fine", "pos k..k+2 fine",
         "floor>=k2", "floor>=k2+1", "floor==k+1", "pos k main rule", "main + pos k+2", "walk rounds (plane)", "flush calls", "flush rounds", "dummy"]
for n, r in runs.items():
    st = r["st"]
    if not st or not any(st[2:]): continue
    st = list(st); st[0] = int(r["tp"]["survivors"]); st[1] = int((r["ov"] or {}).get("overran", 0))
    tot = st[0]
    print(f"-- {n}: staged AND survivors {tot:,}")
    for i in range(1, 16):
        extra = ""
        if 2 <= i <= 11: extra = f"  {st[i]/tot:7.4f} of staged" + (f", {st[i]/st[2]:.4f} of main's list" if i in (6, 11) else "")
        if i == 12: extra = f"  survivors per plane-round {tot/st[i]:.2f}"
        if i == 14: extra = f"  staged per flush {tot/max(1,st[13]):.1f}, per round {tot/max(1,st[14]):.1f} (of 256)"
        print(f"   [{i:2d}] {names[i]:22s} {st[i]:>16,}{extra}")

print("\n== profiled phases per field (mean over fields; s)")
PH = ["upload", "inputs", "top", "bucket", "join", "check", "read", "probe", "unattributed"]
for n, r in runs.items():
    if not r["rows"]: continue
    m = {p: sum(x[p] for x in r["rows"]) / len(r["rows"]) for p in PH}
    tot = sum(m[p] for p in PH if p != "probe")
    print(f"{n:22s} total(excl probe)={tot:7.3f} " + " ".join(f"{p}={m[p]:.3f}" for p in PH) + f"  join share={m['join']/tot:.3f}")

print("\n== A/B (unprofiled device s/field; clock-normalised = s * MHz/1500)")
import collections
ab = collections.defaultdict(list)
for n, r in runs.items():
    m = re.match(r"(c0|pf|base)_(e1[67]_b\d+)_r(\d+)$", n)
    if not m: continue
    kind = "c0" if m.group(1) in ("c0", "base") else "pf"
    ab[(m.group(2), kind)].append((n, r["tp"]["device"], r["mhz"]))
for key in sorted({k[0] for k in ab}):
    c = ab.get((key, "c0"), []); p = ab.get((key, "pf"), [])
    if not c or not p: continue
    mc = S.median(x[1] for x in c); mp = S.median(x[1] for x in p)
    nc = S.median(x[1] * x[2] / 1500 for x in c); npf = S.median(x[1] * x[2] / 1500 for x in p)
    print(f"{key}: control {[(x[0], round(x[1],3), round(x[2])) for x in c]}")
    print(f"{key}: walk-pf  {[(x[0], round(x[1],3), round(x[2])) for x in p]}")
    print(f"{key}: median control {mc:.3f} walk-pf {mp:.3f} ratio x{mp/mc:.3f}; clock-normalised {nc:.3f} vs {npf:.3f} ratio x{npf/nc:.3f}")
