#!/usr/bin/env python3
"""ldsbytes.py ACO_TXT...: per kernel, its phase-3b loop (the innermost loop with the most LDS ops; for g2_kernel
the loop with valu 171) by ds_* mnemonic, and the LDS bytes per wave64-iteration (b32 = 256 B, b64 = 512 B,
b96 = 768 B, b128 = 1,024 B per wave64; ds_bpermute/swizzle 256 B)."""
import sys, re, collections, os
sys.path.insert(0, '/home/claude/projects/nice/.worktrees/g2-cubecl/aco')
import loops as L
SZ = {'b32': 4, 'b64': 8, 'b96': 12, 'b128': 16, 'u8': 1, 'u16': 2, 'i8': 1, 'i16': 2, 'u16_d16': 2}
for p in sys.argv[1:]:
    blocks, st = L.parse(p)
    best = None
    for a, b in L.loops(blocks):
        if any(a < a2 and b2 <= b for (a2, b2) in L.loops(blocks) if (a2, b2) != (a, b)):
            continue
        ops = [o for blk in blocks[a:b + 1] for o in blk[2]]
        c = L.count(ops)
        if best is None or c['lds'] > best[0]['lds']:
            best = (c, ops)
    c, ops = best
    ds = collections.Counter(op for op, _ in ops if op.startswith('ds_'))
    by = 0
    for op, n in ds.items():
        m = re.search(r'(b32|b64|b96|b128|u8|u16|i8|i16)', op)
        by += n * 64 * (SZ[m.group(1)] if m else 4)
    print(f"{os.path.basename(p).split('_WgpuRuntime')[0]}: valu {c['valu']} salu {c['salu']} lds {c['lds']} vcyc {c['vcyc']} | {dict(ds)} | LDS bytes per wave64-iteration {by}")
