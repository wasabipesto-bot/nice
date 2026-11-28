#!/usr/bin/env python3
# tab.py RUNDIR: per run, field t 77777's seconds and fs per admissible n, its counts, and the card's mean
# utilisation / power / SM clock over the run (nvidia-smi samples with util >= 50 %, i.e. while it computes).
import re, sys, glob, os, statistics as st
d = sys.argv[1]
for log in sorted(glob.glob(os.path.join(d, '*.log'))):
    n = os.path.basename(log)[:-4]
    t = open(log, errors='replace').read()
    m = re.search(r"t 77777 v .*?: ([\d.]+) s = ([\d.]+) fs per admissible n \| slices (\d+) survivors (\d+) checked (\d+)", t)
    rc = re.search(r"rc=(\d+)", t[t.rfind("END"):]) if "END" in t else None
    g = []
    try:
        for l in open(os.path.join(d, n + '.gpu')):
            p = [x.strip() for x in l.split(',')]
            if len(p) > 5 and p[1].isdigit() and int(p[1]) >= 50:
                g.append((int(p[1]), float(p[2]), int(p[5])))
    except FileNotFoundError:
        pass
    gs = f"{st.mean(x[0] for x in g):.0f}% {st.mean(x[1] for x in g):.0f}W {st.mean(x[2] for x in g):.0f}MHz" if g else "-"
    if m:
        print(f"{n:24s} {float(m.group(1)):8.2f} s {float(m.group(2)):7.4f} fs  surv {m.group(4)} chk {m.group(5)}  {gs}  rc={rc.group(1) if rc else '?'}")
    else:
        tot = re.search(r"TOTAL.*", t)
        print(f"{n:24s} (no field 77777 line) {tot.group(0)[:90] if tot else ''}  {gs}  rc={rc.group(1) if rc else '?'}")
