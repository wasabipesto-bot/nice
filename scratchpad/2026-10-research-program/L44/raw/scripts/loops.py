#!/usr/bin/env python3
"""List backward branches (loops) of a cuobjdump SASS file with body size and opcode mix."""
import re, sys, collections
ins = []
for line in open(sys.argv[1]):
    m = re.match(r'\s*/\*([0-9a-f]{4,})\*/\s+(.*?);', line)
    if m:
        addr = int(m.group(1), 16)
        txt = m.group(2).strip()
        ins.append((addr, txt))
print(f"{len(ins)} instructions")
def op(t):
    t = re.sub(r'^@!?U?P[0-9T]+\s+', '', t)
    return t.split()[0]
loops = []
for i, (a, t) in enumerate(ins):
    m = re.search(r'\bBRA\b.*?(0x[0-9a-f]+)', t)
    if m:
        tgt = int(m.group(1), 16)
        if tgt <= a:
            loops.append((tgt, a))
for tgt, a in sorted(loops):
    body = [t for (x, t) in ins if tgt <= x <= a]
    c = collections.Counter(op(t).split('.')[0] for t in body)
    top = ', '.join(f"{k} {v}" for k, v in c.most_common(10))
    print(f"loop {tgt:#06x}-{a:#06x}: {len(body)} instr | {top}")
c = collections.Counter(op(t).split('.')[0] for _, t in ins)
print("whole kernel:", ', '.join(f"{k} {v}" for k, v in c.most_common(25)))
