#!/usr/bin/env python3
"""L51 analysis. python3 analyze51.py DIR (copy of the box's /root/l51/logs). Prints every table of RESULTS.md.
Runs: san_<cfg> (chain_sanity.sh), m_<mode>_<field>_r<round> (chain_main.sh), s_<variant>_<field>_r<round>
(chain_screen.sh), ab_<side>_<field>_r<round> (chain_ab.sh, if any). Join/FD kernel variants per process from
DIR/*jit*.txt (ptxjit.py over each process's PTX cache)."""
import re, sys, glob, os, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else 'box'
med = st.median
KEYS = ['setup', 'device_wall', 'upload', 'inputs', 'top', 'bucket', 'join', 'check', 'read', 'probe', 'unattributed',
        'top_fd', 'top_clip', 'clip_launches', 'spilled', 'batches', 'slots', 'null', 'slices', 'up_host', 'up_sort', 'up_dev', 'up_warm',
        'pairs', 'padded_pairs', 'survivors', 'checked', 'tops', 'listed', 'size', 'partitions', 'live_buckets', 'buckets']
EXACT = {'e17_b62': (1020844021499, 62584252554), 'e16_b60': (460847952346, 30871838404)}  # per run (1 / 2 fields)
FIELDS = [('e17_b62', 'b62 1e17 (1 field)'), ('e16_b60', 'b60 1e16 (per field, 2 fields)')]
def prof(path):
    out = []
    for line in open(path, errors='replace'):
        if 'GPU_PROFILE base=' not in line: continue
        d = {}
        for k in KEYS:
            m = re.search(r'(?<![\w])' + k + r'=([0-9.e+-]+)\b', line)
            if m: d[k] = float(m.group(1))
        if d.get('size', 0) > 1e14: out.append(d)
    return out
def thr_all(path):
    t = open(path, errors='replace').read()
    return [dict(base=int(b), fields=int(f), per_field=float(pf), device=float(dev), survivors=int(s), checked=int(c), found=int(fo), slots=int(sl), batches=int(bt), mib=int(mib))
            for b, f, pf, dev, bt, sl, mib, s, c, fo in re.findall(r'JOIN THROUGHPUT.*?base=(\d+) fields=(\d+).*?per_field=([0-9.]+).*?device=([0-9.]+)s.*?batches=(\d+) slots=(\d+) plan_mib=(\d+).*?survivors=(\d+) checked=(\d+) found=(\d+)', t)]
def thr(path):
    a = thr_all(path)
    return a[-1] if a else None
def smi(path, floor=90):
    """Mean SM clock and power over nvidia-smi samples at >= 90 % utilisation (>= 50 % if none: short profiled modes)."""
    mhz, w = [], []
    if not os.path.exists(path): return None, None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) >= 8 and float(p[6].split()[0]) >= floor:
                mhz.append(float(p[1].split()[0])); w.append(float(p[3].split()[0]))
        except (ValueError, IndexError): pass
    if not mhz and floor > 50: return smi(path, 50)
    return (st.mean(mhz) if mhz else None), (st.mean(w) if w else None)
VAR = {}
for jf in sorted(glob.glob(f'{D}/*jit*.txt')):
    own = os.path.basename(jf)[:-len('_jit.txt')] if re.match(r'(s|ab)_.*_r\d+(_spill\d)?_jit\.txt$', os.path.basename(jf)) else None
    for line in open(jf):
        m = re.search(r'/ptx/([^/]+)/ #(\d+) (.*?) ptx=(\w+) regs=(\d+) local=(\d+) sass=(\d+) stl=(\d+) ldl=(\d+)', line)
        if m:
            run = own or m.group(1)
            kind = 'join' if 'join' in m.group(3).lower() else ('fd' if 'top_fd' in m.group(3).lower() or 'topfd' in m.group(3).lower() else None)
            if kind:
                VAR.setdefault((run, kind), {})[int(m.group(2))] = dict(regs=int(m.group(5)), local=int(m.group(6)), sass=int(m.group(7)), stl=int(m.group(8)))
