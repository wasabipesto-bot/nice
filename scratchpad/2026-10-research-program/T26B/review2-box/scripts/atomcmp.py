#!/usr/bin/env python3
"""atomcmp.py SPV_LOG WGSL_LOG: per kernel variant (name + id block minus the runtime), count atomic and
workgroup-store operations in CubeCL's SPIR-V module (cubecl-spirv, runs cubecl-opt) and in its WGSL module
(cubecl-wgpu's WGSL compiler, no cubecl-opt). An operation that survives in WGSL and not in SPIR-V is flagged."""
import re, sys
SPV = {'store': r'OpAtomicStore', 'add': r'OpAtomicIAdd', 'sub': r'OpAtomicISub', 'or': r'OpAtomicOr',
       'and': r'OpAtomicAnd', 'max': r'OpAtomicUMax|OpAtomicSMax', 'min': r'OpAtomicUMin|OpAtomicSMin',
       'xchg': r'OpAtomicExchange', 'cas': r'OpAtomicCompareExchange', 'load': r'OpAtomicLoad'}
WG = {'store': r'atomicStore\(', 'add': r'atomicAdd\(', 'sub': r'atomicSub\(', 'or': r'atomicOr\(',
      'and': r'atomicAnd\(', 'max': r'atomicMax\(', 'min': r'atomicMin\(', 'xchg': r'atomicExchange\(',
      'cas': r'atomicCompareExchangeWeak\(', 'load': r'atomicLoad\('}
def parse(path, pats):
    t = open(path, errors='replace').read(); out = {}
    for k in re.findall(r'\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]', t, re.S):
        name = re.search(r'name: ([\w:]+)', k).group(1).split('::')[-2]
        info = re.search(r'info: (.*?)\n\s*\},?\nsource', k, re.S)
        idb = re.search(r'id: KernelId \{(.*?)\nsource:', k, re.S).group(1)
        idb = re.sub(r'cubecl_\w+::runtime::\w+', 'RT', idb)
        idb = re.sub(r'cubecl_\w+::\w+::\w+', 'RT', idb)
        key = (name, re.sub(r'\s+', ' ', idb))
        src = k.split('source:', 1)[1]
        out[key] = {o: len(re.findall(p, src)) for o, p in pats.items()}
    return out
s = parse(sys.argv[1], SPV); w = parse(sys.argv[2], WG)
names = sorted(set(k[0] for k in s) | set(k[0] for k in w))
bad = 0
for key in sorted(set(s) | set(w)):
    a, b = s.get(key), w.get(key)
    if a is None or b is None:
        print(f"{key[0]}: only in {'SPIR-V' if b is None else 'WGSL'} ({hash(key[1]) & 0xffff:04x})"); continue
    diff = {o: (a[o], b[o]) for o in SPV if a[o] != b[o]}
    tag = 'MISMATCH' if any(a[o] < b[o] for o in SPV if o != 'load') else ('loads differ' if diff else 'same')
    if tag == 'MISMATCH': bad += 1
    print(f"{key[0]} ({hash(key[1]) & 0xffff:04x}): spirv {dict((o,v) for o,v in a.items() if v)} | {tag} {diff if diff else ''}")
print(f"variants: spirv {len(s)}, wgsl {len(w)}, matched {len(set(s)&set(w))}, store/RMW mismatches {bad}")
