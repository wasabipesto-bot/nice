#!/usr/bin/env python3
"""Second-card (RTX 4090) analysis: python3 analyze.py raw  (the box's /root/sc copy).
Trees: main fae7398, p235 = #235 6e7475e, p236 = #236 dd4a0eb, both = e9cdac4 (main + #235 + #236)."""
import re, sys, glob, os, json, statistics as st

D = sys.argv[1] if len(sys.argv) > 1 else 'raw'
TREES = ['main', 'p235', 'p236', 'both']
LBL = {'main': 'main', 'p235': '#235', 'p236': '#236', 'both': 'both'}
# 3080 (180 W) reference speed-ups (main/PR): L29 per_field (#235), L30 device= (#236)
REF = {'e17_b62': (1.075, 1 / 0.823), 'e16_b62': (1.089, 1 / 0.846), 'e16_b60': (1.053, 1 / 0.806), 'e16_b64': (1.040, 1 / 0.769), 'nm': (1.071, 1.194)}
med = st.median

def spread(x):
    return 100 * (max(x) - min(x)) / med(x)

def tp(path):
    out = []
    for line in open(path, errors='replace'):
        if 'JOIN THROUGHPUT' not in line:
            continue
        d = {}
        for k in ['base', 'fields', 'secs', 'per_field', 'device', 'wall', 'setup', 'survivors', 'checked', 'found', 'slots', 'plan_mib', 'retried', 'splits', 'batches']:
            m = re.search(r'\b' + k + r'=([0-9.e+]+)s?\b', line)
            if m:
                d[k] = float(m.group(1)) if any(c in m.group(1) for c in '.e') else int(m.group(1))
        out.append(d)
    return out

def smi(path):
    """mean SM MHz, W, temp at >= 90 % utilisation, and the set of active throttle reasons."""
    mhz, w, t, thr = [], [], [], {}
    if not os.path.exists(path):
        return None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        if len(p) < 8:
            continue
        try:
            if float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0])); t.append(float(p[5]))
                thr[p[7]] = thr.get(p[7], 0) + 1
        except ValueError:
            pass
    if not mhz:
        return None
    return dict(mhz=st.mean(mhz), w=st.mean(w), t=max(t), n=len(mhz), thr=thr)

def runs(prefix):
    """{tree: [(round, tp dict, smi dict)]} for ff_<tree>_<prefix>_r*.log"""
    res = {}
    for t in TREES:
        for f in sorted(glob.glob(f'{D}/ff_{t}_{prefix}_r*.log')):
            x = tp(f)
            if x:
                res.setdefault(t, []).append((int(f.rsplit('_r', 1)[1][:-4]), x[0], smi(f[:-4] + '.smi')))
    return res

THR = {'0x0000000000000004': 'SW power cap', '0x0000000000000000': 'none', '0x0000000000000001': 'idle',
       '0x0000000000000020': 'SW thermal', '0x0000000000000040': 'HW thermal', '0x0000000000000080': 'HW power brake'}

summary = {}
for prefix, label in [('e17_b62', 'b62 1e17 (1 field)'), ('e16_b62', 'b62 1e16 (2 fields)'), ('e16_b60', 'b60 1e16 (2 fields)'), ('e16_b64', 'b64 1e16 (2 fields)')]:
    R = runs(prefix)
    if 'main' not in R:
        print(label, 'missing'); continue
    print(f'== {label}')
    for metric in ['device', 'per_field']:
        m = {t: med([r[1][metric] for r in R[t]]) for t in R}
        for t in TREES:
            if t not in R:
                continue
            x = [r[1][metric] for r in R[t]]
            pr = [a[1][metric] / b[1][metric] for a, b in zip(R['main'], R[t])]
            print(f'  {metric:9} {LBL[t]:5}: {", ".join(f"{y:.3f}" for y in x)} | median {m[t]:.3f} spread {spread(x):.1f} % | '
                  f'speed-up x{m["main"]/m[t]:.3f} (per-round {", ".join(f"{p:.3f}" for p in pr)}) saving {m["main"]-m[t]:.2f} s')
        summary.setdefault(prefix, {})[metric] = m
        if all(t in m for t in TREES):
            s235, s236, sb = m['main'] / m['p235'], m['main'] / m['p236'], m['main'] / m['both']
            add = m['main'] / (m['p235'] + m['p236'] - m['main'])
            print(f'  {metric:9} compounding: product x{s235:.3f} * x{s236:.3f} = x{s235*s236:.3f}; additive savings x{add:.3f} '
                  f'(predicted {m["p235"]+m["p236"]-m["main"]:.3f} s); measured both x{sb:.3f} = {100*sb/(s235*s236):.1f} % of the product, '
                  f'interaction {m["both"]-(m["p235"]+m["p236"]-m["main"]):+.3f} s')
    for t in TREES:
        if t not in R:
            continue
        ss = [r[2] for r in R[t] if r[2]]
        if ss:
            thr = {}
            for s in ss:
                for k, v in s['thr'].items():
                    thr[THR.get(k, k)] = thr.get(THR.get(k, k), 0) + v
            print(f'  clocks {LBL[t]:5}: {st.mean(s["mhz"] for s in ss):.0f} MHz, {st.mean(s["w"] for s in ss):.0f} W, max {max(s["t"] for s in ss):.0f} C, '
                  f'throttle {thr}')
    if all(t in R for t in TREES):
        dm = {t: med([r[1]['device'] for r in R[t]]) for t in TREES}
        cm = {t: st.mean(r[2]['mhz'] for r in R[t] if r[2]) for t in TREES}
        print('  clock-normalised device speed-up: ' + ', '.join(f'{LBL[t]} x{(dm["main"]*cm["main"])/(dm[t]*cm[t]):.3f}' for t in TREES[1:]))
    for t in TREES:
        if t in R:
            c = sorted(set((r[1]['survivors'], r[1]['checked'], r[1]['found']) for r in R[t]))
            print(f'  counts {LBL[t]:5} (survivors, checked, found): {c}  slots={R[t][0][1].get("slots")} plan_mib={R[t][0][1].get("plan_mib")}')

