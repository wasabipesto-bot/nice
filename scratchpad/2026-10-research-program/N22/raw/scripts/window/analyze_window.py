#!/usr/bin/env python3
"""analyze_window.py OUTDIR [REF_MHZ REF_W]: the N21 window's table. Runs $OUT/m<N21>_<tag>_r<round>.log with a .gpu
sample file each. Per run: wall secs, counts, medians of clock / power / busy over samples at >= 80 % busy, and OFF-POINT
when the clock is below 97 % or the power below 90 % of REF (default: the median of the tag's mode-0 runs; on the RX
9070 XT pass 3150 300). Per tag and mode: base/mode per round (base = the same round's mode-0 run) and the median."""
import sys, re, glob, os, statistics as st
D = sys.argv[1]
REF = (float(sys.argv[2]), float(sys.argv[3])) if len(sys.argv) > 3 else None
def kv(l): return dict(re.findall(r'(\w+)=([-\w.:]+)', l))
def gpu(p):
    sc, pw, bz = [], [], []
    if not os.path.exists(p): return (0, 0, 0)
    for l in open(p):
        d = kv(l)
        try: b = float(d['busy'])
        except Exception: continue
        bz.append(b)
        if b >= 80:
            try: sc.append(float(d['sclk'])); pw.append(float(d['pw']))
            except Exception: pass
    return (st.median(sc) if sc else 0, st.median(pw) if pw else 0, st.median(bz) if bz else 0)
R = {}
for p in sorted(glob.glob(f'{D}/m*_b*_r[0-9].log')):
    m = re.match(r'm(\d+)_(b\d\d)_r(\d)$', os.path.basename(p)[:-4])
    if not m: continue
    mode, tag, r = int(m.group(1)), m.group(2), int(m.group(3))
    t = open(p, errors='replace').read()
    tp = [kv(l) for l in t.splitlines() if 'JOIN THROUGHPUT' in l]
    if not tp: print(f'  {os.path.basename(p)}: no result'); continue
    g = gpu(p[:-4] + '.gpu')
    R[(tag, mode, r)] = dict(secs=float(tp[-1]['secs']), cnt=(tp[-1]['survivors'], tp[-1]['checked']), mhz=g[0], w=g[1], busy=g[2])
for tag in sorted({k[0] for k in R}):
    K = [k for k in R if k[0] == tag]
    modes = sorted({k[1] for k in K}); rounds = sorted({k[2] for k in K})
    base = [R[k] for k in K if k[1] == 0]
    ref = REF or ((st.median(x['mhz'] for x in base), st.median(x['w'] for x in base)) if base else (0, 0))
    cnts = {R[k]['cnt'] for k in K}
    print(f'== {tag}: counts {"identical" if len(cnts) == 1 else "DIFFER " + str(sorted(cnts))}; reference {ref[0]:.0f} MHz {ref[1]:.0f} W')
    for k in sorted(K, key=lambda k: (k[2], k[1])):
        x = R[k]; off = x['mhz'] < 0.97 * ref[0] or x['w'] < 0.90 * ref[1]
        print(f'   r{k[2]} m{k[1]:<3} {x["secs"]:8.2f} s  {x["mhz"]:5.0f} MHz {x["w"]:4.0f} W busy {x["busy"]:3.0f} %  {"OFF-POINT" if off else "ok"}')
    for m in modes:
        if m == 0: continue
        q = [R[(tag, 0, r)]['secs'] / R[(tag, m, r)]['secs'] for r in rounds if (tag, 0, r) in R and (tag, m, r) in R]
        if q: print(f'   mode {m}: base/mode ' + ', '.join(f'{v:.3f}' for v in q) + f'  -> median x{st.median(q):.3f}')
