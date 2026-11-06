#!/usr/bin/env python3
"""L41: the walk loops of join_kernel SASS dumps (L40's walkloop.py rule: for each VOTE.ANY P, the loop from the backward
branch's target to that branch), with the instructions from the loop head to the stage (the warp-aggregated ATOMS block,
from its S2R LANEID) counted by pipe (L41 classify.py's pipes). python3 walkcount.py FILE.sass..."""
import re, sys, collections
def pipe(o):
    b = o.split('.')[0]
    if b.startswith('U') or b in ('VOTEU', 'R2UR', 'S2UR'): return 'UNI'
    if b in ('IMAD',): return 'FMA'
    if b in ('FLO', 'POPC', 'BREV', 'MUFU', 'I2F', 'F2I'): return 'XU'
    if b in ('LDS', 'STS', 'ATOMS', 'SHFL', 'S2R', 'CS2R'): return 'MIO'
    if b in ('LDG', 'STG', 'ATOMG', 'RED'): return 'MEM'
    if b in ('BRA', 'BSSY', 'BSYNC', 'NOP', 'BAR', 'CALL', 'EXIT', 'WARPSYNC'): return 'CBU'
    return 'ALU'
def op(t):
    t = re.sub(r'^@!?U?P[T0-9]\s+', '', t)
    return t.split()[0]
for f in sys.argv[1:]:
    ins = []
    for line in open(f):
        m = re.match(r'\s+/\*([0-9a-f]{4,})\*/\s+(.*?)\s*;', line)
        if m: ins.append((int(m.group(1), 16), m.group(2)))
    addr = [a for a, _ in ins]
    k = 0
    for i, (a, t) in enumerate(ins):
        if 'VOTE.ANY P' in t:
            for j in range(i, len(ins)):
                m = re.match(r'BRA 0x([0-9a-f]+)$', ins[j][1].strip())
                if m and int(m.group(1), 16) <= a:
                    head = int(m.group(1), 16); h = addr.index(head)
                    body = ins[h:j + 1]; n = len(body)
                    st = next((q for q, (_, x) in enumerate(body) if 'ATOMS.ADD' in x), None)
                    ss = next((q for q in range(st, 0, -1) if 'S2R' in body[q][1] and 'LANEID' in body[q][1]), st) if st is not None else n
                    c = collections.Counter(pipe(op(x)) for _, x in body[:ss])
                    ops = collections.Counter(op(x).split('.')[0] for _, x in body[:ss])
                    k += 1
                    print(f'{f.split("/")[-1]} loop{k} {head:#x}-{ins[j][0]:#x}: {n} instr; before the stage {ss} '
                          f'(ALU {c["ALU"]}, FMA {c["FMA"]}, XU {c["XU"]}, MIO {c["MIO"]}, MEM {c["MEM"]}, CBU {c["CBU"]}, UNI {c["UNI"]}); '
                          f'stage+tail {n - ss}; ops: ' + ' '.join(f'{o}:{v}' for o, v in sorted(ops.items(), key=lambda x: -x[1])))
                    break
