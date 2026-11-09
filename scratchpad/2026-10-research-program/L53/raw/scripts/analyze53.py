#!/usr/bin/env python3
"""L53: the A/B of N (layer sort off the device thread) against B (87958fd), from the box logs.
python3 analyze53.py ../box/logs   ->  per field: device s and wall s per field (medians of rounds, per round),
speed-up (B / N), cycle ratio (device s x mean SM MHz at >= 90 % utilisation), counts, join-kernel variants,
and the sort timing (sort_timing.log)."""
import re, sys, glob, os, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else '../box/logs'
def thr(path):
    t = open(path, errors='replace').read()
    m = re.findall(r'JOIN THROUGHPUT.*?base=(\d+) fields=(\d+).*?secs=([0-9.]+) per_field=([0-9.]+).*?setup=([0-9.]+)s device=([0-9.]+)s wall=([0-9.]+)s batches=(\d+).*?survivors=(\d+) checked=(\d+) found=(\d+)', t)
    if not m: return None
    b, f, secs, pf, setup, dev, wall, bt, s, c, fo = m[-1]
    return dict(base=int(b), fields=int(f), secs=float(secs), per_field=float(pf), setup=float(setup), device=float(dev),
                wall=float(wall), batches=int(bt), survivors=int(s), checked=int(c), found=int(fo))
def smi(path, floor=90):
    mhz, w = [], []
    if not os.path.exists(path): return None, None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) >= 8 and float(p[6].split()[0]) >= floor:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
        except (ValueError, IndexError): pass
    return (st.mean(mhz) if mhz else None), (st.mean(w) if w else None)
def jit(path):
    if not os.path.exists(path): return '-'
    v = re.findall(r'regs=(\d+) local=(\d+) sass=(\d+) stl=(\d+)', open(path).read())
    return ' '.join(f'{r}r' + (f'+{l}B' if l != '0' else '') for r, l, s, x in v) or '-'
EXPECT = {'e17_b62': (1020844021499, 62584252554), 'e16_b60': (460847952346, 30871838404),
          'e16_b62': (163513599082, 10027698695), 'e16_b64': (787584956227, 47900853327)}
med = st.median
print('# L53 A/B: B = 87958fd (#249 head), N = 87958fd + the layer-sort commit; device s/field and wall s/field\n')
for fld, label in [('e17_b62', 'b62 1e17, 1 field'), ('e16_b60', 'b60 1e16, 2 fields'), ('e16_b62', 'b62 1e16, 2 fields'), ('e16_b64', 'b64 1e16, 2 fields')]:
    rows = {}
    for t in 'BN':
        for f in sorted(glob.glob(f'{D}/ab_{t}_{fld}_r[0-9].log')):
            r = int(re.search(r'_r(\d)\.log$', f).group(1))
            x = thr(f)
            if not x: print('  no result:', f); continue
            x['mhz'], x['w'] = smi(f[:-4] + '.smi')
            x['jit'] = jit(f[:-4] + '_jit.txt')
            x['spilled_before'] = len(glob.glob(f'{D}/ab_{t}_{fld}_r{r}_spill*.log'))
            rows[(t, r)] = x
    rounds = sorted({r for _, r in rows})
    if not rounds: continue
    print(f'## {label}')
    print('| round | side | device s/field | wall s/field | setup s (mean/field) | MHz | W | join kernel | spill re-runs | survivors / checked | exact |')
    print('|---|---|---|---|---|---|---|---|---|---|---|')
    for r in rounds:
        for t in 'BN':
            x = rows.get((t, r))
            if not x: continue
            ok = (x['survivors'], x['checked']) == EXPECT[fld]
            print(f"| {r} | {t} | {x['device']:.3f} | {x['per_field']:.3f} | {x['setup']:.3f} | {x['mhz'] or 0:.0f} | {x['w'] or 0:.0f} | {x['jit']} | {x['spilled_before']} | {x['survivors']:,} / {x['checked']:,} | {'yes' if ok else 'NO'} |")
    both = [r for r in rounds if ('B', r) in rows and ('N', r) in rows]
    def summ(key):
        bs = [rows[('B', r)][key] for r in both]; ns = [rows[('N', r)][key] for r in both]
        per = [rows[('B', r)][key] / rows[('N', r)][key] for r in both]
        return med(bs), med(ns), med(bs) / med(ns), per
    for key, name in [('device', 'device'), ('per_field', 'wall')]:
        mb, mn, sp, per = summ(key)
        print(f"- **{name}**: B {mb:.3f} s ({', '.join(f'{rows[(chr(66), r)][key]:.2f}' for r in both)}), N {mn:.3f} s ({', '.join(f'{rows[(chr(78), r)][key]:.2f}' for r in both)}): **x{sp:.3f}** (per round {', '.join(f'{p:.3f}' for p in per)})")
    cyc = [rows[('B', r)]['device'] * rows[('B', r)]['mhz'] / (rows[('N', r)]['device'] * rows[('N', r)]['mhz']) for r in both if rows[('B', r)]['mhz'] and rows[('N', r)]['mhz']]
    cw = [rows[('B', r)]['per_field'] * rows[('B', r)]['mhz'] / (rows[('N', r)]['per_field'] * rows[('N', r)]['mhz']) for r in both if rows[('B', r)]['mhz'] and rows[('N', r)]['mhz']]
    mB = med([rows[('B', r)]['mhz'] for r in both if rows[('B', r)]['mhz']]); mN = med([rows[('N', r)]['mhz'] for r in both if rows[('N', r)]['mhz']])
    print(f"- **clock-normalised** (s x mean SM MHz): device x{med(cyc):.3f} (per round {', '.join(f'{c:.3f}' for c in cyc)}), wall x{med(cw):.3f}; MHz B {mB:.0f} / N {mN:.0f}")
    print()
sp = glob.glob(f'{D}/ab_*_spill*_jit.txt')
print(f'spill-variant processes re-run: {len(sp)}' + (': ' + ', '.join(os.path.basename(x)[:-8] for x in sorted(sp)) if sp else ''))
for f in ['sort_timing.log']:
    p = f'{D}/{f}'
    if os.path.exists(p):
        print(f'\n## {f}')
        for line in open(p):
            if 'L53 FIELD' in line: print('-', line.strip())
