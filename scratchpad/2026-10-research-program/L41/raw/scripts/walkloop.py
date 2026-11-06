#!/usr/bin/env python3
"""L40: the walk loops of a join_kernel SASS dump: for each VOTE.ANY P (the walk's plane_any), the loop from the
backward branch's target to that branch; instruction counts of the loop, of the part from the loop head to the
residue test's exit branch, and of the stage (the first ATOMS.ADD's block up to the loop's tail).
python3 walkloop.py FILE.sass"""
import re, sys
ins = []
for line in open(sys.argv[1]):
    m = re.match(r'\s+/\*([0-9a-f]{4,})\*/\s+(.*?)\s*;', line)
    if m: ins.append((int(m.group(1), 16), m.group(2)))
addr = [a for a, _ in ins]
for i, (a, t) in enumerate(ins):
    if 'VOTE.ANY P' in t:
        # the loop: a later unconditional BRA back to an address <= a
        for j in range(i, len(ins)):
            m = re.match(r'BRA 0x([0-9a-f]+)$', ins[j][1].strip())
            if m and int(m.group(1), 16) <= a:
                head = int(m.group(1), 16)
                h = addr.index(head)
                n = j - h + 1
                body = ins[h:j + 1]
                st = next((k for k, (_, x) in enumerate(body) if 'ATOMS.ADD' in x), None)
                stage_start = next((k for k in range(st, 0, -1) if 'S2R' in body[k][1] and 'LANEID' in body[k][1]), st) if st is not None else None
                print(f'{sys.argv[1]}: walk loop {head:#x}-{ins[j][0]:#x}: {n} instructions; before the stage {stage_start}, stage+tail {n - stage_start}')
                break
