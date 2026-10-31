#!/usr/bin/env python3
"""Stricter companion to L25/analysis/wgsl_scan.py, same input (CUBECL_DEBUG_LOG
dumps), for the stride nice-only kernel's constant divisions.

On top of wgsl_scan.py's rules, it follows constant-index array stores and
loads within a block, and (literal-zero folding; SHR16, HI32, HI32>>16
dividends) it also folds a word rebuilt from its halves,
`((x >> 16) << 16) | (x & 65535)`, back to x, so dividing a u64 high half
through such a pair is flagged as HI32 too. For every division or remainder by
a literal non-power-of-two constant it reports the dividend's defining
operator (OR / ADD / SUB / other) and, for OR, whether the left operand is a
literal zero.

usage: wgsl_scan2.py LOG...   (prints per-kernel summaries, one per kernel)
"""
import re, sys
from collections import Counter

LET = re.compile(r'^\s*let (l_\d+) = (.*);\s*$')
ASSIGN = re.compile(r'^\s*(l_mut_\d+) = (.*);\s*$')
DIV = re.compile(r'^(\S+) ([/%]) (u32|u64)\((\d+)\)$')
SHR = re.compile(r'^(\S+) >> u32\((\d+)\)$')
SHR64 = re.compile(r'^(\S+) >> u32\(bitcast<u64>\(u64\((\d+)\)\)\)$')
SHL = re.compile(r'^(\S+) << u32\((\d+)\)$')
OR = re.compile(r'^(\S+) \| (\S+)$')
ADD = re.compile(r'^(\S+) \+ (\S+)$')
SUB = re.compile(r'^(\S+) - (\S+)$')
MUL = re.compile(r'^(\S+) \* (\S+)$')
AND = re.compile(r'^(\S+) & u32\((\d+)\)$')
CAST32 = re.compile(r'^u32\(bitcast<u64>\((\S+)\)\)$')
LIT0 = re.compile(r'^u(32|64)\(0\)$')
LOAD = re.compile(r'^(\S+)\[(.*)\]$')
ASTORE = re.compile(r'^\s*(a_\d+)\[u32\((\d+)\)\] = (\S+);\s*$')

def blocks(path):
    cur = None
    for line in open(path, errors='replace'):
        if line.startswith('[START_KERNEL_COMPILATION]'):
            cur = []
        elif line.startswith('[END_KERNEL_COMPILATION]'):
            if cur is not None:
                yield ''.join(cur)
            cur = None
        elif cur is not None:
            cur.append(line)

