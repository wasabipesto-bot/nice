#!/usr/bin/env python3
"""Combined #235 + #236 A/B analysis: python3 analyze.py DIR (the box's /root/cmb copy)."""
import re, sys, glob, os, statistics as st, json

D = sys.argv[1] if len(sys.argv) > 1 else 'box'
# individual PR speed-ups (time ratios main/PR) from L29/RESULTS.md (per_field) and L30/RESULTS.md (device=)
L29 = {'e17_b62': 1.075, 'e16_b62': 1.089, 'e16_b60': 1.053, 'e16_b64': 1.040, 'nm': 1.071}
L30 = {'e17_b62': 1 / 0.823, 'e16_b62': 1 / 0.846, 'e16_b60': 1 / 0.806, 'e16_b64': 1 / 0.769, 'nm': 1.194}

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
    mhz, w = [], []
    if not os.path.exists(path):
        return None, None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        if len(p) < 8:
            continue
        try:
            if float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
        except ValueError:
            pass
    return (st.mean(mhz), st.mean(w)) if mhz else (None, None)

med = st.median
def spread(x):
    return 100 * (max(x) - min(x)) / med(x)

print('A/B, A = main fae7398, B = both (#235 + #236, 0971c6e). Rounds interleaved A B.')
for prefix, label in [('e17_b62', 'b62 1e17 (1 field)'), ('e16_b62', 'b62 1e16 (2 fields)'), ('e16_b60', 'b60 1e16 (2 fields)'), ('e16_b64', 'b64 1e16 (2 fields)')]:
    rows = {}
    for side in ['m', 'p']:
        rs = []
        for f in sorted(glob.glob(f'{D}/ab_{side}_{prefix}_r*.log')):
            t = tp(f)
            if t:
                rs.append((os.path.basename(f), t[0]) + smi(f[:-4] + '.smi'))
        rows[side] = rs
    if not rows['m'] or not rows['p']:
        print(label, 'missing'); continue
    print(f'{label}:')
    for metric in ['device', 'per_field']:
        a = [x[1][metric] for x in rows['m']]; b = [x[1][metric] for x in rows['p']]
        pairs = [aa / bb for aa, bb in zip(a, b)]
        print(f'  {metric}: A {", ".join(f"{x:.3f}" for x in a)} (median {med(a):.3f}, spread {spread(a):.1f} %) | '
              f'B {", ".join(f"{x:.3f}" for x in b)} (median {med(b):.3f}, spread {spread(b):.1f} %)')
        print(f'     B/A x{med(b)/med(a):.3f} = speed-up x{med(a)/med(b):.3f}; per-round speed-up {", ".join(f"{p:.3f}" for p in pairs)}; saving {med(a)-med(b):.2f} s/field')
    am = [x[2] for x in rows['m'] if x[2]]; bm = [x[2] for x in rows['p'] if x[2]]
    aw = [x[3] for x in rows['m'] if x[3]]; bw = [x[3] for x in rows['p'] if x[3]]
    if am and bm:
        a = [x[1]['device'] for x in rows['m']]; b = [x[1]['device'] for x in rows['p']]
        cn = (med(a) * st.mean(am)) / (med(b) * st.mean(bm))
        print(f'  clocks A {st.mean(am):.0f} MHz {st.mean(aw):.0f} W, B {st.mean(bm):.0f} MHz {st.mean(bw):.0f} W; clock-normalised speed-up x{cn:.3f}')
    p29, p30 = L29[prefix], L30[prefix]
    a = [x[1]['device'] for x in rows['m']]; b = [x[1]['device'] for x in rows['p']]
    s = med(a) / med(b)
    print(f'  individual: #235 x{p29:.3f}, #236 x{p30:.3f}, product x{p29*p30:.3f}; combined (device) x{s:.3f} = {100*s/(p29*p30):.1f} % of the product')
    sa = sorted(set((x[1]['survivors'], x[1]['checked'], x[1]['found']) for x in rows['m']))
    sb = sorted(set((x[1]['survivors'], x[1]['checked'], x[1]['found']) for x in rows['p']))
    print(f'  counts (survivors, checked, found) A {sa}')
    print(f'                                     B {sb}')
    print(f'  layout A slots={rows["m"][0][1].get("slots")} plan_mib={rows["m"][0][1].get("plan_mib")} B slots={rows["p"][0][1].get("slots")} plan_mib={rows["p"][0][1].get("plan_mib")}')

print()
print('1e14 compare runs (one field per base; JOIN THROUGHPUT + STRIDE)')
for name in ['main_cmp_e14', 'both_cmp_e14']:
    f = f'{D}/{name}.log'
    if os.path.exists(f):
        for d in tp(f):
            print(f'  {name} b{d["base"]}: survivors={d["survivors"]} checked={d["checked"]} found={d["found"]} device={d["device"]} plan_mib={d.get("plan_mib")}')
        print('   ', [l.strip()[:160] for l in open(f, errors='replace') if l.startswith('STRIDE') or 'test result' in l])

print()
print('NiceMark nice-only (--benchmark-secs 150)')
nm = {}
for side in ['main', 'both']:
    for f in sorted(glob.glob(f'{D}/nm_{side}_r*.json')):
        try:
            j = json.load(open(f))
        except Exception as e:
            print(f, 'unreadable', e); continue
        nm.setdefault(side, []).append((j.get('score'), {s['key']: s for s in j['scenarios']}))
        print(f'  {os.path.basename(f)} score={j.get("score"):.1f}')
if 'main' in nm and 'both' in nm:
    sa = [x[0] for x in nm['main']]; sb = [x[0] for x in nm['both']]
    print(f'  score median main {med(sa):.1f} (spread {spread(sa):.1f} %), both {med(sb):.1f} (spread {spread(sb):.1f} %), x{med(sb)/med(sa):.3f}; '
          f'per-round {", ".join(f"{b/a:.3f}" for a, b in zip(sa, sb))}; product of the PRs x{L29["nm"]*L30["nm"]:.3f}')
    for k in nm['main'][0][1]:
        ra = [x[1][k]['rate'] for x in nm['main'] if k in x[1] and x[1][k].get('rate')]
        rb = [x[1][k]['rate'] for x in nm['both'] if k in x[1] and x[1][k].get('rate')]
        if ra and rb:
            s0 = nm['main'][0][1][k]
            ja = [x[1][k].get('join') or {} for x in nm['main']]; jb = [x[1][k].get('join') or {} for x in nm['both']]
            cnt = ''
            if ja[0]:
                cnt = f" survivors A {sorted(set(j.get('survivors') for j in ja))} B {sorted(set(j.get('survivors') for j in jb))} checked A {sorted(set(j.get('checked') for j in ja))} B {sorted(set(j.get('checked') for j in jb))}"
            print(f'  {k} b{s0.get("base")} route={s0.get("route")}: rate median A {med(ra):.4g} ({min(ra):.4g}-{max(ra):.4g}) B {med(rb):.4g} ({min(rb):.4g}-{max(rb):.4g}) x{med(rb)/med(ra):.3f}{cnt}')
