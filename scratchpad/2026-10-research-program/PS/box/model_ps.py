#!/usr/bin/env python3
"""model_ps.py ACO_DIR... : phase 3b on the RX 9070 XT per kernel variant, PREDICTED from the offline compile (ACO,
GFX1201, W 64) with the two card models of CW/box/model_cw.py:
  issue model: t = VALU cycles x 2 passes / (128 SIMD32 x 2.85 GHz) / 0.77;
  with the LDS limit: t = max(VALU, LDS bytes / (64 CU x 128 B/clk x 2.85 GHz)) / 0.77.
Per wave-iteration of the 3b loop (ACO's innermost loop with the most LDS ops, the body counted once, as
CW/box/ldsbytes.py), the digit basic blocks (a block whose LDS ops are only ds_read_b64 digit-word loads, behind an
exec or scalar branch) are weighted by the fraction of wave-iterations that execute them: the BLOCKS lines (wave64)
of PS/raw/write_712012851.txt for the variant's plan (the dump's count of waves with some lane needing the block).
Digit blocks are matched to (entry slot h, block b) in program order. Static digit loads (no branch) count fully.
Wave-iterations = the BLOCKS line's plane-iterations (= 4 x steps, slice 712012851). Main kernel at
M = 2.607 or 3.16 ms (CW/RESULTS.md): main' = M - 3b(w64) + 3b(variant)."""
import sys, re, collections, os
sys.path.insert(0, '/home/claude/projects/nice/.worktrees/g2-cubecl/aco')
import loops as L
F, SIMD, CU, PASS, EFF, LDS_BPC = 2.85e9, 128, 64, 2, 0.77, 128
SZ = {'b32': 4, 'b64': 8, 'b96': 12, 'b128': 16}
RAW = '/home/claude/projects/nice/scratchpad/2026-10-research-program/PS/raw'
# variant -> plan spec whose BLOCKS fractions apply (None: no data-dependent digit blocks)
SPEC = {'w64': None, 'ps_q17n': None, 'ps_q4': 'freq,c32,q4', 'ps_q4g': 'freq,c32,q4', 'ps_q2': 'freq,c32,q2',
        'ps_q2g': 'freq,c32,q2', 'ps_q1': 'freq,c32,17', 'ps_q1g': 'freq,c32,17', 'ps_u1': 'freq,c32,17',
        'ps_u1g': 'freq,c32,17', 'ps16_q4': 'freq,c16x2,q4', 'ps_q8n': None, 'ps_t4': 'freq,c32,t4',
        'ps_t4g': 'freq,c32,t4', 'ps_t2': 'freq,c32,t2'}
blocks_frac, iters = {}, {}
for l in open(f'{RAW}/write_712012851.txt'):
    m = re.match(r'BLOCKS \d+ spec (\S+) wave64: plane-iterations (\d+) .*\[h\]\[block of (\d+)\] (.*)', l)
    if m:
        blocks_frac[m.group(1)] = (int(m.group(3)), [float(x) for x in m.group(4).split()])
        iters[m.group(1)] = int(m.group(2))
W_IT = 1843816  # wave-iterations of slice 712012851 (= 4 x steps at S = 32; CW/raw/steps.txt)

def opbytes(op):
    m = re.search(r'(b32|b64|b96|b128)', op)
    b = SZ[m.group(1)] if m else 4
    n = 2 if ('read2' in op or 'write2' in op) else 1
    return 64 * b * n

def analyse(path):
    blocks, st = L.parse(path)
    lp = L.loops(blocks)
    inner = [x for x in lp if not any(x[0] < y[0] and y[1] <= x[1] for y in lp if y != x)]
    a, b = max(inner, key=lambda x: L.count([o for blk in blocks[x[0]:x[1] + 1] for o in blk[2]])['lds'])
    fixed_v = fixed_b = 0
    dig = []  # (vcyc, bytes, loads) of each digit block in program order
    prev_branch = False
    for blk in blocks[a:b + 1]:
        c = L.count(blk[2])
        ds = [op for op, _ in blk[2] if op.startswith('ds_')]
        by = sum(opbytes(op) for op in ds)
        guarded = prev_branch and ds and all(op == 'ds_read_b64' for op in ds)
        if guarded:
            dig.append((c['vcyc'], by, len(ds)))
        else:
            fixed_v += c['vcyc']
            fixed_b += by
        prev_branch = any(op.startswith('s_cbranch') for op, _ in blk[2])
    return st, fixed_v, fixed_b, dig

rows = []
for d in sys.argv[1:]:
    for p in sorted(os.listdir(d)):
        if p.endswith('.aco.txt'):
            rows.append((p.split('_WgpuRuntime')[0], os.path.join(d, p)))
seen = set()
out = []
base = None
for v, p in sorted(rows, key=lambda r: (r[0] != 'w64', r[0])):
    if v in seen:
        continue
    seen.add(v)
    st, fv, fb, dig = analyse(p)
    spec = SPEC.get(v)
    vc, by, note = fv, fb, ''
    if dig:
        if spec and spec in blocks_frac:
            qb, fr = blocks_frac[spec]
            if v.startswith('ps_t'):
                # guarded digits 0..t-1 per slot: the BLOCKS fractions of blocks 0..t-1 (blocks of 1)
                t = len(dig) // 2
                nb = len(fr) // 2
                fr = fr[:t] + fr[nb:nb + t]
            if len(fr) != len(dig):
                note = f'digit blocks {len(dig)} vs fractions {len(fr)}: unweighted'
                fr = [1.0] * len(dig)
        else:
            fr = [1.0] * len(dig)
            note = 'no plan fractions: every digit block counted'
        vc += sum(f * x[0] for f, x in zip(fr, dig))
        by += sum(f * x[1] for f, x in zip(fr, dig))
    tv = W_IT * vc * PASS / (SIMD * F) * 1e3
    tl = W_IT * by / (CU * LDS_BPC * F) * 1e3
    ti, tm = tv / EFF, max(tv, tl) / EFF
    if v == 'w64':
        base = (ti, tm)
    gi = ' / '.join(f'x{M / (M - base[0] + ti):.3f}' for M in (2.607, 3.16))
    gm = ' / '.join(f'x{M / (M - base[1] + tm):.3f}' for M in (2.607, 3.16))
    out.append(f"| {v} | {st.get('VGPRs')} | {st.get('LDS size')} | {st.get('Subgroups per SIMD')} | {fv} + {len(dig)} digit blocks | {vc:.1f} | {by:.0f} | {tv:.3f} | {tl:.3f} | {ti:.3f} | {tm:.3f} | {gi} | {gm} | {note} |")
print('| variant | VGPRs | LDS B | waves/SIMD | loop vcyc: fixed + guarded digit blocks | vcyc per wave-iteration (weighted) | LDS B per wave-iteration | VALU bound ms | LDS bound ms | 3b issue model ms | 3b with LDS ms | main x issue (M 2.607 / 3.16) | main x with LDS | note |')
print('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
print('\n'.join(out))
