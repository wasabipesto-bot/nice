#!/usr/bin/env python3
"""smi_summary.py CARD: per phase (phases.log), nvidia-smi samples under load (util >= 50 %):
median SM MHz, median and max W, max C, throttle flags; plus dmon (pwr, sm %, pclk) medians."""
import csv, datetime as dt, os, re, statistics as st, sys
HERE = os.path.dirname(os.path.abspath(__file__))
card = sys.argv[1]
D = f"{HERE}/{card}"
ph = []
for line in open(f"{D}/phases.log"):
    t, *rest = line.split()
    if len(rest) >= 2 and rest[1] in ("begin", "end"):
        ph.append((dt.datetime.strptime(t, "%Y-%m-%dT%H:%M:%SZ"), rest[0], rest[1]))
spans = {}
for t, name, ev in ph:
    spans.setdefault(name, [None, None])[0 if ev == "begin" else 1] = t
def load_smi(path):
    rows = []
    if not os.path.exists(path): return rows
    for r in csv.reader(open(path)):
        if not r or r[0].startswith("timestamp"): continue
        try:
            t = dt.datetime.strptime(r[0].strip().split(".")[0], "%Y/%m/%d %H:%M:%S")
            rows.append(dict(t=t, sm=float(r[1].split()[0]), w=float(r[3].split()[0]), lim=r[5].strip(),
                             c=float(r[6]), fl=r[7].strip(), util=float(r[8].split()[0])))
        except Exception: pass
    return rows
def load_dmon(path, day):
    rows = []
    if not os.path.exists(path): return rows
    for line in open(path):
        if line.startswith("#") or not line.strip(): continue
        f = line.split()
        try:
            t = dt.datetime.combine(day, dt.datetime.strptime(f[0], "%H:%M:%S").time())
            rows.append(dict(t=t, w=float(f[2]), c=float(f[3]), smpct=float(f[5]), pclk=float(f[12])))
        except Exception: pass
    return rows
smi = load_smi(f"{D}/smi.csv") + load_smi(f"{D}/smi_x.csv") + load_smi(f"{D}/smi_x2.csv")
day = ph[0][0].date()
dmon = load_dmon(f"{D}/dmon.log", day) + load_dmon(f"{D}/dmon_x.log", day)
print(f"| phase | secs | smi samples (util>=50) | median SM MHz | median W | max W | max °C | throttle flags | dmon samples (sm>=50 %) | dmon median W / pclk / sm % |")
print("|---|---|---|---|---|---|---|---|---|---|")
for name, (b, e) in spans.items():
    if not b or not e: continue
    s = [r for r in smi if b <= r["t"] <= e and r["util"] >= 50]
    d = [r for r in dmon if b <= r["t"] <= e and r["smpct"] >= 50]
    if s:
        fl = sorted({r["fl"] for r in s})
        smi_cols = f"{len(s)} | {st.median([r['sm'] for r in s]):.0f} | {st.median([r['w'] for r in s]):.0f} | {max(r['w'] for r in s):.0f} | {max(r['c'] for r in s):.0f} | {', '.join(fl)}"
    else:
        smi_cols = "0 | - | - | - | - | -"
    dm = f"{len(d)} | {st.median([r['w'] for r in d]):.0f} W / {st.median([r['pclk'] for r in d]):.0f} MHz / {st.median([r['smpct'] for r in d]):.0f} %" if d else "0 | -"
    print(f"| {name} | {(e-b).total_seconds():.0f} | {smi_cols} | {dm} |")
