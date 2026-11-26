#!/usr/bin/env python3
"""analyze.py RUNDIR...: one row per bench log: per field t, wall s, fs per admissible n, sync+reads, outside device
waits (total - sync+reads), counts; for the last field, nvidia-smi samples (RTX 3060) in the field's window
[END - field s, END]: median util, power, graphics clock, and the share of samples at util >= 90 %."""
import re, sys, glob, os, statistics as st
from datetime import datetime, timezone

REF = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'G2', 'window_1125', 'out', 'w65_nc.log')
FL = re.compile(r'^(WIDE b(\d+)|FIELD) t (\d+) .*?: ([\d.]+) s = ([\d.]+) fs per admissible n \| (.*)$')

def counts(rest):
    parts = rest.split('|')
    return ' | '.join(p.strip() for p in parts[:-1])

def tail(rest):
    m = re.search(r'sync\+reads ([\d.]+) s', rest)
    return float(m.group(1)) if m else None

def ref_counts():
    d = {}
    try:
        for l in open(REF):
            m = FL.match(l)
            if m: d[int(m.group(3))] = counts(m.group(6))
    except OSError: pass
    return d

def gpu_window(gpath, end, secs):
    rows = []
    try:
        for l in open(gpath):
            f = [x.strip() for x in l.split(',')]
            if len(f) < 8: continue
            try:
                ts = datetime.strptime(f[0], '%Y/%m/%d %H:%M:%S.%f').replace(tzinfo=None)
                rows.append((ts, float(f[1]), float(f[2]), float(f[3]), f[6]))
            except ValueError: continue
    except OSError: return None
    return rows

def main():
    ref = ref_counts()
    for d in sys.argv[1:]:
        for log in sorted(glob.glob(os.path.join(d, '*.log')), key=os.path.getmtime):
            name = os.path.basename(log)[:-4]
            L = open(log).read().splitlines()
            fields = [FL.match(l) for l in L]; fields = [m for m in fields if m]
            start = next((l for l in L if l.startswith('START')), '')
            endl = next((l for l in L if l.startswith('END')), '')
            dev = next((l for l in L if l.startswith('device')), '')[:110]
            print(f'## {name}  {start[len("START "+name)+1:][:20]}  {re.search(r"md5=\S+", start).group(0) if "md5=" in start else ""}  {endl[-30:]}')
            print(f'   {dev}')
            for m in fields:
                t = int(m.group(3)); s = float(m.group(4)); fs = float(m.group(5)); sr = tail(m.group(6))
                c = counts(m.group(6)); eq = ''
                if m.group(2) == '65' and t in ref: eq = ' counts=11-25' if c == ref[t] else ' COUNTS DIFFER from 11-25'
                print(f'   t {t}: {s:.2f} s  {fs:.4f} fs  sync+reads {sr}  outside {s - sr if sr is not None else float("nan"):.2f} s{eq}')
            other = [l for l in L if re.match(r'^(STAGE|STOP|stage|TOTAL|time|timing)', l)]
            for l in other[-6:]: print('   ' + l[:160])
            # samples in the last field's window
            em = re.search(r'END \S+ (\S+) rc', endl)
            end = None
            if em:
                try: end = datetime.strptime(em.group(1), '%Y-%m-%dT%H:%M:%S')
                except ValueError: end = None
            if fields and end:
                rows = gpu_window(os.path.join(d, name + '.gpu'), None, None) or []
                # nvidia-smi timestamps are local time on eventeo (America/New_York); align by the last sample
                if rows:
                    off = rows[-1][0] - end
                    secs = float(fields[-1].group(4))
                    w = [r for r in rows if (end + off - r[0]).total_seconds() <= secs]
                    if w:
                        u = [r[1] for r in w]
                        print(f'   gpu last field ({len(w)} samples): util med {st.median(u):.0f} %, >=90 % {100*sum(x>=90 for x in u)/len(u):.0f} %, '
                              f'power med {st.median([r[2] for r in w]):.0f} W, clock med {st.median([r[3] for r in w]):.0f} MHz, pstates {sorted(set(r[4] for r in w))}')
main()
