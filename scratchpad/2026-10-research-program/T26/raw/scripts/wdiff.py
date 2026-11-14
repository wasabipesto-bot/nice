#!/usr/bin/env python3
"""wdiff.py A_LOG B_LOG: compare the WGSL shaders of two CubeCL compilation logs per kernel name, modulo CubeCL's
numbering of locals and shared arrays (renamed in order of first use) and the order of `var<workgroup>` and local `var` declarations."""
import re, sys
def shaders(p):
    t = open(p).read(); ks = {}
    for x in re.findall(r'\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]', t, re.S):
        name = re.search(r'name: ([\w:]+)', x).group(1).split('::')[-2]
        src = re.search(r'```wgsl\n(.*?)```', x, re.S).group(1)
        ks.setdefault(name, []).append(src)
    return ks
def norm(src):
    names = {}
    rx = re.compile(r'\b(?:l_(?:mut_|arr_)?\d+|shared_memory_\d+|_\d+)\b')
    def ren(m):
        k = m.group(0)
        if k not in names: names[k] = f'v{len(names)}'
        return names[k]
    lines = src.splitlines()
    isdecl = lambda l: l.startswith('var<workgroup>') or re.match(r'^\s*var (?:l_\w+|_\w+): [\w<>, ]+;$', l)
    decl = [l for l in lines if isdecl(l)]
    body = [rx.sub(ren, l) for l in lines if not isdecl(l)]
    return body, sorted(rx.sub(lambda m: names.get(m.group(0), '?'), l) for l in decl)
a, b = shaders(sys.argv[1]), shaders(sys.argv[2])
for k in sorted(set(a) | set(b)):
    na = sorted((norm(x) for x in a.get(k, [])), key=str); nb = sorted((norm(x) for x in b.get(k, [])), key=str)
    print(k, len(a.get(k, [])), len(b.get(k, [])), 'IDENTICAL (modulo numbering/order)' if na == nb else 'DIFFER')
