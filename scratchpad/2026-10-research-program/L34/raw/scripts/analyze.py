#!/usr/bin/env python3
"""L34: A/B analysis. python3 analyze.py DIR (the box's /root/l34/logs copy).
One binary T (exp/join-transpose): A = switch off (per-top AND), B = NICE_EXP_JOIN_TRANSPOSE=1 (transposed AND)."""
import re, sys, glob, os, statistics as st, json

D = sys.argv[1] if len(sys.argv) > 1 else 'box'

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
    mhz, w, t = [], [], []
    if not os.path.exists(path):
        return None, None, None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        if len(p) < 8:
            continue
        try:
            if float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0])); t.append(float(p[5]))
        except ValueError:
            pass
    return (st.mean(mhz), st.mean(w), max(t)) if mhz else (None, None, None)

med = st.median
def spread(x):
    return 100 * (max(x) - min(x)) / med(x)

print('A/B, one binary F (exp/join-transpose 73cda4c): A = switch off, B = NICE_EXP_JOIN_TRANSPOSE=1 G=4. Rounds interleaved A B.')
for prefix, label in [('e17_b62', 'b62 1e17 (1 field)'), ('e16_b62', 'b62 1e16 (2 fields)'), ('e16_b60', 'b60 1e16 (2 fields)'), ('e16_b64', 'b64 1e16 (2 fields)')]:
    rows = {}
    for side in ['A', 'B']:
        rs = []
        for f in sorted(glob.glob(f'{D}/ab_{ {"A":"off","B":"on"}[side] }_{prefix}_r*.log')):
            t = tp(f)
            if t:
                rs.append((os.path.basename(f), t[0]) + smi(f[:-4] + '.smi'))
        rows[side] = rs
    if not rows['A'] or not rows['B']:
        print(label, 'missing'); continue
    print(f'{label}:')
    for metric in ['device', 'per_field']:
        a = [x[1][metric] for x in rows['A']]; b = [x[1][metric] for x in rows['B']]
        pairs = [aa / bb for aa, bb in zip(a, b)]
        print(f'  {metric}: A {", ".join(f"{x:.3f}" for x in a)} (median {med(a):.3f}, spread {spread(a):.1f} %) | '
              f'B {", ".join(f"{x:.3f}" for x in b)} (median {med(b):.3f}, spread {spread(b):.1f} %)')
        print(f'     speed-up x{med(a)/med(b):.3f}; per-round {", ".join(f"{p:.3f}" for p in pairs)}; saving {med(a)-med(b):.2f} s/field')
    am = [x[2] for x in rows['A'] if x[2]]; bm = [x[2] for x in rows['B'] if x[2]]
    aw = [x[3] for x in rows['A'] if x[3]]; bw = [x[3] for x in rows['B'] if x[3]]
    at = [x[4] for x in rows['A'] if x[4]]; bt = [x[4] for x in rows['B'] if x[4]]
    if am and bm:
        a = [x[1]['device'] for x in rows['A']]; b = [x[1]['device'] for x in rows['B']]
        cn = (med(a) * st.mean(am)) / (med(b) * st.mean(bm))
        print(f'  clocks A {st.mean(am):.0f} MHz {st.mean(aw):.0f} W max {max(at):.0f} C, B {st.mean(bm):.0f} MHz {st.mean(bw):.0f} W max {max(bt):.0f} C; clock-normalised x{cn:.3f}')
    sa = sorted(set((x[1]['survivors'], x[1]['checked'], x[1]['found']) for x in rows['A']))
    sb = sorted(set((x[1]['survivors'], x[1]['checked'], x[1]['found']) for x in rows['B']))
    print(f'  counts (survivors, checked, found) A {sa}')
    print(f'                                     B {sb}')
    print(f'  layout A slots={rows["A"][0][1].get("slots")} plan_mib={rows["A"][0][1].get("plan_mib")} B slots={rows["B"][0][1].get("slots")} plan_mib={rows["B"][0][1].get("plan_mib")}; setup A {med([x[1]["setup"] for x in rows["A"]]):.2f} B {med([x[1]["setup"] for x in rows["B"]]):.2f}')

print()
print('1e14 compare runs (one field per base; JOIN THROUGHPUT + STRIDE)')
for name in sorted(os.path.basename(x)[:-4] for x in glob.glob(f'{D}/cmp_*_e14.log') + glob.glob(f'{D}/scr_cmp_*_e14.log')):
    f = f'{D}/{name}.log'
    if os.path.exists(f):
        for d in tp(f):
            print(f'  {name} b{d["base"]}: survivors={d["survivors"]} checked={d["checked"]} found={d["found"]} device={d["device"]} plan_mib={d.get("plan_mib")}')
        print('   ', [l.strip()[:160] for l in open(f, errors='replace') if l.startswith('STRIDE') or 'test result' in l])

print()
print('NiceMark nice-only (--benchmark-secs 150)')
nm = {}
for side in ['A', 'B']:
    for f in sorted(glob.glob(f'{D}/nm_{ {"A":"off","B":"on"}[side] }_r*.json')):
        try:
            j = json.load(open(f))
        except Exception as e:
            print(f, 'unreadable', e); continue
        nm.setdefault(side, []).append((j.get('score'), {s['key']: s for s in j['scenarios']}))
        print(f'  {os.path.basename(f)} score={j.get("score"):.1f}')
