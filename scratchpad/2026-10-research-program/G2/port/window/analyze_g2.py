#!/usr/bin/env python3
"""analyze_g2.py OUTDIR [REF_MHZ REF_W] [--size 1e17]: the G2 window's table and verdict.
- exactness runs x_*: ALL CHECKS PASSED or not;
- G2 timing runs t_<variant>_r<round> (with the GPU preparation) and o_<variant>_r<round> (no survivor records):
  prep / probes-off / skip-off / full medians, end-to-end fs per admissible n, clock / power medians over samples at
  >= 80 % busy, OFF-POINT if the clock is below 97 % or the power below 90 % of REF (RX 9070 XT: 3150 300);
- main fields main_f<i>: secs, survivors, checked, clock / power, OFF-POINT; the base mean in fs per admissible n
  (ten fields of SIZE, admissible = 8/63 of n, empties counted);
- the verdict: ratio = main base mean / (G2 end-to-end + tops and survivor checks), the latter 0.115 fs on the
  RTX 3080 (G2/BENCH.md) scaled by this card's main base mean over the 3080's same-session 6.347 fs; stop below x4.0."""
import sys, re, glob, os, statistics as st
a = [x for x in sys.argv[1:] if not x.startswith('--')]
D = a[0]; REF = (float(a[1]), float(a[2])) if len(a) > 2 else (3150.0, 300.0)
SIZE = float(sys.argv[sys.argv.index('--size') + 1]) if '--size' in sys.argv else 1e17
ADM_FIELD = SIZE * 8 / 63
def kv(l): return dict(re.findall(r'(\w+)=([-\w.:]+)', l))
def gpu(p):
    sc, pw = [], []
    if not os.path.exists(p): return (0, 0, 0)
    n = 0
    for l in open(p):
        d = kv(l)
        if 'busy' not in d: continue
        n += 1
        if float(d['busy']) >= 80:
            sc.append(float(d['sclk'])); pw.append(float(d['pw']))
    return (st.median(sc) if sc else 0, st.median(pw) if pw else 0, len(sc))
def off(g): return g[2] > 0 and (g[0] < 0.97 * REF[0] or g[1] < 0.90 * REF[1])
print(f"== exactness")
for p in sorted(glob.glob(f'{D}/x_*.log')):
    t = open(p, errors='replace').read()
    print(f"  {os.path.basename(p)[:-4]:10s} {'PASS' if 'ALL CHECKS PASSED' in t else 'FAIL'}  "
          + ' '.join(re.findall(r'(?:VERIFY \w[\w ]*?: \d+ survivors|order and class segments \w+)', t))[:150])
print("== G2 timing (ms medians; end-to-end fs per admissible n)")
G = {}
for p in sorted(glob.glob(f'{D}/[to]_*_r*.log')):
    name = os.path.basename(p)[:-4]; kind, var, r = name.split('_')
    t = open(p, errors='replace').read()
    ms = dict((m, float(v)) for m, v in re.findall(r'MODE (probes off|skip off|full)\s+median ([\d.]+) ms', t))
    prep = re.search(r'PREP \(GPU, 4 launches\) median ([\d.]+) ms', t)
    e2e = re.search(r'RESULT end-to-end .*?= ([\d.]+) fs', t)
    cok = t.count('EQUAL to the CPU reference'); g = gpu(p[:-4] + '.gpu')
    G[(kind, var, r)] = dict(ms=ms, prep=float(prep.group(1)) if prep else None, e2e=float(e2e.group(1)) if e2e else None)
    print(f"  {name:10s} prep {G[(kind,var,r)]['prep'] or 0:7.3f} off {ms.get('probes off',0):7.3f} skipoff {ms.get('skip off',0):7.3f} "
          f"full {ms.get('full',0):7.3f}  e2e {G[(kind,var,r)]['e2e'] or 0:.4f} fs  counts-equal {cok}/3  "
          f"{g[0]:.0f} MHz {g[1]:.0f} W ({g[2]} busy samples){' OFF-POINT' if off(g) else ''}")
best = {}
for var in sorted({k[1] for k in G}):
    v = [G[k]['e2e'] for k in G if k[0] == 't' and k[1] == var and G[k]['e2e']]
    if v: best[var] = st.median(v); print(f"  variant {var}: end-to-end median {best[var]:.4f} fs over {len(v)} rounds (spread {min(v):.4f}-{max(v):.4f})")
print("== main (base 64, one field per process)")
secs, rows = 0.0, 0
for i in range(1, 11):
    p = f'{D}/main_f{i}.log'
    if not os.path.exists(p): print(f"  main_f{i}: missing"); continue
    tp = [kv(l) for l in open(p, errors='replace') if 'JOIN THROUGHPUT' in l]
    if not tp: print(f"  main_f{i}: no result"); continue
    g = gpu(p[:-4] + '.gpu'); s = float(tp[-1]['secs']); secs += s; rows += 1
    print(f"  main_f{i}: {s:8.2f} s survivors {tp[-1]['survivors']} checked {tp[-1]['checked']}  {g[0]:.0f} MHz {g[1]:.0f} W{' OFF-POINT' if off(g) else ''}")
if rows == 10 and best:
    mean = secs / (10 * ADM_FIELD) * 1e15
    adds = 0.115 * mean / 6.347
    print(f"== main base mean {mean:.3f} fs per admissible n ({secs:.1f} s for 10 fields); tops + survivor checks for G2 {adds:.3f} fs")
    for var, e in sorted(best.items()):
        r = mean / (e + adds)
        print(f"  variant {var}: G2 {e:.4f} + {adds:.3f} = {e + adds:.4f} fs -> ratio x{r:.2f}  {'>= x4.0: continue' if r >= 4.0 else '< x4.0: STOP'}")
else:
    print(f"== incomplete: {rows}/10 main fields, {len(best)} G2 variants")
if SIZE < 1e17: print("(dry run: field size below 1e17; the numbers mean nothing as timings)")
