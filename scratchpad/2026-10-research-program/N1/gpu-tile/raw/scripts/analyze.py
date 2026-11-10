#!/usr/bin/env python3
"""analyze.py LOGDIR: calibration (cal_*) and tile-harness (tile logs) tables for N1/gpu-tile RESULTS.md."""
import re, sys, os, glob, statistics as st
D = sys.argv[1]
def kv(s):
    return {m.group(1): m.group(2) for m in re.finditer(r'(\w+)=([^ |]+)', s)}
def med(x): return st.median(x) if x else float('nan')
def smi_clock(p):
    v = []
    try:
        for l in open(p):
            f = [x.strip() for x in l.split(',')]
            if len(f) >= 7 and f[6].endswith('%') and int(f[6].rstrip(' %')) >= 90:
                v.append(int(f[1].split()[0]))
    except Exception: pass
    return (sum(v) / len(v), len(v)) if v else (float('nan'), 0)
# ---- calibration
cal = {}
for p in sorted(glob.glob(f'{D}/cal_*_r*.log')):
    m = re.match(r'cal_(\w)_r(\d)\.log', os.path.basename(p)); mode, r = m.group(1), int(m.group(2))
    txt = open(p).read()
    prof = [l for l in txt.splitlines() if 'GPU_PROFILE' in l]
    thr = [l for l in txt.splitlines() if 'JOIN THROUGHPUT' in l]
    if not thr: continue
    t = kv(thr[-1][thr[-1].index('JOIN THROUGHPUT'):])
    d = {'per_field': float(t['per_field']), 'device': float(t['device'].rstrip('s')), 'surv': int(t['survivors']), 'checked': int(t['checked'])}
    if prof:
        pl = prof[-1][prof[-1].index('GPU_PROFILE'):]
        d.update({k: float(v) for k, v in kv(pl).items() if re.match(r'^[0-9.e+-]+$', v)})
    jit = open(p.replace('.log', '_jit.txt')).read() if os.path.exists(p.replace('.log', '_jit.txt')) else ''
    regs = re.findall(r'join_kernel.*?regs=(\d+).*?local=(\d+)', jit)
    d['regs'] = ','.join(f'{a}' + (f'+{b}B' if b != '0' else '') for a, b in regs)
    d['mhz'], d['nclk'] = smi_clock(p.replace('.log', '.smi'))
    cal.setdefault(mode, {})[r] = d
if cal:
    print('== calibration: b62 1e17 field at 7226266762397899821056 (E = 14f87cd profiled modes; T = c0c357a unprofiled)')
    for mode in sorted(cal):
        rs = cal[mode]
        js = [rs[r].get('join', float('nan')) for r in sorted(rs)]
        print(f"{mode}: rounds {sorted(rs)} per_field {[round(rs[r]['per_field'],2) for r in sorted(rs)]} device {[round(rs[r]['device'],2) for r in sorted(rs)]} "
              f"join {[round(j,2) for j in js]} MHz {[rs[r]['mhz'] if rs[r]['mhz']!=rs[r]['mhz'] else round(rs[r]['mhz']) for r in sorted(rs)]} regs {[rs[r]['regs'] for r in sorted(rs)]} survivors {sorted(set(rs[r]['surv'] for r in rs))} checked {sorted(set(rs[r]['checked'] for r in rs))}")
    def mj(m, k='join'): return med([cal[m][r][k] for r in cal.get(m, {}) if k in cal[m][r]])
    c0 = next(iter(cal['c'].values())) if 'c' in cal else None
    if c0:
        pairs, padded, surv = c0['pairs'], c0['padded_pairs'], c0['survivors']
        print(f"counts (mode c): pairs {pairs:.4e} padded {padded:.4e} (lanes {100*pairs/padded:.1f} %) AND survivors {surv:.4e} (pass {100*surv/pairs:.2f} %) checked {c0['checked']:.4e} tops {c0['tops']:.4e} listed {c0['listed']:.4e} buckets {c0['buckets']:.4e} slices {c0['slices']:.0f}")
        print(f"   per bucket: tops-in-pairs {pairs/c0['listed']:.0f}, entries {c0['listed']/c0['buckets']:.1f}, pairs {pairs/c0['buckets']:.0f}")
        fld = med([cal['c'][r]['device'] - cal['c'][r].get('probe', 0) for r in cal['c']])
        J = {m: mj(m) for m in 'cazbp' if m in cal}
        print('join s/field (median of rounds):', {m: round(v, 3) for m, v in J.items()})
        base = J.get('z'); dense = J.get('a'); full = J.get('c')
        if base and dense and full:
            andp = dense - base; survp = full - dense
            print(f"dense (a) {dense:.3f} s = {dense/pairs*1e12:.4f} ps/pair [base (z) {base:.3f} s = {base/pairs*1e12:.4f} ps/pair; AND (a-z) {andp:.3f} s = {andp/pairs*1e12:.4f} ps/pair]; "
                  f"survivor path (c-a) {survp:.3f} s = {survp/surv*1e12:.2f} ps/survivor")
            if 'b' in J and 'p' in J:
                print(f"   walk rounds (b-a) {J['b']-dense:.3f} s = {(J['b']-dense)/surv*1e12:.2f} ps/surv; prefilter (p-b) {J['p']-J['b']:.3f} s = {(J['p']-J['b'])/surv*1e12:.2f} ps/surv; stage (c-p) {full-J['p']:.3f} s")
            parts = {k: med([cal['c'][r][k] for r in cal['c']]) for k in ('top', 'bucket', 'join', 'check', 'upload', 'inputs', 'read', 'unattributed') if k in c0}
            tot = sum(parts.values())
            print('profiled field parts (mode c, median):', {k: f'{v:.2f} s ({100*v/tot:.1f} %)' for k, v in parts.items()}, f'sum {tot:.2f}')
        if 'T' in cal:
            print(f"T (c0c357a unprofiled) per_field {med([cal['T'][r]['per_field'] for r in cal['T']]):.3f} s, device {med([cal['T'][r]['device'] for r in cal['T']]):.3f} s")
# ---- tile harness
rows = {}
for p in sorted(glob.glob(f'{D}/*.log')):
    name = os.path.basename(p)[:-4]
    lines = [l for l in open(p) if l.startswith('N1 ') or 'N1 round=' in l]
    if not lines: continue
    pools = re.search(r'N1POOLS (.*)', open(p).read())
    for l in lines:
        l = l[l.index('N1 round='):]
        d = kv(l)
        key = (name, d['cfg'])
        rows.setdefault(key, []).append(d)
if rows:
    print('\n== tile harness: per process and config, ps per pair (mean of reps per round; median [min-max] over rounds)')
    for (proc, cfg), ds in sorted(rows.items()):
        ps = [float(d['ps_pair_mean']) for d in ds]; pss = [float(d['ps_surv_mean']) for d in ds]
        print(f"{proc:28s} {cfg:34s} n={len(ps)} ps/pair {med(ps):.4f} [{min(ps):.4f}-{max(ps):.4f}] pass {float(ds[0]['pass'])*100:.3f} % npf {ds[0]['npf']}")
