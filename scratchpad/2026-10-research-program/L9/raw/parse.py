#!/usr/bin/env python3
"""parse.py CARD...: tables from L9/raw/<card>/ logs (niceonly_*, detailed_*, join_*, smi.csv)."""
import glob, os, re, statistics as st, sys, csv
HERE = os.path.dirname(os.path.abspath(__file__))

def bench(card, mode):
    runs = []
    for f in sorted(glob.glob(f"{HERE}/{card}/{mode}_*.log")):
        txt = open(f).read()
        rates = {}
        for m in re.finditer(r"^(b\d+_\w+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+(?: window)?)\s+([\d.]+)\s+([\d.]+)?\s*([\d.]+e[+-]?\d+)", txt, re.M):
            rates[m.group(1)] = dict(route=m.group(4), timed=m.group(5), secs=float(m.group(6)), rate=float(m.group(8)))
        if not rates:  # detailed window table
            for m in re.finditer(r"^(b\d+_detailed\w*)\s+\d+\s+\S+\s+\d+\s+\S+\s+(\d+)\s+([\d.]+)\s+([\d.]+e[+-]?\d+)", txt, re.M):
                rates[m.group(1)] = dict(reps=int(m.group(2)), secs=float(m.group(3)), rate=float(m.group(4)))
        s = re.search(r"NiceMark: (\d+)", txt)
        back = re.search(r"GPU initialized: ([^\n]+)", txt)
        runs.append(dict(file=os.path.basename(f), rates=rates, score=int(s.group(1)) if s else None,
                         backend=back.group(1) if back else None))
    return runs

def summary(runs):
    keys = sorted({k for r in runs for k in r["rates"]})
    out = []
    for k in keys:
        v = [r["rates"][k]["rate"] for r in runs if k in r["rates"]]
        med = st.median(v)
        out.append((k, med, v, (max(v) - min(v)) / med * 100))
    sc = [r["score"] for r in runs if r["score"]]
    return out, sc

def joins(card):
    out = []
    for f in sorted(glob.glob(f"{HERE}/{card}/join_*.log")):
        txt = open(f).read()
        m = re.search(r"JOIN THROUGHPUT (.*)", txt)
        dbg = re.findall(r"overlap join (b\d+) .*?: setup ([\d.]+)s, device ([\d.]+)s \((\d+) slices of (\d+) partitions, (\d+) batches of (\d+) \(at least (\d+)\), (\d+) MiB\), (\d+) survivors, (\d+) checked, (\d+) re-run, (\d+) splits, total ([\d.]+)s", txt)
        out.append((os.path.basename(f), m.group(1) if m else "NO RESULT", dbg))
    return out

for card in sys.argv[1:]:
    print(f"== {card}")
    for mode in ("niceonly", "detailed"):
        runs = bench(card, mode)
        if not runs: continue
        rows, sc = summary(runs)
        print(f"-- {mode}: backends {sorted({r['backend'] for r in runs})}")
        for k, med, v, sp in rows:
            print(f"  {k:16s} median {med:.3e}  runs {', '.join(f'{x:.3e}' for x in v)}  spread {sp:.1f} %")
        if sc:
            print(f"  score median {st.median(sc)}  runs {sc}  spread {(max(sc)-min(sc))/st.median(sc)*100:.1f} %")
        for r in runs:
            print("   ", r["file"], {k: (v.get("route"), v.get("timed"), v.get("secs")) for k, v in r["rates"].items()})
    for name, line, dbg in joins(card):
        print(f"-- {name}: {line}")
        for d in dbg:
            print(f"     debug {d[0]}: setup {d[1]} device {d[2]} slices {d[3]} partitions {d[4]} batches {d[5]} slots {d[6]} (min {d[7]}) {d[8]} MiB surv {d[9]} checked {d[10]} rerun {d[11]} splits {d[12]} total {d[13]}")
