#!/usr/bin/env python3
"""walkcount.py ACO_TXT...: instructions of the join kernel's set-bit walk loops (the loops whose body holds the
stage append `ds_append`), from RADV's ACO dump ("After lowering to hw instructions"). Per loop (one per entry slot):
  loop  = every instruction from the loop header to the back edge (the pass path included)
  round = the path of a round in which no lane of the wave passes (loop minus the pass-path blocks, which start at the
          first block holding ds_append and end before the latch)
by family: valu, salu (scalar ALU incl. exec-mask ops and branches), wait (s_wait*/s_delay_alu/s_waitcnt_depctr/s_nop),
lds, mul (v_mul*/v_mad*, of valu), vmem. python3 -I walkcount.py files"""
import sys, re, collections

def fam(op):
    if op.startswith('ds_'): return 'lds'
    if op.startswith(('buffer_', 'global_', 's_load', 's_buffer_load')): return 'mem'
    if op.startswith(('s_wait', 's_delay_alu', 's_nop')): return 'wait'
    if op.startswith('s_'): return 'salu'
    if op.startswith('v_'): return 'valu'
    return 'other'

def parse(path):
    t = open(path).read()
    i = t.find('After lowering to hw instructions')
    body = t[i:t.find('*** SHADER STATS', i)] if i >= 0 else ''
    blocks = []  # (name, kind, [ops])
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
    return blocks

def count(ops):
    c = collections.Counter()
    for op, _ in ops:
        f = fam(op); c[f] += 1; c['all'] += 1
        if op.startswith(('v_mul', 'v_mad')): c['mul'] += 1
        if 'mul_hi' in op or 'mul_lo_u32' in op or 'mad_u64' in op or 'mad_co_u64' in op: c['mul32'] += 1
    return c

def walk_loops(blocks):
    idx = {b[0]: n for n, b in enumerate(blocks)}
    out = []
    for n, b in enumerate(blocks):
        if 'loop-header' not in b[1]: continue
        # latch: the last block that branches back to this header
        latch = None
        for m in range(n, len(blocks)):
            if any(op == 's_branch' and f'block:{b[0]}' in s for op, s in blocks[m][2]): latch = m
        if latch is None: continue
        body = blocks[n:latch + 1]
        # only the innermost loops holding ds_append and no nested loop header
        if not any(op == 'ds_append' for bb in body for op, _ in bb[2]): continue
        if any('loop-header' in bb[1] for bb in body[1:]): continue
        first_app = next(k for k, bb in enumerate(body) if any(op == 'ds_append' for op, _ in bb[2]))
        loop_ops = [o for bb in body for o in bb[2]]
        round_ops = [o for bb in body[:first_app] + [body[-1]] for o in bb[2]]
        # the pass path while the stage has room: from the append to the first block of the stage-full branch (the
        # first block after the append that touches global memory)
        stop = next((k for k in range(first_app, len(body)) if any(fam(op) == 'mem' for op, _ in body[k][2])), len(body) - 1)
        pass_ops = [o for bb in body[first_app:stop] for o in bb[2]]
        out.append((b[0], blocks[latch][0], count(loop_ops), count(round_ops), body, first_app, count(pass_ops)))
    return out

if __name__ == '__main__':
    verbose = '-v' in sys.argv
    for p in [a for a in sys.argv[1:] if a != '-v']:
        ls = walk_loops(parse(p))
        print(f'{p.split("/")[-1]}: {len(ls)} walk loops')
        for h, l, cl, cr, body, fa, cp in ls:
            f = lambda c: ' '.join(f'{k}={c[k]}' for k in ('all', 'valu', 'salu', 'wait', 'lds', 'mul32', 'mem', 'other'))
            print(f'  {h}..{l}  loop: {f(cl)}')
            print(f'  {"":{len(h)+len(l)+2}}  round (no lane passes): {f(cr)}')
            print(f'  {"":{len(h)+len(l)+2}}  + pass path (stage has room): {f(cp)}')
            if verbose:
                for bb in body[:fa] + [body[-1]]:
                    print('   ', bb[0], bb[1])
                    for op, s in bb[2]: print('      ', s)
