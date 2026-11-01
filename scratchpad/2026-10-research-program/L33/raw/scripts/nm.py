#!/usr/bin/env python3
"""NiceMark JSONs: python3 nm.py DIR -> score and per-scenario rates, A against each ER variant."""
import json, sys, glob, os
D = sys.argv[1] if len(sys.argv) > 1 else 'box'
runs = {}
for f in sorted(glob.glob(f'{D}/nm_*.json')):
    try:
        runs[os.path.basename(f)[3:-5]] = json.load(open(f))
    except Exception as e:
        print(f, 'unreadable', e)
if 'A' not in runs:
    sys.exit('no A run')
a = runs['A']
keys = [s['key'] for s in a['scenarios']]
print('| | ' + ' | '.join(runs) + ' |')
print('|---|' + '---|' * len(runs))
print('| score | ' + ' | '.join(f"{r['score']:.1f}" + ('' if k == 'A' else f" (×{r['score'] / a['score']:.3f})") for k, r in runs.items()) + ' |')
for key in keys:
    cells = []
    for k, r in runs.items():
        s = next((x for x in r['scenarios'] if x['key'] == key), None)
        sa = next(x for x in a['scenarios'] if x['key'] == key)
        if s is None or s.get('rate') is None:
            cells.append('-'); continue
        cells.append(f"{s['rate']:.4g}" + ('' if k == 'A' else f" (×{s['rate'] / sa['rate']:.3f})"))
    print(f'| {key} | ' + ' | '.join(cells) + ' |')
for key in keys:
    c = {k: next((x for x in r['scenarios'] if x['key'] == key), {}).get('join') or {} for k, r in runs.items()}
    print(f"- {key} counts: " + '; '.join(f"{k} {v.get('survivors')} / {v.get('checked')} ({v.get('sampled')} of {v.get('partitions')} partitions)" for k, v in c.items()))
