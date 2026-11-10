#!/usr/bin/env python3
"""cfgs.py SET: print NICE_N1_CFGS for a set. Entry: name=DBAT:DREG:NBAT:NREG:W:AG:TMIN:WALK.
Orientation T (today): batch side = tops (D_T digits, NT per bucket), registers = bottom entries (D_B, NE).
Orientation R (reverse): batch side = bottoms (D_B, NE), registers = tops (D_T, NT)."""
import sys
SHAPES = {'S0': (2000, 350), 'Sp': (471, 336), 'S1': (1460, 14750), 'S2': (24, 7200), 'S3': (785, 14750)}
WORDS = {'u32': (32, 4), 'u64a2': (64, 2), 'u64a4': (64, 4)}
def ent(o, db, dt, s, wn, tmin=192, walk=0, noand=0):
    nt, ne = SHAPES[s]; w, ag = WORDS[wn]
    if o == 'T': spec = (dt, db, nt, ne)
    else: spec = (db, dt, ne, nt)
    name = f'{o}_B{db}_T{dt}_{s}_{wn}' + (f'_tm{tmin}' if tmin != 192 else '') + ('_walk' if walk else '') + ('_noand' if noand else '')
    return f'{name}=' + ':'.join(map(str, spec + (w, ag, tmin, walk) + ((1,) if noand else ())))
st = sys.argv[1]
out = []
if st == 'smoke':
    out = [ent('T', 12, 17, 'Sp', 'u32'), ent('T', 18, 15, 'S1', 'u64a2'), ent('R', 18, 15, 'S1', 'u32', walk=1)]
elif st == 'cal':
    for s in ('Sp', 'S0'):
        out.append(ent('T', 12, 17, s, 'u32'))
        out.append(ent('T', 12, 15, s, 'u32'))
elif st.startswith('grid'):
    # grid_<DT>: every D_B x shape x word x orientation at one top digit count
    dt = int(st.split('_')[1])
    for o in ('T', 'R'):
        for s in ('S0', 'S1', 'S2'):
            for db in (12, 18, 20):
                for wn in WORDS:
                    out.append(ent(o, db, dt, s, wn))
                    if o == 'T' and s == 'S2':
                        out.append(ent(o, db, dt, s, wn, tmin=1))
elif st == 'walk':
    for (db, dt) in ((12, 15), (12, 17), (18, 15), (18, 14), (20, 15)):
        for s in ('S0', 'S1'):
            for wn in ('u32', 'u64a2'):
                for o in ('T', 'R'):
                    out.append(ent(o, db, dt, s, wn, walk=0))
                    out.append(ent(o, db, dt, s, wn, walk=1))
elif st == 'f03':
    # f0 3, k 9: about 4.3/8.0 of f0 4's tops per bucket at the same bottoms (assumed tile 785 x 14,750), with S1 beside it
    for o in ('T', 'R'):
        for s in ('S3', 'S1'):
            for (db, dt) in ((18, 17), (18, 15), (20, 15)):
                for wn in WORDS:
                    out.append(ent(o, db, dt, s, wn))
elif st == 'ptop':
    # tops per bucket below / around TRANSPOSE_MIN at today's entries (336): the per-top AND's share of production
    for nt in (471, 400, 300, 192, 150, 100, 60):
        for tmin in (192, 1):
            out.append(f'T_B12_T17_n{nt}_u32' + ('_tm1' if tmin == 1 else '') + f'=17:12:{nt}:336:32:4:{tmin}:0')
elif st == 'tsize':
    # tile-size sensitivity around f0 4, k 9 (1,460 x 14,750): tops and entries x0.25..x2
    for nt in (365, 730, 1460, 2920):
        for ne in (3688, 7375, 14750, 29500):
            for (o, wn) in (('T', 'u32'), ('T', 'u64a4'), ('R', 'u64a4')):
                w, ag = WORDS[wn]
                spec = (17, 18, nt, ne) if o == 'T' else (18, 17, ne, nt)
                out.append(f'{o}_B18_T17_t{nt}x{ne}_{wn}=' + ':'.join(map(str, spec + (w, ag, 192, 0))))
elif st == 'base':
    for o in ('T', 'R'):
        for s in ('Sp', 'S0', 'S1'):
            for db in (12, 18, 20):
                for wn in ('u32', 'u64a4'):
                    out.append(ent(o, db, 17, s, wn))
                    out.append(ent(o, db, 17, s, wn, noand=1))
print(';'.join(out))