def var(name, kind='join'):
    v = VAR.get((name, kind))
    return v[max(v)] if v else None
def vstr(v):
    return '-' if not v else (f'{v["regs"]}r/{v["sass"]}' + (f'+{v["stl"]}STL' if v['stl'] else ''))
def load(prefix, spill=False):
    runs = []
    for f in sorted(glob.glob(f'{D}/{prefix}_r*.log')):
        name = os.path.basename(f)[:-4]
        if ('_spill' in name) != spill: continue
        p = prof(f); t = thr(f); mhz, w = smi(f[:-4] + '.smi')
        if not t: continue
        st0 = re.search(r'^START \S+ (\d+):(\d+):(\d+)', open(f, errors='replace').readline())
        r = {'t': (int(st0.group(1)) * 3600 + int(st0.group(2)) * 60 + int(st0.group(3))) if st0 else 0,
             'name': name, 'rnd': int(name.rsplit('_r', 1)[1].split('_')[0]), 'mhz': mhz, 'w': w, 'var': var(name), 'fdv': var(name, 'fd'), 'thr': t, 'dev': t['device']}
        if p:
            n = len(p)
            r.update({k: sum(x.get(k, 0) for x in p) / n for k in KEYS})
            r['field'] = r['device_wall'] - r['probe']
        runs.append(r)
    return runs
def counts_ok(r, fld):
    s, c = EXACT[fld]; t = r['thr']
    return t['survivors'] == s and t['checked'] == c
def fmt(xs, d=2): return ', '.join(f'{x:.{d}f}' for x in xs)
def spread(xs): return 100 * (max(xs) - min(xs)) / med(xs) if len(xs) > 1 else 0

# ---- sanity
san = sorted(glob.glob(f'{D}/san_*.log'))
if san:
    print('## Sanity (1e14, b62 then b60, one process each)\n')
    print('| cfg | env | b62 survivors / checked | b60 survivors / checked | = base | join kernel (b62, b60) |')
    print('|---|---|---|---|---|---|')
    ref = {x['base']: (x['survivors'], x['checked']) for x in thr_all(f'{D}/san_base.log')} if os.path.exists(f'{D}/san_base.log') else {}
    for f in san:
        nm = os.path.basename(f)[4:-4]
        env = re.search(r'env=\[(.*?)\]', open(f).readline()); env = env.group(1).replace('NICE_EXP_', '').strip() if env else ''
        a = {x['base']: (x['survivors'], x['checked']) for x in thr_all(f)}
        same = all(a.get(b) == ref.get(b) for b in (62, 60)) and len(a) == 2
        v = VAR.get((f'san_{nm}', 'join'), {})
        vs = ', '.join(vstr(v[i]) for i in sorted(v))
        print(f'| {nm} | {env} | {a.get(62, ("-", "-"))[0]:,} / {a.get(62, ("-", "-"))[1]:,} | {a.get(60, ("-", "-"))[0]:,} / {a.get(60, ("-", "-"))[1]:,} | {"yes" if same else "**NO**"} | {vs} |' if len(a) == 2 else f'| {nm} | {env} | FAILED ({len(a)} bases) | | | |')

# ---- main chain
MODES = [('c', 'full (d813aea), profiled'), ('a', 'AND only'), ('b', 'walk without the prefilter, no stage'), ('p', 'walk + prefilter, no stage'),
         ('z', 'no AND'), ('d', 'full, per-top AND (TMIN 2^30)'), ('u', 'full, unprofiled (E)'), ('B', 'd813aea binary, unprofiled')]
