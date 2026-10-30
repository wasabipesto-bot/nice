#!/usr/bin/env python3
"""Summarise an A/B directory set copied back from the box.
usage: summarize.py DIR  (DIR holds nm/, win/, prod/ subdirs, any subset)"""
import re, sys, os, glob, json, statistics as st, collections

D = sys.argv[1]
REF = sys.argv[2] if len(sys.argv) > 2 else 'main'


def med(v):
    return st.median(v) if v else float('nan')


def spread(v):
    if not v:
        return ''
    m = med(v)
    return f"{(max(v) - min(v)) / m * 100:.1f}%"


def dmon_rows(d):
    rows = []
    p = os.path.join(d, 'dmon.log')
    if not os.path.exists(p):
        return rows
    for l in open(p):
        if l.startswith('#'):
            continue
        f = l.split()
        if len(f) < 13 or not f[2].isdigit():
            continue
        # t pwr temp sm mclk pclk
        rows.append((f[0], int(f[2]), int(f[3]), int(f[5]), int(f[11]), int(f[12])))
    return rows


def intervals(d):
    p = os.path.join(d, 'times.log')
    iv = {}
    if not os.path.exists(p):
        return iv
    starts = {}
    for l in open(p):
        t, kind, *key = l.split()
        k = ' '.join(key)
        if kind == 'start':
            starts[k] = t
        else:
            iv[k] = (starts.get(k), t)
    return iv


def power_by_tree(d, key_tree):
    rows = dmon_rows(d)
    iv = intervals(d)
    agg = collections.defaultdict(lambda: ([], [], [], []))
    for k, (a, b) in iv.items():
        tree = key_tree(k)
        for (t, pw, tp, sm, mc, pc) in rows:
            if a < t <= b and sm >= 90:
                agg[tree][0].append(pw)
                agg[tree][1].append(pc)
                agg[tree][2].append(tp)
                agg[tree][3].append(sm)
    out = {}
    for tree, (pw, pc, tp, sm) in agg.items():
        if not pw:
            continue
        out[tree] = (f"n={len(pw)} pwr med {med(pw):.0f} W [{min(pw)}-{max(pw)}], "
                     f"pclk med {med(pc):.0f} MHz [{min(pc)}-{max(pc)}], temp max {max(tp)} C")
    return out


def ratio(v, base, key):
    if base and base.get(key):
        return med(v) / med(base[key])
    return float('nan')


nm = os.path.join(D, 'nm')
if os.path.isdir(nm):
    res = collections.defaultdict(lambda: collections.defaultdict(list))
    backend = {}
    for f in sorted(glob.glob(os.path.join(nm, 'r*_*.log'))):
        tree = re.match(r'r(\d+)_(\w+)\.log', os.path.basename(f)).group(2)
        s = open(f).read()
        for sc in ('b40_detailed', 'b50_detailed'):
            mm = re.search(sc + r'\s+\d+\s+\w+\s+\d+\s+\S+\s+\d+\s+\S+\s+(\S+)', s)
            if mm:
                res[tree][sc].append(float(mm.group(1)))
        mm = re.search(r'NiceMark: (\d+)', s)
        if mm:
            res[tree]['nicemark'].append(int(mm.group(1)))
        mm = re.search(r'GPU initialized: (.*)', s)
        if mm:
            backend[tree] = mm.group(1)
    print('## NiceMark detailed GPU')
    base = res.get(REF)
    for tree, d in res.items():
        line = [tree]
        for sc in ('b40_detailed', 'b50_detailed', 'nicemark'):
            v = d[sc]
            line.append(f"{sc}: {' '.join(f'{a:.4g}' for a in v)} med {med(v):.4g} "
                        f"spread {spread(v)} x{ratio(v, base, sc):.3f}")
        print(' | '.join(line))
        print('  backend:', backend.get(tree))
    for t, s in power_by_tree(nm, lambda k: k.split()[1]).items():
        print('  power', t, s)

win = os.path.join(D, 'win')
if os.path.isdir(win):
    res = collections.defaultdict(lambda: collections.defaultdict(list))
    dig = collections.defaultdict(set)
    for f in sorted(glob.glob(os.path.join(win, 'r*_*.log'))):
        tree = re.match(r'r\d+_(\w+)\.log', os.path.basename(f)).group(1)
        for l in open(f):
            mm = re.search(r'b(\d+) reps \d+ secs \[(.*?)\] rate (\S+)', l)
            if mm:
                res[tree]['b' + mm.group(1)].append(float(mm.group(3)))
            mm = re.search(r'b(\d+) start .* (total=.*)', l)
            if mm:
                dig['b' + mm.group(1)].add((tree, mm.group(2)))
    print('## fixed windows')
    base = res.get(REF)
    for tree, d in res.items():
        print(tree, ' | '.join(
            f"{b}: {' '.join(f'{a:.4g}' for a in v)} med {med(v):.4g} spread {spread(v)} x{ratio(v, base, b):.3f}"
            for b, v in sorted(d.items())))
    for b, s in sorted(dig.items()):
        ds = {x[1] for x in s}
        trees = ','.join(sorted({x[0] for x in s}))
        if len(ds) == 1:
            print(f"  digest {b}: IDENTICAL across {trees}: {next(iter(ds))}")
        else:
            print(f"  digest {b}: DIFFER {sorted(s)}")
    for t, s in power_by_tree(win, lambda k: k.split()[1]).items():
        print('  power', t, s)

prod = os.path.join(D, 'prod')
if os.path.isdir(prod):
    res = collections.defaultdict(lambda: collections.defaultdict(list))
    first = collections.defaultdict(list)
    payload = collections.defaultdict(set)
    nsub = collections.Counter()
    for dd in sorted(glob.glob(os.path.join(prod, 'r*_*_b*'))):
        m = re.match(r'r\d+_(\w+)_b(\d+)$', os.path.basename(dd))
        tree, b = m.group(1), 'b' + m.group(2)
        # the logged rate has 3 significant figures; the logged seconds only 2 decimals
        secs = [1e10 / float(x) for x in re.findall(r'Processed \S+ numbers in \S+s \((\S+) numbers/sec\)',
                                                    open(os.path.join(dd, 'client.log')).read())]
        if secs:
            first[(tree, b)].append(secs[0])
            res[tree][b] += secs[1:]
        for sf in glob.glob(os.path.join(dd, 'submit_*.json')):
            j = json.load(open(sf))
            nsub[(tree, b)] += 1
            payload[b].add((tree, json.dumps([j['unique_distribution'], j['nice_numbers']], sort_keys=True)))
    print('## 1e10 production fields (fields after the first; the first includes JIT)')
    base = res.get(REF)
    for tree, d in res.items():
        parts = []
        for b, v in sorted(d.items()):
            x = med(base[b]) / med(v) if base and base.get(b) else float('nan')
            parts.append(f"{b}: n={len(v)} med {med(v):.4f}s = {1e10 / med(v):.4g} n/s spread {spread(v)} "
                         f"x{x:.3f}; first {' '.join(f'{y:.3f}' for y in first[(tree, b)])}s")
        print(tree, ' | '.join(parts))
    for b, s in sorted(payload.items()):
        ps = {x[1] for x in s}
        n = sum(k for (t, bb), k in nsub.items() if bb == b)
        print(f"  submissions {b}: {n} payloads, {'IDENTICAL' if len(ps) == 1 else 'DIFFER'} "
              f"(distribution + nice_numbers) across {sorted({x[0] for x in s})}")
    for t, s in power_by_tree(prod, lambda k: k.split()[1]).items():
        print('  power', t, s)
