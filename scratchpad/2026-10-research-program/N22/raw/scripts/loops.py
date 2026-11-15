#!/usr/bin/env python3
"""loops.py ACO_TXT [--blocks LOOPIDX] : every loop of an ACO dump ("After lowering to hw instructions"), innermost
first marked, with instruction counts by class over the loop's whole body (header .. latch, nested loops included):
  valu (full-rate VALU), q (quarter-rate: v_mul_lo/hi_u32/i32), v64 (64-bit VALU: *_b64/_u64/_i64, v_mad_*u64*),
  salu (scalar ALU incl. exec-mask ops and branches), lds (ds_*), vmem (global_/buffer_), smem, wait
  (s_wait*/s_delay_alu/s_nop/s_waitcnt_depctr), alu = valu+q+v64+salu+lds (N21's ALU), vcyc = valu + 4q + 2v64
  (VALU issue in full-rate units, ACO's GFX10+ cost table). Also the kernel's LDS bytes, VGPRs, waves per SIMD.
python3 -I loops.py files"""
import sys, re, collections

def fam(op):
    if op.startswith('ds_'): return 'lds'
    if op.startswith(('buffer_', 'global_', 'scratch_')): return 'vmem'
    if op.startswith(('s_load', 's_buffer_load')): return 'smem'
    if op.startswith(('s_wait', 's_delay_alu', 's_nop')): return 'wait'
    if op.startswith('s_'): return 'salu'
    if op.startswith('v_'):
        if re.match(r'v_mul_(lo|hi)_(u|i)32$', op): return 'q'
        if re.search(r'_(b64|u64|i64)(_e64)?$', op) or 'u64_u32' in op: return 'v64'
        return 'valu'
    return 'other'

def parse(path):
    t = open(path).read()
    i = t.find('After lowering to hw instructions')
    body = t[i:t.find('*** SHADER STATS', i)] if i >= 0 else ''
    st = dict(re.findall(r'^(VGPRs|SGPRs|LDS size|Subgroups per SIMD|Instructions|Latency|Inverse Throughput): (\d+)', t[t.find('*** SHADER STATS'):], re.M))
    blocks = []
    cur = None
    for l in body.splitlines():
        s = l.strip()
        m = re.match(r'^(BB\d+)$', s)
        if m:
            cur = [m.group(1), '', []]; blocks.append(cur); continue
        if cur is None: continue
        if s.startswith('/*'):
            k = re.search(r'kind: ([^*]*)\*/', s)
            if k: cur[1] = k.group(1)
            continue
        if not s or s.startswith('ACO'): continue
        r = s.split(' = ', 1)[1] if ' = ' in s else s
        m = re.match(r'([a-z]\w+)', r)
        if m: cur[2].append((m.group(1), s))
    return blocks, st

def count(ops):
    c = collections.Counter()
    for op, _ in ops:
        c[fam(op)] += 1
    c['alu'] = c['valu'] + c['q'] + c['v64'] + c['salu'] + c['lds']
    c['vcyc'] = c['valu'] + 4 * c['q'] + 2 * c['v64']
    return c

def loops(blocks):
    out = []
    for n, b in enumerate(blocks):
        if 'loop-header' not in b[1]: continue
        latch = None
        for m in range(n, len(blocks)):
            if any(op == 's_branch' and re.search(rf'block:{b[0]}\b', s) for op, s in blocks[m][2]): latch = m
        if latch is None: continue
        out.append((n, latch))
    return out

def fmt(c):
    return ' '.join(f'{k}={c[k]}' for k in ('alu', 'valu', 'q', 'v64', 'salu', 'lds', 'vmem', 'smem', 'wait', 'vcyc'))

if __name__ == '__main__':
    args = sys.argv[1:]
    show = None
    summary = '--summary' in args
    if summary: args.remove('--summary')
    if '--blocks' in args:
        i = args.index('--blocks'); show = int(args[i + 1]); del args[i:i + 2]
    for p in args:
        blocks, st = parse(p)
        allops = [o for b in blocks for o in b[2]]
        print(f"== {p.split('/')[-1]}: {' '.join(f'{k}={v}' for k, v in st.items())}")
        print(f"   whole: {fmt(count(allops))}")
        ls = loops(blocks)
        for li, (n, l) in enumerate(ls):
            inner = not any(n < n2 <= l2 <= l and (n2, l2) != (n, l) for n2, l2 in ls)
            ops = [o for b in blocks[n:l + 1] for o in b[2]]
            c = count(ops)
            print(f"   loop {li}: {blocks[n][0]}..{blocks[l][0]} ({l - n + 1} blocks{', innermost' if inner else ''}) {fmt(c)}")
            if show == li:
                for b in blocks[n:l + 1]:
                    br = ' '.join(re.sub(r'.*(s_\w+).*block:(BB\d+).*', r'\1->\2', s2) for op, s2 in b[2] if 'block:' in s2)
                    print(f"     {b[0]} [{b[1].strip()}] {fmt(count(b[2]))}  {br}")
                    if not summary:
                        for op, s2 in b[2]:
                            print(f"        {fam(op):5} {s2}")
