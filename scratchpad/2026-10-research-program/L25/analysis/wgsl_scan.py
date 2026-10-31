#!/usr/bin/env python3
"""Split CUBECL_DEBUG_LOG dumps into per-kernel WGSL files and flag every
integer division / remainder by a literal constant whose dividend is (after
folding literal zeros) a right shift by half the width:

  SHR16       x >> 16 on a u32                       (naga_div(x >> 16u, K))
  HI32        u32(u64 >> 32)                         (uint(p >> 32) / K)
  HI32>>16    u32(u64 >> 32) >> 16                   (hi_mul_shr16 form)
  SHR48/HI    any other u64 shift >= 32 then u32

Literal-zero tracking: `l_mut_N = u32(0);` makes l_mut_N zero until the next
assignment or the next `{`/`}` (any control flow clears all knowledge, so a
runtime loop's loop-carried remainder is never treated as zero). `0 << k`
is zero, `0 | y` is y, `y & 65535` of a SHR16 value is that value.

usage: wgsl_scan.py OUT_DIR LOG...   (writes OUT_DIR/<kernel>_b<base>_<i>.wgsl
and prints one line per flagged site, plus a per-kernel summary)
"""
import os, re, sys

out_dir = sys.argv[1]
os.makedirs(out_dir, exist_ok=True)

LET = re.compile(r'^\s*let (l_\d+) = (.*);\s*$')
ASSIGN = re.compile(r'^\s*(l_mut_\d+) = (.*);\s*$')
DIV = re.compile(r'^(\S+) ([/%]) (u32|u64)\((\d+)\)$')
SHR = re.compile(r'^(\S+) >> u32\((\d+)\)$')
SHR64 = re.compile(r'^(\S+) >> u32\(bitcast<u64>\(u64\((\d+)\)\)\)$')
SHL = re.compile(r'^(\S+) << u32\((\d+)\)$')
OR = re.compile(r'^(\S+) \| (\S+)$')
AND = re.compile(r'^(\S+) & u32\((\d+)\)$')
CAST32 = re.compile(r'^u32\(bitcast<u64>\((\S+)\)\)$')
LIT0 = re.compile(r'^u(32|64)\(0\)$')

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

def analyse(src, tag):
    shape = {}      # l_N -> shape string
    known0 = set()  # l_mut_N currently a literal zero
    hits = []
    ndiv = 0
    for ln, line in enumerate(src.splitlines(), 1):
        if '{' in line or '}' in line:
            known0.clear()
        m = ASSIGN.match(line)
        if m:
            v, e = m.groups()
            if LIT0.match(e.strip()):
                known0.add(v)
            else:
                known0.discard(v)
            # a division written straight into a mutable (x /= base)
            dm = DIV.match(e.strip())
            if dm:
                ndiv += 1
            continue
        m = LET.match(line)
        if not m:
            continue
        v, e = m.groups()
        e = e.strip()
        def sh(x):
            if x in known0 or LIT0.match(x):
                return 'ZERO'
            return shape.get(x, '')
        s = ''
        if (mm := SHR64.match(e)):
            s = f'SHR64_{mm.group(2)}'
        elif (mm := SHR.match(e)):
            src_s = sh(mm.group(1))
            k = int(mm.group(2))
            if src_s == 'HI32' and k == 16:
                s = 'HI32>>16'
            elif k == 16:
                s = 'SHR16'
            else:
                s = f'SHR{k}'
        elif (mm := CAST32.match(e)):
            src_s = sh(mm.group(1))
            if src_s.startswith('SHR64_') and int(src_s[6:]) >= 32:
                s = 'HI32' if src_s == 'SHR64_32' else f'HI{src_s[6:]}'
        elif (mm := SHL.match(e)):
            if sh(mm.group(1)) == 'ZERO':
                s = 'ZERO'
        elif (mm := OR.match(e)):
            a, b = sh(mm.group(1)), sh(mm.group(2))
            if a == 'ZERO':
                s = b
            elif b == 'ZERO':
                s = a
            else:
                s = 'OR'
        elif (mm := AND.match(e)):
            a = sh(mm.group(1))
            if a in ('SHR16', 'HI32>>16') and int(mm.group(2)) == 65535:
                s = a
            elif a.startswith('SHR') and a != 'SHR16':
                s = a + '&'
        elif LIT0.match(e):
            s = 'ZERO'
        elif e in shape:
            s = shape[e]
        elif e in known0:
            s = 'ZERO'
        shape[v] = s
        dm = DIV.match(e)
        if dm:
            ndiv += 1
            dv, op, ty, k = dm.groups()
            k = int(k)
            ds = sh(dv)
            pow2 = k & (k - 1) == 0
            if ds in ('SHR16', 'HI32', 'HI32>>16') or ds.startswith('HI'):
                hits.append((ln, v, f'{dv} {op} {ty}({k})', ds, 'pow2' if pow2 else 'NON-POW2'))
    return hits, ndiv

tot = {}
for path in sys.argv[2:]:
    for i, blk in enumerate(blocks(path)):
        name = re.search(r'^name: (\S+?)::(\w+)<', blk, re.M)
        kname = name.group(2) if name else f'kernel{i}'
        base = re.search(r'^\s+base: (\d+),', blk, re.M)
        b = base.group(1) if base else 'x'
        srcpos = blk.find('\nsource:')
        src = blk[srcpos + 8:] if srcpos >= 0 else blk
        info = blk[:srcpos] if srcpos >= 0 else ''
        tag = f'{kname}_b{b}'
        n = 0
        while os.path.exists(os.path.join(out_dir, f'{tag}_{n}.wgsl')):
            n += 1
        fn = os.path.join(out_dir, f'{tag}_{n}.wgsl')
        with open(fn, 'w') as f:
            f.write(src)
        with open(fn[:-5] + '.info.txt', 'w') as f:
            f.write(info)
        hits, ndiv = analyse(src, tag)
        bad = [h for h in hits if h[4] == 'NON-POW2']
        print(f'## {fn}  const-div/rem sites: {ndiv}  half-shift dividends: {len(hits)} (non-pow2 divisor: {len(bad)})')
        for h in hits:
            print(f'   line {h[0]}: {h[1]} = {h[2]}   dividend={h[3]}  divisor={h[4]}')
