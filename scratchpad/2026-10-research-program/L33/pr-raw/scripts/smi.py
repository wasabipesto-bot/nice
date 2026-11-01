#!/usr/bin/env python3
"""Clock/power/temperature under load (utilisation >= 90 %) per timed run. python3 smi.py DIR"""
import glob, sys
D = sys.argv[1]
allm, allw, allt = [], [], []
for f in sorted(glob.glob(f'{D}/ab_*.smi')) + sorted(glob.glob(f'{D}/nm_*.smi')):
    mhz, w, t, thr = [], [], [], set()
    for line in open(f, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        if len(p) < 8: continue
        try:
            if float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0])); t.append(float(p[5])); thr.add(p[7])
        except ValueError: pass
    if mhz:
        allm.append(sum(mhz) / len(mhz)); allw += w; allt += t
        print(f'{f.split("/")[-1]}: {sum(mhz)/len(mhz):.0f} MHz, {sum(w)/len(w):.1f} W, max {max(t):.0f} C, throttle {sorted(thr)}, {len(mhz)} samples')
print(f'ALL: mean SM clock per run {min(allm):.0f}-{max(allm):.0f} MHz, power {min(allw):.0f}-{max(allw):.0f} W (mean {sum(allw)/len(allw):.1f}), max {max(allt):.0f} C')
