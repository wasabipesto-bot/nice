#!/usr/bin/env python3
"""L43: backward branches (loops) in a SASS dump: start, end, body size, LDS / SHFL / BAR in the body, uniform or not.
python3 loops.py FILE.sass [MINLDS]"""
import re, sys
L = []
for l in open(sys.argv[1], errors='replace'):
    m = re.match(r'\s+/\*([0-9a-f]{4,})\*/\s+(.*?)\s*;', l)
    if m: L.append((int(m.group(1), 16), m.group(2).strip()))
addr = {a: i for i, (a, _) in enumerate(L)}
mn = int(sys.argv[2]) if len(sys.argv) > 2 else 0
for i, (a, ins) in enumerate(L):
    m = re.search(r'\bBRA\s+(?:`\()?0x([0-9a-f]+)', ins)
    if m:
        t = int(m.group(1), 16)
        if t <= a and t in addr:
            body = [x for _, x in L[addr[t]:i + 1]]
            lds = sum(1 for x in body if re.search(r'\bLDS\b|LDS\.', x))
            if lds < mn: continue
            print(f'loop 0x{t:04x}-0x{a:04x}: {len(body)} instr, LDS {lds}, SHFL {sum("SHFL" in x for x in body)}, BAR {sum("BAR" in x for x in body)}, uniform-branch {"U" in ins.split()[0] or "UP" in ins}  [{ins}]')
