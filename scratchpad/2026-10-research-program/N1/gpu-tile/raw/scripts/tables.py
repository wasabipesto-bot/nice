#!/usr/bin/env python3
"""tables.py LOGDIR: RESULTS tables from the tile-harness logs (tgrid*, twalk*, tcal*).
Per (layout, config): all rounds of all processes pooled; median ps/pair, spread = [min-max] of the per-round means
(round = mean of 3 launches), and the per-process medians."""
import re, sys, glob, os, statistics as st
D = sys.argv[1]
def kv(s): return {m.group(1): m.group(2) for m in re.finditer(r'(\w+)=([^ |]+)', s)}
R = {}   # (layout, cfg) -> {proc: [ps]}
W = {}
for p in sorted(glob.glob(f'{D}/t*_L*.log')):
    name = os.path.basename(p)[:-4]
    lay = re.search(r'_L(\d+)', name).group(1)
    for l in open(p):
        if not l.startswith('N1 round='): continue
        d = kv(l)
        R.setdefault((lay, d['cfg']), {}).setdefault(name, []).append(d)
def ps(lay, cfg, k='ps_pair_mean'):
    v = [float(d[k]) for ds in R.get((lay, cfg), {}).values() for d in ds]
    return (st.median(v), min(v), max(v), len(v)) if v else None
def cell(lay, cfg):
    x = ps(lay, cfg)
    if not x: return '—'
    procs = R[(lay, cfg)]
    pm = '/'.join(f'{st.median(float(d["ps_pair_mean"]) for d in ds):.3f}' for ds in procs.values())
    return f'{x[0]:.3f} [{x[1]:.3f}–{x[2]:.3f}] ({pm})' if len(procs) > 1 else f'{x[0]:.3f} [{x[1]:.3f}–{x[2]:.3f}]'
mode = sys.argv[2] if len(sys.argv) > 2 else 'all'
SH = {'S0': '2,000 × 350', 'S1': '1,460 × 14,750', 'S2': '24 × 7,200', 'S3': '785 × 14,750'}
WN = {'u32': 'u32 (AG 4: 128 tops/iter)', 'u64a2': 'u64 AG 2 (128)', 'u64a4': 'u64 AG 4 (256)'}
if mode in ('all', 'cal'):
    print('### calibration shapes (D_B 12, u32, today orientation)\n\n| layout | 471 × 336, D_T 17 | 471 × 336, D_T 15 | 2,000 × 350, D_T 17 | 2,000 × 350, D_T 15 |\n|---|---|---|---|---|')
    for lay in ('53', '5', '1'):
        print(f'| L{lay} | ' + ' | '.join(cell(lay, f'T_B12_T{dt}_{s}_u32') for s in ('Sp', 'S0') for dt in (17, 15)) + ' |')
if mode in ('all', 'grid'):
    for lay in ('5', '1', '53'):
        for dt in (17, 15):
            if not any(k[0] == lay and f'_T{dt}_' in k[1] for k in R): continue
            print(f'\n### layout L{lay}, D_T {dt}: ps per pair, median [min–max over rounds] (per-process medians)\n')
            print('| orientation | tile (tops × entries) | word | D_B 12 | D_B 18 | D_B 20 |\n|---|---|---|---|---|---|')
            for o in ('T', 'R'):
                for s in ('S0', 'S1', 'S3', 'S2'):
                    for wn in ('u32', 'u64a2', 'u64a4'):
                        for tm in ('', '_tm1'):
                            if tm and not (o == 'T' and s == 'S2'): continue
                            cfgs = [f'{o}_B{db}_T{dt}_{s}_{wn}{tm}' for db in (12, 18, 20)]
                            if not any((lay, c) in R for c in cfgs): continue
                            on = 'today (tops transposed)' if o == 'T' else 'reverse (bottoms transposed)'
                            print(f'| {on} | {SH[s]}{" (forced transpose)" if tm else ""} | {WN[wn]} | ' + ' | '.join(cell(lay, c) for c in cfgs) + ' |')
if mode in ('all', 'walk'):
    print('\n### survivor path (walk + lean prefilter, counted not staged): per AND survivor = (walk − dense) / survivors\n')
    print('| layout | orientation | tile | word | D_B | D_T | pass | dense ps/pair | walk ps/pair | ps per survivor [min–max] | walk extra ps/pair |\n|---|---|---|---|---|---|---|---|---|---|---|')
    for lay in ('5', '1'):
        for (db, dt) in ((12, 15), (12, 17), (18, 14), (18, 15), (20, 15)):
            for s in ('S0', 'S1'):
                for wn in ('u32', 'u64a2'):
                    for o in ('T', 'R'):
                        c0 = f'{o}_B{db}_T{dt}_{s}_{wn}'; c1 = c0 + '_walk'
                        a = R.get((lay, c0)); b = R.get((lay, c1))
                        if not a or not b: continue
                        pa = [d for ds in a.values() for d in ds]; pb = [d for ds in b.values() for d in ds]
                        # pair rounds within the walk process (same round index)
                        pr = {}
                        for proc, ds in a.items():
                            for d in ds: pr.setdefault((proc, d['round']), {})['a'] = d
                        for proc, ds in b.items():
                            for d in ds: pr.setdefault((proc, d['round']), {})['b'] = d
                        per = []
                        for v in pr.values():
                            if 'a' in v and 'b' in v:
                                pairs = float(v['b']['pairs']); sv = int(v['b']['nand'])
                                per.append((float(v['b']['secs_mean']) - float(v['a']['secs_mean'])) / sv * 1e12)
                        da = st.median(float(d['ps_pair_mean']) for d in pa); dbb = st.median(float(d['ps_pair_mean']) for d in pb)
                        pas = float(pb[0]['pass']) * 100
                        on = 'today' if o == 'T' else 'reverse'
                        print(f'| L{lay} | {on} | {SH[s]} | {wn} | {db} | {dt} | {pas:.3f} % | {da:.3f} | {dbb:.3f} | {st.median(per):.2f} [{min(per):.2f}–{max(per):.2f}] | {dbb-da:.3f} |')
if mode in ('all', 'base'):
    print('\n### dense phase split (binary T2): base = no-AND mode (loads, transposed copy, one shared read per chunk), AND = full − base; ps per pair, median of rounds (both processes)\n')
    print('| layout | orientation | tile | word | D_B | full | base | AND | AND per entry digit (×1000) |\n|---|---|---|---|---|---|---|---|---|')
    SH2 = dict(SH); SH2['Sp'] = '471 × 336'
    for lay in ('5', '1'):
        for o in ('T', 'R'):
            for s in ('Sp', 'S0', 'S1'):
                for wn in ('u32', 'u64a4'):
                    for db in (12, 18, 20):
                        c0 = f'{o}_B{db}_T17_{s}_{wn}'
                        procs = [k for k in R if k[0] == lay and k[1] == c0 + '_noand']
                        if not procs: continue
                        full = [float(d['ps_pair_mean']) for proc, ds in R[(lay, c0)].items() if 'tbase' in proc for d in ds]
                        base = [float(d['ps_pair_mean']) for proc, ds in R[(lay, c0 + '_noand')].items() for d in ds]
                        f, b = st.median(full), st.median(base)
                        nd = db if o == 'T' else 17
                        on = 'today' if o == 'T' else 'reverse'
                        print(f'| L{lay} | {on} | {SH2[s]} | {wn} | {db} | {f:.3f} | {b:.3f} | {f-b:.3f} | {1000*(f-b)/nd:.1f} (/{nd}) |')
