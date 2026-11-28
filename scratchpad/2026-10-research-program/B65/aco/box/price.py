#!/usr/bin/env python3
"""price.py SLOTS ACO_TXT [LOOPIDX]: the word loop (phase 3b) of a main-kernel ACO listing: counts per wave-iteration
(aco/loops.py's classes), LDS bytes per wave-iteration (ds op width x 64 lanes), and the model of
G2/port/model_rdna4.py per wave-iteration in SIMD-cycles: VALU 2 x vcyc (wave64 in two passes), SALU salu,
LDS bytes / 64 (128 B/clk per CU = 64 B/clk per SIMD); bound = max; per slot = / SLOTS (lane slots = (entry, chunk)
pairs per wave-iteration). Default loop: the innermost loop with the most ds_read_b64. B65 ACO study, 2026-11-28."""
import sys, re
sys.path.insert(0, '/home/claude/projects/nice/.worktrees/g2-cubecl/aco')
import loops as L  # noqa: E402
W = {'b32': 4, 'b64': 8, 'b96': 12, 'b128': 16, 'u8': 1, 'u16': 2, 'i8': 1, 'i16': 2, '2_b32': 8, '2_b64': 16, '2st64_b32': 8, '2st64_b64': 16}
def ldsbytes(ops):
    n = 0
    for op, s in ops:
        if not op.startswith('ds_'): continue
        m = re.match(r'ds_(read|write|load|store)(2st64|2)?_?(b32|b64|b96|b128|u8|u16|i8|i16)', op)
        if m:
            n += (2 if m.group(2) else 1) * W[m.group(3)] * 64
        else:
            n += 4 * 64  # atomics, others
    return n
if __name__ == '__main__':
    slots = int(sys.argv[1]); p = sys.argv[2]
    blocks, st = L.parse(p)
    ls = L.loops(blocks)
    def body(i): a, b = ls[i]; return [o for blk in blocks[a:b + 1] for o in blk[2]]
    inner = [i for i, (a, b) in enumerate(ls) if not any(a < a2 and b2 <= b for (a2, b2) in ls if (a2, b2) != (a, b))]
    li = int(sys.argv[3]) if len(sys.argv) > 3 else max(inner, key=lambda i: sum(1 for o, _ in body(i) if o == 'ds_read_b64'))
    ops = body(li); c = L.count(ops); lb = ldsbytes(ops)
    r64 = sum(1 for o, _ in ops if o == 'ds_read_b64'); br = sum(1 for o, _ in ops if o.startswith('s_cbranch') or o == 's_branch')
    lw = sum(1 for o, _ in ops if o.startswith('ds_') and ('write' in o or 'store' in o or 'add' in o or 'and' in o or 'or' in o))
    v, s_, l = 2 * c['vcyc'], c['salu'], lb / 64
    print(f"{p.split('/')[-1][:40]} VGPRs={st.get('VGPRs')} LDS={st.get('LDS size')} waves={st.get('Subgroups per SIMD')} instr={st.get('Instructions')} loop {li}")
    print(f"  per wave-iteration: valu={c['valu']} q={c['q']} v64={c['v64']} vcyc={c['vcyc']} salu={c['salu']} (branches {br}) lds={c['lds']} (ds_read_b64 {r64}, stores/atomics {lw}) vmem={c['vmem']} wait={c['wait']} ldsB={lb}")
    print(f"  model SIMD-cycles per wave-iteration: VALU {v} SALU {s_} LDS {l:.0f} -> bound {max(v, s_, l):.0f}; per slot ({slots}): VALU {v/slots:.3f} LDS {l/slots:.3f} bound {max(v, s_, l)/slots:.3f}")
