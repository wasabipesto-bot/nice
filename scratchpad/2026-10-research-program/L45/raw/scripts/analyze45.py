#!/usr/bin/env python3
"""L45 analysis. python3 analyze45.py DIR (copy of the box's /root/l45/logs). Prints every table of RESULTS.md.
Runs: m_<mode>_<field>_r<round> (chain_main.sh), sn_<S|N>_<field>_r<round> (chain_sn.sh).
Join variants per process from DIR/*jit*.txt (ptxjit.py over each process's PTX cache; the field's join kernel is the
last join entry compiled)."""
import re, sys, glob, os, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else 'box'
med = st.median
KEYS = ['setup', 'device_wall', 'upload', 'inputs', 'top', 'bucket', 'join', 'check', 'read', 'probe', 'unattributed',
        'top_fd', 'top_clip', 'top_scan', 'top_fill', 'clip_launches', 'spilled', 'batches', 'slots', 'null',
        'pairs', 'padded_pairs', 'survivors', 'checked', 'tops', 'listed', 'size', 'partitions']
EXACT = {'e17_b62': (1020844021499, 62584252554), 'e16_b60': (460847952346, 30871838404)}  # per run (1 / 2 fields)
FIELDS = [('e17_b62', 'b62 1e17 (1 field)'), ('e16_b60', 'b60 1e16 (per field, 2 fields)')]
def prof(path):
    out = []
    for line in open(path, errors='replace'):
        if 'GPU_PROFILE' not in line: continue
        d = {}
        for k in KEYS:
            m = re.search(r'(?<![\w])' + k + r'=([0-9.e+]+)\b', line)
            if m: d[k] = float(m.group(1))
        if d.get('size', 0) > 1e14: out.append(d)
    return out
def thr(path):
    t = open(path, errors='replace').read()
    m = re.findall(r'JOIN THROUGHPUT.*?fields=(\d+).*?per_field=([0-9.]+).*?device=([0-9.]+)s.*?survivors=(\d+) checked=(\d+) found=(\d+)', t)
    if not m: return None
    f, pf, dev, s, c, fo = m[-1]
    # device= is the mean device seconds per field; survivors / checked are the run's totals
    return dict(fields=int(f), per_field=float(pf), device=float(dev), survivors=int(s), checked=int(c), found=int(fo))
def smi(path):
    mhz, w = [], []
    if not os.path.exists(path): return None, None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) >= 8 and float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
        except (ValueError, IndexError): pass
    return (st.mean(mhz) if mhz else None), (st.mean(w) if w else None)
VAR = {}
for jf in glob.glob(f'{D}/*jit*.txt'):
    for line in open(jf):
        m = re.search(r'/ptx/([^/]+)/ #(\d+) (.*?) ptx=(\w+) regs=(\d+) local=(\d+) sass=(\d+) stl=(\d+) ldl=(\d+)', line)
        if m and 'join' in m.group(3):
            VAR.setdefault(m.group(1), {})[int(m.group(2))] = dict(ptx=m.group(4), regs=int(m.group(5)), local=int(m.group(6)),
                                                                  sass=int(m.group(7)), stl=int(m.group(8)), ldl=int(m.group(9)))
def var(name):
    v = VAR.get(name)
    if not v: return None
    return v[max(v)]
def vstr(v):
    return '-' if not v else (f'{v["regs"]}r' + (f'+{v["stl"]}STL' if v['stl'] else ''))
def load(prefix):
    runs = []
    for f in sorted(glob.glob(f'{D}/{prefix}_r*.log')):
        name = os.path.basename(f)[:-4]
        p = prof(f); t = thr(f); mhz, w = smi(f[:-4] + '.smi')
        if not t: continue
        r = {'name': name, 'mhz': mhz, 'w': w, 'var': var(name), 'thr': t}
        if p:
            n = len(p)
            r.update({k: sum(x.get(k, 0) for x in p) / n for k in KEYS})
            r['field'] = r['device_wall'] - r['probe']
        r['dev'] = t['device']
        runs.append(r)
    return runs
def counts_ok(r, fld):
    s, c = EXACT[fld]; t = r['thr']
    return t['survivors'] == s and t['checked'] == c
def fmt(xs, d=2): return ', '.join(f'{x:.{d}f}' for x in xs)
def spread(xs): return 100 * (max(xs) - min(xs)) / med(xs) if len(xs) > 1 else 0
MODES = [('c', 'full (#246)'), ('a', 'AND only'), ('b', 'walk without walk_pf_lean, no stage'), ('p', 'walk + walk_pf_lean, no stage'),
         ('z', 'no AND'), ('d', 'full, per-top AND (TMIN 2^30)'), ('s7', 'stage checked every 4 chunks'),
         ('s8', 'stage checked every 8 chunks'), ('s15', 'stage checked once per top batch'), ('u', 'full, unprofiled')]
