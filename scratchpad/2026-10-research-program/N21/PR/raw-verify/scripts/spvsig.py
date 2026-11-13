#!/usr/bin/env python3
"""spvsig.py A_LOG B_LOG: compare the SPIR-V kernels of two CubeCL compilation logs (the cubecl-spirv runtime). CubeCL's
SPIR-V output orders capabilities, debug names and phi operands differently from process to process, so each kernel is
compared as a multiset of instructions with every %id replaced by %_ and the debug instructions (OpName, OpSource,
OpLine, OpString) dropped, and member offsets (the workgroup-memory layout, whose order varies between
processes like the CUDA backend's shared-memory layout) blanked. Equal multisets: IDENTICAL (multiset); else the opcode count differences. Also prints each
kernel's OpBitCount count (the population count)."""
import re, sys
from collections import Counter
def kernels(p):
    t = open(p).read(); ks = {}
    for x in re.findall(r'\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]', t, re.S):
        name = re.search(r'name: [\w:]*::(\w+)<', x).group(1)
        src = x.split('\nsource:', 1)[1] if '\nsource:' in x else x
        lines = [re.sub(r'(OpMemberDecorate %_ \d+ Offset) \d+', r'\1 N', re.sub(r'%\w+', '%_', l.strip())) for l in src.splitlines()
                 if l.strip() and not re.search(r'\bOp(Name|MemberName|Source|Line|String|NoLine)\b', l) and not l.startswith(('`', ';', '|'))]
        ks.setdefault(name, []).append(Counter(lines))
    return ks
a, b = kernels(sys.argv[1]), kernels(sys.argv[2])
for k in sorted(set(a) | set(b)):
    ca = sum(a.get(k, []), Counter()); cb = sum(b.get(k, []), Counter())
    bc = lambda c: sum(v for l, v in c.items() if 'OpBitCount' in l)
    if ca == cb:
        print(f'{k} IDENTICAL (multiset, {sum(ca.values())} instructions, {len(a.get(k,[]))} shader(s)) OpBitCount {bc(ca)}')
    else:
        op = lambda c: Counter({re.search(r'Op\w+', l).group(0) if re.search(r'Op\w+', l) else l: v for l, v in c.items()})
        oa = Counter(); ob = Counter()
        for l, v in ca.items(): oa[(re.search(r'Op\w+', l) or [l])[0]] += v
        for l, v in cb.items(): ob[(re.search(r'Op\w+', l) or [l])[0]] += v
        d = {o: ob[o] - oa[o] for o in set(oa) | set(ob) if ob[o] != oa[o]}
        print(f'{k} DIFFER ({sum(ca.values())} vs {sum(cb.values())} instructions) OpBitCount {bc(ca)} -> {bc(cb)}; opcode count changes {dict(sorted(d.items()))}')
