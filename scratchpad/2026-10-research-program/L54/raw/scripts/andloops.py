#!/usr/bin/env python3
"""andloops.py SASS...: the transposed AND's digit loops in a join_kernel SASS dump: every backward branch whose body
holds a FLO (the set-bit iteration) and at least 2 LDS; per loop: instructions, LDS, and the classification of the
body into the OR work (LDS + LOP3 ORs into the accumulators), address arithmetic (IADD3/IMAD/LEA/IMAD.IADD/IMAD.SHL
whose result feeds an LDS address), and the rest (bit iteration, invariants). Also the per-top AND loop (backward
branch, 2 LDS, no FLO) for reference. With -v the loop bodies are printed."""
import re, sys, collections
verbose = '-v' in sys.argv; only_and = '--and' in sys.argv
for f in [a for a in sys.argv[1:] if not a.startswith('-')]:
    ins = []
    for line in open(f):
        m = re.match(r'\s+/\*([0-9a-f]{4,})\*/\s+(.*?)\s*;', line)
        if m: ins.append((int(m.group(1), 16), m.group(2)))
    addr = {a: i for i, (a, _) in enumerate(ins)}
    out = []
    for i, (a, t) in enumerate(ins):
        m = re.search(r'\bBRA\s+(?:`\()?\.?L?_?x?_?(?:0x)?([0-9a-f]+)', t)
        if not m: continue
        tgt = int(m.group(1), 16)
        if tgt >= a or tgt not in addr: continue
        body = ins[addr[tgt]:i + 1]
        ops = [re.sub(r'^@!?U?P[T0-9]\s+', '', x).split()[0] for _, x in body]
        nlds = sum(o.startswith('LDS') for o in ops); nflo = sum(o.startswith('FLO') for o in ops)
        if nlds < 2 or len(body) > 80: continue
        kind = 'transposed' if nflo else 'per-top'
        # address registers: the LDS operands' base registers; walk back their producers in the body
        lds_regs = set()
        for _, x in body:
            mm = re.search(r'LDS(?:\.\S+)?\s+R\d+,\s*\[(R\d+)', x)
            if mm: lds_regs.add(mm.group(1))
        addr_ins = 0; dests = {}
        for j, (_, x) in enumerate(body):
            o = re.sub(r'^@!?U?P[T0-9]\s+', '', x)
            mm = re.match(r'(\S+)\s+(R\d+)', o)
            if mm: dests[j] = (mm.group(1), mm.group(2))
        # producers of LDS address registers (one level back through IADD3/IMAD chains)
        want = set(lds_regs); chain = set()
        for _ in range(3):
            for j, (op, d) in dests.items():
                if d in want and (op.startswith('IADD3') or op.startswith('IMAD') or op.startswith('LEA') or op.startswith('SHF') or op.startswith('LOP3')):
                    src = re.findall(r'\bR\d+\b', body[j][1].split(d, 1)[1]) if d in body[j][1] else []
                    if j not in chain: chain.add(j)
                    want |= {s for s in src if s != 'RZ'}
        # an OR into an accumulator = LOP3 ... 0xfc whose operand is an LDS destination
        lds_dst = {re.search(r'LDS(?:\.\S+)?\s+(R\d+)', x).group(1) for _, x in body if re.search(r'LDS(?:\.\S+)?\s+(R\d+)', x)}
        nor = sum(1 for _, x in body if 'LOP3' in x and '0xfc' in x and any(r in re.findall(r'R\d+', x)[1:] for r in lds_dst))
        out.append((kind, a, tgt, len(body), nlds, nor, len(chain), body))
    print(f'== {f}')
    for kind, a, tgt, n, nlds, nor, nadr, body in out:
        if only_and and not (kind == 'transposed' and nor >= 2 and nor == nlds): continue
        print(f'  {kind:10s} loop {tgt:#06x}-{a:#06x}: {n:3d} instr, LDS {nlds}, OR {nor}, address-chain {nadr}, other {n - nlds - nor - nadr}')
        if verbose:
            for aa, x in body: print(f'      {aa:#06x} {x}')
