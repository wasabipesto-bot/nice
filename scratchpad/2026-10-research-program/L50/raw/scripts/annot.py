#!/usr/bin/env python3
"""Annotate one function's disassembly with per-instruction sample shares
per event, from `perf script -F event,sym,symoff` output (gzip).
usage: annot.py <binary> <symbol substring> <ips.gz> [min %]"""
import sys, gzip, re, subprocess, collections
binary, sub, ips = sys.argv[1], sys.argv[2], sys.argv[3]
minp = float(sys.argv[4]) if len(sys.argv) > 4 else 0.5
cnt = collections.defaultdict(lambda: collections.Counter())
tot = collections.Counter()
symname = None
for line in gzip.open(ips, 'rt'):
    parts = line.split()
    if len(parts) < 2:
        continue
    ev = parts[0].rstrip(':')
    m = re.match(r'(.*)\+0x([0-9a-f]+)$', parts[1])
    if not m or sub not in m.group(1):
        continue
    symname = m.group(1)
    off = int(m.group(2), 16)
    cnt[ev][off] += 1
    tot[ev] += 1
nm = subprocess.run(['nm', binary], capture_output=True, text=True).stdout
addr = None
for l in nm.splitlines():
    f = l.split()
    if len(f) == 3 and f[2] == symname:
        addr = int(f[0], 16)
dis = subprocess.run(['objdump', '-d', '--no-show-raw-insn', f'--start-address={addr}', f'--stop-address={addr+4096}', binary], capture_output=True, text=True).stdout
evs = sorted(tot)
print('samples', dict(tot))
print(' '.join(f'{e[:6]:>7}' for e in evs), ' off  insn')
for l in dis.splitlines():
    m = re.match(r'\s*([0-9a-f]+):\s+(.*)', l)
    if not m:
        continue
    off = int(m.group(1), 16) - addr
    vals = [100 * cnt[e][off] / max(tot[e], 1) for e in evs]
    if max(vals) >= minp:
        print(' '.join(f'{v:7.2f}' for v in vals), f'{off:5x}', m.group(2)[:70])
    if 'ret' in m.group(2) and off > 0 and all(cnt[e][o] == 0 for e in evs for o in range(off + 1, off + 64)) and off > max(max(cnt[e].keys(), default=0) for e in evs):
        break
