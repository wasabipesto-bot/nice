#!/usr/bin/env python3
"""stores.py LOG: for each distinct niceonly_kernel variant in a CubeCL SPIR-V log: the Workgroup variables (name,
offset, element count x size) and every OpAtomicStore into a Workgroup array, with its index (constant value or
'dynamic')."""
import re, sys
t = open(sys.argv[1]).read(); seen = set()
for k in re.findall(r'\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]', t, re.S):
    name = re.search(r'name: ([\w:]+)', k).group(1).split('::')[-2]
    g = lambda a: (re.search(rf'\b{a}: (\w+)', k) or [0, '-'])[1]
    key = (name, g('x'), g('base'), g('plane_scoped'), g('ballot'), g('probe'))
    if key in seen: continue
    seen.add(key)
    L = [l.strip() for l in k.splitlines()]
    consts = dict(re.findall(r'%(\d+) = OpConstant\s+%\d+\s+(\d+)', k))
    names = dict(re.findall(r'OpName %(\d+) "([^"]+)"', k))
    defs = {l.split()[0]: l for l in L if ' = ' in l}
    wg = {}
    for v, ptr in re.findall(r'%(\d+) = OpVariable\s+%(\d+)\s+Workgroup', k):
        blk = defs['%' + ptr].split()[-1]; mem = defs[blk].split()[-1]; arr = defs.get(mem, '')
        off = (re.search(rf'OpMemberDecorate {blk} 0 Offset (\d+)', k) or [0, '?'])[1]
        m = re.search(r'OpTypeArray %(\d+) %(\d+)', arr)
        n = consts.get(m.group(2), '?') if m else '1'
        es = (re.search(rf'OpDecorate {mem} ArrayStride (\d+)', k) or [0, '?'])[1] if m else '?'
        wg[v] = f"{names.get(v, v)}@{off} {n}x{es}B"
    st = []
    for l in L:
        m = re.match(r'OpAtomicStore (%\d+)', l)
        if not m: continue
        d = defs.get(m.group(1), '')
        m2 = re.search(r'AccessChain\s+%\d+\s+%(\d+) %\d+ %(\d+)$', d)
        if m2 and m2.group(1) in wg:
            st.append(f"{names.get(m2.group(1))}[{consts.get(m2.group(2), 'dynamic')}]")
    print(f"{name} cube={key[1]} b{key[2]} plane_scoped={key[3]} ballot={key[4]} probe={key[5]}:\n   shared: {', '.join(wg.values())}\n   atomic stores into shared: {st}")
