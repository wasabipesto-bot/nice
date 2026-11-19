#!/usr/bin/env python3
"""preflight.py DIR... : one markdown row per kernel of an ACO dump directory (dump.sh): wave size, VGPRs, SGPRs,
LDS bytes, waves per SIMD (ACO: wave32 slots... RADV prints 'Subgroups per SIMD' in the kernel's own wave size),
scratch, spills, instructions, whole-kernel class counts (aco/loops.py's classes: valu, q = quarter-rate muls, v64 =
64-bit VALU, salu, lds, vmem, vcyc = valu + 4q + 2v64), the spirv-val verdict, and per loop (innermost marked) the
same counts per wave-iteration. Step 4S, 2026-11-19. python3 -I preflight.py DIR..."""
import sys, os, re, glob
sys.path.insert(0, '/home/claude/projects/nice/.worktrees/g2-cubecl/aco')
import loops as L  # noqa: E402

def stats(t):
    s = t[t.find('*** SHADER STATS'):]
    return dict(re.findall(r'^(SGPRs|VGPRs|Spilled SGPRs|Spilled VGPRs|LDS size|Scratch size|Subgroups per SIMD|Instructions): (\d+)', s, re.M))

for d in sys.argv[1:]:
    print(f"\n### {os.path.basename(d.rstrip('/'))}\n")
    print('| kernel | wave | VGPRs | SGPRs | LDS B | waves/SIMD | scratch | spills | instr | valu | q | v64 | salu | lds | vmem | vcyc | spirv-val |')
    print('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
    loops_out = []
    for p in sorted(glob.glob(os.path.join(d, '*.aco.txt'))):
        name = os.path.basename(p).split('_WgpuRuntime')[0]
        t = open(p).read()
        st = stats(t)
        blocks, _ = L.parse(p)
        body = t[t.find('After lowering to hw instructions'):t.find('*** SHADER STATS')]
        wave = 64 if re.search(r'%0:exec = s_mov_b64', body) else 32
        c = L.count([o for b in blocks for o in b[2]])
        v = p.replace('.aco.txt', '.val')
        val = 'ok' if os.path.exists(v) and os.path.getsize(v) == 0 else (open(v).read().split('\n')[0][:60] if os.path.exists(v) else '?')
        print(f"| {name} | {wave} | {st.get('VGPRs')} | {st.get('SGPRs')} | {st.get('LDS size')} | {st.get('Subgroups per SIMD')} | {st.get('Scratch size')} | {st.get('Spilled VGPRs')}/{st.get('Spilled SGPRs')} | {st.get('Instructions')} | {c['valu']} | {c['q']} | {c['v64']} | {c['salu']} | {c['lds']} | {c['vmem']} | {c['vcyc']} | {val} |")
        for n, (a, b) in enumerate(L.loops(blocks)):
            inner = not any(a < a2 and b2 <= b for (a2, b2) in L.loops(blocks) if (a2, b2) != (a, b))
            cc = L.count([o for blk in blocks[a:b + 1] for o in blk[2]])
            loops_out.append(f"- {name} loop {n} ({blocks[a][0]}..{blocks[b][0]}{', innermost' if inner else ''}): {L.fmt(cc)}")
    print('\nLoops (per wave-iteration, the loop body including nested loops once):\n')
    print('\n'.join(loops_out))
