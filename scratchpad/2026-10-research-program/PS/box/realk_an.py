#!/usr/bin/env python3
"""realk_an.py REALK_DIR NSLICES: the real kernel's timing stops (realk.sh) per round, with the mean SM clock over
each run (smi.csv) and the run's SM cycles (s x MHz); per slice: main kernel = stop 3 - stop 2, phase 3b in situ =
stop 3 - stop 3 with MIDOUT_ABL3B, in ms and in Mcycles, and 3b's share of the main kernel."""
import sys, csv, datetime, re
d, K = sys.argv[1], int(sys.argv[2])
DAY = sys.argv[3] if len(sys.argv) > 3 else '2026/11/22'  # PS copy: the day is an argument
rows = list(csv.reader(open(f'{d}/smi.csv')))[1:]
smp = []
for r in rows:
    try:
        smp.append((datetime.datetime.strptime(r[0].strip(), '%Y/%m/%d %H:%M:%S.%f'), float(r[1].split()[0]), float(r[3].split()[0]), int(r[4]), int(r[5].split()[0])))
    except (ValueError, IndexError):
        pass
runs = {}
for l in open(f'{d}/summary.txt'):
    f = l.split()
    end = datetime.datetime.strptime(DAY + ' ' + f[0], '%Y/%m/%d %H:%M:%S')
    w = float(re.search(r'stop \d+: ([\d.]+) s', l).group(1))
    st = end - datetime.timedelta(seconds=w)
    sel = [x for x in smp if st <= x[0] <= end and x[4] > 50] or [x for x in smp if st <= x[0] <= end]
    mhz = sum(x[1] for x in sel) / len(sel); pw = sum(x[2] for x in sel) / len(sel); tmax = max(x[3] for x in sel)
    runs[(f[1], f[2])] = (w, mhz, pw, tmax)
print('| round | run | wall s | SM MHz | W | max temp C | Gcycles |')
print('|---|---|---|---|---|---|---|')
for (r, s), (w, mhz, pw, t) in sorted(runs.items()):
    print(f'| {r} | {s} | {w:.2f} | {mhz:.0f} | {pw:.0f} | {t} | {w * mhz / 1e3:.2f} |')
print('\n| round | main kernel ms/slice | main Mcycles/slice | 3b in situ ms/slice | 3b Mcycles/slice | 3b share (cycles) | head control (s3h - s3) |')
print('|---|---|---|---|---|---|---|')
for r in sorted({k[0] for k in runs}):
    g = lambda s: runs[(r, s)]
    main_ms = (g('s3')[0] - g('s2')[0]) / K * 1e3
    main_c = (g('s3')[0] * g('s3')[1] - g('s2')[0] * g('s2')[1]) / K
    b_ms = (g('s3')[0] - g('s3a')[0]) / K * 1e3
    b_c = (g('s3')[0] * g('s3')[1] - g('s3a')[0] * g('s3a')[1]) / K
    hc = (g('s3h')[0] * g('s3h')[1] - g('s3')[0] * g('s3')[1]) / K if (r, 's3h') in runs else float('nan')
    print(f'| {r} | {main_ms:.3f} | {main_c:.3f} | {b_ms:.3f} | {b_c:.3f} | {b_c / main_c:.3f} | {hc:+.3f} Mcycles/slice |')