for fld, label in FIELDS:
    R = {t: load(f'm_{t}_{fld}') for t, _ in MODES}
    if not any(R.values()): continue
    print(f'\n## Main chain, {label}\n')
    print('| mode | join s/field (rounds) | spread | field s profiled excl. probe (rounds) | device s/field (harness) | SM MHz | W | join kernel per round | counts |')
    print('|---|---|---|---|---|---|---|---|---|')
    for t, nm in MODES:
        rs = R[t]
        if not rs: continue
        exact = all(counts_ok(r, fld) for r in rs)
        cnt = 'exact' if exact else f'{rs[0]["thr"]["survivors"]:,} / {rs[0]["thr"]["checked"]:,}' + ('' if len({(r['thr']['survivors'], r['thr']['checked']) for r in rs}) == 1 else ' (vary)')
        dv = [r['dev'] for r in rs]
        if 'join' in rs[0]:
            j = [r['join'] for r in rs]; fl = [r['field'] for r in rs]
            print(f'| {t}: {nm} | {med(j):.2f} ({fmt(j)}) | {spread(j):.1f} % | {med(fl):.2f} ({fmt(fl)}) | {med(dv):.2f} | {fmt([r["mhz"] or 0 for r in rs], 0)} | {fmt([r["w"] or 0 for r in rs], 0)} | {", ".join(vstr(r["var"]) for r in rs)} | {cnt} |')
        else:
            print(f'| {t}: {nm} | | | | {med(dv):.2f} ({fmt(dv)}) | {fmt([r["mhz"] or 0 for r in rs], 0)} | {fmt([r["w"] or 0 for r in rs], 0)} | {", ".join(vstr(r["var"]) for r in rs)} | {cnt} |')
    c = R['c']
    if not c or 'join' not in c[0]: continue
    fieldp = med([r['field'] for r in c]); unp = med([r['dev'] for r in R['u']]) if R['u'] else float('nan')
    unpB = med([r['dev'] for r in R['B']]) if R['B'] else float('nan')
    mh = med([r['mhz'] for r in c if r['mhz']])
    print(f'\n### Phases of mode c, {label} (3 profiled runs, medians; share = % of the profiled field excl. probe; "in B s" = share × the unprofiled d813aea median {unpB:.2f} s (E unprofiled {unp:.2f} s))\n')
    print('| phase | profiled s/field (rounds) | share | in B s | G-cycles |')
    print('|---|---|---|---|---|')
    rows = [('top: FD kernel (`top_fd_kernel`, seeds incl.)', 'top_fd'), ('top: clipped-block launch (`top_kernel`)', 'top_clip'), ('**top total**', 'top'),
            ('bucket', 'bucket'), ('join', 'join'), ('check', 'check'), ('other: upload', 'upload'), ('other: inputs', 'inputs'),
            ('other: read', 'read'), ('other: null mark (one empty sync per batch)', 'null'), ('other: unattributed', 'unattributed'), ('probe (excluded)', 'probe')]
    for nm, k in rows:
        xs = [r[k] for r in c]
        cyc = med([r[k] * r['mhz'] / 1000 for r in c if r['mhz']])
        print(f'| {nm} | {med(xs):.3f} ({fmt(xs, 3)}) | {100 * med(xs) / fieldp:.2f} % | {med(xs) / fieldp * unpB:.2f} | {cyc:.2f} |')
    oth = [r['upload'] + r['inputs'] + r['read'] + r['null'] + r['unattributed'] for r in c]
    print(f'| **other total** | {med(oth):.3f} ({fmt(oth, 3)}) | {100 * med(oth) / fieldp:.2f} % | {med(oth) / fieldp * unpB:.2f} | |')
    mhB = med([r['mhz'] for r in R['B'] if r['mhz']]) if R['B'] else 0
    print(f'| field (profiled device excl. probe) | {fieldp:.3f} ({fmt([r["field"] for r in c], 3)}) | 100 % | {unpB:.2f} | {fieldp * mh / 1000:.1f} (B: {unpB * mhB / 1000:.1f}) |')
    print(f'\nprofiled field excl. probe ÷ unprofiled B: {fieldp / unpB:.3f} in time, {fieldp * mh / (unpB * mhB):.3f} in cycles (clock c {mh:.0f}, B {mhB:.0f} MHz); with probe {(fieldp + med([r["probe"] for r in c])) / unpB:.3f}')
    print(f'\nclip launches/field {c[0]["clip_launches"]:.0f}, batches/field {c[0]["batches"]:.0f}, slots {c[0]["slots"]:.0f}, slices {c[0].get("slices", 0):.0f}, kept tops/field {c[0]["tops"]:.4g}, '
          f'pairs {c[0]["pairs"]:.4g}, padded {c[0]["padded_pairs"]:.4g} (lanes used {100 * c[0]["pairs"] / c[0]["padded_pairs"]:.1f} %), live buckets {c[0]["live_buckets"]:.4g} of {c[0]["buckets"]:.4g}; '
          f'clock c {mh:.0f} / u {med([r["mhz"] for r in R["u"] if r["mhz"]]) if R["u"] else 0:.0f} / B {med([r["mhz"] for r in R["B"] if r["mhz"]]) if R["B"] else 0:.0f} MHz; '
          f'null mark {1e6 * med([r.get("null", 0) for r in c]) / c[0]["batches"]:.1f} us per batch; FD per batch {1e3 * med([r["top_fd"] for r in c]) / c[0]["batches"]:.3f} ms; '
          f'join per batch {1e3 * med([r["join"] for r in c]) / c[0]["batches"]:.3f} ms; check per batch {1e3 * med([r["check"] for r in c]) / c[0]["batches"]:.3f} ms')
    if all(R[t] and 'join' in R[t][0] for t in 'cabpz'):
        J = {t: med([r['join'] for r in R[t]]) for t in 'cabpzd' if R[t]}
        CY = {t: med([r['join'] * r['mhz'] / 1000 for r in R[t] if r['mhz']]) for t in 'cabpzd' if R[t]}
        PR = {t: {r['rnd']: r['join'] for r in R[t]} for t in 'cabpzd' if R[t]}
        parts = [('base (z: work items, batch load + transposed copy, wave loads + prefilter terms, per-batch stage check)', None, 'z'),
                 ('AND (a − z: transposed ORs, clipped-chunk range test, popcounts)', 'z', 'a'),
                 ('walk rounds (b − a: vote, pop, plane barrier)', 'a', 'b'),
                 ('prefilter `walk_pf_lean` (p − b)', 'b', 'p'),
                 ('stage + flush (c − p)', 'p', 'c')]
        print(f'\n### Join ablation, {label} (profiled join kernel seconds, medians of 3 rounds; marginal z → a → b → p → c)\n')
        print('| part | profiled s/field | % of join | % of field (profiled) | in B s | G-cycles (% of join) | per round (s) |')
        print('|---|---|---|---|---|---|---|')
        for nm, lo, hi in parts:
            s = J[hi] - (J[lo] if lo else 0); cy = CY[hi] - (CY[lo] if lo else 0)
            pr = [PR[hi][k] - (PR[lo][k] if lo else 0) for k in sorted(PR[hi]) if (not lo or k in PR[lo])]
            print(f'| {nm} | **{s:.2f}** | {100 * s / J["c"]:.1f} % | {100 * s / fieldp:.1f} % | {s / fieldp * unpB:.2f} | {cy:.1f} ({100 * cy / CY["c"]:.1f} %) | {fmt(pr)} |')
        print(f'| **join (c)** | **{J["c"]:.2f}** | 100 % | {100 * J["c"] / fieldp:.1f} % | {J["c"] / fieldp * unpB:.2f} | {CY["c"]:.1f} | {fmt([PR["c"][k] for k in sorted(PR["c"])])} |')
        print('\nper-mode mean SM MHz (median of rounds): ' + ', '.join(f'{t} {med([r["mhz"] for r in R[t] if r["mhz"]]):.0f}' for t in 'zabpcd' if R[t]))
        if 'd' in J:
            print(f'\nper-top AND (d) join {J["d"]:.2f} s: +{J["d"] - J["c"]:.2f} s; d field {med([r["field"] for r in R["d"]]):.2f} s profiled: ×{med([r["field"] for r in R["d"]]) / fieldp:.3f}')
        print(f'survivor path (walk + prefilter + stage) {J["c"] - J["a"]:.2f} s = {100 * (J["c"] - J["a"]) / J["c"]:.1f} % of join, {100 * (J["c"] - J["a"]) / fieldp:.1f} % of field')

