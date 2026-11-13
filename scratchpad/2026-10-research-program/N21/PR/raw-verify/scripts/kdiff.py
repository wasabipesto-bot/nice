#!/usr/bin/env python3
"""kdiff.py A_LOG B_LOG [KERNEL...]: compare kernels of two CubeCL compilation logs (CUDA source) modulo CubeCL's
variable numbering and declaration order: each kernel's whole compilation block, the declaration lines are
set aside, every l_*/l_mut_*/l_arr_* name is renamed by first use, and the bodies and the declaration multisets are
compared. Prints IDENTICAL / DIFFER per kernel, and the first differing lines."""
import re, sys, difflib
def kernels(p):
    t = open(p).read()
    ks = {}
    for x in re.findall(r'\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]', t, re.S):
        m = re.search(r'extern "C" __global__ void (?:__launch_bounds__\(\d+\))?(\w+)', x) or \
            re.search(r'name: [\w:]*::(\w+)<', x)
        x = re.sub(r'\n\| [\d.]+[mµn]?s \|.*', '', x)  # profiling lines
        ks.setdefault(m.group(1), []).append(x)
    return ks
def norm(src):
    # Only the generated source (the block's `source:` part), not CubeCL's kernel-id metadata. The shared-memory
    # declarations (a comment and a pointer per array, at an offset CubeCL lays out in an order that varies between
    # processes) are compared as a set of (array, size) without offsets.
    if '\nsource:' in src:
        src = src.split('\nsource:', 1)[1]
    lines = src.splitlines()
    shm = sorted(re.sub(r'\[\d+\]\);', '[OFF]);', l) for l in lines
                 if l.startswith('// Shared array size') or ('reinterpret_cast' in l and 'dynamic_shared_mem[' in l))
    lines = [l for l in lines if not (l.startswith('// Shared array size') or ('reinterpret_cast' in l and 'dynamic_shared_mem[' in l))]
    lines += ['--shared--'] + shm
    decl = [l for l in lines if re.match(r'^(uint32|uint64|int32|int64|bool|float|uint32_4|uint3)\*? ?\w+(\[\d+\])?;$', l) or re.match(r'^\s*var l_\w+: [\w<>, ]+;$', l)]
    body = [l for l in lines if l not in decl]
    names = {}
    def ren(m):
        k = m.group(0)
        if k not in names: names[k] = f'v{len(names)}'
        return names[k]
    rx = re.compile(r'\bl_(?:mut_|arr_)?\d+\b')
    body = [rx.sub(ren, l) for l in body]
    decl = sorted(rx.sub(lambda m: names.get(m.group(0), '?'), l) for l in decl)
    return body, decl
a, b = kernels(sys.argv[1]), kernels(sys.argv[2])
want = sys.argv[3:] or sorted(set(a) | set(b))
for k in want:
    if len(a.get(k, [])) != len(b.get(k, [])):
        print(k, 'count', len(a.get(k, [])), len(b.get(k, []))); continue
    na = sorted((norm(x) for x in a[k]), key=str); nb = sorted((norm(x) for x in b[k]), key=str)
    (ba, da), (bb, db) = (sum((x[0] for x in na), []), sum((x[1] for x in na), [])), (sum((x[0] for x in nb), []), sum((x[1] for x in nb), []))
    same = ba == bb and da == db
    print(k, 'IDENTICAL (modulo numbering/order)' if same else 'DIFFER', len(ba), len(bb))
    if not same:
        for l in list(difflib.unified_diff(ba + ['--decl--'] + da, bb + ['--decl--'] + db, lineterm='', n=1))[:30]: print('   ', l)
