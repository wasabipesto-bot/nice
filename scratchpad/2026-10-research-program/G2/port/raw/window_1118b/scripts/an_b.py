#!/usr/bin/env python3
"""an_b.py DIR: window_1118b tables. Per run: the G2 numbers, and the card's samples at >= 80 % busy (median clock,
power; how many at >= 3055 MHz (97 % of 3150) and >= 270 W; how many at >= 270 W). Pipelined runs: the pipe line
and the queued components. Main fields: secs, survivors/checked, clock/power."""
import sys, re, glob, os, statistics as st
D = sys.argv[1]
def kv(l): return dict(re.findall(r'(\w+)=([-\w.:]+)', l))
def gpu(p):
    sc, pw = [], []
    if not os.path.exists(p): return None
    for l in open(p):
        d = kv(l)
        if 'busy' not in d: continue
        if float(d['busy']) >= 80: sc.append(float(d['sclk'])); pw.append(float(d['pw']))
    if not sc: return (0, 0, 0, 0, 0)
    n97 = sum(1 for s, w in zip(sc, pw) if s >= 3055 and w >= 270)
    n270 = sum(1 for w in pw if w >= 270)
    return (st.median(sc), st.median(pw), len(sc), n97, n270)
def gs(g): return f"{g[0]:.0f} MHz {g[1]:.0f} W ({g[2]} busy, {g[3]} at >=3055 MHz & >=270 W, {g[4]} at >=270 W)" if g else "no samples"
rows = {}
for p in sorted(glob.glob(f'{D}/*.log')):
    n = os.path.basename(p)[:-4]; t = open(p, errors='replace').read(); g = gpu(p[:-4] + '.gpu')
    ok = 'PASS' if 'ALL CHECKS PASSED' in t else ('main' if n.startswith('main') else 'FAIL')
    if n.startswith('main'):
        tp = [kv(l) for l in t.splitlines() if 'JOIN THROUGHPUT' in l]
        if tp: print(f"{n:10s} secs {float(tp[-1]['secs']):8.2f} survivors {tp[-1]['survivors']} checked {tp[-1]['checked']}  {gs(g)}")
        continue
    ms = dict((m, float(v)) for m, v in re.findall(r'MODE (probes off|skip off|full)\s+median ([\d.]+) ms', t))
    prep = re.search(r'PREP \(GPU, \d launches\) median ([\d.]+) ms', t)
    e2e = re.search(r'RESULT end-to-end .*?= ([\d.]+) fs', t)
    pipe = re.search(r'PIPE K (\d+) .*?([\d.]+) ms per super-unit = ([\d.]+) fs', t)
    parts = re.search(r'PIPEPARTS .*?launch: (.*?); counts (\w+)', t)
    s = f"{n:10s} {ok}"
    if prep: s += f" prep {float(prep.group(1)):.3f}"
    for k in ('probes off', 'skip off', 'full'):
        if k in ms: s += f" {k.replace(' ', '')} {ms[k]:.3f}"
    if e2e: s += f" e2e {float(e2e.group(1)):.4f} fs"
    if pipe: s += f" PIPE {pipe.group(2)} ms = {pipe.group(3)} fs"
    if parts: s += f" | parts {parts.group(1)} ({parts.group(2)})"
    print(s + "  " + gs(g))
