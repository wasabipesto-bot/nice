#!/usr/bin/env python3
"""MU260 task 2 table: timing runs T{1,2}_{build}_f{i} (box/out_*.jsonl) with join run_secs, setup, whole-field wall
(stub claim -> submit), counts, and the card's mean power / SM clock / max temperature (box/gpu.csv, 2 s samples,
utilisation > 50 %). Counts: main 0711b163 must equal yesterday's main 54d0aac4 (T28/raw/box) exactly; v3.4.7 must lie
within T28's overrun bound around main's counts. usage: timing2.py (from MU260/t2)"""
import json, glob, re, math, statistics as st
from datetime import datetime, timezone
M, R = '0711b163', '8bd154bc'
gpu = []
for l in open('box/gpu.csv'):
    p = [x.strip() for x in l.split(',')]
    if not p[0][:4].isdigit(): continue
    t = datetime.strptime(p[0], '%Y/%m/%d %H:%M:%S.%f').replace(tzinfo=timezone.utc).timestamp()
    gpu.append((t, float(p[1].split()[0]), float(p[4].split()[0]), float(p[5]), float(p[6].split()[0])))
yday = {}
for fn in glob.glob('../../T28/raw/box/out_T[12]_54d0aac4_f*.jsonl'):
    for l in open(fn):
        d = json.loads(l)
        if d['claim_id'] == 1: continue
        j = d['telemetry']['pipeline']['join']
        yday.setdefault(d['claim_id'], set()).add((j['survivors'], j['checked'], len(d['nice_numbers'])))
rows = []
for fn in sorted(glob.glob('box/out_T[12]_*.jsonl')):
    r, b, f = re.match(r'.*out_T(\d)_(\w+)_f(\d)\.jsonl', fn).groups()
    for l in open(fn):
        d = json.loads(l)
        if d['claim_id'] == 1: continue
        j = d['telemetry']['pipeline']['join']; s = d['_stub']
        g = [x for x in gpu if s['claim'] <= x[0] <= s['recv'] and x[4] > 50]
        rows.append(dict(round=int(r), build=b, f=int(f), field=d['claim_id'], run=j['run_secs'], setup=j['setup_secs'],
                         wall=s['recv'] - s['claim'], surv=j['survivors'], chk=j['checked'], nice=len(d['nice_numbers']),
                         slots=j['slots'], sha=d['telemetry'].get('build_sha', '')[:8],
                         W=st.mean(x[1] for x in g) if g else 0, MHz=st.mean(x[2] for x in g) if g else 0,
                         T=max((x[3] for x in g), default=0)))
rows.sort(key=lambda x: (x['f'], x['round'], x['build']))
print("| field | round | build (telemetry sha) | join run_secs | setup_secs | wall s | survivors | checked | nice | slots | mean W | mean SM MHz | max °C | counts |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
for x in rows:
    (T, P, _), = yday[x['field']] if len(yday.get(x['field'], ())) == 1 else ((None, None, None),)
    if T is None: verdict = 'no reference'
    elif x['build'] == M: verdict = 'equal' if (x['surv'], x['chk'], x['nice']) in yday[x['field']] else '**DIFFERS**'
    else:
        p = P / T; xx = T - x['surv']; dd = abs(x['chk'] - P - xx * (1 - p))
        tol = 5 * math.sqrt(max(xx, 0) * p * (1 - p)) + 2 + 0.06 * p * (1 - p) * max(xx, 0)
        verdict = f"x={xx}, |d|={dd:.0f} ≤ {tol:.0f}" if xx >= 0 and dd <= tol else f"**OUT** x={xx} d={dd:.0f} tol={tol:.0f}"
    x['verdict'] = verdict
    print(f"| {x['field']} | {x['round']} | {x['build']} ({x['sha']}) | {x['run']:.1f} | {x['setup']:.1f} | {x['wall']:.1f} | {x['surv']:,} | {x['chk']:,} | {x['nice']} | {x['slots']} | {x['W']:.0f} | {x['MHz']:.0f} | {x['T']:.0f} | {verdict} |")
print()
gm = lambda v: math.exp(st.mean(math.log(x) for x in v))
rr, rw = [], []
for f in sorted({x['f'] for x in rows}):
    for r in (1, 2):
        m = [x for x in rows if x['f'] == f and x['round'] == r and x['build'] == M]
        v = [x for x in rows if x['f'] == f and x['round'] == r and x['build'] == R]
        if m and v:
            rr.append(v[0]['run'] / m[0]['run']); rw.append(v[0]['wall'] / m[0]['wall'])
            print(f"f{f} ({m[0]['field']}) round {r}: v3.4.7/main run {rr[-1]:.3f}, wall {rw[-1]:.3f}")
if rr:
    print(f"geomean over {len(rr)} pairs: run ×{gm(rr):.3f} (range {min(rr):.3f}-{max(rr):.3f}), wall ×{gm(rw):.3f} (range {min(rw):.3f}-{max(rw):.3f})")
for b in (M, R):
    v = [x for x in rows if x['build'] == b]
    if v: print(f"{b}: mean run {st.mean(x['run'] for x in v):.1f} s, mean wall {st.mean(x['wall'] for x in v):.1f} s, power {min(x['W'] for x in v):.0f}-{max(x['W'] for x in v):.0f} W, SM {min(x['MHz'] for x in v):.0f}-{max(x['MHz'] for x in v):.0f} MHz")
