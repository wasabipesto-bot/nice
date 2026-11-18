#!/usr/bin/env python3
"""summ3.py OUTDIR: table of r{R}_{v10,P,A,D}.log (per-launch medians, ms; end to end fs) + smi busy means; medians."""
import re, sys, glob, os, statistics as st
d = sys.argv[1]
rx = {"prep": r"^PREP(?::| \(GPU)[^\n]*?median ([0-9.]+) ms", "off": r"^MODE probes off\s+median ([0-9.]+) ms",
      "skipoff": r"^MODE skip off\s+median ([0-9.]+) ms", "full": r"^MODE full\s+median ([0-9.]+) ms",
      "e2e": r"RESULT end-to-end[^\n]*= ([0-9.]+) fs"}
res = {}
for f in sorted(glob.glob(f"{d}/r*_*.log")):
    m = re.match(r"r(\d+)_(\w+)\.log", os.path.basename(f))
    if not m: continue
    t = open(f).read(); row = {}
    for k, r in rx.items():
        mm = re.search(r, t, re.M); row[k] = float(mm.group(1)) if mm else None
    row["ok"] = ("ALL CHECKS PASSED" in t) if m.group(2) != "v10" else ("EQUAL" in t or "RESULT end" in t)
    s = f"{d}/smi_r{m.group(1)}_{m.group(2)}.csv"
    if os.path.exists(s):
        rows = [l.strip().split(", ") for l in open(s) if l.strip()]
        busy = [r for r in rows if r[5].split()[0].isdigit() and float(r[5].split()[0]) > 50]
        if busy:
            row["W"] = st.mean(float(r[1].split()[0]) for r in busy); row["MHz"] = st.mean(float(r[3].split()[0]) for r in busy)
            row["Wmax"] = max(float(r[1].split()[0]) for r in busy); row["lim"] = rows[0][2]
    res.setdefault(m.group(2), {})[int(m.group(1))] = row
for v in ["v10", "P", "A", "D"]:
    if v not in res: continue
    print(f"== {v}")
    for R in sorted(res[v]):
        r = res[v][R]
        print(f"  r{R}: prep {r['prep']} off {r['off']} skipoff {r['skipoff']} full {r['full']} e2e {r['e2e']} fs ok={r['ok']} "
              f"{r.get('W', 0):.0f} W (max {r.get('Wmax', 0):.0f}, lim {r.get('lim')}) {r.get('MHz', 0):.0f} MHz")
    med = {k: st.median([res[v][R][k] for R in res[v] if res[v][R][k] is not None]) for k in ["prep", "off", "full", "e2e"]}
    print(f"  median: prep {med['prep']:.3f} off {med['off']:.3f} full {med['full']:.3f} e2e {med['e2e']:.4f} fs; min e2e {min(res[v][R]['e2e'] for R in res[v]):.4f}")
