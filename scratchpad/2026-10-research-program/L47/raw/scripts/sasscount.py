#!/usr/bin/env python3
"""L47: the check kernel's SASS by region. python3 sasscount.py FILE.sass
Prints the instruction count, the per-entry body (from the record loads' LDG to the inner loop's back edge), the gated
block (the rest of n³: from the branch after the first POPC pair to the second POPC pair) and the common path per
warp-iteration = body − gated block, with a class split (FMA-pipe IMAD*, ALU, LD/ST, branch, other)."""
import re, sys
ins = []
for line in open(sys.argv[1]):
    m = re.match(r'\s+/\*([0-9a-f]{4,})\*/\s+(.*?)\s*;', line)
    if m: ins.append((int(m.group(1), 16), m.group(2)))
def op(t):
    t = re.sub(r'^@!?U?P\w+\s+', '', t)
    return t.split()[0]
def cls(o):
    if o.startswith('IMAD') or o.startswith('IMUL') or o.startswith('FFMA') or o.startswith('IDP'): return 'fma'
    if o.startswith(('LDG', 'STG', 'LDS', 'STS', 'LDL', 'STL', 'ATOM', 'RED', 'LDC', 'ULDC', 'SHFL', 'LD.', 'ST.')): return 'mem'
    if o.startswith(('BRA', 'BSYNC', 'BSSY', 'EXIT', 'WARPSYNC', 'BAR', 'CALL', 'RET', 'BREAK', 'YIELD', 'BPT', 'JMP', 'NOP')): return 'br'
    return 'alu'
n = len(ins)
ops = [op(t) for _, t in ins]
addr = [a for a, _ in ins]
popc = [i for i, o in enumerate(ops) if o.startswith('POPC')]
# back edges: BRA to a lower address
back = []
for i, (a, t) in enumerate(ins):
    if op(t).startswith('BRA'):
        m = re.search(r'`?\(\.L_x_\d+\)|0x([0-9a-f]+)', t)
        tgt = re.search(r'0x([0-9a-f]+)', t)
        if tgt and int(tgt.group(1), 16) < a: back.append((i, int(tgt.group(1), 16)))
ldg = [i for i, o in enumerate(ops) if o.startswith('LDG')]
print(f'{sys.argv[1]}: {n} instructions, POPC at {[hex(addr[i]) for i in popc]}, LDG at {[hex(addr[i]) for i in ldg]}')
print('back edges:', [(hex(addr[i]), hex(t)) for i, t in back])
def split(lo, hi):
    c = {'fma': 0, 'alu': 0, 'mem': 0, 'br': 0}
    for o in ops[lo:hi]: c[cls(o)] += 1
    return c
# the mask popcounts come in adjacent register pairs (the atomics' POPC of a vote mask do not)
regp = [k for k in popc if 'UR' not in ins[k][1] and 'LTMASK' not in ins[k - 1][1] and 'SR_' not in ins[k][1]]
pairs = []
for k in regp:
    nxt = [j for j in regp if 0 < j - k <= 3]
    if nxt and k not in pairs:
        pairs += [k, nxt[0]]
best = None
for i_be, t_be in back:
    inside = [k for k in pairs if t_be <= addr[k] <= addr[i_be]]
    if len(inside) >= 4 and (best is None or addr[i_be] - t_be < addr[best[0]] - best[1]):
        best = (i_be, t_be, inside)
if best:
    i_be, t_be, pin = best
    lo = next(k for k in range(n) if addr[k] >= t_be)
    body = i_be + 1 - lo
    g0 = next(k for k in range(pin[1] + 1, n) if ops[k].startswith('BRA'))
    g1 = pin[2]
    gated = g1 - g0 - 1
    # the hit write-back: the first forward conditional branch after the final POPC pair, to its target
    h0 = next(k for k in range(pin[3] + 1, n) if ops[k].startswith('BRA') and ins[k][1].startswith('@'))
    ht = int(re.search(r'0x([0-9a-f]+)', ins[h0][1]).group(1), 16)
    h1 = next(k for k in range(n) if addr[k] >= ht)
    hitblk = h1 - h0 - 1
    common = body - gated - hitblk
    print(f'inner loop {hex(addr[lo])}..{hex(addr[i_be])}: {body} instructions; gated block (rest of n^3) '
          f'{hex(addr[g0])}..{hex(addr[g1])}: {gated}; hit write-back {hex(addr[h0])}..{hex(ht)}: {hitblk}; '
          f'common path {common}  split {split(lo, g0 + 1)} + {split(g1, h0 + 1)} + {split(h1, i_be + 1)}')
