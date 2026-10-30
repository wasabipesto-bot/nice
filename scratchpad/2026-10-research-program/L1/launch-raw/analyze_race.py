#!/usr/bin/env python3
"""Sweep, counter-study and race tables: python3 analyze_race.py box/"""
import re, sys, glob, os, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else "box"
JT = re.compile(r"JOIN THROUGHPUT .*base=(\d+) .*per_field=([\d.]+) .*batches=(\d+) slots=(\d+) plan_mib=(\d+) .*survivors=(\d+) checked=(\d+) found=(\d+)")
FL = re.compile(r"EXP_FLUSH base=(\d+) flush_sync=(\d) planes_entered=(\d+) planes_expected=(\d+)")
OV = re.compile(r"EXP_OVERRAN base=(\d+) flush_at=\d+ overran=(\d+)")

def parse(path):
    out = {}
    for line in open(path, errors="replace"):
        for m in FL.finditer(line):
            out.setdefault(int(m.group(1)), {})["d"] = int(m.group(3)) - int(m.group(4))
        for m in OV.finditer(line):
            out.setdefault(int(m.group(1)), {})["ov"] = int(m.group(2))
        m = JT.search(line)
        if m:
            o = out.setdefault(int(m.group(1)), {})
            o.update(pf=float(m.group(2)), batches=int(m.group(3)), slots=int(m.group(4)), mib=int(m.group(5)),
                     surv=int(m.group(6)), chk=int(m.group(7)), found=int(m.group(8)))
    return out

# Main's exact counts at 1e14 (identical in every main run).
MAIN = {58: (65276511454, 3681958634), 60: (45679552353, 3059971138), 62: (24394574150, 1494977611), 64: (65747036999, 3999993450)}
PREF = 0.94  # share of overrun survivors that the prefilter would have dropped (measured Δchk/−Δsurv on clean runs)

def excess(b, r):
    """Full checks beyond what the overrun explains: chk − main_chk − (main_surv − surv)."""
    ms, mc = MAIN[b]
    return r["chk"] - mc - (ms - r["surv"])

def sweep():
    print("\n### Sweep: partitions per launch, 1e14, 20 fields per base, this card's budget (4 GiB), experiment binary, no barrier\n")
    print("| cap | b58 s/field | b60 | b62 | b64 | planes mismatch (d) per base, r1; r2 | full checks beyond the overrun, r1; r2 |")
    print("|---|---|---|---|---|---|---|")
    for s in ("16", "32", "64", "96", "128", "max"):
        runs = [parse(f"{D}/sweep_s{s}_r{r}.log") for r in (1, 2) if os.path.exists(f"{D}/sweep_s{s}_r{r}.log")]
        cells = []
        for b in (58, 60, 62, 64):
            xs = [r[b]["pf"] for r in runs if b in r and "pf" in r[b]]
            sl = sorted({r[b]["slots"] for r in runs if b in r and "slots" in r[b]})
            cells.append(f"{st.median(xs):.3f} ({', '.join(f'{x:.3f}' for x in xs)}; {'/'.join(map(str, sl))})" if xs else "-")
        ds = "; ".join(" ".join(f"{r[b].get('d', '?')}" for b in (58, 60, 62, 64)) for r in runs)
        ex = "; ".join(" ".join(f"{excess(b, r[b]):+d}" for b in (58, 60, 62, 64) if "chk" in r[b]) for r in runs)
        print(f"| {s} | " + " | ".join(cells) + f" | {ds} | {ex} |")

def counters():
    print("\n### Counter study: b64 1e14, 20 fields, this card's budget, experiment binary, 3 reps\n")
    print("| cap | barrier | s/field (reps) | overran (reps) | planes mismatch d (reps) | full checks beyond the overrun (reps) |")
    print("|---|---|---|---|---|---|")
    for s in ("16", "32", "64", "max"):
        for sync in ("0", "1"):
            runs = [parse(f"{D}/cnt_s{s}_sync{sync}_r{r}.log")[64] for r in (1, 2, 3) if os.path.exists(f"{D}/cnt_s{s}_sync{sync}_r{r}.log")]
            print(f"| {s} ({runs[0]['slots']}) | {'yes' if sync == '1' else 'no'} | " + ", ".join(f"{r['pf']:.3f}" for r in runs)
                  + " | " + ", ".join(str(r.get('ov')) for r in runs) + " | " + ", ".join(str(r.get('d')) for r in runs)
                  + " | " + ", ".join(f"{excess(64, r):+d}" for r in runs) + " |")

