#!/usr/bin/env python3
"""mkvar.py BASE.cu VARIANT OUT.cu: rewrite the transposed AND's digit loops of a CubeCL join_kernel CUDA source into the
C++ that a candidate CubeCL formulation would emit (zero-GPU codegen scoping; every form here is one CubeCL emits for
the Rust named in brackets). Variants combine with '+':
  abm   ab = (cb & 7) * 64, hoisted per group, free              [`let ab = (cb & 7u32) * 64u32`]
  mask  a = (ab + d) & 511 per digit                             [`let a = (ab + d) & 511u32`]
  dm    d = (bit + (lo ? 0 : 32)) & 63 per digit                 [`... & 63u32`]
  ctz   bit = trailing_zeros(v) instead of find_first_set(v) - 1 [`v.trailing_zeros()`]
  hi    highest set bit: bit = clz(v) ^ 31, v ^= 1 << bit        [`v.leading_zeros() ^ 31u32`]
  hi2   highest set bit: bit = 31 - clz(v), v ^= 1 << bit        [`31u32 - v.leading_zeros()`]
  or    d = bit | (lo ? 0 : 32)                                  [`|` for `+`]
  arr4  the group's 4 chunks as 4 arrays (constant offsets from the dynamic shared base; no index add per chunk)
        [4 `SharedMemory`s, one per chunk of a group]
  swap  no per-digit select of the word: walk x, then y (x = y once x is empty), base + 32 from then on
"""
import re, sys
src, var, out = sys.argv[1], sys.argv[2], sys.argv[3]
V = set(var.split('+')) - {'base'}
t = open(src).read()
m = re.search(r'const uint32 (l_\d+) = (l_(?:mut_)?\d+) / uint32\(32\);\nconst uint32 (l_\d+) = \1 % uint32\(4\);', t)
cb = m.group(1)
mab = re.search(r'const uint32 (l_\d+) = %s \* uint32\(64\);' % cb, t)
ab = mab.group(1)
if 'abm' in V:
    t = t.replace(mab.group(0), f'const uint32 {ab} = ({cb} & uint32(7)) * uint32(64);')
blk = re.compile(
    r'(?P<x0>l_mut_\d+) = (?P<xi>l_\d+);\n(?P<mid>(?:const uint32 l_\d+ = l_arr_\d+\[uint32\(\d\)\];\n){2}const uint32 l_\d+ = l_\d+ & l_\d+;\n)'
    r'(?P<y0>l_mut_\d+) = (?P<yi>l_\d+);\n'
    r'while \(true\) \{\nconst uint32 (?P<h1>l_\d+) = (?P=x0) \| (?P=y0);\nconst bool (?P<h2>l_\d+) = (?P=h1) != uint32\(0\);\n'
    r'const bool (?P<h3>l_\d+) = !(?P=h2);\nif \((?P=h3)\) \{\nbreak;\}\n'
    r'const bool (?P<lo>l_\d+) = (?P=x0) != uint32\(0\);\n'
    r'const uint32 (?P<v>l_\d+) = \((?P=lo)\) \? (?P=x0) : (?P=y0);\n'
    r'const uint32 (?P<f>l_\d+) = uint32\(__ffs\(int32\((?P=v)\)\)\);\n'
    r'const uint32 (?P<f1>l_\d+) = (?P=f) - uint32\(1\);\n'
    r'const uint32 (?P<s>l_\d+) = \((?P=lo)\) \? uint32\(0\) : uint32\(32\);\n'
    r'const uint32 (?P<d>l_\d+) = (?P=f1) \+ (?P=s);\n'
    r'const uint32 (?P<m1>l_\d+) = (?P=v) - uint32\(1\);\n'
    r'const uint32 (?P<c>l_\d+) = (?P=v) & (?P=m1);\n'
    r'const uint32 (?P<xx>l_\d+) = \((?P=lo)\) \? (?P=c) : (?P=x0);\n(?P=x0) = (?P=xx);\n'
    r'const uint32 (?P<yy>l_\d+) = \((?P=lo)\) \? (?P=y0) : (?P=c);\n(?P=y0) = (?P=yy);\n'
    r'const uint32 (?P<a>l_\d+) = (?P<ab>l_\d+) \+ (?P=d);\n')
n = 0
def bitof(g, v):
    if 'hi' in V: return f'const uint32 {g["f"]} = uint32(__clz(int32({v})));\nconst uint32 {g["f1"]} = {g["f"]} ^ uint32(31);\n'
    if 'hi2' in V: return f'const uint32 {g["f"]} = uint32(__clz(int32({v})));\nconst uint32 {g["f1"]} = uint32(31) - {g["f"]};\n'
    if 'ctz' in V: return f'const uint32 {g["f1"]} = uint32(({v} == 0 ? 32 : __ffs({v}) - 1));\n'
    return f'const uint32 {g["f"]} = uint32(__ffs(int32({v})));\nconst uint32 {g["f1"]} = {g["f"]} - uint32(1);\n'
