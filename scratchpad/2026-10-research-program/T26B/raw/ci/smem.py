#!/usr/bin/env python3
"""smem.py LOG: per SPIR-V kernel in a CubeCL compilation log: its key compile args and every Workgroup variable's
name, member offset, element size, length, byte range; flags overlapping ranges."""
import re, sys
t = open(sys.argv[1]).read()
for k in re.findall(r'\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]', t, re.S):
    name = re.search(r'name: ([\w:]+)', k).group(1).split('::')[-2]
    args = {a: (re.search(rf'\b{a}: ([\w]+)', k) or [None, '?'])[1] for a in ['x', 'base', 'probe', 'compact', 'plane_scoped', 'ballot', 'test_bits', 'pre_limbs', 'limbs']}
    consts = {m[0]: int(m[1]) for m in re.findall(r'%(\d+) = OpConstant %\d+ (\d+)', k)}
    names = dict(re.findall(r'OpName %(\d+) "([^"]+)"', k))
    stride = dict(re.findall(r'OpDecorate %(\d+) ArrayStride (\d+)', k))
    offs = {}
    for blk, off in re.findall(r'OpMemberDecorate %(\d+) 0 Offset (\d+)', k): offs.setdefault(blk, int(off))
    structs = dict(re.findall(r'%(\d+) = OpTypeStruct %(\d+)\s*\n', k))
    arrays = {a: (e, l) for a, e, l in re.findall(r'%(\d+) = OpTypeArray %(\d+) %(\d+)', k)}
    ptrs = dict(re.findall(r'%(\d+) = OpTypePointer Workgroup %(\d+)', k))
    rows = []
    for var, ptr in re.findall(r'%(\d+) = OpVariable\s+%(\d+)\s+Workgroup', k):
        blk = ptrs.get(ptr); mem = structs.get(blk); off = offs.get(blk, 0)
        if mem in arrays:
            e, l = arrays[mem]; n = consts.get(l, -1); es = int(stride.get(mem, 0)); size = n * es
        else:
            n = 1; es = 4; size = 4
        rows.append((off, off + size, names.get(var, '%' + var), es, n))
    rows.sort()
    ov = [(a[2], b[2]) for i, a in enumerate(rows) for b in rows[i + 1:] if b[0] < a[1]]
    print(f"{name} cube={args['x']} b{args['base']} probe={args['probe']} plane={args['plane_scoped']} ballot={args['ballot']} bits={args['test_bits']} pre={args['pre_limbs']}: " +
          ', '.join(f"{n}@[{a},{b}) {c}x{es}B" for a, b, n, es, c in rows) + (f"  OVERLAP {ov}" if ov else ''))