def analyse(src):
    shape = {}   # var -> (kind, src)
    op = {}      # var -> defining operator
    known0 = set()
    mut = {}     # l_mut -> var/expr last assigned (same block only)
    arr = {}     # (a_N, const index) -> var stored there (same block only)
    hits, kinds = [], Counter()
    for ln, line in enumerate(src.splitlines(), 1):
        if '{' in line or '}' in line:
            known0.clear(); mut.clear(); arr.clear()
        m = ASTORE.match(line)
        if m:
            arr[(m.group(1), m.group(2))] = m.group(3)
            continue
        m = ASSIGN.match(line)
        if m:
            v, e = m.groups(); e = e.strip()
            if LIT0.match(e):
                known0.add(v)
            else:
                known0.discard(v)
            mut[v] = e
            continue
        m = LET.match(line)
        if not m:
            continue
        v, e = m.groups(); e = e.strip()
        def sh(x):
            if x in known0 or LIT0.match(x):
                return ('ZERO', None)
            return shape.get(x, ('', x))
        s = ('', v); o = 'other'
        if (mm := SHR64.match(e)):
            s = (f'SHR64_{mm.group(2)}', mm.group(1)); o = 'SHR'
        elif (mm := SHR.match(e)):
            k0, _ = sh(mm.group(1)); k = int(mm.group(2)); o = 'SHR'
            if k == 16:
                s = ('HI32>>16' if k0 == 'HI32' else 'SHR16', mm.group(1))
            else:
                s = (f'SHR{k}', mm.group(1))
        elif (mm := CAST32.match(e)):
            k0, _ = sh(mm.group(1)); o = 'CAST'
            if k0.startswith('SHR64_') and int(k0[6:]) >= 32:
                s = ('HI32' if k0 == 'SHR64_32' else f'HI{k0[6:]}', mm.group(1))
        elif (mm := SHL.match(e)):
            k0, s0 = sh(mm.group(1)); o = 'SHL'
            if k0 == 'ZERO':
                s = ('ZERO', None)
            elif k0 in ('SHR16', 'HI32>>16') and mm.group(2) == '16':
                s = ('HIPART', s0)   # (x >> 16) << 16
        elif (mm := OR.match(e)):
            a, b = sh(mm.group(1)), sh(mm.group(2)); o = 'OR0' if a[0] == 'ZERO' else 'OR'
            if a[0] == 'ZERO':
                s = b
            elif b[0] == 'ZERO':
                s = a
            elif {a[0], b[0]} == {'HIPART', 'LOPART'} and a[1] == b[1]:
                s = shape.get(a[1], ('', a[1]))     # rebuilt word: fold to x
                o = 'OR(rebuilt word)'
        elif (mm := AND.match(e)):
            k0, s0 = sh(mm.group(1)); o = 'AND'
            if int(mm.group(2)) == 65535:
                s = ('LOPART', mm.group(1)) if k0 not in ('SHR16', 'HI32>>16') else (k0, s0)
        elif (mm := ADD.match(e)):
            o = 'ADD'
        elif (mm := SUB.match(e)):
            o = 'SUB'
        elif (mm := MUL.match(e)):
            o = 'MUL'
        elif LIT0.match(e):
            s = ('ZERO', None)
        elif e in known0:
            s = ('ZERO', None)
        elif e in shape:
            s = shape[e]; o = op.get(e, 'other')
        elif (mm := re.match(r'^(a_\d+)\[u32\((\d+)\)\]$', e)) and (mm.group(1), mm.group(2)) in arr:
            src_v = arr[(mm.group(1), mm.group(2))]
            s = sh(src_v) if (src_v in shape or src_v in known0) else ('', src_v)
            o = op.get(src_v, 'LOAD')
        elif LOAD.match(e):
            o = 'LOAD'
        shape[v] = s; op[v] = o
        dm = DIV.match(e)
        if dm:
            dv, opc, ty, k = dm.groups(); k = int(k)
            if k & (k - 1) == 0:
                continue
            ds = sh(dv)[0]
            dop = 'ZERO' if ds == 'ZERO' else op.get(dv, 'mut' if dv.startswith('l_mut') else 'other')
            kinds[(k, dop)] += 1
            if ds in ('SHR16', 'HI32', 'HI32>>16') or ds.startswith('HI'):
                hits.append((ln, f'{v} = {dv} {opc} {ty}({k})', ds))
    return hits, kinds

for path in sys.argv[1:]:
    for i, blk in enumerate(blocks(path)):
        name = re.search(r'^name: (\S+?)::(\w+)<', blk, re.M)
        kname = name.group(2) if name else f'kernel{i}'
        if kname != 'NiceonlyKernel':
            continue
        info = {k: re.search(rf'^\s+{k}: (\w+),', blk, re.M) for k in
                ('base', 'limbs', 'pre_limbs', 'pre_chunk_div', 'chunk_div', 'probe', 'compact', 'plane_scoped', 'cross')}
        info = {k: (m.group(1) if m else '-') for k, m in info.items()}
        srcpos = blk.find('\nsource:')
        src = blk[srcpos + 8:] if srcpos >= 0 else blk
        hits, kinds = analyse(src)
        desc = ' '.join(f'{k}={v}' for k, v in info.items())
        print(f'## {path.split("/")[-1]} kernel {i}: {desc}')
        print(f'   flagged dividends (SHR16 / HI32 / HI32>>16, incl. rebuilt words): {len(hits)}')
        for h in hits:
            print(f'      line {h[0]}: {h[1]}   dividend={h[2]}')
        for (k, dop), c in sorted(kinds.items()):
            print(f'   divisor {k}: {c:3d} with dividend {dop}')
