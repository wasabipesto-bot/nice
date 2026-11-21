#!/usr/bin/env python3
"""model_cw.py: phase 3b on the RX 9070 XT per width, PREDICTED from the offline compile (ACO, GFX1201, W 64:
CW/raw/ldsbytes.txt) and the dumps' dynamic step counts (CW/raw/steps.txt), with the card's model
(G2/build4s/model_4s.py: issue-bound, wave64 = two passes on a SIMD32, 128 SIMD32 at 2.85 GHz, efficiency 0.77),
and beside it the same with the LDS bound of G2/port/model_rdna4.py (128 B/clk per CU, 64 CUs): t = max(VALU, LDS).
The main kernel at width W = main(64) - 3b(64) + 3b(W), with main(64) = 2.607 ms (measured 2026-11-19, stop
difference; the design doc says too low) or 3.16 ms (stop 3's measured 3.843 ms minus the model's tops + parents,
0.60-0.76 ms, mid)."""
import re
F, SIMD, CU, PASS, EFF, LDS_BPC = 2.85e9, 128, 64, 2, 0.77, 128
lds = {}
for l in open('/home/claude/projects/nice/scratchpad/2026-10-research-program/CW/raw/ldsbytes.txt'):
    m = re.match(r'(\w+): valu (\d+) salu \d+ lds (\d+) vcyc (\d+) .*iteration (\d+)', l)
    if m:
        lds[m.group(1)] = (int(m.group(4)), int(m.group(3)), int(m.group(5)))
steps = {}
for l in open('/home/claude/projects/nice/scratchpad/2026-10-research-program/CW/raw/steps.txt'):
    m = re.match(r's(\d+) w(\d+): .*steps\(S=32\) (\d+) \| steps\(S=64\) (\d+) \| steps\(S=128\) (\d+)', l)
    p, w = m.group(1), int(m.group(2))
    steps[(p, w)] = {32: int(m.group(3)), 64: int(m.group(4)), 128: int(m.group(5))}
# variant -> (width, entries per cube step S)
V = {'w64': (64, 32), 'w128s1': (128, 32), 'w128v1': (128, 32), 'w128s2': (128, 64), 'w128v2': (128, 64),
     'w256s1': (256, 64), 'w256v1': (256, 64), 'w256x1': (256, 64), 'w256v2': (256, 128), 'w256x2': (256, 128),
     'G2Kernel': (64, 32)}
MAINS = (2.607, 3.16)
for p in sorted({k[0] for k in steps}):
    print(f'\n## slice {p}\n')
    print('| variant | vcyc / wave-iter | LDS ops | LDS B / wave-iter | wave-iterations | VALU bound ms | LDS bound ms | 3b issue model ms (VALU/0.77) | 3b with LDS ms (max/0.77) | main x (issue model; main 2.607 / 3.16) | main x (with LDS) |')
    print('|---|---|---|---|---|---|---|---|---|---|---|')
    base = None
    for v in ['G2Kernel', 'w64', 'w128s1', 'w128v1', 'w128s2', 'w256v1', 'w256x1', 'w256v2', 'w256x2']:
        vc, lo, lb = lds[v]
        w, S = V[v]
        n = 4 * steps[(p, w)][S]
        tv = n * vc * PASS / (SIMD * F) * 1e3
        tl = n * lb / (CU * LDS_BPC * F) * 1e3
        ti, tm = tv / EFF, max(tv, tl) / EFF
        if v == 'w64':
            base = (ti, tm)
        gi = gm = ''
        if base and v != 'G2Kernel':
            gi = ' / '.join(f'x{M / (M - base[0] + ti):.3f}' for M in MAINS)
            gm = ' / '.join(f'x{M / (M - base[1] + tm):.3f}' for M in MAINS)
        print(f'| {v} | {vc} | {lo} | {lb} | {n} | {tv:.3f} | {tl:.3f} | {ti:.3f} | {tm:.3f} | {gi} | {gm} |')
