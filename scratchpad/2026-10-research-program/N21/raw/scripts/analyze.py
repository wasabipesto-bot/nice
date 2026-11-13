#!/usr/bin/env python3
"""analyze.py LOGDIR [NMDIR]: the A/B tables. Per run (ab_<tree>_<field>_r<round>.log): the harness's wall seconds of the
timed fields (secs=), counts, the median SM clock and power over nvidia-smi samples at >= 90 % utilisation, the power
cap, and the join kernel's registers / local bytes from the driver-JIT replay. Then per field and round M/S and M/F
(= speed-up of the branch), the median over rounds. NiceMark (nm_<tree>_r<round>.json): score and per-scenario rates."""
import sys, re, glob, os, json, statistics as st
D = sys.argv[1]
def smi(p):
    c, w, cap = [], [], set()
    for l in open(p, errors='replace'):
        x = [y.strip() for y in l.split(',')]
        if len(x) < 7: continue
        try:
            u = float(x[6].split()[0]); mhz = float(x[1].split()[0]); pw = float(x[3].split()[0]); cap.add(x[4])
        except Exception: continue
        if u >= 90: c.append(mhz); w.append(pw)
    return (st.median(c) if c else 0, st.median(w) if w else 0, ','.join(sorted(cap)), len(c))
R = {}
for p in sorted(glob.glob(f'{D}/ab_*_r[0-9].log')):
    n = os.path.basename(p)[:-4]
    m = re.match(r'ab_([A-Z]+)_(\w+?)_r(\d)$', n)
    t, f, r = m.groups()
    s = open(p, errors='replace').read()
    tp = re.findall(r'JOIN THROUGHPUT .*', s)
    if not tp: print('no result', n); continue
    kv = dict(re.findall(r'(\w+)=([-\w.:]+)', tp[-1]))
    j = open(p[:-4] + '_jit.txt').read() if os.path.exists(p[:-4] + '_jit.txt') else ''
    jr = re.findall(r'join_kernel\S*.*?regs=(\d+) local=(\d+)', j)
    g = smi(p[:-4] + '.smi')
    R[(t, f, int(r))] = dict(secs=float(kv['secs']), surv=kv['survivors'], chk=kv['checked'], mhz=g[0], w=g[1], cap=g[2],
                             ns=g[3], regs='/'.join(sorted({f'{a}+{b}' for a, b in jr})) or '?', retried=kv.get('retried'),
                             batches=kv.get('batches'), slots=kv.get('slots'), start=re.search(r'START \S+ (\S+)', s).group(1))
fields = sorted({k[1] for k in R}, key=lambda f: ['b62', 'b60', 'b64e17', 'b64e16'].index(f) if f in ['b62', 'b60', 'b64e17', 'b64e16'] else 9)
for f in fields:
    print(f'== {f}')
    print(f"   {'run':4s} {'r':>2s} {'start':>8s} {'secs':>8s} {'MHz':>6s} {'W':>5s} cap   regs+local  batches slots counts")
    cnt = None
    for k in sorted(k for k in R if k[1] == f):
        x = R[k]; c = (x['surv'], x['chk']); cnt = cnt or c
        print(f"   {k[0]:4s} {k[2]:2d} {x['start']:>8s} {x['secs']:8.2f} {x['mhz']:6.0f} {x['w']:5.0f} {x['cap']:5s} {x['regs']:11s} {x['batches']:>7s} {x['slots']:>5s} {c[0]}/{c[1]} {'exact' if c == cnt else 'DIFF'} retried={x['retried']}")
    for t in ['S', 'F']:
        rs = sorted({k[2] for k in R if k[1] == f and k[0] == t and ('M', f, k[2]) in R})
        q = [R[('M', f, r)]['secs'] / R[(t, f, r)]['secs'] for r in rs]
        sp = lambda x: '24' in x['regs'].split('+')[-1]  # the 40-register variant with 24 B of spills
        mark = ['*' if sp(R[('M', f, r)]) or sp(R[(t, f, r)]) else '' for r in rs]
        if q:
            clean = [x for x, m in zip(q, mark) if not m]
            print(f"   M/{t}: per round " + ', '.join(f'{x:.3f}{m}' for x, m in zip(q, mark)) + f"  -> median x{st.median(q):.3f}" +
                  (f", spill-free rounds x{st.median(clean):.3f} (n={len(clean)})" if clean and len(clean) < len(q) else '') +
                  f"  (M {st.median(R[('M', f, r)]['secs'] for r in rs):.2f} s, {t} {st.median(R[(t, f, r)]['secs'] for r in rs):.2f} s)")
if len(sys.argv) > 2:
    N = {}
    for p in sorted(glob.glob(f'{sys.argv[2]}/nm_*_r[0-9].json')):
        t, r = re.match(r'nm_([A-Z]+)_r(\d)', os.path.basename(p)).groups()
        try: d = json.load(open(p))
        except Exception as e: print('bad json', p, e); continue
        g = smi(p[:-5] + '.smi')
        N[(t, int(r))] = (d, g)
    if N:
        d0 = next(iter(N.values()))[0]
        print('== NiceMark; keys:', list(d0.keys())[:20])
        def scen(d):
            out = {}
            for s in d.get('scenarios', []):
                nm = s.get('key') or s.get('name')
                rate = s.get('rate') or s.get('numbers_per_sec') or s.get('rate_nps') or s.get('throughput')
                out[nm] = rate
            return out
        for k in sorted(N):
            d, g = N[k]
            print(f"   {k[0]} r{k[1]} score={d.get('score')} MHz={g[0]:.0f} W={g[1]:.0f} cap={g[2]} " + ' '.join(f'{a}={b}' for a, b in scen(d).items()))
        for t in ['S', 'F']:
            rs = sorted({k[1] for k in N if k[0] == t and ('M', k[1]) in N})
            if not rs: continue
            q = [N[(t, r)][0]['score'] / N[('M', r)][0]['score'] for r in rs]
            print(f"   score {t}/M per round " + ', '.join(f'{x:.3f}' for x in q) + f" -> median x{st.median(q):.3f}")
            names = scen(N[('M', rs[0])][0]).keys()
            for nm in names:
                qq = [scen(N[(t, r)][0])[nm] / scen(N[('M', r)][0])[nm] for r in rs]
                print(f"     {nm}: " + ', '.join(f'{x:.3f}' for x in qq) + f" -> median x{st.median(qq):.3f}, min {min(qq):.3f}")
