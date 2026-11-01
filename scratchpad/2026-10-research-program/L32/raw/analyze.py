#!/usr/bin/env python3
"""L32 analysis: A/B device seconds, counts, clocks; profile phases and padding accounting.
usage: analyze.py BOXDIR"""
import glob, os, re, statistics, sys
D = sys.argv[1] if len(sys.argv) > 1 else 'box'

def kv(line):
    return dict(re.findall(r'(\w+)=([^\s|]+)', line))

def clock(name):
    p = os.path.join(D, name + '.smi')
    if not os.path.exists(p):
        return None, None
    mhz, w = [], []
    for l in open(p):
        f = [x.strip() for x in l.split(',')]
        if len(f) < 8:
            continue
        try:
            u = float(f[6].split()[0]); m = float(f[1].split()[0]); pw = float(f[3].split()[0])
        except ValueError:
            continue
        if u >= 90:
            mhz.append(m); w.append(pw)
    return (statistics.mean(mhz) if mhz else None), (statistics.mean(w) if w else None)

def thr(path):
    """JOIN THROUGHPUT lines: device seconds, per_field, counts."""
    out = []
    for l in open(path, errors='replace'):
        if 'JOIN THROUGHPUT' in l:
            m = re.search(r'device=([\d.]+)s', l)
            k = kv(l)
            out.append(dict(device=float(m.group(1)), per_field=float(k['per_field']), surv=int(k['survivors']),
                            checked=int(k['checked']), found=int(k['found']), batches=int(k['batches']),
                            slots=k['slots'], plan=k['plan_mib'], fields=int(k['fields'])))
    return out

# ---- A/B
print('== A/B (device s per field; run = last JOIN THROUGHPUT line, the timed one)')
rows = {}
for p in sorted(glob.glob(os.path.join(D, 'ab*_*.log'))):
    name = os.path.basename(p)[:-4]
    m = re.match(r'ab_(\w+?)_(e1\d_b\d+)_r(\d)', name) or re.match(r'ab2_(\w+?)_(e1\d_b\d+)_r(\d)', name)
    if name.startswith('ab2_') and m:
        m = re.match(r'ab2_(\w+?)_(e1\d_b\d+)_r(\d)', name)
        arm, fld, r = m.groups()
        t = thr(p)
        if t:
            mhz, w = clock(name)
            rows.setdefault('pad2 ' + fld, {}).setdefault(arm, []).append((int(r), t[-1]['device'], mhz, t[-1]))
        continue
    if not m:
        continue
    arm, fld, r = m.groups()
    t = thr(p)
    if not t:
        print('  (no result)', name); continue
    x = t[-1]
    mhz, w = clock(name)
    dev = x['device']  # device= is already the mean per field
    rows.setdefault(fld, {}).setdefault(arm, []).append((int(r), dev, mhz, x))
for fld in sorted(rows):
    print(f'-- {fld}')
    base = rows[fld].get('base')
    bmed = statistics.median([d for _, d, _, _ in base]) if base else None
    for arm in ['base', 'tail', 't1', 't2', 'ept1', 'ept1tail', 'ept3tail', 'ept4tail', 'off']:
        if arm not in rows[fld]:
            continue
        v = sorted(rows[fld][arm])
        ds = [d for _, d, _, _ in v]
        med = statistics.median(ds)
        spread = (max(ds) - min(ds)) / med * 100
        cl = [c for _, _, c, _ in v if c]
        rr = ', '.join(f'r{r} {d:.3f} ({c:.0f} MHz)' if c else f'r{r} {d:.3f}' for r, d, c, _ in v)
        sp = f'  x{bmed/med:.4f} vs base' if bmed else ''
        cnt = {(x['surv'], x['checked'], x['found']) for _, _, _, x in v}
        print(f'  {arm:9s} median {med:.3f}  spread {spread:.1f}%  [{rr}]{sp}  counts {cnt}  batches {v[0][3]["batches"]} slots {v[0][3]["slots"]} plan {v[0][3]["plan"]}')
    # per-round ratios base/tail
    if 'tail' in rows[fld] and base:
        b = {r: d for r, d, _, _ in base}; t = {r: d for r, d, _, _ in rows[fld]['tail']}
        print('  per-round base/tail: ' + ', '.join(f'r{r} x{b[r]/t[r]:.4f}' for r in sorted(b) if r in t))
        bc = {r: c for r, _, c, _ in base}; tc = {r: c for r, _, c, _ in rows[fld]['tail']}
        try:
            print('  clock-normalised (dev x MHz): base/tail ' + ', '.join(f'r{r} x{(b[r]*bc[r])/(t[r]*tc[r]):.4f}' for r in sorted(b) if r in t))
        except TypeError:
            pass

# ---- profile + PAD_ACCT
print('\n== profile runs (timed fields only; the first line of a process is its 1e14 warm-up)')
for p in sorted(glob.glob(os.path.join(D, 'p_*.log'))):
    name = os.path.basename(p)[:-4]
    gp = [kv(l) for l in open(p, errors='replace') if 'GPU_PROFILE base=' in l]
    pa = [l for l in open(p, errors='replace') if 'PAD_ACCT base=' in l]
    for g, a in list(zip(gp, pa))[1:]:
        k = kv(a)
        pad = [int(x) for x in k['pad'].split(',')]
        pairs, padded = int(k['pairs']), int(k['padded'])
        dev = float(g['device_wall']); join = float(g['join']); top = float(g['top'])
        print(f'-- {name} start={g["start"]} dev={dev:.2f} join={join:.2f} ({join/dev*100:.1f}%) top={top:.2f} check={float(g["check"]):.2f} '
              f'tops={int(g["tops"]):.4e} surv={int(g["survivors"]):.4e} checked={int(g["checked"]):.4e} spilled={g["spilled"]}')
        print(f'   pairs={pairs:.4e} padded={padded:.4e} (x{padded/pairs:.3f}, empty {(padded-pairs)/padded*100:.1f}%)'
              f' | tail slots {pad[0]:.4e} (x{pad[0]/pairs:.3f}) | stride-256 per-plane {pad[1]:.4e} (x{pad[1]/pairs:.3f})'
              f' | EPT1 lanes {pad[2]:.4e} (x{pad[2]/pairs:.3f}) | EPT4+tail {pad[7]:.4e} (x{pad[7]/pairs:.3f})')
        print(f'   top-waves EPT2 {pad[3]:.4e}  EPT1 {pad[4]:.4e} (x{pad[4]/pad[3]:.3f})  EPT4 {pad[8]:.4e} | plane-tops now {pad[5]:.4e}  tail {pad[6]:.4e} (x{pad[6]/pad[5]:.3f})')
        hist = [tuple(int(y) for y in x.split(':')) for x in k['hist'].split(',') if x]
        tn = sum(h[1] for h in hist); tt = sum(h[2] for h in hist)
        cum = 0; out = []
        for lo, n, t in hist:
            cum += t
            out.append(f'{lo}-{lo+31}:{n/tn*100:.1f}%/{t/tt*100:.1f}%')
        print('   ne bins (work items% / tops%): ' + ' '.join(out))