# ---- screen
SCR = ['base', 'base2', 'base3', 'base4', 'base5', 'base6', 'ept1', 'ept3', 'tm128', 'tm256', 'tm512', 'ag2', 'ag8', 'tc128', 'tc512', 'fd128', 'fd512', 'stg1', 'fl256', 'fl768']
DESC = {'base': 'base (EPT 2, TMIN 192, AG 4, TCAP 256, FD 256, stage per batch, flush 512)', 'base2': 'base, second run', 'base3': 'base (round 1 b62: the run labelled ag2 by the name bug)', 'base4': 'base (round 1 b62: the run labelled tm512 by the name bug)', 'base5': 'base (round 1 b62, after the restart)', 'base6': 'base (round 1 b62, after the restart, mid-block)',
        'ept1': 'EPT 1', 'ept3': 'EPT 3', 'tm128': 'TRANSPOSE_MIN 128', 'tm256': 'TRANSPOSE_MIN 256', 'tm512': 'TRANSPOSE_MIN 512 (= per-top AND)',
        'ag2': 'AND_GROUP 2', 'ag8': 'AND_GROUP 8', 'tc128': 'TOP_CAP 128 (TMIN 96)', 'tc512': 'TOP_CAP 512', 'fd128': 'FD cube 128', 'fd512': 'FD cube 512',
        'stg1': 'stage once per work item', 'fl256': 'SURV_FLUSH 256', 'fl768': 'SURV_FLUSH 768'}