for fld, label in FIELDS:
    R = {t: load(f'm_{t}_{fld}') for t, _ in MODES}
    print(f'\n## {label}\n')
    print('| mode | join s/field (rounds) | spread | field s (profiled, excl. probe) | unprofiled device s | SM MHz | W | join variant per round | counts |')
    print('|---|---|---|---|---|---|---|---|---|')
    for t, nm in MODES:
        rs = R[t]
        if not rs: continue
        exact = all(counts_ok(r, fld) for r in rs)
        cnt = 'exact' if exact else f'{rs[0]["thr"]["survivors"]:,} / {rs[0]["thr"]["checked"]:,}' + ('' if len({(r['thr']['survivors'], r['thr']['checked']) for r in rs}) == 1 else ' (vary)')
        if 'join' in rs[0]:
            j = [r['join'] for r in rs]; fl = [r['field'] for r in rs]
            print(f'| {t}: {nm} | {med(j):.2f} ({fmt(j)}) | {spread(j):.1f} % | {med(fl):.2f} ({fmt(fl)}) | | {fmt([r["mhz"] or 0 for r in rs], 0)} | {fmt([r["w"] or 0 for r in rs], 0)} | {", ".join(vstr(r["var"]) for r in rs)} | {cnt} |')
        else:
            dv = [r['dev'] for r in rs]
            print(f'| {t}: {nm} | | | | {med(dv):.2f} ({fmt(dv)}) | {fmt([r["mhz"] or 0 for r in rs], 0)} | {fmt([r["w"] or 0 for r in rs], 0)} | {", ".join(vstr(r["var"]) for r in rs)} | {cnt} |')
    c = R['c']
    if not c or 'join' not in c[0]: continue
    # Part A: top split
    fieldp = med([r['field'] for r in c]); unp = med([r['dev'] for r in R['u']]) if R['u'] else float('nan')
    mh = med([r['mhz'] for r in c if r['mhz']])
    print(f'\n### Part A, {label}: phases of mode c (3 profiled runs; medians; % of the profiled field excl. probe; '
          f'% of the unprofiled median {unp if unp else float("nan"):.2f} s)\n')
    print('| phase | s/field (rounds) | % of profiled field | % of unprofiled field | G-cycles at the run clock |')
    print('|---|---|---|---|---|')
    rows = [('top: FD kernel (`top_fd_kernel`)', 'top_fd'), ('top: clipped-block launch (`top_kernel`)', 'top_clip'),
            ('top: `top_scan_kernel`', 'top_scan'), ('top: `top_fill_kernel`', 'top_fill'), ('**top total**', 'top'),
            ('bucket', 'bucket'), ('join', 'join'), ('check', 'check'), ('upload', 'upload'), ('inputs', 'inputs'),
            ('read', 'read'), ('null mark (one empty sync per batch)', 'null'), ('unattributed', 'unattributed'), ('probe (excluded)', 'probe')]
    for nm, k in rows:
        xs = [r[k] for r in c]
        cyc = med([r[k] * r['mhz'] / 1000 for r in c if r['mhz']])
        print(f'| {nm} | {med(xs):.3f} ({fmt(xs, 3)}) | {100 * med(xs) / fieldp:.2f} % | {100 * med(xs) / unp:.2f} % | {cyc:.2f} |')
    ss = [r['top_scan'] + r['top_fill'] for r in c]; ssc = [r['top_scan'] + r['top_fill'] + r['top_clip'] for r in c]
    print(f'| **scan + fill** | {med(ss):.3f} ({fmt(ss, 3)}) | **{100 * med(ss) / fieldp:.2f} %** | **{100 * med(ss) / unp:.2f} %** | |')
    print(f'| scan + fill + clipped | {med(ssc):.3f} ({fmt(ssc, 3)}) | {100 * med(ssc) / fieldp:.2f} % | {100 * med(ssc) / unp:.2f} % | |')
    print(f'| field (profiled device excl. probe) | {fieldp:.3f} ({fmt([r["field"] for r in c], 3)}) | | | |')
    print(f'\nclip launches/field {c[0]["clip_launches"]:.0f}, batches/field {c[0]["batches"]:.0f}, slots {c[0]["slots"]:.0f}, kept tops/field {c[0]["tops"]:.4g}; '
          f'scan+fill per kept top {1e9 * med(ss) / c[0]["tops"]:.3f} ns; profiled vs unprofiled: {fieldp:.2f} + probe {med([r["probe"] for r in c]):.2f} vs {unp:.2f} s '
          f'(clock c {mh:.0f} / u {med([r["mhz"] for r in R["u"] if r["mhz"]]) if R["u"] else 0:.0f} MHz); '
          f'per batch: scan {1e6 * med([r["top_scan"] for r in c]) / c[0]["batches"]:.0f} us, fill {1e6 * med([r["top_fill"] for r in c]) / c[0]["batches"]:.0f} us, '
          f'null mark {1e6 * med([r.get("null", 0) for r in c]) / c[0]["batches"]:.1f} us, clipped {1e6 * med([r["top_clip"] for r in c]) / max(c[0]["clip_launches"], 1):.0f} us per launch')
    # Part B: ablation split
    if all(R[t] and 'join' in R[t][0] for t in 'cabpz'):
        J = {t: med([r['join'] for r in R[t]]) for t in ['c', 'a', 'b', 'p', 'z', 'd', 's7', 's8', 's15'] if R[t]}
        Jc = {t: med([r['join'] * r['mhz'] / 1000 for r in R[t] if r['mhz']]) for t in J}
        parts = [('base (no AND: work items, top batch + transposed copy, wave loads + prefilter terms, per-chunk check)', 'z', None),
                 ('AND (a − z)', 'a', 'z'), ('walk rounds (b − a)', 'b', 'a'), ('prefilter `walk_pf_lean` (p − b)', 'p', 'b'),
                 ('stage + flush (c − p)', 'c', 'p')]
        print(f'\n### Part B, {label}: the lean join by ablation (marginals z → a → b → p → c; join {J["c"]:.2f} s/field, field {fieldp:.2f} s)\n')
        print('| part | s/field | % of join | % of field | G-cycles | % of join in cycles | per round (s) |')
        print('|---|---|---|---|---|---|---|')
        for nm, t1, t0 in parts:
            v = J[t1] - (J[t0] if t0 else 0); vc = Jc[t1] - (Jc[t0] if t0 else 0)
            pr = [r1['join'] - (r0['join'] if t0 else 0) for r1, r0 in zip(R[t1], R[t0] if t0 else R[t1])]
            print(f'| {nm} | {v:.2f} | {100 * v / J["c"]:.1f} % | {100 * v / fieldp:.1f} % | {vc:.2f} | {100 * vc / Jc["c"]:.1f} % | {fmt(pr)} |')
        print(f'| **join (c)** | {J["c"]:.2f} | 100 % | {100 * J["c"] / fieldp:.1f} % | {Jc["c"]:.2f} | | |')
        if 'd' in J:
            print(f'\nper-top AND (d, TMIN 2^30): join {J["d"]:.2f} vs {J["c"]:.2f} s (+{J["d"] - J["c"]:.2f}, x{J["d"] / J["c"]:.3f} join; '
                  f'field {med([r["field"] for r in R["d"]]):.2f} vs {fieldp:.2f}, x{med([r["field"] for r in R["d"]]) / fieldp:.3f})')
        print('\n### stage cadence (profiled join s/field; ratio = c / mode, per round)\n')
        print('| mode | join s/field (rounds) | vs c | per round | G-cycles vs c | field s | vs c |')
        print('|---|---|---|---|---|---|---|')
        for t in ['s7', 's8', 's15']:
            if t not in J: continue
            pr = [r0['join'] / r1['join'] for r1, r0 in zip(R[t], R['c'])]
            fl = med([r['field'] for r in R[t]])
            print(f'| {t} | {J[t]:.2f} ({fmt([r["join"] for r in R[t]])}) | x{J["c"] / J[t]:.4f} | {fmt(pr, 4)} | x{Jc["c"] / Jc[t]:.4f} | {fl:.2f} | x{fieldp / fl:.4f} |')