if 'A' in nm and 'B' in nm:
    sa = [x[0] for x in nm['A']]; sb = [x[0] for x in nm['B']]
    print(f'  score median A {med(sa):.1f} (spread {spread(sa):.1f} %), B {med(sb):.1f} (spread {spread(sb):.1f} %), x{med(sb)/med(sa):.3f}; '
          f'per-round {", ".join(f"{b/a:.3f}" for a, b in zip(sa, sb))}')
    for k in nm['A'][0][1]:
        ra = [x[1][k]['rate'] for x in nm['A'] if k in x[1] and x[1][k].get('rate')]
        rb = [x[1][k]['rate'] for x in nm['B'] if k in x[1] and x[1][k].get('rate')]
        if ra and rb:
            s0 = nm['A'][0][1][k]
            ja = [x[1][k].get('join') or {} for x in nm['A']]; jb = [x[1][k].get('join') or {} for x in nm['B']]
            cnt = ''
            if ja[0]:
                cnt = f" survivors A {sorted(set(j.get('survivors') for j in ja))} B {sorted(set(j.get('survivors') for j in jb))} checked A {sorted(set(j.get('checked') for j in ja))} B {sorted(set(j.get('checked') for j in jb))}"
            print(f'  {k} b{s0.get("base")} route={s0.get("route")}: rate median A {med(ra):.4g} ({min(ra):.4g}-{max(ra):.4g}) B {med(rb):.4g} ({min(rb):.4g}-{max(rb):.4g}) x{med(rb)/med(ra):.3f}{cnt}')

print()
print('Screens: b62 1e16, 2 fields (scr_* = T 5814422, s2_* = T2 4a04000, s3_* = T3 c058bea, s4_* = T3/T2), in run order')
for f in (sorted(glob.glob(f'{D}/scr_*_r*.log') + glob.glob(f'{D}/s[234]_*_r*.log'), key=os.path.getmtime)):
    for d in tp(f):
        mhz = smi(f[:-4] + '.smi')[0]
        print(f'  {os.path.basename(f)[:-4]:14s} device={d["device"]:.3f} per_field={d["per_field"]:.3f} survivors={d["survivors"]} checked={d["checked"]} found={d["found"]} slots={d.get("slots")} mhz={mhz and round(mhz)}')

print()
print('Hybrid short A/B (chain_hx.sh): off and f = F (73cda4c) switch off / G=4; h = H (fcd6581) G=4 MIN=128. device s/field')
def runs(prefix):
    out = {}
    for f in sorted(glob.glob(f'{D}/hab_*_{prefix}_r*.log')):
        side = os.path.basename(f).split('_')[1]
        t = tp(f)
        if t:
            out.setdefault(side, []).append(t)
    return out
for prefix, label in [('e17_b62', 'b62 1e17 (1 field)'), ('e16_b62', 'b62 1e16 (2 fields)'), ('e16_b60', 'b60 1e16 (2 fields)'), ('e16_b64', 'b64 1e16 (2 fields)')]:
    r = runs(prefix)
    if 'off' not in r:
        continue
    off = [x[0]['device'] for x in r['off']]
    line = f'  {label}: off {", ".join(f"{v:.3f}" for v in off)} (median {med(off):.3f})'
    for side in ['f', 'h']:
        if side in r:
            v = [x[0]['device'] for x in r[side]]
            line += f' | {side} {", ".join(f"{x:.3f}" for x in v)} (median {med(v):.3f}, x{med(off)/med(v):.3f})'
    cs = sorted(set((x[0]['survivors'], x[0]['checked']) for side in r for x in r[side]))
    print(line + f'; counts {cs}')
r = {}
for f in sorted(glob.glob(f'{D}/hab_*_e14_r*.log')):
    side = os.path.basename(f).split('_')[1]
    for d in tp(f):
        r.setdefault((d['base'], side), []).append((d['device'], d['survivors'], d['checked']))
for b in sorted(set(k[0] for k in r)):
    off = [x[0] for x in r.get((b, 'off'), [])]
    if not off:
        continue
    line = f'  b{b} 1e14 (3 fields): off {", ".join(f"{v:.3f}" for v in off)}'
    for side in ['f', 'h']:
        v = [x[0] for x in r.get((b, side), [])]
        if v:
            line += f' | {side} {", ".join(f"{x:.3f}" for x in v)} (x{st.mean(off)/st.mean(v):.3f} on means)'
    cs = sorted(set((x[1], x[2]) for side in ['off', 'f', 'h'] for x in r.get((b, side), [])))
    print(line + f'; counts {cs}')
nm = {}
for side in ['off', 'h']:
    for f in sorted(glob.glob(f'{D}/hnm_{side}_r*.json')):
        try:
            j = json.load(open(f))
        except Exception as e:
            print(f, 'unreadable', e); continue
        nm.setdefault(side, []).append((j.get('score'), {s['key']: s for s in j['scenarios']}))
if 'off' in nm and 'h' in nm:
    sa = [x[0] for x in nm['off']]; sb = [x[0] for x in nm['h']]
    print(f'  NiceMark (client_H) score off {", ".join(f"{x:.1f}" for x in sa)} | hybrid {", ".join(f"{x:.1f}" for x in sb)}: x{med(sb)/med(sa):.3f}; per round {", ".join(f"{b/a:.3f}" for a, b in zip(sa, sb))}')
    for k in nm['off'][0][1]:
        ra = [x[1][k]['rate'] for x in nm['off']]; rb = [x[1][k]['rate'] for x in nm['h']]
        print(f'    {k}: off {", ".join(f"{x:.4g}" for x in ra)} | hybrid {", ".join(f"{x:.4g}" for x in rb)}: x{med(rb)/med(ra):.3f}')
