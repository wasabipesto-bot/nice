#!/usr/bin/env python3
"""L41: classify the post-#241 join_kernel SASS (b62, L40/raw/box/sass/M) by part and by pipe.
python3 classify.py [SASS]   (default: ../../L40/raw/box/sass/M/join_kernel_b62_1.sass)

Pipes (sm_86; CUDA C guide throughput table, results/clock/SM): ALU = LOP3/SHF/ISETP/IADD3/SEL/PLOP3/LEA/VOTE/IMNMX
(64, i.e. 16 lanes per SMSP: one warp instruction per 2 cycles); FMA = IMAD* (64, a separate pipe: fmaheavy);
XU = FLO/POPC/BREV (clz/popc: 16); MIO = LDS/STS/ATOMS/SHFL/S2R; MEM = LDG/STG/ATOMG/RED; CBU = BRA/BSSY/BSYNC/NOP/BAR/CALL/EXIT;
UNI = uniform-datapath U* (and VOTEU, R2UR)."""
import re, sys, collections
f = sys.argv[1] if len(sys.argv) > 1 else '../../L40/raw/box/sass/M/join_kernel_b62_1.sass'
ins = []
for line in open(f):
    m = re.match(r'\s+/\*([0-9a-f]{4,})\*/\s+(.*?)\s*;', line)
    if m: ins.append((int(m.group(1), 16), m.group(2)))
def op(t):
    t = re.sub(r'^@!?U?P[T0-9]\s+', '', t)
    return t.split()[0]
def pipe(o):
    b = o.split('.')[0]
    if b.startswith('U') or b in ('VOTEU', 'R2UR', 'S2UR'): return 'UNI'
    if b in ('IMAD',): return 'FMA'
    if b in ('FLO', 'POPC', 'BREV', 'MUFU', 'I2F', 'F2I'): return 'XU'
    if b in ('LDS', 'STS', 'ATOMS', 'SHFL', 'S2R', 'CS2R'): return 'MIO'
    if b in ('LDG', 'STG', 'ATOMG', 'RED'): return 'MEM'
    if b in ('BRA', 'BSSY', 'BSYNC', 'NOP', 'BAR', 'CALL', 'EXIT', 'WARPSYNC'): return 'CBU'
    return 'ALU'
def region(lo, hi, skip=()):
    return [(a, t) for a, t in ins if lo <= a <= hi and a not in skip]
def tally(name, rs):
    c = collections.Counter(pipe(op(t)) for _, t in rs)
    alu = c['ALU']
    print(f'{name:58s} {len(rs):4d}  ALU {alu:3d}  FMA {c["FMA"]:3d}  XU {c["XU"]:2d}  MIO {c["MIO"]:2d}  MEM {c["MEM"]:2d}  CBU {c["CBU"]:2d}  UNI {c["UNI"]:2d}')
    return c
