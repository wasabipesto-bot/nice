#!/usr/bin/env python3
"""srchash.py LOG_A LOG_B: split two CUBECL_DEBUG_LOG files into kernel sources (each 'name:' block up to the next),
key them by the kernel name line plus its comptime/info lines, hash the source text, and compare A and B kernel by
kernel (in compile order per key). Prints identical / DIFFERENT per kernel, and a diff of the first different one."""
import sys, re, hashlib, difflib
def blocks(p):
    t = open(p, errors='replace').read().split('\n')
    idx = [i for i, l in enumerate(t) if l.startswith('name: ')]
    out = []
    for a, b in zip(idx, idx[1:] + [len(t)]):
        blk = t[a:b]
        # the source: from the first fenced block to its end
        try:
            s = next(i for i, l in enumerate(blk) if l.strip().startswith('```'))
            e = next(i for i in range(s + 1, len(blk)) if blk[i].strip() == '```')
            src = blk[s + 1:e]; head = blk[:s]
        except StopIteration:
            src = blk; head = blk[:1]
        out.append((' '.join(x.strip() for x in head)[:400], '\n'.join(src)))
    return out
DECL = re.compile(r'^\s*[\w:<>, ]+ l_mut_\d+;\s*$')
def canon(src):
    """CubeCL emits the mutable locals' declarations in an order that varies from process to process (a hash map):
    the canonical form keeps every other line in order and the declarations as a sorted list after them."""
    lines = src.split('\n')
    # the shared arrays' placement in dynamic shared memory also varies by process: keep each array's size and type,
    # drop its offset, and sort them with their size comments
    SH = re.compile(r'^(\w+ \*shared_memory_\d+ = reinterpret_cast<\w+\*>\(&dynamic_shared_mem\[)\d+(\]\);)$')
    out, i = [], 0
    sh = []
    while i < len(lines):
        if lines[i].startswith('// Shared array size') and i + 1 < len(lines) and SH.match(lines[i + 1]):
            sh.append(lines[i] + ' ' + SH.sub(r'\1@\2', lines[i + 1])); i += 2; continue
        out.append(lines[i]); i += 1
    lines = out + sorted(sh)
    return '\n'.join([l for l in lines if not DECL.match(l)] + sorted(l.strip() for l in lines if DECL.match(l)))
A, B = blocks(sys.argv[1]), blocks(sys.argv[2])
if len(sys.argv) > 3 and sys.argv[3] == 'raw': canon = lambda x: x
print(f'{len(A)} / {len(B)} kernels')
same = diff = 0; shown = 0
for (ha, sa), (hb, sb) in zip(A, B):
    kn = re.search(r'kernels::(\w+)::', ha); kn = kn.group(1) if kn else ha[:40]
    sa, sb = canon(sa), canon(sb)
    ok = ha == hb and sa == sb
    same += ok; diff += not ok
    ba = re.search(r'base: (\d+)', ha) or re.search(r'(\d+)u32', ha)
    print(f"{'identical' if ok else 'DIFFERENT'} {kn} {hashlib.sha256(sa.encode()).hexdigest()[:12]} {hashlib.sha256(sb.encode()).hexdigest()[:12]} | {ha[:200]}")
    if not ok and shown < 2:
        shown += 1
        print('\n'.join(list(difflib.unified_diff(sa.split('\n'), sb.split('\n'), lineterm='', n=1))[:60]))
print(f'identical {same}, different {diff}')