print()
print('== 1e14 compare runs (one field per base, NICE_TEST_JOIN_COMPARE=1)')
cmp = {}
for name in ['main_cmp_e14', 'both_cmp_e14']:
    f = f'{D}/{name}.log'
    if os.path.exists(f):
        for d in tp(f):
            cmp.setdefault(name, {})[d['base']] = (d['survivors'], d['checked'], d['found'])
            print(f'  {name} b{d["base"]}: survivors={d["survivors"]} checked={d["checked"]} found={d["found"]} device={d["device"]} plan_mib={d.get("plan_mib")}')
        print('   ', [l.strip()[:120] for l in open(f, errors='replace') if l.startswith('STRIDE') or 'test result' in l or 'panicked' in l])
if len(cmp) == 2:
    print('  identical main vs both:', cmp['main_cmp_e14'] == cmp['both_cmp_e14'])
f = f'{D}/x_ref.log'
if os.path.exists(f):
    print('  x_ref:', [l.strip()[:140] for l in open(f, errors='replace') if 'test result' in l or l.startswith('END') or 'panicked' in l])

print()
print('== NiceMark nice-only (--benchmark-secs 150)')
nm = {}
for t in TREES:
    for f in sorted(glob.glob(f'{D}/nm_{t}_r*.json')):
        try:
            j = json.load(open(f))
        except Exception as e:
            print(' ', f, 'unreadable', e); continue
        s = smi(f[:-5] + '.smi')
        nm.setdefault(t, []).append((j['score'], {x['key']: x for x in j['scenarios']}, s))
if 'main' in nm:
    sm = {t: med([x[0] for x in nm[t]]) for t in nm}
    for t in TREES:
        if t not in nm:
            continue
        x = [y[0] for y in nm[t]]
        pr = [b[0] / a[0] for a, b in zip(nm['main'], nm[t])]
        cl = [y[2] for y in nm[t] if y[2]]
        print(f'  {LBL[t]:5} score {", ".join(f"{y:.1f}" for y in x)} | median {sm[t]:.1f} spread {spread(x):.1f} % | x{sm[t]/sm["main"]:.3f} '
              f'(per-round {", ".join(f"{p:.3f}" for p in pr)})' + (f' | {st.mean(c["mhz"] for c in cl):.0f} MHz {st.mean(c["w"] for c in cl):.0f} W' if cl else ''))
    summary['nm'] = sm
    if all(t in sm for t in TREES):
        a, b = sm['p235'] / sm['main'], sm['p236'] / sm['main']
        print(f'  compounding: product x{a:.3f} * x{b:.3f} = x{a*b:.3f}; measured both x{sm["both"]/sm["main"]:.3f} = {100*(sm["both"]/sm["main"])/(a*b):.1f} % of the product')
    for k in nm['main'][0][1]:
        line = []
        rm = [x[1][k]['rate'] for x in nm['main'] if x[1].get(k, {}).get('rate')]
        for t in TREES:
            if t not in nm:
                continue
            r = [x[1][k]['rate'] for x in nm[t] if x[1].get(k, {}).get('rate')]
            if r:
                line.append(f'{LBL[t]} {med(r):.4g} ({min(r):.4g}-{max(r):.4g}) x{med(r)/med(rm):.3f}')
        s0 = nm['main'][0][1][k]
        print(f'  {k} b{s0.get("base")} route={s0.get("route")}: ' + ' | '.join(line))
    for k in nm['main'][0][1]:
        for t in TREES:
            if t in nm:
                js = [x[1][k].get('join') or {} for x in nm[t]]
                if js[0]:
                    print(f'  counts {k} {LBL[t]}: survivors {sorted(set(j.get("survivors") for j in js))} checked {sorted(set(j.get("checked") for j in js))}')
