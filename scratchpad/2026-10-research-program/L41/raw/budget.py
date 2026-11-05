#!/usr/bin/env python3
"""L41: the join's warp-instruction budget per b62 1e17 field (post-#241 SASS, L40 M) and the candidates' estimates.
Counts per field: plane-rounds, plane-chunks, plane-groups measured (L37 s1, L40 s4); plane-waves estimated from L39's
entry loads (1.29e11 lane entry loads / (64 lane slots x 65 % filled)); plane-batches ~ plane-waves (one wave per batch
at ~336 entries per bucket); work items 1.6e8 x 8 planes (L37). Per-unit counts from classify.py. Estimates, not
measurements."""
R, C, G = 1.284e11, 1.9697e10, 5.3555e9
W = 1.29e11 / (64 * 0.65)
B = W * 0.97
I = 1.6e8 * 8
p_stage = 1 - (1 - 0.061) ** (1.021e12 / R)        # P(any of ~8 active lanes passes the prefilter)
s = 1.3                                            # entry slots holding entries per plane
units = {  # name: (count, instr per unit, ALU per unit)
    'walk rounds (74 + stage x p)':            (R, 74 + 16 * p_stage, 45 + 3 * p_stage),
    'per chunk (head, pass words, 2 walk exits, stage check + 2 barriers, tails)': (C, 13 + 7 + 11 + 5 + 8 + 10 + 6, 1 + 1 + 3 + 3 + 4 + 2 + 1),
    'per AND group (12 digits x 21 + setup, per slot with entries)': (G, s * (18 + 12 * 21) + (2 - s) * 10, s * (5 + 12 * 11) + (2 - s) * 3),
    'per wave (setup + entry loads + key-level terms)': (W, 20 + s * 70 + (2 - s) * 6, 6 + s * 25 + (2 - s) * 2),
    'per batch (top gather + transposed copy)': (B, 32 + 0.9 * 232, 6 + 0.9 * 141),
    'per work item': (I, 55, 10),
}
ti = sum(c * n for c, n, a in units.values()); ta = sum(c * a for c, n, a in units.values())
print(f'p_stage = {p_stage:.3f}; plane-waves ~ {W:.3g}')
for k, (c, n, a) in units.items():
    print(f'{k:80s} {c:9.3g} x {n:6.1f} = {c*n:9.3g} ({100*c*n/ti:5.1f} %)  ALU {c*a:9.3g} ({100*c*a/ta:5.1f} %)')
print(f'{"total":80s} {"":20s} {ti:9.3g}            ALU {ta:9.3g}')
clk, sms = 1.297e9, 68
print(f'ALU-pipe time (64 lanes/clk/SM): {ta*32/64/sms/clk:.1f} s; issue time (1/clk/SMSP): {ti/(4*sms)/clk:.1f} s; L37 join 72.4 s (pre-#241), ~60.7 s post-#241 (L38: -10.9 s at 180 W, scaled)')
# candidates: (d instr per unit, d ALU per unit, count) lists
cand = {
    'P-A fixed-point digits':            [(-15, -11, R), (-2, 0, W * s), (6, 2, B)],
    'C2 membership by 64-bit shift':     [(-8, -7, R)],
    'P-B seed-gated top masks':          [(-3, -3, R), (4, 2, B)],
    'W1 residue test per clipped chunk': [(-6, -3, R), (2, 1, 2 * C), (3, 1, C)],
    'copy as a warp shuffle transpose':  [(-190, -110, 0.9 * B)],
    'W2 branch-free lane guard':         [(-4, 0, R)],
    'wave load hoisted out of the batch loop (single-wave buckets)': [(-(1 - 1 / 2.3) * (20 + s * 70), -(1 - 1 / 2.3) * (6 + s * 25), W)],
    'AND digit loop at a fixed 2k trips': [(-2 * 12 * s, -12 * s, G)],
    'pc (2rho, 3rho^2) in the bucket kernel': [(-17 * s, -4 * s, W)],
}
pf, walk = 24.18, 11.29   # L37 marginal s per b62 1e17 field (pre-#241, 150 W)
for k, v in cand.items():
    di = sum(a * c for a, _, c in v); da = sum(b * c for _, b, c in v)
    print(f'{k:62s} instr {di:9.3g} ({100*di/ti:6.1f} %)  ALU {da:9.3g} ({100*da/ta:6.1f} %)  ALU time {da*32/64/sms/clk:6.1f} s')
bi = -26 * R; ba = -21 * R
print(f'bundle P-A + C2 + P-B: instr {bi:.3g} ({100*bi/ti:.1f} %), ALU {ba:.3g} ({100*ba/ta:.1f} %), ALU time {ba*32/64/sms/clk:.1f} s;'
      f' L37-part scaling: pf x 26/51 = {pf*26/51:.1f} s, x 21/36 = {pf*21/36:.1f} s; W1 on the walk: x 6/23 = {walk*6/23:.1f} s, x 3/9 = {walk*3/9:.1f} s')
