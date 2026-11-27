#!/usr/bin/env python3
"""ab_table.py RUNDIR: one row per bench log (field 77777, the second field of each process): wall s, ms per slice
(slices from the coordinate: 4225 at b65, 4096 at b64), fs per admissible n, sync+reads, and over the field's
window [END - field s, END] of the run's nvidia-smi samples (RTX 3060): median util, share of samples >= 90 %,
median power and graphics clock, peak memory used over the whole run. Then the counts of every full run against
the first full run of the same base."""
import re, sys, glob, os, statistics as st
from datetime import datetime, timedelta
d = sys.argv[1]
FL = re.compile(r'^WIDE b(\d+) t 77777 (?:TIMING STOP: ([\d.]+) s = ([\d.]+) fs per admissible n|v .*?: ([\d.]+) s = ([\d.]+) fs per admissible n \| (.*)$)')
rows = []; ref = {}
for log in sorted(glob.glob(os.path.join(d, '*.log')), key=os.path.getmtime):
    name = os.path.basename(log)[:-4]
    wall = fs = None; rest = None; b = None; end = None; share = ''
    for l in open(log):
        m = FL.match(l)
        if m:
            b = int(m.group(1))
            if m.group(2): wall, fs = float(m.group(2)), float(m.group(3))
            else: wall, fs, rest = float(m.group(4)), float(m.group(5)), m.group(6)
        if l.startswith('END '):
            end = datetime.strptime(l.split()[2], '%Y-%m-%dT%H:%M:%S')
        if l.startswith('WIDE SHARE t 77777'): share = l.split(':', 1)[1].strip()
    if wall is None: rows.append((name, 'no field line')); continue
    sl = 4225 if b == 65 else 4096
    sync = None; cnt = ''
    if rest:
        ms = re.search(r'sync\+reads ([\d.]+) s', rest); sync = float(ms.group(1)) if ms else None
        cnt = ' | '.join(p.strip() for p in rest.split('|')[:-1])
    g = []; mem = 0
    try:
        for l in open(log[:-4] + '.gpu'):
            f = [x.strip() for x in l.split(',')]
            if len(f) < 9: continue
            try:
                ts = datetime.strptime(f[0], '%Y/%m/%d %H:%M:%S.%f'); mem = max(mem, float(f[8]))
            except ValueError: continue
            # nvidia-smi timestamps are local (EST, UTC-5); END is UTC
            tu = ts + timedelta(hours=5)
            if end and end - timedelta(seconds=wall) <= tu <= end: g.append((float(f[1]), float(f[2]), float(f[3])))
    except OSError: pass
    gs = ''
    if g:
        u = [x[0] for x in g]
        gs = f'util {st.median(u):.0f} % (>=90 %: {100*sum(1 for x in u if x >= 90)/len(u):.0f} %), {st.median([x[1] for x in g]):.0f} W, {st.median([x[2] for x in g]):.0f} MHz, n={len(g)}'
    rows.append((name, f'b{b} {wall:7.2f} s  {1000*wall/sl:6.3f} ms/slice  {fs:.4f} fs' + (f'  sync {sync:.2f}' if sync else '') + f'  | {gs} | mem {mem:.0f} MiB' + (f' | share {share}' if share else '')))
    if cnt:
        ref.setdefault(b, (name, cnt))
        rows.append(('', 'counts ' + ('= ' + ref[b][0] if cnt == ref[b][1] else 'DIFFER from ' + ref[b][0] + ': ' + cnt)))
for n, r in rows: print(f'{n:14s} {r}')
