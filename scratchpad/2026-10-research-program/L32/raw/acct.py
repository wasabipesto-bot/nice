#!/usr/bin/env python3
"""Padding accounting tables from PAD_ACCT lines (timed fields of the off profile runs)."""
import glob, os, re, sys
D = sys.argv[1] if len(sys.argv) > 1 else 'box'
def kv(l): return dict(re.findall(r'(\w+)=([^\s|]+)', l))
for p in sorted(glob.glob(os.path.join(D, 'p_off_*.log'))):
    name = os.path.basename(p)[:-4]
    gp = [kv(l) for l in open(p, errors='replace') if 'GPU_PROFILE base=' in l][1:]
    pa = [kv(l) for l in open(p, errors='replace') if 'PAD_ACCT base=' in l][1:]
    for i, (g, a) in enumerate(zip(gp, pa)):
        pad = [int(x) for x in a['pad'].split(',')]
        pairs, padded = int(a['pairs']), int(a['padded'])
        hist = [tuple(int(y) for y in x.split(':')) for x in a['hist'].split(',') if x]
        tn = sum(h[1] for h in hist); tt = sum(h[2] for h in hist)
        print(f'## {name} field {i+1} (start {g["start"]}): live work items {tn:,}, tops x work items {tt:,}')
        print(f'   mean entries per probed bucket (tops-weighted) {pairs/tt:.1f}; lanes used per 512-lane wave {pairs/padded*100:.1f} %; empty lanes {padded-pairs:.4e} ({(padded-pairs)/padded*100:.1f} %)')
        print(f'   waves per bucket: all buckets one wave: {all(lo + 31 < 512 for lo, _, _ in hist)} (largest bin {hist[-1][0]}-{hist[-1][0]+31})')
        print(f'   tail: slots {pad[0]:.4e} = pairs x{pad[0]/pairs:.4f}; empty lanes left {pad[0]-pairs:.4e} ({(padded-pad[0])/(padded-pairs)*100:.1f} % of the empty lanes removed); plane-tops {pad[5]:.4e} -> {pad[6]:.4e} (x{pad[6]/pad[5]:.3f})')
        print(f'   EPT1: lanes {pad[2]:.4e} (x{pad[2]/padded:.4f} of EPT 2), top-waves x{pad[4]/pad[3]:.3f};  EPT4+tail slots x{pad[7]/pairs:.3f} of pairs')
        print('   | entries | work items | share of work items | share of tops (lane-pairs weight) | lanes used in its wave | tail: planes running the AND |')
        for lo, n, t in hist:
            if n / tn < 0.0005 and t / tt < 0.0005:
                continue
            mid = lo + 16
            s = -(-(-(-mid // 2)) // 32) * 32
            planes = sum(1 for q in range(s // 32) if 32 * q < mid)
            print(f'   | {lo}-{lo+31} | {n:,} | {n/tn*100:.1f} % | {t/tt*100:.1f} % | {mid/512*100:.0f} % | {planes} of 8 |')