for fld, label in FIELDS:
    R = {v: load(f's_{v}_{fld}') for v in SCR}
    if not R['base']: continue
    print(f'\n## Screen, {label} (unprofiled device s/field; ratio = base ÷ variant, base = mean of the round\'s base runs)\n')
    bases = {}
    for r in [x for b in ('base', 'base2', 'base3', 'base4', 'base5', 'base6') for x in R[b]]:
        bases.setdefault(r['rnd'], []).append(r)
    bdev = {k: st.mean(x['dev'] for x in v) for k, v in bases.items()}
    bcyc = {k: st.mean(x['dev'] * (x['mhz'] or 0) for x in v) for k, v in bases.items()}
    allb = sorted([x for b in ('base', 'base2', 'base3', 'base4', 'base5', 'base6') for x in R[b]], key=lambda x: x['t'])
    def local(r):
        # the base runs of the same round nearest in time before and after (one side if only one exists)
        bs = [x for x in allb if x['rnd'] == r['rnd'] and x is not r]
        pre = [x for x in bs if x['t'] < r['t']]; post = [x for x in bs if x['t'] > r['t']]
        near = ([pre[-1]] if pre else []) + ([post[0]] if post else [])
        return st.mean(x['dev'] for x in near) if near else None
    print('| variant | s/field (rounds) | **× vs local base** (per round) | × vs round-mean base | MHz (rounds) | cycles × | join kernel | FD kernel | counts |')
    print('|---|---|---|---|---|---|---|---|---|')
    for v in SCR:
        rs = R[v]
        if not rs: continue
        loc = [local(r) / r['dev'] for r in rs if local(r)]
        rat = [bdev[r['rnd']] / r['dev'] for r in rs if r['rnd'] in bdev]
        cyr = [bcyc[r['rnd']] / (r['dev'] * r['mhz']) for r in rs if r['rnd'] in bcyc and r['mhz']]
        exact = all(counts_ok(r, fld) for r in rs)
        print(f'| {v}: {DESC[v]} | {st.mean([r["dev"] for r in rs]):.3f} ({fmt([r["dev"] for r in rs], 3)}) | **×{st.mean(loc) if loc else 0:.3f}** ({fmt(loc, 3)}) | ×{st.mean(rat):.3f} ({fmt(rat, 3)}) | {fmt([r["mhz"] or 0 for r in rs], 0)} | ×{st.mean(cyr) if cyr else 0:.3f} | {", ".join(vstr(r["var"]) for r in rs)} | {", ".join(vstr(r["fdv"]) for r in rs)} | {"exact" if exact else "**DIFFER**"} |')

