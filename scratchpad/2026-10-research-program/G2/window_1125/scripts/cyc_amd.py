#!/usr/bin/env python3
"""cyc_amd.py OUT TAG [DATE]: window 3 (adapted from CW/box/cyc.py for the RX 9070 XT): join each measurement line of
mo_width_bench (M s<pip> <var> mode <m> rep <r> t0 <unix> t1 <unix> ms <x>) in OUT/cw_TAG.txt with smp.sh's samples
(OUT/cw_TAG.gpu, UTC time of day on DATE, default 2026-11-25) and report per (slice, variant, mode) the median ms and
the median shader clock / power / busy over the measurement's interval; phase 3b = full - no-3b (mode 1 - mode 0) in ms
and in cycles; ps per pair from the dump's `pairs`; and each variant's 3b ratio against w64 (the x1.35 rule)."""
import sys, re, datetime, statistics as st, collections, bisect, glob, os
out, tag = sys.argv[1], sys.argv[2]
day = sys.argv[3] if len(sys.argv) > 3 else '2026-11-25'
smp = []
for l in open(f'{out}/cw_{tag}.gpu'):
    m = re.match(r'(\d\d:\d\d:\d\d\.\d+) busy=(\d+) sclk=(\d+) pw=(\d+)', l)
    if m:
        t = datetime.datetime.strptime(f'{day} {m.group(1)}', '%Y-%m-%d %H:%M:%S.%f').replace(tzinfo=datetime.timezone.utc).timestamp()
        smp.append((t, float(m.group(3)), float(m.group(4)), float(m.group(2))))
smp.sort()
ts = [x[0] for x in smp]
pairs = {}
for p in glob.glob(f'{out}/cw_dump_*.txt'):
    pip = re.search(r'cw_dump_(\d+)', p).group(1)
    m = re.search(r'WIDTH 64 .* pairs (\d+)', open(p).read())
    if m:
        pairs['s' + pip] = int(m.group(1))
M = collections.defaultdict(list)
for l in open(f'{out}/cw_{tag}.txt'):
    if not l.startswith('M '):
        continue
    f = l.split()
    pip, var, mode, t0, t1, ms = f[1], f[2], int(f[4]), float(f[8]), float(f[10]), float(f[12])
    i, j = bisect.bisect_left(ts, t0), bisect.bisect_right(ts, t1)
    sel = smp[i:j] or smp[max(0, i - 1):i + 1]
    M[(pip, var, mode)].append((ms, st.mean(x[1] for x in sel), st.mean(x[2] for x in sel), ms * st.mean(x[1] for x in sel), st.mean(x[3] for x in sel), len(smp[i:j])))
keys = sorted({(p, v) for (p, v, m) in M})
print('| slice | variant | full ms | no-3b ms | no-store ms | 3b ms | 3b ps/pair | x3b vs w64 | 3b Mcycles | x3b cycles vs w64 | MHz (full) | W (full) | busy % (full) | samples in full intervals | n |')
print('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
res = {}
for p, v in keys:
    g = {m: M[(p, v, m)] for m in (1, 0, 3)}
    med = lambda m, k: st.median(x[k] for x in g[m])
    f, z, ns = med(1, 0), med(0, 0), med(3, 0)
    res[(p, v)] = (f - z, (med(1, 3) - med(0, 3)) / 1e3)
for p, v in keys:
    g = {m: M[(p, v, m)] for m in (1, 0, 3)}
    med = lambda m, k: st.median(x[k] for x in g[m])
    f, z, ns = med(1, 0), med(0, 0), med(3, 0)
    b, cyc = res[(p, v)]
    b64, c64 = res.get((p, 'w64'), (None, None))
    pp = b * 1e-3 / pairs[p] * 1e12 if p in pairs else float('nan')
    print(f'| {p} | {v} | {f:.4f} | {z:.4f} | {ns:.4f} | {b:.4f} | {pp:.4f} | x{b64 / b:.3f} | {cyc:.3f} | x{c64 / cyc:.3f} | {med(1, 1):.0f} | {med(1, 2):.0f} | {med(1, 4):.0f} | {sum(x[5] for x in g[1])} | {len(g[1])} |' if b64 else f'| {p} | {v} | {f:.4f} | {z:.4f} | {ns:.4f} | {b:.4f} | {pp:.4f} | - | {cyc:.3f} | - | {med(1, 1):.0f} | {med(1, 2):.0f} | {med(1, 4):.0f} | {sum(x[5] for x in g[1])} | {len(g[1])} |')
print('\nMeans over slices (3b ratio against w64, ms and cycles):')
for v in sorted({v for _, v in keys}):
    r = [res[(p, 'w64')][0] / res[(p, v)][0] for p, vv in keys if vv == v and (p, 'w64') in res]
    rc = [res[(p, 'w64')][1] / res[(p, v)][1] for p, vv in keys if vv == v and (p, 'w64') in res]
    pp = [res[(p, v)][0] * 1e-3 / pairs[p] * 1e12 for p, vv in keys if vv == v and p in pairs]
    print(f'- {v}: 3b x{st.mean(r):.3f} (ms), x{st.mean(rc):.3f} (cycles) vs w64; {st.mean(pp):.4f} ps per pair' if r else f'- {v}')
