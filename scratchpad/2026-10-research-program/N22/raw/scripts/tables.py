#!/usr/bin/env python3
"""tables.py SPVDIR LABEL...: the N22 ACO tables from RADV dumps ($SPVDIR/LABEL/*.aco.txt, Mesa 26.0.8, GFX1201,
wave64): per kernel its VGPRs, LDS, waves per SIMD, ACO's latency and inverse-throughput estimates; the join kernel's
walk round where no lane passes (walkcount.py's split, first entry slot) and its transposed-AND digit loop (the first
innermost loop holding ds_read2); the check kernel's per-entry loop. ALU = VALU + SALU + LDS (N21's measure), q =
quarter-rate multiplies, vcyc = VALU issue in full-rate units (valu + 4q + 2·v64). python3 -I tables.py DIR labels"""
import sys, glob, os, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import loops, walkcount

def kern(d, name):
    f = glob.glob(f'{d}/{name}_*.aco.txt')
    return f[0] if f else None

D = sys.argv[1]
print('label | kernel | VGPRs | LDS B | waves/SIMD | ACO latency | ACO inv. throughput')
rows = []
for L in sys.argv[2:]:
    for k in ('JoinKernel', 'CheckKernel', 'TopFdKernel', 'BucketKernel'):
        f = kern(f'{D}/{L}', k)
        if not f: continue
        b, st = loops.parse(f)
        print(f"{L} | {k} | {st.get('VGPRs')} | {st.get('LDS size')} | {st.get('Subgroups per SIMD')} | {st.get('Latency')} | {st.get('Inverse Throughput')}")
print()
print('label | walk round ALU (valu/salu/lds) | mul32 | waits | pass path ALU | AND digit loop ALU (valu/salu/lds) | check loop ALU | check q | check vcyc')
for L in sys.argv[2:]:
    f = kern(f'{D}/{L}', 'JoinKernel'); out = [L]
    if f:
        blocks = walkcount.parse(f)
        lp = walkcount.walk_loops(blocks)
        if lp:
            rd, pp = lp[0][3], lp[0][6]
            out.append(f"{rd['valu'] + rd['salu'] + rd['lds']} ({rd['valu']}/{rd['salu']}/{rd['lds']})")
            out += [str(rd['mul32']), str(rd['wait']), str(pp['valu'] + pp['salu'] + pp['lds'])]
        bl, st = loops.parse(f)
        for n, l in loops.loops(bl):
            ops = [o for x in bl[n:l + 1] for o in x[2]]
            if any(o[0].startswith('ds_read2') for o in ops) and l - n <= 12 and not any(o[0] == 'ds_append' for o in ops):
                c = loops.count(ops); out.append(f"{c['alu']} ({c['valu'] + c['q'] + c['v64']}/{c['salu']}/{c['lds']})"); break
    f = kern(f'{D}/{L}', 'CheckKernel')
    if f:
        bl, st = loops.parse(f)
        ls = loops.loops(bl)
        if ls:
            n, l = ls[0]; c = loops.count([o for x in bl[n:l + 1] for o in x[2]])
            out += [str(c['alu']), str(c['q']), str(c['vcyc'])]
    print(' | '.join(out))
