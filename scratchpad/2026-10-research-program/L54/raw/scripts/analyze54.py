#!/usr/bin/env python3
"""analyze54.py BOXDIR: the L54 A/B tables from the box's logs (raw/box/logs). For each field and side: per-field
device seconds per round (`per_field=`), counts (checked against the exact values), the join kernel's registers / local
bytes per process (ptxjit), mean SM clock over nvidia-smi samples at >= 90 % utilisation, mean power; ratio = B / side
per round (> 1 is faster), median over rounds; clock-normalised = ratio x (side MHz / B MHz) (cycles per field).
Spill-variant processes that were re-run (`*_spill<k>`) are listed separately."""
import re, sys, glob, os, statistics as st, collections
D = sys.argv[1]
EXACT = {'e17_b62': (1020844021499, 62584252554), 'e16_b60': (460847952346, 30871838404),
         'e16_b62': (163513599082, 10027698695), 'e16_b64': (787584956227, 47900853327)}
def smi(path):
    mhz, w = [], []
    for l in open(path, errors='replace'):
        p = [x.strip() for x in l.split(',')]
        if len(p) < 7: continue
        try:
            u = float(p[6].split()[0]); m = float(p[1].split()[0]); pw = float(p[3].split()[0])
        except ValueError: continue
        if u >= 90: mhz.append(m); w.append(pw)
    return (st.mean(mhz) if mhz else float('nan'), st.mean(w) if w else float('nan'), len(mhz))
def jit(path):
    if not os.path.exists(path): return '?'
    r = re.findall(r'regs=(\d+) local=(\d+)', open(path).read())
    return ','.join(f'{a}' + (f'+{b}B' if b != '0' else '') for a, b in r)
runs = collections.defaultdict(dict); spills = []
for lg in sorted(glob.glob(f'{D}/ab_*.log')):
    n = os.path.basename(lg)[:-4]
    m = re.match(r'ab_(\w+?)_(e1\d_b\d\d)_r(\d)(_spill\d)?$', n)
    if not m: continue
    side, fld, r, sp = m.group(1), m.group(2), int(m.group(3)), m.group(4)
    t = open(lg).read()
    pf = re.findall(r'per_field=([0-9.]+)', t); cnt = re.findall(r'survivors=(\d+) checked=(\d+)', t)
    if not pf: continue
    sec = float(pf[-1]); sv, ck = map(int, cnt[-1])
    ok = (sv, ck) == EXACT[fld]
    mhz, w, ns = smi(f'{D}/{n}.smi')
    rec = dict(sec=sec, ok=ok, mhz=mhz, w=w, ns=ns, regs=jit(f'{D}/{n}_jit.txt'))
    if sp: spills.append((n, rec))
    else: runs[fld][(side, r)] = rec
order = ['e17_b62', 'e16_b60', 'e16_b62', 'e16_b64']
for fld in order:
    if fld not in runs: continue
    R = runs[fld]; sides = sorted({s for s, _ in R}, key=lambda s: (s != 'B', s)); rounds = sorted({r for _, r in R})
    print(f'\n== {fld} (exact {EXACT[fld][0]:,} / {EXACT[fld][1]:,})')
    print(f'{"side":5s} {"s/field (rounds)":38s} {"median":>8s} {"x vs B (rounds)":34s} {"median":>7s} {"MHz":>6s} {"W":>5s} {"x cyc":>6s}  regs (rounds)  exact')
    for s in sides:
        secs = [R[(s, r)]['sec'] if (s, r) in R else None for r in rounds]
        rat = [R[('B', r)]['sec'] / R[(s, r)]['sec'] if (s, r) in R and ('B', r) in R else None for r in rounds]
        mh = [R[(s, r)]['mhz'] for r in rounds if (s, r) in R]; mb = [R[('B', r)]['mhz'] for r in rounds if ('B', r) in R]
        cyc = [R[('B', r)]['sec'] * R[('B', r)]['mhz'] / (R[(s, r)]['sec'] * R[(s, r)]['mhz']) for r in rounds if (s, r) in R and ('B', r) in R]
        ws = [R[(s, r)]['w'] for r in rounds if (s, r) in R]
        regs = ' '.join(R[(s, r)]['regs'] for r in rounds if (s, r) in R)
        ok = all(R[(s, r)]['ok'] for r in rounds if (s, r) in R)
        fs = lambda v: '-' if v is None else f'{v:.3f}'
        print(f'{s:5s} {", ".join(fs(x) for x in secs):38s} {st.median([x for x in secs if x]):8.3f} '
              f'{", ".join(fs(x) for x in rat):34s} {st.median([x for x in rat if x]):7.3f} {st.mean(mh):6.0f} {st.mean(ws):5.1f} {st.median(cyc):6.3f}  {regs:14s} {"yes" if ok else "NO"}')
if spills:
    print('\n== spill-variant processes (re-run)')
    for n, rec in spills: print(f'{n:28s} {rec["sec"]:.3f} s/field {rec["mhz"]:.0f} MHz regs {rec["regs"]} exact {rec["ok"]}')
