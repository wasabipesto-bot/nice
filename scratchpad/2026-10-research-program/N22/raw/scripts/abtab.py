#!/usr/bin/env python3
"""abtab.py LOGDIR: the A/B table from ab_m<mode>_<field>_r<round>.log: per run the harness's wall seconds, counts,
the median SM clock / power over nvidia-smi samples at >= 90 % utilisation, the start temperature and the join
kernel's registers / local bytes (driver-JIT replay); per field and mode, base/mode per round and the median."""
import sys, re, glob, os, statistics as st
D = sys.argv[1]
def smi(p):
    c, w = [], []
    for l in open(p, errors='replace'):
        x = [y.strip() for y in l.split(',')]
        if len(x) < 7: continue
        try: u = float(x[6].split()[0]); mhz = float(x[1].split()[0]); pw = float(x[3].split()[0])
        except Exception: continue
        if u >= 90: c.append(mhz); w.append(pw)
    return (st.median(c) if c else 0, st.median(w) if w else 0)
R = {}
for p in sorted(glob.glob(f'{D}/ab_m*_r[0-9].log')):
    n = os.path.basename(p)[:-4]
    m = re.match(r'ab_m(\d+)_(\w+?)_r(\d)$', n)
    if not m: continue
    mode, f, r = int(m.group(1)), m.group(2), int(m.group(3))
    s = open(p, errors='replace').read()
    tp = re.findall(r'JOIN THROUGHPUT .*', s)
    if not tp: print('no result', n); continue
    kv = dict(re.findall(r'(\w+)=([-\w.:]+)', tp[-1]))
    j = open(p[:-4] + '_jit.txt').read() if os.path.exists(p[:-4] + '_jit.txt') else ''
    jr = re.findall(r'join_kernel\S*.*?regs=(\d+) local=(\d+)', j)
    cool = re.search(r'cooled (\d+)s to (\d+)C', s)
    g = smi(p[:-4] + '.smi')
    R[(f, mode, r)] = dict(secs=float(kv['secs']), cnt=(kv['survivors'], kv['checked']), mhz=g[0], w=g[1],
                           rv='+'.join(jr[0]) if jr else '?', cool=cool.group(2) if cool else '?')
for f in sorted({k[0] for k in R}):
    print(f'== {f}')
    modes = sorted({k[1] for k in R if k[0] == f}); rounds = sorted({k[2] for k in R if k[0] == f})
    cnts = {R[k]['cnt'] for k in R if k[0] == f}
    print(f'   counts: {"identical" if len(cnts) == 1 else "DIFFER"} {sorted(cnts)}')
    for r in rounds:
        print(f'   r{r}: ' + '  '.join(f'm{m} {R[(f,m,r)]["secs"]:.2f}s {R[(f,m,r)]["mhz"]:.0f}MHz {R[(f,m,r)]["w"]:.0f}W {R[(f,m,r)]["cool"]}C {R[(f,m,r)]["rv"]}' for m in modes if (f,m,r) in R))
    for m in modes:
        if m == 0: continue
        q = [R[(f,0,r)]['secs'] / R[(f,m,r)]['secs'] for r in rounds if (f,0,r) in R and (f,m,r) in R]
        if q: print(f'   base/m{m}: ' + ', '.join(f'{x:.3f}' for x in q) + f' -> median x{st.median(q):.3f}')
