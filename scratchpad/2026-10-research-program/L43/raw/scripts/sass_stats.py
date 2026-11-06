#!/usr/bin/env python3
"""L43: per-variant join_kernel SASS statistics. python3 sass_stats.py SASSDIR TAG... (files SASSDIR/TAG/join_kernel_b{60,62,64}_1.sass
and SASSDIR/TAG/registers.txt). Prints registers, spills, instruction count and selected opcode counts per base, and the delta
against the first TAG."""
import sys, re, glob, collections, os
D, tags = sys.argv[1], sys.argv[2:]
ops = ['SHFL', 'BAR', 'LDS', 'STS', 'LDG', 'VOTE', 'FLO', 'BREV', 'POPC', 'BRA', 'IMAD', 'LOP3', 'SHF', 'SEL', 'ISETP', 'PRMT']
def stats(path):
    c = collections.Counter(); n = 0
    for line in open(path, errors='replace'):
        m = re.match(r'\s+/\*[0-9a-f]{4,}\*/\s+(@!?U?P\w+\s+)?([A-Z0-9_]+)', line)
        if m:
            n += 1; op = m.group(2)
            for o in ops:
                if op.startswith(o): c[o] += 1
    return n, c
def regs(tag, base):
    f = f'{D}/{tag}/registers.txt'
    if not os.path.exists(f): return '-'
    for line in open(f):
        if line.startswith(f'join_kernel_b{base}_1.cu'):
            r = re.search(r'Used (\d+) registers', line); s = re.findall(r'(\d+) bytes spill', line)
            return f'{r.group(1) if r else "?"} regs, spill {"/".join(s) if s else "?"}'
    return '-'
base_n = {}
print('| tag | base | registers | SASS | Δ vs ' + tags[0] + ' | ' + ' | '.join(ops) + ' |')
print('|---' * (5 + len(ops)) + '|')
for t in tags:
    for b in (60, 62, 64):
        fs = sorted(glob.glob(f'{D}/{t}/join_kernel_b{b}_1.sass'))
        if not fs: continue
        n, c = stats(fs[0])
        if t == tags[0]: base_n[b] = n
        d = n - base_n.get(b, n)
        print(f'| {t} | b{b} | {regs(t, b)} | {n} | {d:+d} | ' + ' | '.join(str(c[o]) for o in ops) + ' |')
