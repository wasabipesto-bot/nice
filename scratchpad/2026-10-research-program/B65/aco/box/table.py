#!/usr/bin/env python3
"""table.py: the before/after table of every listing in B65/aco (word loop = phase 3b), per wave-iteration and per
slot, plus a per-round estimate. MODEL, not measurement: VALU 2 x vcyc (wave64 two passes), LDS bytes / 64 per SIMD
(128 B/clk per CU), bound = max, times the slice reads' bank-conflict factor (banks.py, assumed hardware) on the
slice bytes; per round of one wave: steps = E / entries-per-step + 0.5 (E = 392.6 listed entries per round, the
narrow b64 figure of PS/RESULTS, assumed for b65 too), plus 2 x the VALU added outside the inner loops (phase 2 /
3b setup) and the phase-2 stores' conflict cost (4 stores x 8 x (factor - 1)). B65 ACO study, 2026-11-28."""
import sys, glob, os
sys.path.insert(0, '/home/claude/projects/nice/.worktrees/g2-cubecl/aco'); sys.path.insert(0, os.path.dirname(__file__))
import loops as L
from price import ldsbytes  # noqa
D = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
E = 392.6
# tag: (kernel, slots per wave-iteration, entries per cube step, slice-read conflict factor, phase-2 store factor, what)
V = {
 'pre_wide': ('Wide', 128, 32, 1.00, 1, '73bc0065 (before the count and hooks)'),
 'head_wide': ('Wide', 128, 32, 1.00, 1, 'f503a13c (head)'),
 'g2w_wide': ('Wide', 128, 32, 1.88, 1, 'V1: 2 chunks/lane (q, q+8)'),
 'g4w_wide': ('Wide', 256, 64, 2.14, 1, 'V2: 4 chunks/lane (q+4k)'),
 'g4k3w_wide': ('Wide', 256, 64, 2.14, 1, 'V3: V2 + skip reads of unkept chunks 1-3'),
 'g4dw_wide': ('Wide', 256, 64, 1.00, 16, 'V4: digit-major, chunks (t%16)^4k'),
 'g4r2w_wide': ('Wide', 256, 64, 1.00, 4, 'V5: V4 + rotated phase-2 stores'),
 'pre_narrow': ('G2Kernel', 128, 32, 1.00, 1, '73bc0065'),
 'head_narrow': ('G2Kernel', 128, 32, 1.00, 1, 'f503a13c (head)'),
 'g2n_narrow': ('G2Kernel', 128, 32, 1.88, 1, 'V1n: 2 chunks/lane'),
 'g4rn_narrow': ('G2Kernel', 256, 64, 1.00, 4, 'V5n: digit-major + rotated stores'),
}
base = {}
pend = []
rows = []
print('| variant | VGPRs | LDS B | waves | instr | loop VALU | SALU | LDS ops (b64) | LDS B/iter | slots | VALU/slot | LDS/slot | bound/slot | conflicts (model) | outside +VALU | per-round est. |')
print('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
for tag, (k, slots, eps, cf, sf, what) in V.items():
    fs = [f for f in glob.glob(f'{D}/{tag}/*.aco.txt') if os.path.basename(f).startswith(k)]
    if not fs: continue
    blocks, st = L.parse(fs[0]); ls = L.loops(blocks)
    body = lambda i: [o for b in blocks[ls[i][0]:ls[i][1] + 1] for o in b[2]]
    c = L.count(body(4)); outer = L.count(body(1))['vcyc'] - sum(L.count(body(i))['vcyc'] for i in (2, 3, 4))
    lb = ldsbytes(body(4)); r64 = sum(1 for o, _ in body(4) if o in ('ds_read_b64', 'ds_read2_b32'))
    slice_b = 18 * 8 * 64 * slots / 64 * (1 if k == 'Wide' else 17 / 18)  # slice bytes per wave-iteration
    v = 2 * c['vcyc']; l = lb / 64; lc = (lb + slice_b * (cf - 1)) / 64
    steps = E / eps + 0.5
    rnd = steps * max(v, c['salu'], lc) + 2 * outer + 4 * 8 * sf
    key = k
    if tag.startswith('head'): base[key] = (rnd, outer)
    if key not in base: base[key] = (None, outer); pend.append(tag)
    rows.append((key, rnd, outer, f"| {what} | {st['VGPRs']} | {st['LDS size']} | {st['Subgroups per SIMD']} | {st['Instructions']} | {c['vcyc']} | {c['salu']} | {c['lds']} ({r64}) | {lb} | {slots} | {v/slots:.3f} | {l/slots:.3f} | {max(v, c['salu'], l)/slots:.3f} | {cf:.2f} reads, {sf} stores -> {max(v, c['salu'], lc)/slots:.3f} | OUT | RND |"))

for key, rnd, outer, r in rows:
    b = base[key]
    print(r.replace('RND', f"{rnd / b[0]:.3f}").replace('OUT', f"{outer - b[1]:+d}"))
