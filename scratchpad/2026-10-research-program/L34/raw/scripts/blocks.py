#!/usr/bin/env python3
"""Basic blocks (OpLabel) per kernel in a CUBECL_DEBUG_LOG dump of SPIR-V.

cubecl-spirv's `compile_block` recurses once per block along the control
flow, so the block count bounds the compile's stack depth. Usage:
blocks.py LOG[.gz] [--top N] [--name SUBSTR]
"""
import gzip, re, sys
from collections import defaultdict

def kernels(path):
    op = gzip.open if path.endswith('.gz') else open
    name = info = None
    labels = 0
    in_src = False
    with op(path, 'rt', errors='replace') as f:
        for line in f:
            if line.startswith('[START_KERNEL_COMPILATION]'):
                name, info, labels, in_src = None, {}, 0, False
            elif name is None and line.startswith('name: '):
                name = line[6:].strip().rstrip('<').split('::')[-1]
            elif line.strip() == '```spirv':
                in_src = True
            elif in_src and line.strip() == '```':
                in_src = False
                yield name, info, labels
                name = None
            elif in_src:
                if ' = OpLabel' in line or line.strip().endswith('OpLabel'):
                    labels += 1
            elif info is not None:
                m = re.match(r'\s+(base|limbs|s2|s3|part|k2|cap|key_level|nb|ept|f0|k):\s*([^,]+),', line)
                if m:
                    info.setdefault(m.group(1), m.group(2))

def main():
    args = sys.argv[1:]
    top = 15
    sub = None
    if '--top' in args:
        i = args.index('--top'); top = int(args[i + 1]); del args[i:i + 2]
    if '--name' in args:
        i = args.index('--name'); sub = args[i + 1]; del args[i:i + 2]
    for path in args:
        ks = list(kernels(path))
        print(f'== {path}: {len(ks)} kernels')
        best = defaultdict(int)
        rows = []
        for name, info, labels in ks:
            if sub and sub not in name:
                continue
            key = (name, info.get('base'), info.get('limbs'), info.get('part'))
            if labels > best[key]:
                best[key] = labels
        for (name, base, limbs, part), labels in sorted(best.items(), key=lambda kv: -kv[1])[:top]:
            p = f' part {part}' if part is not None else ''
            print(f'  {labels:6d} blocks  {name} b{base} limbs {limbs}{p}')
        if ks:
            name, info, labels = ks[-1]
            print(f'  last logged: {name} {info} {labels} blocks')

main()
