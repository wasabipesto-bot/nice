"""sass_loops.py FILE.sass [--show LO-HI]: SASS loops (backward branches), instruction count and mix, source-line span."""
import sys, re, collections
p = sys.argv[1]; show = None
fn = sys.argv[sys.argv.index('--func') + 1] if '--func' in sys.argv else None
if '--show' in sys.argv: show = sys.argv[sys.argv.index('--show') + 1]
ins = []; line = 0; func = None; labels = {}; pend = []
keep = fn is None
for l in open(p):
    mf = re.match(r'\s*\.text\.(\S+):', l)
    if mf: keep = fn is None or fn in mf.group(1)
    if not keep: continue
    ml = re.match(r'\s*(\.L_x_\d+):', l)
    if ml: pend.append(ml.group(1)); continue
    m = re.search(r'line (\d+)', l) if '//##' in l else None
    if m: line = int(m.group(1)); continue
    m = re.match(r'\s*/\*([0-9a-f]{4,})\*/\s+(@!?U?P\w+\s+)?([A-Z][A-Z0-9_.]*)\s*([^;]*);', l)
    if m:
        ins.append((int(m.group(1), 16), m.group(3), m.group(4), line, m.group(2) or ''))
        for lb in pend: labels[lb] = int(m.group(1), 16)
        pend = []
    if re.match(r'\s*\.text\.', l) or ('Function :' in l): ins.append((-1, 'FUNC', l.strip(), 0, ''))
def cls(op):
    o = op.split('.')[0]
    if o in ('LDS', 'STS', 'ATOMS'): return 'shared'
    if o in ('LDG', 'STG', 'ATOMG', 'RED', 'LD', 'ST'): return 'global'
    if o in ('SHFL', 'VOTE', 'VOTEU', 'MATCH', 'REDUX'): return 'warp'
    if o in ('BRA', 'BSSY', 'BSYNC', 'BAR', 'WARPSYNC', 'CALL', 'RET', 'EXIT', 'NOP', 'BREAK', 'BPT', 'YIELD'): return 'ctrl'
    if o in ('IMAD', 'IMUL'): return 'imad'
    return 'alu'
loops = []
for i, (a, op, args, ln, pr) in enumerate(ins):
    if op == 'BRA':
        m = re.search(r'(\.L_x_\d+)', args)
        if m and labels.get(m.group(1), 1 << 30) <= a: loops.append((labels[m.group(1)], a))
for lo, hi in sorted(set(loops)):
    body = [x for x in ins if lo <= x[0] <= hi]
    c = collections.Counter(cls(x[1]) for x in body)
    lines = [x[3] for x in body if x[3]]
    print(f"loop 0x{lo:x}-0x{hi:x}: {len(body)} instr  " + ' '.join(f"{k}={c[k]}" for k in ('alu', 'imad', 'shared', 'global', 'warp', 'ctrl')) + f"  src lines {min(lines) if lines else 0}-{max(lines) if lines else 0}")
    if show == f"{lo:x}-{hi:x}":
        for x in body: print(f"    {x[0]:5x} {x[4]}{x[1]} {x[2]}   //{x[3]}")
