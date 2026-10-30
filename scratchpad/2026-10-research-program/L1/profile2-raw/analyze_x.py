#!/usr/bin/env python3
"""Lever experiments (knob binary 455d4c0): python3 analyze_x.py DIR. x14_{ctl,slots32,slots8,ept1}_r{1,2}, x16_{ctl,ept1}_r{1,2}, *_prof_r1."""
import re, sys, glob, collections, statistics
D = sys.argv[1]
STARTS = {58: 104400216587923470200, 60: 1366406074057412100454, 62: 7997740455941656911841, 64: 41242006262957161709568}
def kvs(line): return {k: float(v) for k, v in re.findall(r"(\w+)=([0-9][0-9.e+-]*)", line)}
def tput(path):
    out = {}
    for line in open(path):
        if "JOIN THROUGHPUT" in line:
            r = kvs(line[line.index("JOIN THROUGHPUT"):]); out[int(r["base"])] = r
    return out
def prof(path):
    P = collections.defaultdict(list)
    for line in open(path):
        if "GPU_PROFILE" not in line: continue
        r = kvs(line[line.index("GPU_PROFILE"):])
        st = int(re.search(r"start=(\d+)", line).group(1))
        if st < STARTS[int(r["base"])]: continue
        P[int(r["base"])].append(r)
    return P
for size in ["x14", "x16", "y16"]:
    cfgs = sorted({re.sub(r"_r\d+\.log$", "", p.split("/")[-1])[len(size) + 1:] for p in glob.glob(f"{D}/{size}_*_r*.log") if "_prof_" not in p})
    if not cfgs: continue
    T = {c: [tput(p) for p in sorted(glob.glob(f"{D}/{size}_{c}_r*.log"))] for c in cfgs}
    bases = sorted({b for c in cfgs for t in T[c] for b in t})
    print(f"\n### {size}: device s/field (unprofiled), rounds and median; ratio against ctl\n")
    print("| base | " + " | ".join(cfgs) + " | " + " | ".join(f"{c} vs ctl" for c in cfgs if c != "ctl") + " | batches (" + ", ".join(cfgs) + ") | survivors equal |")
    print("|---|" + "---|" * (2 * len(cfgs) - 1) + "---|---|")
    for b in bases:
        med = {c: statistics.median([t[b]["device"] for t in T[c] if b in t]) for c in cfgs}
        cells = [f"{med[c]:.3f} (" + ", ".join("%.3f" % t[b]["device"] for t in T[c] if b in t) + ")" for c in cfgs]
        rat = [f"{med[c]/med['ctl']:.3f}" for c in cfgs if c != "ctl"]
        bat = ", ".join(f"{T[c][0][b]['batches']:.0f}" for c in cfgs)
        sv = {(t[b]["survivors"], t[b]["checked"]) for c in cfgs for t in T[c] if b in t}
        print(f"| {b} | " + " | ".join(cells) + " | " + " | ".join(rat) + f" | {bat} | {'yes' if len(sv) == 1 else sv} |")
    for p in sorted(glob.glob(f"{D}/{size}_*_prof_r1.log")):
        P = prof(p)
        print(f"\n{p.split('/')[-1]} (profiled, probe excluded), mean per field:\n")
        print("| base | ept | device | top | bucket | join | check | other | pairs | padded | padded/pairs | survivors |")
        print("|---|---|---|---|---|---|---|---|---|---|---|---|")
        for b in sorted(P):
            rs = P[b]; m = lambda k: sum(r[k] for r in rs) / len(rs)
            oth = m("upload") + m("inputs") + m("read") + m("unattributed")
            print(f"| {b} | {m('ept'):.0f} | {m('device_wall')-m('probe'):.3f} | {m('top'):.3f} | {m('bucket'):.3f} | {m('join'):.3f} | {m('check'):.3f} | {oth:.3f} | {m('pairs'):.4g} | {m('padded_pairs'):.4g} | {m('padded_pairs')/m('pairs'):.2f} | {m('survivors'):.4g} |")
