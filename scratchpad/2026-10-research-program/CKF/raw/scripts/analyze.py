#!/usr/bin/env python3
"""analyze.py LOGDIR [PTXJIT_OUT]: the speed A/B's table. Per run (NAME = field_bin_rROUND): device s/field
(`device=`, mean run_field device seconds), wall s/field (`per_field=`), survivors/checked, mean SM MHz and power over
the samples at >= 90 % utilisation, start temperature, and (if given) the check and join kernels' registers/spills from
ptxjit.py. Prints per-run lines, then per field: medians per binary, per-round ratios against B and M."""
import re, sys, glob, os, statistics as st
d = sys.argv[1]
regs = {}
if len(sys.argv) > 2:
    for l in open(sys.argv[2]):
        m = re.match(r'/ptx/(\S+)/ #\d+ (\S+).* regs=(\d+) .*variant=(\S+)', l)
        if m:
            run, k, r, v = m.groups()
            for kn in ('join_kernel', 'check_kernel'):
                if k.startswith(kn):
                    regs.setdefault(run, {}).setdefault(kn, set()).add(f'{r}{"S" if v == "SPILL" else ""}')
runs = {}
for f in sorted(glob.glob(f'{d}/b6*_r*.log')):
    name = os.path.basename(f)[:-4]
    fld, b, r = name.split('_')
    t = open(f).read()
    m = re.search(r'JOIN THROUGHPUT .*?secs=([\d.]+) per_field=([\d.]+).*?device=([\d.]+)s.*?survivors=(\d+) checked=(\d+) found=(\d+)', t)
    if not m:
        print('NO RESULT', name); continue
    secs, pf, dev, surv, chk, found = m.groups()
    mhz, pw, temp0 = [], [], None
    for l in open(f[:-4] + '.smi'):
        p = [x.strip() for x in l.split(',')]
        try:
            u = float(p[6].split()[0]); c = float(p[1].split()[0]); w = float(p[3].split()[0])
            if temp0 is None: temp0 = p[5]
            if u >= 90: mhz.append(c); pw.append(w)
        except Exception:
            pass
    rg = regs.get(name, {})
    runs[name] = dict(f=fld, b=b, r=int(r[1:]), dev=float(dev), pf=float(pf), surv=int(surv), chk=int(chk), found=int(found),
                      mhz=st.mean(mhz) if mhz else 0, pw=st.median(pw) if pw else 0, t0=temp0,
                      jr='/'.join(sorted(rg.get('join_kernel', []))), cr='/'.join(sorted(rg.get('check_kernel', []))))
for n, x in sorted(runs.items(), key=lambda kv: (kv[1]['f'], kv[1]['r'], kv[0])):
    print(f"{n:14s} device={x['dev']:8.3f} wall={x['pf']:8.3f} MHz={x['mhz']:6.0f} W={x['pw']:5.1f} T0={x['t0']} "
          f"join_regs={x['jr'] or '?'} check_regs={x['cr'] or '?'} surv={x['surv']} checked={x['chk']} found={x['found']}")
print()
for fld in sorted({x['f'] for x in runs.values()}):
    by = {}
    for x in runs.values():
        if x['f'] == fld: by.setdefault(x['b'], {})[x['r']] = x
    counts = {(x['surv'], x['chk'], x['found']) for v in by.values() for x in v.values()}
    print(f"{fld}: counts {'IDENTICAL ' + str(counts.pop()) if len(counts) == 1 else 'DIFFER ' + str(counts)}")
    for b, v in sorted(by.items()):
        ds = [v[r]['dev'] for r in sorted(v)]
        print(f"  {b:3s} device median {st.median(ds):8.3f} rounds {', '.join(f'{z:.3f}' for z in ds)}  MHz {st.mean(v[r]['mhz'] for r in v):.0f}")
    for ref in ('B', 'M'):
        if ref in by and 'F3' in by:
            rs = [by[ref][r]['dev'] / by['F3'][r]['dev'] for r in sorted(by['F3']) if r in by[ref]]
            cy = [by[ref][r]['dev'] * by[ref][r]['mhz'] / (by['F3'][r]['dev'] * by['F3'][r]['mhz']) for r in sorted(by['F3']) if r in by[ref] and by['F3'][r]['mhz']]
            med = st.median([by[ref][r]['dev'] for r in by[ref]]) / st.median([by['F3'][r]['dev'] for r in by['F3']])
            print(f"  {ref}/F3 (>1 = fix faster): medians x{med:.4f}; per round {', '.join(f'{z:.4f}' for z in rs)}; cycles {', '.join(f'{z:.4f}' for z in cy)}")
