#!/usr/bin/env python3
"""L34 follow-up: the gate screen (mn_*: H fcd6581, G=4, NICE_EXP_JOIN_TRANSPOSE_MIN = 128/192/256 vs switch off) and
the PR A/B (pab_*: #236's head fb05597 vs pr/join-transpose-and 1298ce7; prt = the PR with survivors' top ids from the list, 1e14 only). python3 analyze2.py DIR"""
import re, sys, glob, os, json, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else 'box'
med = st.median
def tp(path):
    out = []
    for line in open(path, errors='replace'):
        if 'JOIN THROUGHPUT' not in line:
            continue
        d = {}
        for k in ['base', 'device', 'per_field', 'survivors', 'checked', 'found', 'slots', 'plan_mib']:
            m = re.search(r'\b' + k + r'=([0-9.e+]+)s?\b', line)
            if m:
                d[k] = float(m.group(1)) if any(c in m.group(1) for c in '.e') else int(m.group(1))
        out.append(d)
    return out
def smi(path):
    mhz, w = [], []
    if not os.path.exists(path):
        return None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        if len(p) < 8:
            continue
        try:
            if float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
        except ValueError:
            pass
    return (st.mean(mhz), st.mean(w)) if mhz else None
def table(prefix, sides, ref, fields):
    for key, label in fields:
        rows = {}
        for s in sides:
            for f in sorted(glob.glob(f'{D}/{prefix}_{s}_{key}_r*.log')):
                t = tp(f)
                if t:
                    rows.setdefault(s, []).append((t, smi(f[:-4] + '.smi')))
        if ref not in rows:
            continue
        if key.startswith('e14'):
            for b in sorted(set(d['base'] for t, _ in rows[ref] for d in t)):
                o = [d['device'] for t, _ in rows[ref] for d in t if d['base'] == b]
                line = f'  b{b} 1e14 (3 fields): {ref} {", ".join(f"{x:.3f}" for x in o)}'
                for s in sides:
                    if s == ref or s not in rows:
                        continue
                    v = [d['device'] for t, _ in rows[s] for d in t if d['base'] == b]
                    line += f' | {s} {", ".join(f"{x:.3f}" for x in v)} x{st.mean(o)/st.mean(v):.3f}'
                cs = sorted(set((d['survivors'], d['checked']) for s in rows for t, _ in rows[s] for d in t if d['base'] == b))
                print(line + f'  counts {cs}')
            continue
        o = [t[0]['device'] for t, _ in rows[ref]]
        line = f'  {label}: {ref} {", ".join(f"{x:.3f}" for x in o)} (med {med(o):.3f}, spread {100*(max(o)-min(o))/med(o):.1f} %)'
        for s in sides:
            if s == ref or s not in rows:
                continue
            v = [t[0]['device'] for t, _ in rows[s]]
            pr = [a / b for a, b in zip(o, v)]
            line += f' | {s} {", ".join(f"{x:.3f}" for x in v)} (med {med(v):.3f}, spread {100*(max(v)-min(v))/med(v):.1f} %) x{med(o)/med(v):.3f} per-round {", ".join(f"{p:.3f}" for p in pr)}'
        print(line)
        clk = '; '.join(f'{s} {st.mean([c[0] for _, c in rows[s] if c]):.0f} MHz {st.mean([c[1] for _, c in rows[s] if c]):.0f} W' for s in sides if s in rows)
        cs = sorted(set((t[0]['survivors'], t[0]['checked'], t[0]['found']) for s in rows for t, _ in rows[s]))
        lay = sorted(set((t[0].get('slots'), t[0].get('plan_mib')) for s in rows for t, _ in rows[s]))
        print(f'     clocks: {clk}; counts {cs}; slots/plan MiB {lay}')
def nm(prefix, sides, ref):
    d = {}
    for s in sides:
        for f in sorted(glob.glob(f'{D}/{prefix}_{s}_r*.json')):
            j = json.load(open(f))
            d.setdefault(s, []).append((j['score'], {x['key']: x for x in j['scenarios']}))
    if ref not in d:
        return
    o = [x[0] for x in d[ref]]
    print(f'  NiceMark score {ref} {", ".join(f"{x:.1f}" for x in o)}')
    for s in sides:
        if s == ref or s not in d:
            continue
        v = [x[0] for x in d[s]]
        print(f'  NiceMark score {s} {", ".join(f"{x:.1f}" for x in v)} x{st.mean(v)/st.mean(o):.3f} (means), per round {", ".join(f"{b/a:.3f}" for a, b in zip(o, v))}')
        for k in d[ref][0][1]:
            ro = [x[1][k]['rate'] for x in d[ref]]; rv = [x[1][k]['rate'] for x in d[s]]
            co = sorted(set((x[1][k].get('join') or {}).get('survivors') for x in d[ref])); cv = sorted(set((x[1][k].get('join') or {}).get('survivors') for x in d[s]))
            print(f'     {k}: {ref} {", ".join(f"{x:.4g}" for x in ro)} | {s} {", ".join(f"{x:.4g}" for x in rv)} x{st.mean(rv)/st.mean(ro):.3f}; survivors {ref} {co} {s} {cv}')
F = [('e17_b62', 'b62 1e17 (1 field)'), ('e16_b62', 'b62 1e16 (2 fields)'), ('e16_b60', 'b60 1e16 (2 fields)'), ('e16_b64', 'b64 1e16 (2 fields)'), ('e14', '1e14')]
print('Gate screen (H fcd6581, G=4; off = switch off; mNNN = NICE_EXP_JOIN_TRANSPOSE_MIN=NNN), device s/field, ratio of medians (1e14: of means)')
table('mn', ['off', 'm128', 'm192', 'm256'], 'off', F)
nm('mnm', ['off', 'm128', 'm192', 'm256'], 'off')
print()
print("PR A/B: base = #236's head fb05597 (B236), pr = pr/join-transpose-and (P192)")
table('pab', ['base', 'pr', 'prt'], 'base', F)
nm('pnm', ['base', 'pr'], 'base')
