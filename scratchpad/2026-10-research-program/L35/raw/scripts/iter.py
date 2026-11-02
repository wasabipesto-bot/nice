#!/usr/bin/env python3
"""Kernel-level iteration history: medians over rounds of cubecl_cuda_top_fd_timing lines (ns per prefix-slot)."""
import re, sys, glob, statistics as st, os
D = sys.argv[1] if len(sys.argv) > 1 else 'box'
def parse(path, prefix=None):
    rows = {}
    for line in open(path, errors='replace'):
        if 'TOPFD TIMING' not in line:
            continue
        if prefix and line.split()[0] != prefix:
            continue
        m = re.search(r'TOPFD TIMING (b\d+) (\S+) round=(\d+) prefixes=(\d+) slots=(\d+)', line)
        key = (m.group(1), m.group(2), m.group(5))
        cons, gap = line.split('| consecutive')[1].split('| gapped')
        def kv(seg):
            return {k: float(v) for k, v in re.findall(r'(\w+)=([0-9.]+)', seg)}
        c, g = kv(cons), kv(gap)
        rows.setdefault(key, []).append((c, g))
    return rows
def show(path, prefix=None, tag=None):
    for key, rs in parse(path, prefix).items():
        def med(side, k):
            vals = [r[0 if side == 'c' else 1].get(k) for r in rs]
            vals = [v for v in vals if v is not None]
            return st.median(vals) if vals else None
        if 'fd1' in rs[0][0]:
            c = (med('c', 'old'), med('c', 'fd1'), med('c', 'fd2')); g = (med('g', 'old'), med('g', 'fd1'), med('g', 'fd2'))
            print(f"{tag or os.path.basename(path):24s} {key[0]} {key[1]:5s} slots={key[2]:3s} n={len(rs)} | consecutive old {c[0]:.4f} fd1 {c[1]:.4f} (x{c[0]/c[1]:.3f}) fd2 {c[2]:.4f} (x{c[0]/c[2]:.3f}) | all-seed old {g[0]:.4f} fd1 {g[1]:.4f} (x{g[0]/g[1]:.3f}) fd2 {g[2]:.4f} (x{g[0]/g[2]:.3f})")
        else:
            co, cf = med('c', 'old'), med('c', 'fd'); go, gf = med('g', 'old'), med('g', 'fd')
            print(f"{tag or os.path.basename(path):24s} {key[0]} {key[1]:5s} slots={key[2]:3s} n={len(rs)} | consecutive old {co:.4f} fd {cf:.4f} (x{co/cf:.3f}) | all-seed old {go:.4f} fd {gf:.4f} (x{go/gf:.3f})")
for f in ['timing_v2_e17.log', 'timing_B3.log', 'timing_B4.log', 'timing_B6.log', 'timing_B8.log']:
    p = f'{D}/{f}'
    if os.path.exists(p):
        show(p)
for f, pre in [('abl_B5.log', None), ('abl_B7.log', None), ('abl_B8.log', None), ('wg_B7.log', None)]:
    p = f'{D}/{f}'
    if os.path.exists(p):
        tags = sorted(set(l.split()[0] for l in open(p) if 'TOPFD' in l))
        for t in tags:
            show(p, t, f'{f[:-4]} {t}')
for p in sorted(glob.glob(f'{D}/tm_*.log')):
    show(p)
