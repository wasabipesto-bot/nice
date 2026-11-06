#!/usr/bin/env python3
"""L41 (from L37): interleaved A/B analysis. python3 ab.py DIR PREFIX VARIANTS...
Logs DIR/{PREFIX}_{VARIANT}_{field}_r{N}.log (JOIN THROUGHPUT lines); the first variant is the baseline.
NiceMark: DIR/nm{PREFIX[2:]}_{VARIANT}_r{N}.json if present (e.g. ab1 -> nm1)."""
import re, sys, glob, os, statistics as st, json
D, P, V = sys.argv[1], sys.argv[2], sys.argv[3:]
med = st.median
def tp(path):
    for line in open(path, errors='replace'):
        if 'JOIN THROUGHPUT' in line:
            d = {}
            for k in ['device', 'per_field', 'setup', 'survivors', 'checked', 'found', 'slots', 'plan_mib']:
                m = re.search(r'\b' + k + r'=([0-9.e+]+)s?\b', line)
                if m: d[k] = float(m.group(1))
            return d
def smi(path):
    mhz, w = [], []
    if not os.path.exists(path): return None, None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) >= 8 and float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
        except ValueError: pass
    return (st.mean(mhz), st.mean(w)) if mhz else (None, None)
def spread(x): return 100 * (max(x) - min(x)) / med(x) if len(x) > 1 else 0.0
fields = sorted(set(re.sub(r'_r\d+\.log$', '', os.path.basename(f)).split('_', 2)[2] for f in glob.glob(f'{D}/{P}_*_r*.log')))
order = ['e17_b62', 'e16_b62', 'e16_b60', 'e16_b64', 'e14_b57', 'e14_b60', 'e14_b62', 'e14_b64']
fields = sorted(fields, key=lambda f: order.index(f) if f in order else 99)
print(f'| field | ' + ' | '.join(f'{v} s/field (rounds)' for v in V) + ' | ' + ' | '.join(f'{v} vs {V[0]} (per round)' for v in V[1:]) + ' | clock MHz | counts |')
print('|---' * (2 + 2 * len(V)) + '|---|')
for fld in fields:
    rows = {}
    for v in V:
        fs = sorted(glob.glob(f'{D}/{P}_{v}_{fld}_r*.log'))
        rows[v] = [(tp(f), smi(f[:-4] + '.smi')[0]) for f in fs]
        rows[v] = [r for r in rows[v] if r[0]]
    if not all(rows[v] for v in V): continue
    dev = {v: [r[0]['device'] for r in rows[v]] for v in V}
    cells = [f'**{med(dev[v]):.3f}** ({", ".join(f"{x:.2f}" for x in dev[v])}; {spread(dev[v]):.1f} %)' for v in V]
    rat = []
    mh = {v: [r[1] for r in rows[v]] for v in V}
    for v in V[1:]:
        pr = [a / b for a, b in zip(dev[V[0]], dev[v])]
        cn = ''
        if all(mh[V[0]]) and all(mh[v]):
            # cycles: device seconds x the run's mean SM clock
            ca = [d * m for d, m in zip(dev[V[0]], mh[V[0]])]; cb = [d * m for d, m in zip(dev[v], mh[v])]
            cn = f'; cycles ×{med(ca) / med(cb):.3f}'
        rat.append(f'**×{med(dev[V[0]]) / med(dev[v]):.3f}** ({", ".join(f"{x:.3f}" for x in pr)}{cn})')
    clk = ' / '.join(f'{st.mean([r[1] for r in rows[v] if r[1]]):.0f}' if any(r[1] for r in rows[v]) else '-' for v in V)
    cnt = []
    for v in V:
        s = sorted(set((int(r[0]['survivors']), int(r[0]['checked']), int(r[0]['found'])) for r in rows[v]))
        cnt.append(f'{v}: ' + '; '.join(f'{a:,} / {b:,} / {c}' for a, b, c in s))
    print(f'| {fld} | ' + ' | '.join(cells) + ' | ' + ' | '.join(rat) + f' | {clk} | ' + ' — '.join(cnt) + ' |')
nmp = 'nm' + P[2:]
nm = {}
for v in V:
    for f in sorted(glob.glob(f'{D}/{nmp}_{v}_r*.json')):
        try: nm.setdefault(v, []).append(json.load(open(f)))
        except Exception as e: print(f, 'unreadable', e)
if all(v in nm for v in V):
    print()
    sc = {v: [j['score'] for j in nm[v]] for v in V}
    print('NiceMark score: ' + ' | '.join(f'{v} {", ".join(f"{x:.1f}" for x in sc[v])} (median {med(sc[v]):.1f})' for v in V))
    for v in V[1:]:
        print(f'  {v} vs {V[0]}: x{med(sc[v]) / med(sc[V[0]]):.3f} per round {", ".join(f"{b / a:.3f}" for a, b in zip(sc[V[0]], sc[v]))}')
    for k in [s['key'] for s in nm[V[0]][0]['scenarios']]:
        r = {v: [next(s for s in j['scenarios'] if s['key'] == k)['rate'] for j in nm[v]] for v in V}
        js = {v: sorted(set((next(s for s in j['scenarios'] if s['key'] == k).get('join') or {}).get('survivors') for j in nm[v])) for v in V}
        print(f'  {k}: ' + ' | '.join(f'{v} {med(r[v]):.4g}' for v in V) + ' | ' + ' '.join(f'x{med(r[v]) / med(r[V[0]]):.3f}' for v in V[1:]) + f' | join survivors {js}')
