#!/usr/bin/env python3
"""L44: post-stack (main 6f060a9 + #241 + #246) device budget per field on an RTX 3080 at 180 W.

Every input is a measured number from an earlier lead (cited); the arithmetic is the derivation.
Unit: G-cycles = device seconds x mean SM clock (GHz). Cycles are invariant across caps to +-2 %
(#241's b62 1e17: 158.5-164.4 G at 150/180/320 W, seven runs, four boxes), so they transfer between boxes.
"""
F = {}
# ---------------- b62 1e17 ----------------
b62 = dict(
    main=120.369 * 1.427,          # L38 A/B, main 6f060a9, 180 W
    d241=120.369 * 1.427 - 109.458 * 1.502,   # L38 A/B cycles saved by #241
    base241=108.972 * 1.501,       # L41 A/B base (#241), 180 W
    post=100.383 * 1.472,          # L41 A/B PR side (#241 + #246), 180 W
    clk=1.472,
    shares=dict(top=40.57, bucket=2.56, join=76.66, check=11.16, other=5.60),   # L36 all5 profile (= main binary), 150 W
    joinpct=dict(base=39.9, AND=1.7, walk=16.8, pf=36.1, stage=5.5),           # L37 cycles column, main, 150 W
    screen=dict(FX=3.8, MT=3.8, GM=0.1, RC=1.8),                               # L41 screen, % of field cycles
    pairs=30.64e6 * 3844, slots=6.57, s=0.197, g=0.352,                        # PROFILE-3 counts; L35/L38 FD timings, 180 W
)
b60 = dict(
    main=23.122 * 1.451, d241=23.122 * 1.451 - 21.823 * 1.497,
    base241=22.039 * 1.480, post=19.649 * 1.469, clk=1.469,
    shares=dict(top=13.27, bucket=0.93, join=32.62, check=5.37, other=2.41),
    joinpct=dict(base=39.1, AND=0.0, walk=13.9, pf=44.0, stage=3.6),          # AND measured -0.5 % (noise) -> 0
    screen=dict(FX=6.3, MT=2.3, GM=3.0, RC=2.1),
    pairs=5.30e6 * 3600, slots=5.33, s=0.192, g=0.329,
)
for name, d in (('b62 1e17', b62), ('b60 1e16', b60)):
    tot = sum(d['shares'].values())
    sh = {k: v / tot for k, v in d['shares'].items()}
    ph = {k: sh[k] * d['main'] for k in sh}
    nonjoin = sum(v for k, v in ph.items() if k != 'join')
    d246 = d['base241'] - d['post']
    join1 = d['post'] - nonjoin
    jm = ph['join']
    jp = {k: v / 100 * jm for k, v in d['joinpct'].items()}
    jp['base'] -= d['d241']
    scr = d['screen']; ss = sum(scr.values())
    jp['walk'] -= d246 * scr['RC'] / ss
    jp['pf'] -= d246 * (scr['FX'] + scr['MT'] + scr['GM']) / ss
    join2 = sum(jp.values())
    k = join1 / join2
    jp = {kk: v * k for kk, v in jp.items()}
    stepped = d['pairs'] * (d['slots'] - 1) / d['slots']; seeds = d['pairs'] / d['slots']
    fd_s = stepped * d['s'] * 1e-9 + seeds * d['g'] * 1e-9
    fd_c = fd_s * d['clk']
    print(f"== {name}: main {d['main']:.2f} G, #241 -{d['d241']:.2f} G, #246 -{d246:.2f} G, post-stack {d['post']:.2f} G"
          f" = {d['post']/d['clk']:.2f} s at {d['clk']*1000:.0f} MHz")
    print(f"   join: route 1 (total - unchanged phases) {join1:.2f} G; route 2 (main's join - #241 - #246) {join2:.2f} G"
          f" ({100*(join2/join1-1):+.1f} %)")
    rows = [('top', ph['top']), ('  FD kernel (seeds incl.)', fd_c), ('  scan + fill + clipped (residual)', ph['top'] - fd_c),
            ('bucket', ph['bucket']), ('join', join1)] + [('  ' + kk, v) for kk, v in jp.items()] + \
           [('check', ph['check']), ('other', ph['other'])]
    for lab, v in rows:
        print(f"   {lab:36s} {v:7.2f} G  {v/d['clk']:6.2f} s  {100*v/d['post']:5.1f} %")
    print(f"   FD: stepped pairs {stepped:.3g}, seeds {seeds:.3g}; seed excess (g-s) {seeds*(d['g']-d['s'])*1e-9:.2f} s;"
          f" stepped-slot time {stepped*d['s']*1e-9:.2f} s")
    F[name] = (d, ph, jp, join1)

# issue model (L41 budget.py units, post-#246 round), b62 1e17
R, C, G, W, B, I = 1.284e11, 1.9697e10, 5.3555e9, 3.1e9, 3.0e9, 1.28e9
round_new = 41 + 16 * 0.394
units = {'walk rounds': R * round_new, 'per chunk (+RC)': C * 67, 'AND groups': G * 358, 'per wave': W * 115.2,
         'per batch (+dh, gating)': B * (240.8 * 1.0) + B * 10, 'work items': I * 55}
tot = sum(units.values()); smsp = 272
print("== issue model, b62 1e17 post-stack (warp instructions / 272 SMSP-issues per clock)")
for k, v in units.items():
    print(f"   {k:28s} {v:9.3g} instr  {v/smsp/1e9:6.2f} G")
join1 = F['b62 1e17'][3]
print(f"   total {tot:.3g} instr = {tot/smsp/1e9:.2f} G issue; join {join1:.2f} G; non-issue {join1 - tot/smsp/1e9:.2f} G"
      f" = {(join1 - tot/smsp/1e9)/1.472:.1f} s")
pre = 1.4614e13
print(f"   pre-#246: {pre/smsp/1e9:.2f} G issue vs post-#241 join {join1 + (108.972*1.501-100.383*1.472):.2f} G;"
      f" #246 predicted issue saving {(80.3-round_new)*R/smsp/1e9 - (7*C + 10*B)/smsp/1e9:.2f} G vs measured"
      f" {108.972*1.501-100.383*1.472:.2f} G")
# caps
print("== #241 b62 1e17 cycles across caps (G):", [round(x, 1) for x in (118.913*1.379, 118.827*1.334, 120.133*1.357,
      108.972*1.501, 108.255*1.506, 109.458*1.502, 86.777*1.882)])