# --- b62 round body, slot 0 (L40 walkloop: 0x2a90-0x3160)
if 'b62' in f and '/M/' in f:
    pf_bits = {
        'top operands (LDS t_dm, t_lo, t_hi)': [0x2bc0, 0x2da0, 0x2e60],
        'unpack ac/pc halves, D, seed flag': [0x2bd0, 0x2bf0, 0x2c00, 0x2c20, 0x2c30, 0x2c50],
        'x2, x3 = carries + coefficient*D (IMAD)': [0x2c40, 0x2c60],
        'x mod b^2 (mul-shift, b^2 = 3844)': [0x2c70, 0x2c80, 0x2c90, 0x2ca0, 0x2cb0, 0x2cc0],
        'h = x / b, g = x mod b (b = 62 = 2*31: shift, mul-shift)': [0x2cd0, 0x2ce0, 0x2cf0, 0x2d00, 0x2d10, 0x2d20, 0x2d30, 0x2d60],
        'one-hot 64-bit masks (1 const, 4 x (SHF.L.U32 + SHF.L.U64.HI), 2 ORs)': [0x2be0, 0x2d40, 0x2d70, 0x2d80, 0x2db0, 0x2dc0, 0x2dd0, 0x2de0, 0x2df0, 0x2e00, 0x2e10],
        'compares g2==g3, h2==h3': [0x2d50, 0x2d90],
        'seen = entry | (seed ? top : 0) (2 SEL, 2 OR)': [0x2e20, 0x2e30, 0x2e80, 0x2e90],
        'mask tests (seen&at_k, (seen|at_k)&at_k1, lo and hi)': [0x2e40, 0x2e50, 0x2e70, 0x2ea0, 0x2eb0, 0x2ec0, 0x2ed0],
        'combine + branch': [0x2ee0, 0x2ef0],
    }
    parts = [
        ('loop control: x != 0, plane_any (VOTE.ANY), exit', region(0x2a90, 0x2ac0)),
        ('lane guard: if x != 0 (ISETP, BSSY, MOV, BRA)', region(0x2ad0, 0x2b00)),
        ('pop: ctz (BREV+FLO), x &= x-1, jt2, byte offset', region(0x2b10, 0x2b60)),
        ('residue test (2 LDS, 2 ISETP, BRA)', region(0x2b70, 0x2bb0)),
        ('nand += 1', region(0x2c10, 0x2c10)),
    ]
    print('== b62 round body, entry slot 0 (0x2a90-0x3160) ==')
    tot = collections.Counter()
    for n, r in parts: tot += tally(n, r)
    pfc = collections.Counter(); npf = 0
    for n, addrs in pf_bits.items():
        r = [(a, t) for a, t in ins if a in addrs]
        assert len(r) == len(addrs), n
        pfc += tally('  walk_pf: ' + n, r); npf += len(r)
    print(f'{"  walk_pf total":58s} {npf:4d}  ALU {pfc["ALU"]:3d}  FMA {pfc["FMA"]:3d}  MIO {pfc["MIO"]}')
    tot += pfc
    st1 = tally('stage: warp-aggregated ATOMS + bound check', region(0x2f00, 0x2fc0))
    st2 = tally('stage: LDS t_id + 2 STS (taken path)', region(0x3110, 0x3130))
    st3 = tally('stage overflow to the global list (rare)', region(0x2fd0, 0x3100))
    tl = tally('tail: BSYNC, NOP (sync_plane), BRA', region(0x3140, 0x3160))
    tot += tl
    print(f'{"common path without stage":58s} {sum(tot.values()):4d}  ALU {tot["ALU"]:3d}  FMA {tot["FMA"]:3d}  XU {tot["XU"]}  MIO {tot["MIO"]}  CBU {tot["CBU"]}')
    print('== base regions ==')
    tally('kernel entry + work item (0x0000-0x0360)', region(0x0, 0x360))
    tally('batch: top gather (0x0370-0x0560)', region(0x370, 0x560))
    tally('batch: transposed copy (0x0570-0x13e0)', region(0x570, 0x13e0))
    tally('wave: setup (0x13f0-0x1520)', region(0x13f0, 0x1520))
    tally('wave: slot 0 entry load + key level (0x1530-0x1940)', region(0x1530, 0x1940))
    tally('wave: slot 1 entry load + key level (0x1950-0x1dd0)', region(0x1950, 0x1dd0))
    tally('chunk: head (0x1de0-0x1ea0)', region(0x1de0, 0x1ea0))
    tally('chunk: transposed path, rotate acc (0x24d0-0x2530)', region(0x24d0, 0x2530))
    tally('group: AND setup slot 0 (0x2540-0x2650)', region(0x2540, 0x2650))
    tally('group: AND digit iteration slot 0 (0x2660-0x27a0)', region(0x2660, 0x27a0))
    tally('chunk: chunk mask, pass words (0x29e0-0x2a80)', region(0x29e0, 0x2a80))
    tally('chunk: slot-1 walk entry (0x3170-0x31b0)', region(0x3170, 0x31b0))
    tally('chunk: stage check, 2 barriers (0x3860-0x38f0)', region(0x3860, 0x38f0))
    tally('chunk: flush (taken at >= 512 staged)', region(0x3900, 0x3b50))
    tally('chunk/wave/batch loop tails (0x3b60-0x3c70)', region(0x3b60, 0x3c70))
    tally('small batch: per-top AND, 4 tops/iteration (0x1fe0-0x2260)', region(0x1fe0, 0x2260))
