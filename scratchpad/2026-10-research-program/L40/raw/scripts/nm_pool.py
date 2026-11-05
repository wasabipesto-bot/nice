#!/usr/bin/env python3
"""L40: NiceMark rounds pooled across sessions. python3 nm_pool.py DIR BASE VARIANT PREFIX... (files DIR/PREFIX_{BASE,VARIANT}_rN.json)
Per scenario: every run's rate per side, per-round ratios (same prefix and round), median ratio of the medians."""
import sys, glob, json, statistics as st, re
D, B, V, P = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
runs = {B: [], V: []}
pairs = []
for p in P:
    for f in sorted(glob.glob(f'{D}/{p}_{B}_r*.json')):
        r = re.search(r'_r(\d+)\.json$', f).group(1)
        g = f'{D}/{p}_{V}_r{r}.json'
        try:
            a, b = json.load(open(f)), json.load(open(g))
        except Exception:
            continue
        runs[B].append(a); runs[V].append(b); pairs.append((p, r, a, b))
keys = [s['key'] for s in runs[B][0]['scenarios']]
print(f'| scenario | {B} runs | {V} runs | per-round ratios ({", ".join(p + "/r" + r for p, r, _, _ in pairs)}) | ratio of medians | median of per-round ratios |')
print('|---|---|---|---|---|---|')
def rate(j, k): return next(s for s in j['scenarios'] if s['key'] == k)['rate']
for k in ['score'] + keys:
    fa = (lambda j: j['score']) if k == 'score' else (lambda j, k=k: rate(j, k))
    ra = [fa(j) for j in runs[B]]; rb = [fa(j) for j in runs[V]]
    pr = [fa(b) / fa(a) for _, _, a, b in pairs]
    fmt = (lambda x: f'{x:.1f}') if k == 'score' else (lambda x: f'{x:.4g}')
    print(f'| {k} | {", ".join(fmt(x) for x in ra)} | {", ".join(fmt(x) for x in rb)} | {", ".join(f"{x:.3f}" for x in pr)} | ×{st.median(rb) / st.median(ra):.3f} | ×{st.median(pr):.3f} |')
