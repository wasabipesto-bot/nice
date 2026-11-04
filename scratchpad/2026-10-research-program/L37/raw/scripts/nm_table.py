#!/usr/bin/env python3
"""L37: NiceMark markdown table. python3 nm_table.py DIR PREFIX VARIANTS... (files DIR/PREFIX_VARIANT_rN.json; first = baseline)"""
import sys, glob, json, statistics as st
D, P, V = sys.argv[1], sys.argv[2], sys.argv[3:]
med = st.median
nm = {v: [json.load(open(f)) for f in sorted(glob.glob(f'{D}/{P}_{v}_r*.json'))] for v in V}
print('| | ' + ' | '.join(V) + ' | ' + ' | '.join(f'{v} vs {V[0]}' for v in V[1:]) + ' |')
print('|---' * (1 + 2 * len(V) - 1) + '|')
sc = {v: [j['score'] for j in nm[v]] for v in V}
print('| **score** | ' + ' | '.join(f'{", ".join(f"{x:.1f}" for x in sc[v])} (median **{med(sc[v]):.1f}**)' for v in V) + ' | ' +
      ' | '.join(f'**×{med(sc[v]) / med(sc[V[0]]):.3f}** (per round {", ".join(f"{b / a:.3f}" for a, b in zip(sc[V[0]], sc[v]))})' for v in V[1:]) + ' |')
for k in [s['key'] for s in nm[V[0]][0]['scenarios']]:
    r = {v: [next(s for s in j['scenarios'] if s['key'] == k)['rate'] for j in nm[v]] for v in V}
    print(f'| {k}, n/s | ' + ' | '.join(f'{med(r[v]):.4g}' for v in V) + ' | ' + ' | '.join(f'×{med(r[v]) / med(r[V[0]]):.3f}' for v in V[1:]) + ' |')
