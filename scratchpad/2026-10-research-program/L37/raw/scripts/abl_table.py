#!/usr/bin/env python3
"""L37: markdown breakdown table from the ablation logs. python3 abl_table.py DIR"""
import sys, glob, os, statistics as st, importlib.util
spec = importlib.util.spec_from_file_location('abl', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'abl.py'))
D = sys.argv[1]
sys.argv = [sys.argv[0], D]
import io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    abl = importlib.util.module_from_spec(spec); spec.loader.exec_module(abl)
med = st.median
out = {}
for fld in ['e17_b62', 'e16_b60']:
    R = {}
    for tag in 'cabpzd':
        runs = []
        for f in sorted(glob.glob(f'{D}/abl_{tag}_{fld}_r*.log')):
            p = abl.prof(f)
            if p:
                d = {k: sum(x.get(k, 0) for x in p) / len(p) for k in abl.KEYS}
                d['mhz'] = abl.smi(f[:-4] + '.smi')
                d['gcyc'] = d['join'] * d['mhz'] / 1000
                runs.append(d)
        R[tag] = runs
    out[fld] = R
def J(fld, t): return med([r['join'] for r in out[fld][t]])
def G(fld, t): return med([r['gcyc'] for r in out[fld][t]])
def M(fld, t): return st.mean([r['mhz'] for r in out[fld][t]])
def F(fld, t): return med([r['device_wall'] - r['probe'] for r in out[fld][t]])
def rr(fld, t): return ', '.join(f"{r['join']:.2f}" for r in out[fld][t])
rows = [('base: no AND (mode z): work items, top batch + transposed copy, entry loads + prefilter terms, per-chunk stage check (2 barriers)', 'z', None),
        ('AND: the transposed digit ORs (a − z)', 'a', 'z'),
        ('walk: rounds, set-bit pops, residue test (b − a)', 'b', 'a'),
        ('prefilter `walk_pf` (p − b)', 'p', 'b'),
        ('stage + flush (c − p)', 'c', 'p')]
print('| part | b62 1e17 s/field | % join | % field | % join in cycles | b60 1e16 s/field | % join | % field | % join in cycles |')
print('|---|---|---|---|---|---|---|---|---|')
for name, t1, t0 in rows:
    cells = []
    for fld in ['e17_b62', 'e16_b60']:
        v = J(fld, t1) - (J(fld, t0) if t0 else 0)
        g = G(fld, t1) - (G(fld, t0) if t0 else 0)
        cells.append(f'{v:.2f} | {100 * v / J(fld, "c"):.1f} % | {100 * v / F(fld, "c"):.1f} % | {100 * g / G(fld, "c"):.1f} %')
    print(f'| {name} | ' + ' | '.join(cells) + ' |')
print(f'| **join (mode c = main)** | **{J("e17_b62", "c"):.2f}** | 100 % | {100 * J("e17_b62", "c") / F("e17_b62", "c"):.1f} % | {G("e17_b62", "c"):.1f} G-cycles | **{J("e16_b60", "c"):.2f}** | 100 % | {100 * J("e16_b60", "c") / F("e16_b60", "c"):.1f} % | {G("e16_b60", "c"):.1f} G-cycles |')
print(f'| field (profiled device, probe excluded) | {F("e17_b62", "c"):.2f} | | 100 % | | {F("e16_b60", "c"):.2f} | | 100 % | |')
print()
print('| mode | NICE_EXP_JOIN_ABL | b62 1e17 join s/field (rounds) | field | SM MHz | b60 1e16 join s/field (rounds) | field | SM MHz |')
print('|---|---|---|---|---|---|---|---|')
for t, name, a in [('c', 'full (= main)', '0'), ('a', 'AND only', '1'), ('b', 'walk, no prefilter, no stage', '2'), ('p', 'walk + prefilter, no stage', '3'),
                   ('z', 'no AND', '4'), ('d', 'full, per-top AND (TMIN = 2^30)', '0 + TMIN')]:
    print(f'| {t}: {name} | {a} | {J("e17_b62", t):.2f} ({rr("e17_b62", t)}) | {F("e17_b62", t):.2f} | {M("e17_b62", t):.0f} | {J("e16_b60", t):.2f} ({rr("e16_b60", t)}) | {F("e16_b60", t):.2f} | {M("e16_b60", t):.0f} |')
