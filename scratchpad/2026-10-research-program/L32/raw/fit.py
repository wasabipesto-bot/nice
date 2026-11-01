#!/usr/bin/env python3
"""Join cost re-fit on the combined tree (profiled runs, timed fields), and the off->tail differences.
uv run --with numpy python3 fit.py box"""
import glob, os, re, sys
import numpy as np
D = sys.argv[1] if len(sys.argv) > 1 else 'box'
def kv(l): return dict(re.findall(r'(\w+)=([^\s|]+)', l))
rows = []
for p in sorted(glob.glob(os.path.join(D, 'p_*.log'))):
    name = os.path.basename(p)[:-4]
    mode = name.split('_')[1]
    gp = [kv(l) for l in open(p, errors='replace') if 'GPU_PROFILE base=' in l][1:]
    pa = [kv(l) for l in open(p, errors='replace') if 'PAD_ACCT base=' in l][1:]
    for g, a in zip(gp, pa):
        pad = [int(x) for x in a['pad'].split(',')]
        pairs, padded = int(a['pairs']), int(a['padded'])
        execd = pad[0] if mode == 'tail' else padded
        planes = pad[6] if mode == 'tail' else pad[5]
        rows.append(dict(name=name, mode=mode, base=g['base'], start=g['start'], size=g['size'], join=float(g['join']), dev=float(g['device_wall']),
                         probe=float(g['probe']), pairs=pairs, empty=execd - pairs, surv=int(g['survivors']), tops=int(g['tops']),
                         planes=planes, waves=pad[3], wi=int(g['live_buckets'])))
def fit(rs, cols, label):
    X = np.array([[r[c] for c in cols] for r in rs], float)
    y = np.array([r['join'] for r in rs])
    W = 1 / y
    coef, *_ = np.linalg.lstsq(X * W[:, None], y * W, rcond=None)
    pred = X @ coef
    rel = (pred - y) / y
    print(f'{label}: ' + ', '.join(f'{c} {v*1e12:.3f} ps' for c, v in zip(cols, coef)) + f'  | rms {np.sqrt(np.mean(rel**2))*100:.1f} %, max {np.max(np.abs(rel))*100:.1f} %  (n={len(rs)})')
    for r, pr in zip(rs, pred):
        parts = ' '.join(f'{c}={r[c]*v:.2f}s' for c, v in zip(cols, coef))
        print(f'    {r["name"]:16s} {r["start"][:8]} join {r["join"]:.2f} pred {pr:.2f} ({(pr-r["join"])/r["join"]*100:+.1f} %)  {parts}')
    return coef
off = [r for r in rows if r['mode'] == 'off']
fit(off, ['pairs', 'empty', 'surv', 'tops'], 'off runs, 4-term (PROFILE-3 form)')
fit(rows, ['pairs', 'empty', 'surv', 'tops'], 'off + tail runs, 4-term (empty = AND slots run - pairs)')
fit(rows, ['pairs', 'empty', 'surv', 'tops', 'planes'], 'off + tail runs, 5-term (+ plane-tops running the AND)')
print('\nper-field differences off -> tail (same field, profiled):')
by = {}
for r in rows:
    by.setdefault((r['base'], r['size'], r['start']), {})[r['mode']] = r
for k, d in sorted(by.items()):
    if 'off' in d and 'tail' in d:
        o, t = d['off'], d['tail']
        dj = o['join'] - t['join']; de = o['empty'] - t['empty']; dp = o['planes'] - t['planes']
        print(f'  b{k[0]} size {float(k[1]):.0e} {k[2][:8]}: join {o["join"]:.2f} -> {t["join"]:.2f} (-{dj:.2f} s, {dj/o["join"]*100:.1f} % of join); device (probe excl.) {o["dev"]-o["probe"]:.2f} -> {t["dev"]-t["probe"]:.2f} '
              f'(x{(o["dev"]-o["probe"])/(t["dev"]-t["probe"]):.4f}); empty slots removed {de:.3e} -> {dj/de*1e12:.3f} ps each; plane-tops removed {dp:.3e} -> {dj/dp*1e12:.1f} ps each')
