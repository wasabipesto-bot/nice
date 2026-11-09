#!/usr/bin/env python3
"""L53: the in-process A/B (chain_alt.sh; binary Y). Per base: every field's device and wall seconds by mode, the mean
per mode, and the drift-cancelling estimate: each interior field against the mean of its two neighbours (the other
mode), so a linear thermal drift cancels; speed-up = old / new. python3 analyze_alt.py ../box/logs"""
import re, sys, glob, os, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else '../box/logs'
for f in sorted(glob.glob(f'{D}/alt_*.log')):
    rows = [dict(n=int(n), mode=m, b=int(b), slices=int(sl), device=float(d), wall=float(w), sort=float(so), wait=float(wa), setup=float(se))
            for n, m, b, sl, d, w, so, wa, se in re.findall(r'L53 FIELD n=(\d+) mode=(\w+) b=(\d+) slices=(\d+) device=([0-9.]+) wall=([0-9.]+) sort_dev=([0-9.]+) prep_wait=([0-9.]+) setup=([0-9.]+)', open(f).read())]
    rows = [r for r in rows if r['n'] > 0]  # n = 0 is the 1e14 warm-up field
    thr = re.findall(r'survivors=(\d+) checked=(\d+)', open(f).read())
    print(f'## {os.path.basename(f)[:-4]}: {len(rows)} fields, {rows[0]["slices"] if rows else 0} slices each; totals {thr[-1] if thr else "-"}')
    for key in ['device', 'wall']:
        old = [r[key] for r in rows if r['mode'] == 'old']; new = [r[key] for r in rows if r['mode'] == 'new']
        nb = []
        for i in range(1, len(rows) - 1):
            a, b, c = rows[i - 1][key], rows[i][key], rows[i + 1][key]
            if rows[i]['mode'] == 'new': nb.append((a + c) / 2 / b)
            else: nb.append(b / ((a + c) / 2))
        print(f'- {key}: old mean {st.mean(old):.3f} (n={len(old)}, sd {st.pstdev(old):.3f}), new mean {st.mean(new):.3f} (n={len(new)}, sd {st.pstdev(new):.3f}): '
              f'x{st.mean(old) / st.mean(new):.4f}; neighbour ratios median x{st.median(nb):.4f} mean x{st.mean(nb):.4f} (n={len(nb)}, min {min(nb):.4f}, max {max(nb):.4f})')
    so = [r['sort'] for r in rows if r['mode'] == 'old']; wa = [r['wait'] for r in rows if r['mode'] == 'new']; wo = [r['wait'] for r in rows if r['mode'] == 'old']
    print(f'- device-thread sort per old field: mean {st.mean(so):.3f} s ({min(so):.3f}-{max(so):.3f}); prep wait per field: new {st.mean(wa):.4f} s, old {st.mean(wo):.4f} s')
    print('- fields: ' + ' '.join(f'{r["mode"][0]}{r["wall"]:.2f}' for r in rows))
    print()
