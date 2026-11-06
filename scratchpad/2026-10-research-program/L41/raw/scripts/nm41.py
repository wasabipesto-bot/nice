#!/usr/bin/env python3
"""L41: NiceMark A/B with clocks. python3 nm41.py DIR A B: files DIR/nm_{A,B}_rN.json and .smi (A = baseline).
Per round: score ratio B/A (wall) and clock-normalised (× clock_A / clock_B, the runs' mean SM MHz at >= 90 % util);
per scenario: medians over the rounds, the ratio of medians, per-round ratios, min ratio."""
import sys, glob, json, statistics as st, os, re
D, A, B = sys.argv[1:4]
med = st.median
def clock(path):
    mhz = []
    if not os.path.exists(path): return None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) >= 8 and float(p[6].split()[0]) >= 90: mhz.append(float(p[1].split()[0]))
        except ValueError: pass
    return st.mean(mhz) if mhz else None
def runs(v):
    out = {}
    for f in glob.glob(f'{D}/nm_{v}_r*.json'):
        r = int(re.search(r'_r(\d+)\.json$', f).group(1))
        try: out[r] = (json.load(open(f)), clock(f[:-5] + '.smi'))
        except Exception as e: print(f, 'unreadable', e)
    return out
ra, rb = runs(A), runs(B)
rounds = sorted(set(ra) & set(rb))
print(f'| round | order | {A} score | {B} score | {B} vs {A} | MHz {A} / {B} | clock-normalised |')
print('|---|---|---|---|---|---|---|')
wr, cr = [], []
for r in rounds:
    (ja, ca), (jb, cb) = ra[r], rb[r]
    w = jb['score'] / ja['score']; wr.append(w)
    c = w * ca / cb if ca and cb else None
    if c: cr.append(c)
    order = f'{A} {B}' if r % 2 else f'{B} {A}'
    print(f'| {r} | {order} | {ja["score"]:.1f} | {jb["score"]:.1f} | ×{w:.3f} | {ca or 0:.0f} / {cb or 0:.0f} | ' + (f'×{c:.3f}' if c else '-') + ' |')
sa = [ra[r][0]['score'] for r in rounds]; sb = [rb[r][0]['score'] for r in rounds]
print(f'| **median** | | **{med(sa):.1f}** | **{med(sb):.1f}** | **×{med(sb) / med(sa):.3f}** (per-round median ×{med(wr):.3f}) | {med([ra[r][1] for r in rounds if ra[r][1]]):.0f} / {med([rb[r][1] for r in rounds if rb[r][1]]):.0f} | ' + (f'**×{med(cr):.3f}**' if cr else '-') + ' |')
print()
print(f'| scenario | {A} n/s (median) | {B} n/s (median) | {B} vs {A} | per round | min | join survivors {A} / {B} |')
print('|---|---|---|---|---|---|---|')
for k in [s['key'] for s in ra[rounds[0]][0]['scenarios']]:
    get = lambda j: next(s for s in j['scenarios'] if s['key'] == k)
    xa = [get(ra[r][0])['rate'] for r in rounds]; xb = [get(rb[r][0])['rate'] for r in rounds]
    pr = [b / a for a, b in zip(xa, xb)]
    js = lambda rr: sorted(set((get(rr[r][0]).get('join') or {}).get('survivors') for r in rounds))
    print(f'| {k} | {med(xa):.4g} | {med(xb):.4g} | **×{med(xb) / med(xa):.3f}** | {", ".join(f"{x:.3f}" for x in pr)} | ×{min(pr):.3f} | {js(ra)} / {js(rb)} |')
