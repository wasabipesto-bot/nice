#!/usr/bin/env python3
"""T2.8 task 3 table: timing runs T{1,2}_{build}_f{i} with join run_secs, setup, whole-field wall (stub claim -> submit),
counts, and the card's mean power / SM clock / max temperature over each run (box/gpu.csv, 5 s samples)."""
import json, glob, re, statistics as st
from datetime import datetime, timezone
gpu = []
for l in open('box/gpu.csv'):
    p = [x.strip() for x in l.split(',')]
    if not p[0][:4].isdigit(): continue
    t = datetime.strptime(p[0], '%Y/%m/%d %H:%M:%S.%f').replace(tzinfo=timezone.utc).timestamp()
    gpu.append((t, float(p[1].split()[0]), float(p[2].split()[0]), float(p[3]), float(p[4].split()[0])))
rows = []
for fn in sorted(glob.glob('box/out_T[12]_*.jsonl')):
    r, b, f = re.match(r'.*out_T(\d)_(\w+)_f(\d)\.jsonl', fn).groups()
    for l in open(fn):
        d = json.loads(l)
        if d['claim_id'] == 1: continue
        j = d['telemetry']['pipeline']['join']; s = d['_stub']
        g = [x for x in gpu if s['claim'] <= x[0] <= s['recv'] and x[4] > 50]
        rows.append(dict(round=int(r), build=b, f=int(f), field=d['claim_id'], run=j['run_secs'], setup=j['setup_secs'], wall=s['recv'] - s['claim'],
            surv=j['survivors'], chk=j['checked'], slots=j['slots'], W=st.mean(x[1] for x in g) if g else None, MHz=st.mean(x[2] for x in g) if g else None, T=max((x[3] for x in g), default=None)))
rows.sort(key=lambda x: (x['f'], x['round'], x['build']))
print("| field | round | build | join run_secs | setup_secs | whole-field wall s | survivors | checked | slots | mean W | mean SM MHz | max °C |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|")
for x in rows:
    print(f"| {x['field']} | {x['round']} | {x['build']} | {x['run']:.1f} | {x['setup']:.1f} | {x['wall']:.1f} | {x['surv']:,} | {x['chk']:,} | {x['slots']} | {x['W'] or 0:.0f} | {x['MHz'] or 0:.0f} | {x['T'] or 0:.0f} |")
print()
rat_run = []; rat_wall = []
for f in sorted({x['f'] for x in rows}):
    for r in (1, 2):
        m = [x for x in rows if x['f'] == f and x['round'] == r and x['build'] == '54d0aac4']
        v = [x for x in rows if x['f'] == f and x['round'] == r and x['build'] == '8bd154bc']
        if m and v:
            print(f"f{f} round {r}: v3.4.7/main run {v[0]['run']/m[0]['run']:.3f}, wall {v[0]['wall']/m[0]['wall']:.3f}")
            if m[0]['surv'] > 10**6: rat_run.append(v[0]['run'] / m[0]['run']); rat_wall.append(v[0]['wall'] / m[0]['wall'])
gm = lambda v: __import__('math').exp(st.mean(__import__('math').log(x) for x in v))
print(f"geomean over the 10 real-size runs pairs (f1-f5, 2 rounds): run {gm(rat_run):.3f} (range {min(rat_run):.3f}-{max(rat_run):.3f}), wall {gm(rat_wall):.3f} (range {min(rat_wall):.3f}-{max(rat_wall):.3f})")
