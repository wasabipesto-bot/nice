#!/usr/bin/env python3
"""N16 Task A: re-derive the RX 9070 XT join profile from N13's logs with the clock and power of each run.
python3 -I taskA.py ../../N13/raw/demoux   (prints every table of RESULTS.md section A)

Every number printed is from the logs [M] or arithmetic on them [D]. Per profiled run: the busy-sample medians of
sclk/power (busy >= 80), the profile's phase seconds (probe excluded), and three estimates of the join's parts:
  T  = differences of whole-field totals (N13's method; mixes clocks),
  J  = differences of the join phase's own timer (per-phase syncs; each mode at its own clock),
  JS = J with each mode's join time scaled by top(c)/top(mode) (the top phase is the same FD kernel and work in
       every mode, so its time ratio is a clock proxy; rough: bucket does not scale the same way).
"""
import sys, re, glob, os, statistics as st
D = sys.argv[1]
def kv(l): return dict(re.findall(r'(\w+)=([-\w.:]+)', l))
def gpu(n):
    sc, pw, bz = [], [], []
    for l in open(f'{D}/{n}.gpu'):
        d = kv(l)
        try:
            b = int(d['busy']); bz.append(b)
            if b >= 80:
                sc.append(int(re.sub(r'\D', '', d['sclk'].split(':')[-1]))); pw.append(int(d['pw']) / 1e6)
        except Exception: pass
    return (st.median(sc) if sc else 0, st.median(pw) if pw else 0, st.median(bz) if bz else 0, len(bz))
K = ['upload', 'inputs', 'top', 'bucket', 'join', 'check', 'read', 'unattributed']
def prof(n):
    out = []
    for l in open(f'{D}/{n}.log', errors='replace'):
        if 'GPU_PROFILE base=' in l:
            g = kv(l[l.index('GPU_PROFILE'):])
            if g['size'] == '100000000000000': continue  # the 1e14 warm-up field
            out.append(g)
    return out
modes = ['c', 'c2', 'p', 'b', 'a', 'z']
for fld in ['b62', 'b60']:
    print(f'== {fld} (profiled runs p_<mode>_{fld}; b60 = sum of its two fields)')
    R = {}
    for m in modes:
        n = f'p_{m}_{fld}'
        if not os.path.exists(f'{D}/{n}.log'): continue
        gs = prof(n)
        tot = {k: sum(float(g[k]) for g in gs) for k in K + ['probe', 'top_fd']}
        tot['total'] = sum(tot[k] for k in K)
        tot['pairs'] = sum(int(g['pairs']) for g in gs)
        sc, pw, bz, ns = gpu(n)
        R[m] = (tot, sc, pw, bz)
        print(f"  {m:3s} sclk={sc:5.0f} MHz W={pw:4.0f} busy={bz:3.0f}% ({ns} samples) total={tot['total']:6.2f} top={tot['top']:6.2f} "
              f"bucket={tot['bucket']:5.2f} join={tot['join']:6.2f} check={tot['check']:6.2f} upload={tot['upload']:5.2f} probe={tot['probe']:5.2f}")
    c = R['c'][0]; tc = c['top']; pairs = c['pairs']; F = c['total']
    def est(name, f):
        z, a, b, p = (f(R[m][0], m) for m in ['z', 'a', 'b', 'p'])
        cj = f(c, 'c')
        zb = z if name[0] != 'T' else c['join'] - (p - z)  # N13: base = join(c) - (AND + walk + prefilter from totals)
        parts = {'base (z)': zb, 'AND (a-z)': a - z, 'walk (b-a)': b - a, 'prefilter (p-b)': p - b}
        parts['stage+rest (c-p)'] = cj - p  # T: includes the check kernel's survivor-dependent time
        print(f'  [{name}] ' + '  '.join(f"{k}={v:6.2f}s {100*v/F:5.1f}% {1e12*v/pairs:5.2f}ps/pair" for k, v in parts.items()))
    # T: totals (check removed from c-p so that it is the join's stage only, as N13 did: c - p includes check)
    est('T totals (N13)', lambda t, m: t['total'])
    est('J join timer  ', lambda t, m: t['join'])
    est('JS join x top(c)/top(m)', lambda t, m: t['join'] * tc / t['top'])
    print(f"  field (mode c, probe excluded) = {F:.2f} s; pairs = {pairs:.4e}; check {c['check']:.2f} s = {100*c['check']/F:.1f} %; "
          f"top {tc:.2f} s = {100*tc/F:.1f} %; join(c) {c['join']:.2f} s = {100*c['join']/F:.1f} %")
    # clock proxy check: top(m)/top(c) against sclk(c)/sclk(m)
    for m in modes[1:]:
        if m in R:
            print(f"    {m}: top ratio {R[m][0]['top']/tc:5.2f}  sclk ratio c/m {R['c'][1]/R[m][1]:5.2f}  bucket ratio {R[m][0]['bucket']/c['bucket']:5.2f}")
    print()
print('== Unprofiled runs (s_*, a_*): busy-sample medians (operating point check)')
rows = []
for p in sorted(glob.glob(f'{D}/[sa]_*.gpu')):
    n = os.path.basename(p)[:-4]
    sc, pw, bz, ns = gpu(n)
    rows.append((n, sc, pw, bz))
scs = [r[1] for r in rows]; pws = [r[2] for r in rows]
print(f'  {len(rows)} runs: sclk median {st.median(scs):.0f} MHz (min {min(scs):.0f}, max {max(scs):.0f}); W median {st.median(pws):.0f} (min {min(pws):.0f}, max {max(pws):.0f})')
for r in rows:
    if r[1] < 3000 or r[2] < 280:
        print(f'  off the operating point: {r}')
