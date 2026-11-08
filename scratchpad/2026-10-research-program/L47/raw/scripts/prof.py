#!/usr/bin/env python3
"""L47: profiled runs' check / join / top seconds per field (GPU_PROFILE lines, warm-up field excluded) and the SM clock.
python3 prof.py DIR PREFIX  -> one row per log DIR/PREFIX*.log: mode, field, round, check s/field, device s/field, MHz."""
import re, sys, glob, os, statistics as st
D, P = sys.argv[1], sys.argv[2]
def smi(path):
    mhz = []
    if not os.path.exists(path): return float('nan')
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) > 6 and int(p[6].split()[0]) >= 90: mhz.append(float(p[1].split()[0]))
        except Exception: pass
    return st.mean(mhz) if mhz else float('nan')
rows = []
for f in sorted(glob.glob(f'{D}/{P}*.log')):
    L = [l for l in open(f, errors='replace') if l.startswith('GPU_PROFILE') or 'GPU_PROFILE base' in l]
    recs = []
    for l in L:
        l = l[l.index('GPU_PROFILE'):]
        d = {k: float(v) for k, v in re.findall(r'\b(check|join|top|bucket|device_wall|size|checked)=([0-9.e+]+)', l)}
        recs.append(d)
    if not recs: print(os.path.basename(f), 'no profile'); continue
    big = [r for r in recs if r['size'] >= 1e15] or recs[1:] or recs
    n = len(big)
    chk = sum(r['check'] for r in big) / n; dev = sum(r['device_wall'] for r in big) / n
    jn = sum(r['join'] for r in big) / n
    rows.append((os.path.basename(f)[:-4], chk, jn, dev, smi(f[:-4] + '.smi'), int(sum(r['checked'] for r in big))))
for r in rows: print(f'{r[0]:32s} check={r[1]:8.3f} join={r[2]:8.3f} device={r[3]:8.3f} MHz={r[4]:6.0f} checked={r[5]}')
