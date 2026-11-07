#!/usr/bin/env python3
"""L47: path costs of the post-#241 check_kernel (L44/raw/sass/check_kernel_b62_1.sass, nvcc sm_86, 38 regs),
by address range, with an L41-style pipe split. Every range below was read off the SASS by hand
(see SCOPING.md §2 for the walk); the b60 kernel has the same structure (704 instr) with shifted
addresses, so b60 paths are priced with the b62 table (the per-digit chunk code differs by 2-3 SHFs)."""
import re, collections, os
HERE = os.path.dirname(os.path.abspath(__file__))
SASS = os.path.join(HERE, '../../../L44/raw/sass/check_kernel_b62_1.sass')
ins = {}
for line in open(SASS):
    m = re.match(r'\s+/\*([0-9a-f]{4,})\*/\s+(.*?)\s*;', line)
    if m: ins[int(m.group(1), 16)] = m.group(2)
def op(t):
    t = re.sub(r'^@!?U?P[T0-9]\s+', '', t)
    return t.split()[0]
def pipe(o):
    b = o.split('.')[0]
    if b.startswith('U') or b in ('VOTEU', 'R2UR', 'S2UR'): return 'UNI'
    if b == 'IMAD': return 'FMA'
    if b in ('FLO', 'POPC', 'BREV', 'MUFU', 'I2F', 'F2I'): return 'XU'
    if b in ('LDS', 'STS', 'ATOMS', 'SHFL', 'S2R', 'CS2R'): return 'MIO'
    if b in ('LDG', 'STG', 'ATOMG', 'RED'): return 'MEM'
    if b in ('BRA', 'BSSY', 'BSYNC', 'NOP', 'BAR', 'CALL', 'EXIT', 'WARPSYNC', 'YIELD'): return 'CBU'
    return 'ALU'
def rng(lo, hi):
    c = collections.Counter()
    for a in range(lo, hi + 1, 0x10):
        o = op(ins[a]); c[pipe(o)] += 1; c['n'] += 1
        if o.startswith('IMAD.WIDE'): c['wide'] += 1
    return c
def S(*rs):
    c = collections.Counter()
    for r in rs: c += rng(*r)
    return c
# --- per survivor, outside the scans
PRO = S((0x0110, 0x06c0)) - S((0x0570, 0x0640)) + S((0x0570, 0x05a0))   # loads, n, n^2 (59), top limb (5 limbs: 4), setup
PRO += S((0x06d0, 0x0700))
SQ_EXIT = S((0x1470, 0x14c0))
EPI = S((0x28f0, 0x2960)) + S((0x2ac0, 0x2b10))
CU_SETUP = S((0x14d0, 0x19a0)) + S((0x19b0, 0x1a10)) + S((0x1b20, 0x1bb0))   # multiply (78), top limb (7 limbs), setup
# --- one pass of the n^2 scan (loop head 0x0710) and of the n^3 scan (0x1bc0)
def rem_cost(base, r):
    starts = base
    c = collections.Counter()
    if r >= 1: c += S(starts[0])
    if r >= 2: c += S(starts[1])
    if r >= 3: c += S(starts[2])
    return c
SQ = dict(head=S((0x0710, 0x0740), (0x0750, 0x07f0)), pre4=S((0x0800, 0x0860)), loop4=S((0x0870, 0x0b70)),
          mid=S((0x0b80, 0x0b90)), rem=[(0x0ba0, 0x0c70), (0x0c80, 0x0d40), (0x0d50, 0x0df0)], after=S((0x0e00, 0x0e00)),
          trim0=S((0x0e10, 0x0e20)), trim_nz=S((0x0e30, 0x0e60)), trim_z=S((0x0e30, 0x0e90)), trimend=S((0x0ea0, 0x0ea0)),
          br=S((0x0eb0, 0x0ed0)), inter=S((0x10f0, 0x13b0)), ms0=S((0x0ee0, 0x0f20)), msd1=S((0x0f30, 0x0ff0)),
          msdn=S((0x1000, 0x10c0)), msend=S((0x10d0, 0x10e0), (0x13b0, 0x13b0)), tail=S((0x13c0, 0x1460)))
CU = dict(head=S((0x1bc0, 0x1bf0), (0x1c00, 0x1cb0)), pre4=S((0x1cc0, 0x1ce0)), loop4=S((0x1cf0, 0x1ff0)),
          mid=S((0x2000, 0x2010)), rem=[(0x2020, 0x20f0), (0x2100, 0x21c0), (0x21d0, 0x2270)], after=S((0x2280, 0x2280)),
          trim0=S((0x2290, 0x22a0)), trim_nz=S((0x22b0, 0x22e0)), trim_z=S((0x22b0, 0x2310)), trimend=S((0x2320, 0x2320)),
          br=S((0x2330, 0x2350)), inter=S((0x2570, 0x2830)), ms0=S((0x2360, 0x2390)), msd1=S((0x23a0, 0x2460)),
          msdn=S((0x2480, 0x2540)), msend=S((0x2550, 0x2560), (0x2830, 0x2830)), tail=S((0x2840, 0x28e0)))
def pass_cost(T, nl, zeros, ends_negative, ms_digits):
    """nl limbs divided; `zeros` zero limbs trimmed after the division; ends_negative: the quotient is 0
    (the chunk is the most significant one, ms_digits digits until zero)."""
    c = T['head'] + T['mid'] + T['after'] + T['trim0'] + T['trimend'] + T['br'] + T['tail']
    if nl >= 4:
        c += T['pre4']
        for _ in range(nl // 4): c += T['loop4']
    for i in range(nl & 3): c += S(T['rem'][i])
    if ends_negative:
        for _ in range(zeros): c += T['trim_z']
        c += T['ms0']
        if ms_digits >= 1: c += T['msd1']
        for _ in range(ms_digits - 1): c += T['msdn']
        c += T['msend']
    else:
        for _ in range(zeros): c += T['trim_z']
        c += T['trim_nz'] + T['inter']
    return c
if __name__ == '__main__':
    for name, c in [('prologue', PRO), ('sq exit', SQ_EXIT), ('epilogue', EPI), ('cube setup', CU_SETUP)]:
        print(f'{name:12s} {dict(c)}')
    for nl in range(1, 8):
        print('sq pass nl', nl, dict(pass_cost(SQ, nl, 1, False, 0)))
    print('sq MS pass nl 1, 5 digits', dict(pass_cost(SQ, 1, 1, True, 5)))
    print('per-limb 4x loop', dict(SQ['loop4']), 'interior chunk', dict(SQ['inter']))
