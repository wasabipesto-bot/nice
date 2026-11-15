#!/usr/bin/env python3
"""acotab.py SPVDIR...: one row per dump directory (<label>/JoinKernel*.aco.txt, label = b<base>_<n21> or d<base>_<n21>):
instructions of the first entry slot's walk, from RADV's ACO (GFX1201, wave64). Columns:
  round  = a walk round in which no lane passes (header, pop, loads, prefilter, the pass test, latch); with switch D
           (bit 128) the walk has no pass branch and this is the whole walk loop
  pass   = what a round adds when some lane passes and the stage has room (ds_append, the stage writes); with D, the
           second (append) walk's round instead, run only over the passing pairs' bits
  alu    = valu + salu + lds of `round` (waits and s_delay_alu excluded), the number the brief's price applies to
python3 -I acotab.py ../box/spv/*"""
import sys, os, glob, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import walkcount as w

def loops(b):
    out = []
    for n, bb in enumerate(b):
        if 'loop-header' not in bb[1]: continue
        latch = None
        for m in range(n, len(b)):
            if any(op == 's_branch' and f'block:{bb[0]}' in s for op, s in b[m][2]): latch = m
        if latch is None: continue
        body = b[n:latch + 1]
        if any('loop-header' in x[1] for x in body[1:]): continue
        out.append(body)
    return out

def row(path):
    b = w.parse(path)
    L = loops(b)
    isapp = lambda body: any(op == 'ds_append' for x in body for op, _ in x[2])
    ispf = lambda body: any(op.startswith(('v_mul_hi', 'v_bcnt', 'v_lshrrev_b64', 'v_lshlrev_b64')) for x in body for op, _ in x[2])
    walk = [x for x in L if ispf(x)]
    if not walk: return None
    first = walk[0]
    if isapp(first):
        fa = next(k for k, x in enumerate(first) if any(op == 'ds_append' for op, _ in x[2]))
        rnd = [o for x in first[:fa] + [first[-1]] for o in x[2]]
        stop = next((k for k in range(fa, len(first)) if any(w.fam(op) == 'mem' for op, _ in first[k][2])), len(first) - 1)
        pas = [o for x in first[fa:stop] for o in x[2]]
        d = False
    else:
        rnd = [o for x in first for o in x[2]]
        app = [x for x in L if isapp(x) and not ispf(x)][0]
        stop = next((k for k in range(len(app)) if any(w.fam(op) == 'mem' for op, _ in app[k][2])), len(app) - 1)
        pas = [o for x in app[:stop] + [app[-1]] for o in x[2]]
        d = True
    return w.count(rnd), w.count(pas), d

print(f'{"dump":10} {"round all":>9} {"valu":>5} {"salu":>5} {"lds":>4} {"wait":>5} {"mul32":>5} {"ALU":>4} | {"pass/append":>11} {"ALU":>4}')
for d in sys.argv[1:]:
    fs = glob.glob(os.path.join(d, 'JoinKernel*.aco.txt'))
    if not fs: continue
    r = row(fs[0])
    if not r: print(os.path.basename(d), 'no walk'); continue
    c, p, isd = r
    alu = c['valu'] + c['salu'] + c['lds']
    print(f'{os.path.basename(d):10} {c["all"]:9} {c["valu"]:5} {c["salu"]:5} {c["lds"]:4} {c["wait"]:5} {c["mul32"]:5} {alu:4} | '
          f'{("append " if isd else "pass ") + str(p["all"]):>11} {p["valu"] + p["salu"] + p["lds"]:4}')