# register variants, pinned (chain_sn.sh): N runtime compile, M nvcc 5 cubes (no spill), S nvcc with spills
for fld, label in FIELDS:
    V = {v: load(f'sn_{v}_{fld}') for v in 'NMS'}
    if not any(V.values()): continue
    print(f'\n## join-kernel register variants, {label} (every kernel image pinned; profile on)\n')
    print('| variant | join kernel | join s/field (rounds) | spread | field s (rounds) | SM MHz | counts |')
    print('|---|---|---|---|---|---|---|')
    names = {'N': 'N: runtime compile (NVRTC -> driver JIT)', 'M': 'M: nvcc, 5 cubes/SM, no spill', 'S': 'S: nvcc with spills'}
    for v in 'NMS':
        rs = V[v]
        if not rs: continue
        j = [r['join'] for r in rs]
        print(f'| {names[v]} | {", ".join(vstr(r["var"]) for r in rs)} | {med(j):.3f} ({fmt(j, 3)}) | {spread(j):.1f} % | '
              f'{med([r["field"] for r in rs]):.3f} ({fmt([r["field"] for r in rs], 3)}) | {fmt([r["mhz"] or 0 for r in rs], 0)} | {"exact" if all(counts_ok(r, fld) for r in rs) else "DIFFER"} |')
    for a, b in [('S', 'M'), ('N', 'M'), ('S', 'N')]:
        if V[a] and V[b]:
            ja = med([r['join'] for r in V[a]]); jb = med([r['join'] for r in V[b]])
            ca = med([r['join'] * r['mhz'] for r in V[a] if r['mhz']]); cb = med([r['join'] * r['mhz'] for r in V[b] if r['mhz']])
            print(f'\n{a} vs {b}: join {ja:.3f} / {jb:.3f} s = x{ja / jb:.4f} (cycles x{ca / cb:.4f}); field x{med([r["field"] for r in V[a]]) / med([r["field"] for r in V[b]]):.4f}')