# ---- A/B (optional)
for fld, label in FIELDS + [('e16_b62', 'b62 1e16'), ('e16_b64', 'b64 1e16')]:
    A = load(f'ab_A_{fld}'); Bs = load(f'ab_B_{fld}')
    if not A or not Bs: continue
    a = {r['rnd']: r for r in A}; b = {r['rnd']: r for r in Bs}
    rat = [a[k]['dev'] / b[k]['dev'] for k in sorted(a) if k in b]
    print(f'\n## A/B {label}: A {med([r["dev"] for r in A]):.3f} ({fmt([r["dev"] for r in A], 3)}) vs B {med([r["dev"] for r in Bs]):.3f} ({fmt([r["dev"] for r in Bs], 3)}): ×{med([r["dev"] for r in A]) / med([r["dev"] for r in Bs]):.3f} (per round {fmt(rat, 3)}); MHz A {fmt([r["mhz"] or 0 for r in A], 0)} B {fmt([r["mhz"] or 0 for r in Bs], 0)}')

# ---- spill tax: screen runs whose join kernel was the 40-register spill variant, against the same config's re-run
rows = []
for fld, label in FIELDS:
    for v in SCR:
        sp = load(f's_{v}_{fld}', spill=True)
        ok = {r['rnd']: r for r in load(f's_{v}_{fld}')}
        for r in sp:
            o = ok.get(r['rnd'])
            if o: rows.append((label, v, r['rnd'], r['name'], r['dev'], o['dev'], vstr(r['var']), vstr(o['var']), r['mhz'], o['mhz']))
if rows:
    print('\n## Spill tax (screen runs that compiled the 40-register spill variant, then re-ran)\n')
    print('| field | variant | round | spill run s | re-run s | spill ÷ re-run | kernels | MHz |')
    print('|---|---|---|---|---|---|---|---|')
    for lab, v, rnd, nm, a, b, va, vb, ma, mb in rows:
        print(f'| {lab} | {v} | {rnd} | {a:.3f} | {b:.3f} | ×{a / b:.3f} | {va} / {vb} | {ma or 0:.0f} / {mb or 0:.0f} |')

# ---- pinned spill-tax runs (chain_post.sh): S spill variant, N spill-free, D = S's PTX + '.minnctapersm 5'
for fld, label in FIELDS:
    P = {v: load(f'pn_{v}_{fld}') for v in 'SND'}
    if not all(P.values()): continue
    print(f'\n## Pinned join images, {label} (unprofiled device s/field; 3 interleaved rounds)\n')
    print('| image | s/field (rounds) | vs N (per round) | MHz | join kernel (driver JIT of the pinned PTX) | counts |')
    print('|---|---|---|---|---|---|')
    n = {r['rnd']: r['dev'] for r in P['N']}
    for v, nm in (('S', 'S: the 40-register spill variant'), ('N', 'N: spill-free (same config, another process)'), ('D', "D: S's PTX + .minnctapersm 5")):
        rs = P[v]
        rat = [n[r['rnd']] / r['dev'] for r in rs if r['rnd'] in n]
        print(f'| {nm} | {med([r["dev"] for r in rs]):.3f} ({fmt([r["dev"] for r in rs], 3)}) | ×{med(rat):.3f} ({fmt(rat, 3)}) | {fmt([r["mhz"] or 0 for r in rs], 0)} | {", ".join(vstr(r["var"]) for r in rs)} | {"exact" if all(counts_ok(r, fld) for r in rs) else "DIFFER"} |')
bf = sorted(glob.glob(f'{D}/bfreq_*_jit.txt'))
if bf:
    sp = 0; tot = 0; regs = []
    for f in bf:
        for line in open(f):
            m = re.search(r'regs=(\d+) local=(\d+)', line)
            if m and 'join' in line:
                tot += 1; regs.append(int(m.group(1)))
                if int(m.group(2)) > 0: sp += 1
    print(f'\n## How often d813aea (B) compiles the spill variant: {sp} of {tot} join kernels (b62 + b60, {len(bf)} processes at 1e14); registers {sorted(regs)}')
