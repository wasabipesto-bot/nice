#!/usr/bin/env python3
"""cyc.py MICRO_DIR: join each measurement line of mo_width_bench (M s<pip> <var> mode <m> rep <r> t0 <unix> t1 <unix>
ms <x>) with the nvidia-smi log of the same pass (smi.csv, UTC timestamps) and report per (slice, variant, mode) the
median ms and the median SM clock over the measurement's interval, and kilocycles = ms x MHz; phase 3b = full - no-3b
(mode 1 - mode 0) in ms and in cycles, and the record store = full - no-store (mode 1 - mode 3)."""
import sys, csv, datetime, statistics as st, collections
d = sys.argv[1]
rows = list(csv.reader(open(f'{d}/smi.csv')))[1:]
smp = []
for r in rows:
    try:
        t = datetime.datetime.strptime(r[0].strip(), '%Y/%m/%d %H:%M:%S.%f').replace(tzinfo=datetime.timezone.utc).timestamp()
        smp.append((t, float(r[1].split()[0]), float(r[3].split()[0])))
    except (ValueError, IndexError):
        pass
smp.sort()
import bisect
ts = [x[0] for x in smp]
M = collections.defaultdict(list)
for l in open(f'{d}/out.txt'):
    if not l.startswith('M '):
        continue
    f = l.split()
    pip, var, mode, t0, t1, ms = f[1], f[2], int(f[4]), float(f[8]), float(f[10]), float(f[12])
    i, j = bisect.bisect_left(ts, t0), bisect.bisect_right(ts, t1)
    sel = smp[i:j] or smp[max(0, i - 1):i + 1]
    mhz = sum(x[1] for x in sel) / len(sel)
    w = sum(x[2] for x in sel) / len(sel)
    M[(pip, var, mode)].append((ms, mhz, w, ms * mhz))
keys = sorted({(p, v) for (p, v, m) in M})
print('| slice | variant | full ms | no-3b ms | no-store ms | 3b ms | store ms | MHz (full) | W (full) | 3b Mcycles | n |')
print('|---|---|---|---|---|---|---|---|---|---|---|')
for p, v in keys:
    g = {m: M[(p, v, m)] for m in (1, 0, 3)}
    med = lambda m, k: st.median(x[k] for x in g[m])
    f, z, ns = med(1, 0), med(0, 0), med(3, 0)
    cyc3b = (med(1, 3) - med(0, 3)) / 1e3  # ms*MHz = kcycles; /1e3 -> Mcycles
    print(f'| {p} | {v} | {f:.4f} | {z:.4f} | {ns:.4f} | {f - z:.4f} | {f - ns:.4f} | {med(1, 1):.0f} | {med(1, 2):.0f} | {cyc3b:.3f} | {len(g[1])} |')