# unprofiled cadence A/B (chain_ab.sh)
for fld, label in FIELDS:
    A = {t: load(f'ab_{t}_{fld}') for t in ['c', 's8', 's15']}
    if not A['c']: continue
    print(f'\n## unprofiled stage-cadence A/B, {label} (device s/field; 3 rounds, order rotating)\n')
    print('| mode | device s/field (rounds) | spread | SM MHz | vs c | per round | cycles vs c | join variant | counts |')
    print('|---|---|---|---|---|---|---|---|---|')
    dc = med([r['dev'] for r in A['c']]); cc = med([r['dev'] * r['mhz'] for r in A['c'] if r['mhz']])
    for t in ['c', 's8', 's15']:
        rs = A[t]
        if not rs: continue
        d = [r['dev'] for r in rs]
        pr = [rc['dev'] / r['dev'] for r, rc in zip(rs, A['c'])]
        cyc = med([r['dev'] * r['mhz'] for r in rs if r['mhz']])
        print(f'| {t} | {med(d):.3f} ({fmt(d, 3)}) | {spread(d):.1f} % | {fmt([r["mhz"] or 0 for r in rs], 0)} | x{dc / med(d):.4f} | {fmt(pr, 4)} | x{cc / cyc:.4f} | '
              f'{", ".join(vstr(r["var"]) for r in rs)} | {"exact" if all(counts_ok(r, fld) for r in rs) else "DIFFER"} |')
# front end / back end (chain_pq.sh)
for fld, label in FIELDS:
    V = {v: load(f'pq_{v}_{fld}') for v in 'NMPQ'}
    if not any(V.values()): continue
    print(f'\n## compile paths of the same join kernel, {label} (pinned; profile on; 2 rounds)\n')
    print('| image | join kernel | join s/field (rounds) | field s (rounds) | SM MHz | vs M (join) | counts |')
    print('|---|---|---|---|---|---|---|')
    names = {'N': 'N: NVRTC PTX -> driver JIT (the runtime)', 'M': 'M: nvcc + ptxas 12.8, 5 cubes/SM', 'P': 'P: NVRTC PTX -> offline ptxas 12.8',
             'Q': 'Q: nvcc PTX -> driver JIT'}
    jm = med([r['join'] for r in V['M']]) if V['M'] else float('nan')
    for v in 'NMPQ':
        rs = V[v]
        if not rs: continue
        j = [r['join'] for r in rs]
        print(f'| {names[v]} | {", ".join(vstr(r["var"]) for r in rs)} | {med(j):.3f} ({fmt(j, 3)}) | {med([r["field"] for r in rs]):.3f} ({fmt([r["field"] for r in rs], 3)}) | '
              f'{fmt([r["mhz"] or 0 for r in rs], 0)} | x{med(j) / jm:.4f} | {"exact" if all(counts_ok(r, fld) for r in rs) else "DIFFER"} |')
# spill counts
sp = sorted(glob.glob(f'{D}/spc_*.log'))
if sp:
    print('\n## stage spills (NICE_EXP_JOIN_SPILLCNT=1, one run each)\n')
    print('| run | spilled pairs/field | checked/field | % of checked | join s |')
    print('|---|---|---|---|---|')
    for f in sp:
        p = prof(f)
        if p:
            n = len(p); s = sum(x.get('spilled', 0) for x in p) / n; ck = sum(x['checked'] for x in p) / n
            print(f'| {os.path.basename(f)[:-4]} | {s:,.0f} | {ck:,.0f} | {100 * s / ck:.4f} % | {sum(x["join"] for x in p) / n:.2f} |')
# variants seen
print('\n## join-kernel variants per process (driver JIT of each process\'s own PTX)\n')
for k in sorted(VAR):
    print(k, ' '.join(f'#{i}:{vstr(v)}:sass{v["sass"]}:stl{v["stl"]}:ldl{v["ldl"]}:{v["ptx"]}' for i, v in sorted(VAR[k].items())))
