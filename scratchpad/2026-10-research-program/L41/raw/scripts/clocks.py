#!/usr/bin/env python3
"""L41 (from L37): per-run mean SM clock / power (samples at >= 90 % utilisation) and device seconds. python3 clocks.py GLOB..."""
import glob, statistics as st, re, sys
for g in sys.argv[1:]:
    for f in sorted(glob.glob(g)):
        mhz, w = [], []
        for line in open(f, errors='replace'):
            p = [x.strip() for x in line.split(',')]
            try:
                if len(p) >= 8 and float(p[6].split()[0]) >= 90:
                    mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
            except ValueError:
                pass
        try:
            d = re.search(r'JOIN THROUGHPUT.*?device=([0-9.]+)s', open(f[:-4] + '.log', errors='replace').read())
        except FileNotFoundError:
            d = None
        if mhz:
            print(f.split('/')[-1][:-4], f'{st.mean(mhz):.0f} MHz {st.mean(w):.0f} W', d.group(1) if d else '-')