def clear(g, v):
    if 'hi' in V or 'hi2' in V: return f'const uint32 {g["m1"]} = uint32(1) << {g["f1"]};\nconst uint32 {g["c"]} = {v} ^ {g["m1"]};\n'
    return f'const uint32 {g["m1"]} = {v} - uint32(1);\nconst uint32 {g["c"]} = {v} & {g["m1"]};\n'
def rep(m):
    global n; n += 1
    g = m.groupdict(); x, y = g['x0'], g['y0']
    s = f'{x} = {g["xi"]};\n{g["mid"]}{y} = {g["yi"]};\n'
    if 'swap' in V:
        b = f'l_base_{n}'
        s += f'uint32 {b} = {g["ab"]};\nif ({x} == uint32(0)) {{\n{x} = {y};\n{y} = uint32(0);\n{b} = {g["ab"]} + uint32(32);\n}}\n'
        s += f'while (true) {{\nconst bool {g["h2"]} = {x} != uint32(0);\nconst bool {g["h3"]} = !{g["h2"]};\nif ({g["h3"]}) {{\nbreak;}}\n'
        s += bitof(g, x) + clear(g, x)
        s += f'const bool {g["lo"]} = {g["c"]} == uint32(0);\n{x} = ({g["lo"]}) ? {y} : {g["c"]};\n{y} = ({g["lo"]}) ? uint32(0) : {y};\n'
        aexpr = f'{b} + {g["f1"]}'
        if 'dm' in V: aexpr = f'{b} + ({g["f1"]} & uint32(31))'
        if 'mask' in V: aexpr = f'({aexpr}) & uint32(511)'
        s += f'const uint32 {g["a"]} = {aexpr};\n{b} = ({g["lo"]}) ? {g["ab"]} + uint32(32) : {b};\n'
        return s
    s += f'while (true) {{\nconst uint32 {g["h1"]} = {x} | {y};\nconst bool {g["h2"]} = {g["h1"]} != uint32(0);\nconst bool {g["h3"]} = !{g["h2"]};\nif ({g["h3"]}) {{\nbreak;}}\n'
    s += f'const bool {g["lo"]} = {x} != uint32(0);\nconst uint32 {g["v"]} = ({g["lo"]}) ? {x} : {y};\n'
    s += bitof(g, g['v'])
    s += f'const uint32 {g["s"]} = ({g["lo"]}) ? uint32(0) : uint32(32);\n'
    dexpr = f'{g["f1"]} | {g["s"]}' if 'or' in V else f'{g["f1"]} + {g["s"]}'
    if 'dm' in V: dexpr = f'({dexpr}) & uint32(63)'
    s += f'const uint32 {g["d"]} = {dexpr};\n'
    s += clear(g, g['v'])
    s += f'const uint32 {g["xx"]} = ({g["lo"]}) ? {g["c"]} : {x};\n{x} = {g["xx"]};\nconst uint32 {g["yy"]} = ({g["lo"]}) ? {y} : {g["c"]};\n{y} = {g["yy"]};\n'
    aexpr = f'{g["ab"]} + {g["d"]}'
    if 'mask' in V: aexpr = f'({aexpr}) & uint32(511)'
    s += f'const uint32 {g["a"]} = {aexpr};\n'
    return s
t = blk.sub(rep, t)
assert n == 2, n
if 'arr4' in V:
    # the t_tr array: the one the AND loads index with A + 64
    mm = re.search(r'const uint32 (l_\d+) = (l_\d+) \+ uint32\(64\);\nconst uint32 l_\d+ = (shared_memory_\d+)\[\1\];', t)
    arr = mm.group(3)
    off = int(re.search(r'uint32 \*%s = reinterpret_cast<uint32\*>\(&dynamic_shared_mem\[(\d+)\]\);' % arr, t).group(1))
    decl = ''.join(f'uint32 *t_tr_k{k} = reinterpret_cast<uint32*>(&dynamic_shared_mem[{off + 256 * k}]);\n' for k in range(4))
    t = re.sub(r'(uint32 \*%s = reinterpret_cast<uint32\*>\(&dynamic_shared_mem\[\d+\]\);\n)' % arr, lambda m: m.group(1) + decl, t, count=1)
    cnt = 0
    for k in range(4):
        def r2(m):
            global cnt; cnt += 1
            return f'const uint32 {m.group(3)} = t_tr_k{k}[{m.group(2)}];\n'
        t = re.sub(r'const uint32 (l_\d+) = (l_\d+) \+ uint32\(%d\);\nconst uint32 (l_\d+) = %s\[\1\];\n' % (64 * k, arr), r2, t)
    assert cnt == 8, cnt
open(out, 'w').write(t)
print(out, 'ab', ab, 'loops', n)
