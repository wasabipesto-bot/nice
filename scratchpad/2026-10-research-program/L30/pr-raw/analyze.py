#!/usr/bin/env python3
"""L30 PR A/B analysis: python3 analyze.py DIR (the box's /root/l30pr copy)."""
import re, sys, glob, os, statistics as st, json

D = sys.argv[1] if len(sys.argv) > 1 else '.'

def tp(path):
    """JOIN THROUGHPUT lines of a run log -> list of dicts (warm-up excluded: the harness prints only timed fields)."""
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
    """mean SM MHz and W over samples with util >= 90 %."""
    mhz, w = [], []
    if not os.path.exists(path):
        return None, None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        if len(p) < 8:
            continue
        try:
            util = float(p[6].split()[0])
            if util >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
        except ValueError:
            pass
    if not mhz:
        return None, None
    return st.mean(mhz), st.mean(w)

def scen(prefix):
    rows = {}
    for side in ['m', 'p']:
        rs = []
        for f in sorted(glob.glob(f'{D}/ab_{side}_{prefix}_r*.log')):
            t = tp(f)
            if not t:
                continue
            mhz, w = smi(f[:-4] + '.smi')
            rs.append((os.path.basename(f), t[0], mhz, w))
        rows[side] = rs
    return rows

def med(x):
    return st.median(x)

print('A/B (device s per field, from JOIN THROUGHPUT device=; A = main, B = PR)')
for prefix, label in [('e16_b62', 'b62 1e16 (2 fields)'), ('e16_b60', 'b60 1e16 (2 fields)'), ('e16_b64', 'b64 1e16 (2 fields)'), ('e17_b62', 'b62 1e17 (1 field)')]:
    r = scen(prefix)
    if not r['m'] or not r['p']:
        print(label, 'missing'); continue
    a = [x[1]['device'] for x in r['m']]; b = [x[1]['device'] for x in r['p']]
    am = [x[2] for x in r['m'] if x[2]]; bm = [x[2] for x in r['p'] if x[2]]
    aw = [x[3] for x in r['m'] if x[3]]; bw = [x[3] for x in r['p'] if x[3]]
    ratio = med(b) / med(a)
    pairs = [bb / aa for aa, bb in zip(a, b)]
    cn = (med(b) * st.mean(bm)) / (med(a) * st.mean(am)) if am and bm else float('nan')
    print(f'{label}: A {", ".join(f"{x:.3f}" for x in a)} | B {", ".join(f"{x:.3f}" for x in b)}')
    print(f'   median A {med(a):.3f} (spread {100*(max(a)-min(a))/med(a):.1f} %), B {med(b):.3f} (spread {100*(max(b)-min(b))/med(b):.1f} %); ratio x{ratio:.3f}; per-round B/A {", ".join(f"{p:.3f}" for p in pairs)}; saving {med(a)-med(b):.2f} s/field')
    print(f'   clocks A {st.mean(am):.0f} MHz {st.mean(aw):.0f} W, B {st.mean(bm):.0f} MHz {st.mean(bw):.0f} W; clock-normalised x{cn:.3f}')
    sa = sorted(set((x[1]['survivors'], x[1]['checked'], x[1]['found']) for x in r['m']))
    sb = sorted(set((x[1]['survivors'], x[1]['checked'], x[1]['found']) for x in r['p']))
    print(f'   counts (AND survivors, checked, found) A {sa} B {sb}')
    print(f'   layout A slots={r["m"][0][1].get("slots")} plan_mib={r["m"][0][1].get("plan_mib")} B slots={r["p"][0][1].get("slots")} plan_mib={r["p"][0][1].get("plan_mib")}')

print()
print('1e14 compare runs (one field per base; JOIN THROUGHPUT + STRIDE)')
for name in ['m_cmp_e14', 'pr2_cmp_e14']:
    f = f'{D}/{name}.log'
    if os.path.exists(f):
        for d in tp(f):
            print(f'  {name} b{d["base"]}: survivors={d["survivors"]} checked={d["checked"]} found={d["found"]} device={d["device"]} plan_mib={d.get("plan_mib")}')
        print('   ', [l.strip() for l in open(f) if l.startswith('STRIDE') or 'test result' in l])

print()
print('NiceMark nice-only (--benchmark-secs 150)')
nm = {}
for side in ['main', 'pr']:
    for f in sorted(glob.glob(f'{D}/nm_{side}_r*.json')):
        try:
            j = json.load(open(f))
        except Exception as e:
            print(f, 'unreadable', e); continue
        sc = {s['key']: s for s in j['scenarios']}
        nm.setdefault(side, []).append((j.get('score'), sc))
        print(f'  {os.path.basename(f)} score={j.get("score"):.1f} sha={j.get("build_sha")}')
if 'main' in nm and 'pr' in nm:
    sa = [x[0] for x in nm['main']]; sb = [x[0] for x in nm['pr']]
    print(f'  score median main {med(sa):.1f} (spread {100*(max(sa)-min(sa))/med(sa):.1f} %), pr {med(sb):.1f} (spread {100*(max(sb)-min(sb))/med(sb):.1f} %), ratio x{med(sb)/med(sa):.3f}')
    keys = list(nm['main'][0][1].keys())
    for k in keys:
        ra = [x[1][k]['rate'] for x in nm['main'] if k in x[1] and x[1][k].get('rate')]
        rb = [x[1][k]['rate'] for x in nm['pr'] if k in x[1] and x[1][k].get('rate')]
        if ra and rb:
            s0 = nm['main'][0][1][k]
            route = s0.get('route')
            ja = [x[1][k].get('join') or {} for x in nm['main']]; jb = [x[1][k].get('join') or {} for x in nm['pr']]
            cnt = ''
            if ja[0]:
                cnt = f" survivors A {sorted(set(j.get('survivors') for j in ja))} B {sorted(set(j.get('survivors') for j in jb))} checked A {sorted(set(j.get('checked') for j in ja))} B {sorted(set(j.get('checked') for j in jb))}"
            print(f'  {k} b{s0.get("base")} route={route}: rate median A {med(ra):.4g} B {med(rb):.4g} x{med(rb)/med(ra):.3f} (A {", ".join(f"{x:.4g}" for x in ra)}; B {", ".join(f"{x:.4g}" for x in rb)}){cnt}')