def race():
    print("\n### Barrier cost at 1e14: the 10 GB card's budget, cap 64, experiment binary, 3 rounds interleaved\n")
    print("| base | no barrier s/field (rounds) | barrier (rounds) | **barrier / none** | d without; with | excess checks without; with |")
    print("|---|---|---|---|---|---|")
    R = {sy: [parse(f"{D}/race_e14_sync{sy}_r{r}.log") for r in (1, 2, 3) if os.path.exists(f"{D}/race_e14_sync{sy}_r{r}.log")] for sy in ("0", "1")}
    for b in (58, 60, 62, 64):
        a = [r[b]["pf"] for r in R["0"] if b in r and "pf" in r[b]]
        c = [r[b]["pf"] for r in R["1"] if b in r and "pf" in r[b]]
        if not a or not c:
            continue
        print(f"| {b} | {st.median(a):.3f} ({', '.join(f'{x:.3f}' for x in a)}) | {st.median(c):.3f} ({', '.join(f'{x:.3f}' for x in c)}) | **×{st.median(c)/st.median(a):.3f}** | "
              + ",".join(str(r[b].get('d')) for r in R["0"]) + "; " + ",".join(str(r[b].get('d')) for r in R["1"]) + " | "
              + ",".join(f"{excess(b, r[b]):+d}" for r in R["0"]) + "; " + ",".join(f"{excess(b, r[b]):+d}" for r in R["1"]) + " |")

def anomalies():
    print("\n### Every 1e14 run with full checks beyond the overrun (> 1e5 per 20 fields)\n")
    print("| run | base | partitions per launch | barrier | d | full checks beyond the overrun | share of the full checks |")
    print("|---|---|---|---|---|---|---|")
    n = 0
    for f in sorted(glob.glob(f"{D}/*.log")):
        name = os.path.basename(f)[:-4]
        if "e16" in name or name.startswith(("build", "exact", "smoke", "lint", "nm_")):
            continue
        p = parse(f)
        for b, r in sorted(p.items()):
            if "chk" not in r or b not in MAIN:
                continue
            if "_r" not in name:
                continue
            n += 1
            ex = excess(b, r)
            if ex > 100000:
                sync = "yes" if ("sync1" in name or "barrier" in name) else "no"
                print(f"| {name} | {b} | {r['slots']} | {sync} | {r.get('d', 'n/a')} | {ex:+,d} | {ex / r['chk'] * 100:.2f} % |")
    print(f"\n({n} base-runs scanned.)")

if __name__ == "__main__":
    sweep(); counters(); race(); anomalies()

def census():
    """Base-runs at 1e14 by (cap >= 64, barrier): how many, how many with excess checks, with d != 0."""
    from collections import defaultdict
    c = defaultdict(lambda: [0, 0, 0, 0])  # runs, excess, d!=0, d measured
    for f in sorted(glob.glob(f"{D}/*.log")):
        name = os.path.basename(f)[:-4]
        if "e16" in name or "_r" not in name or name.startswith(("build", "exact", "smoke", "lint", "nm_")):
            continue
        for b, r in parse(f).items():
            if "chk" not in r or b not in MAIN:
                continue
            tree = "main" if "_main_" in name else "other"
            barrier = "sync1" in name
            key = (tree, r["slots"] >= 64, r["slots"] > 19, barrier)
            k = c[key]
            k[0] += 1
            k[1] += excess(b, r) > 100000
            if "d" in r:
                k[3] += 1
                k[2] += r["d"] != 0
    print("\n### Census of 1e14 base-runs\n")
    print("| tree | per launch | barrier | base-runs | with excess checks | planes counted | with a planes mismatch |")
    print("|---|---|---|---|---|---|---|")
    for key in sorted(c):
        tree, ge64, gt19, barrier = key
        n, ex, dd, dm = c[key]
        pl = ">= 64" if ge64 else ("20-63" if gt19 else "<= 19")
        print(f"| {tree} | {pl} | {'yes' if barrier else 'no'} | {n} | {ex} | {dm} | {dd} |")

census()
