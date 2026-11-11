#!/usr/bin/env python3
"""B64 analysis: python3 analyze.py BOXDIR  (BOXDIR = copy of the box's /root/b64/logs).
Base means (a_*), profiles (p_*), screen (s_*), JIT variants. Every number printed is from the logs."""
import sys, re, glob, os, statistics as st
D = sys.argv[1]
ROOTS = {64: 8, 62: 2, 60: 4}
# Runs excluded from the summaries (listed, not used): a_M_b64_1e16_r1 ran its first five fields under the host's 260 W
# period at 06:00-06:02 UTC, 2.5x slower than every later round of the same fields.
EXCLUDE = {'a_M_b64_1e16_r1', 'a_S_b64_1e17_r2'}  # S r2: fields 1-6 at half speed, 08:18-08:35 UTC, card at full power and clock
def kv(line):
    return {k: v for k, v in re.findall(r'(\w+)=([-\w.:]+)', line)}
def num(x):
    try: return float(x)
    except: return None
def load(path):
    out = {'fields': [], 'prof': [], 'tp': None, 'start': None, 'end': None}
    for line in open(path, errors='replace'):
        if line.startswith('START'):
            out['start'] = kv(line)
        elif 'FIELD i=' in line:
            out['fields'].append(kv(line[line.index('FIELD i='):]))
        elif 'GPU_PROFILE base=' in line:
            out['prof'].append(kv(line[line.index('GPU_PROFILE'):]))
        elif 'JOIN THROUGHPUT' in line:
            out['tp'] = kv(line)
        elif line.startswith('END'):
            out['end'] = line.strip()
    return out
def jit(name):
    p = f'{D}/{name}_jit.txt'
    if not os.path.exists(p): return '?'
    v = []
    for line in open(p):
        m = re.search(r' (join_kernel)\S* .*regs=(\d+) local=(\d+)', line)
        if m: v.append(f"{m.group(2)}{'+' + m.group(3) + 'B' if m.group(3) != '0' else ''}")
    return '/'.join(v) or '?'
def smi(name):
    p = f'{D}/{name}.smi'
    if not os.path.exists(p): return None, None
    mhz, w = [], []
    lims = set()
    for line in open(p):
        x = [s.strip() for s in line.split(',')]
        if len(x) < 7: continue
        try:
            u = float(x[6].split()[0]); c = float(x[1].split()[0]); pw = float(x[3].split()[0])
        except: continue
        try: lims.add(int(float(x[4].split()[0])))
        except: pass
        if u >= 90: mhz.append(c); w.append(pw)
    SMI_LIMITS[name] = sorted(lims)
    return (st.mean(mhz) if mhz else None), (st.mean(w) if w else None)
SMI_LIMITS = {}

# ---------------- base means ----------------
print('== Base means (a_*: 10 fields at 0.05..0.95, unprofiled; s per admissible n = secs / (10 * size * roots/(b-1)))')
rows = {}
for p in sorted(glob.glob(f'{D}/a_*.log')):
    name = os.path.basename(p)[:-4]
    m = re.match(r'a_(\w)_b(\d+)_(1e\d+)_r(\d+)', name)
    if not m: continue
    t, b, sz, r = m.group(1), int(m.group(2)), m.group(3), int(m.group(4))
    o = load(p)
    if not o['tp']: print(f'  {name}: incomplete ({len(o["fields"])} fields)'); continue
    secs = float(o['tp']['secs']); nf = len(o['fields']); size = float(sz)
    adm = nf * size * ROOTS[b] / (b - 1)
    fl = o['fields']
    at = [float(f['at']) for f in fl]
    per = [at[0]] + [at[i] - at[i - 1] for i in range(1, len(at))]
    empt = sum(1 for f in fl if f['batches'] == '0')
    surv = sum(int(f['survivors']) for f in fl); chk = sum(int(f['checked']) for f in fl)
    mhz, w = smi(name)
    if name in EXCLUDE:
        print(f'  {name}: EXCLUDED secs={secs:.2f}'); continue
    rows.setdefault((b, sz, t), []).append((r, secs, secs / adm, empt, surv, chk, jit(name), mhz, w, fl, per))
    print(f'  {name}: secs={secs:.2f} per_field={secs/nf:.2f} s/adm={secs/adm:.4e} empty={empt}/{nf} surv={surv} chk={chk} '
          f'join={jit(name)} MHz={mhz and round(mhz)} W={w and round(w)} cap={SMI_LIMITS.get(name)}')
print()
print('  summary (median over rounds of s per admissible n; per round in brackets)')
for (b, sz, t), v in sorted(rows.items()):
    vals = [x[2] for x in sorted(v)]
    print(f'  b{b} {sz} {t}: median {st.median(vals):.4e} s/adm  per field {st.median([x[1] for x in v])/10:.2f} s  rounds [{", ".join(f"{x:.4e}" for x in vals)}]')
for b, sz in sorted({(k[0], k[1]) for k in rows}):
    if (b, sz, 'M') in rows and (b, sz, 'S') in rows:
        rm = {x[0]: x[1] for x in rows[(b, sz, 'M')]}; rs = {x[0]: x[1] for x in rows[(b, sz, 'S')]}
        common = sorted(set(rm) & set(rs))
        rat = [rm[r] / rs[r] for r in common]
        print(f'  b{b} {sz}: S speed-up over M (M secs / S secs) per round {[round(x, 4) for x in rat]} median {st.median(rat):.4f}')
print()
print('  per field (s between finishes; device s of the field; survivors / checked), first round of M and S')
for (b, sz, t), v in sorted(rows.items()):
    r, secs, _, _, _, _, _, _, _, fl, per = sorted(v)[0]
    print(f'  b{b} {sz} {t} r{r}: ' + ' | '.join(f'{i}:{per[i]:.1f}/{float(f["jdevice"]):.1f}'
          + ('E' if f['batches'] == '0' else '') for i, f in enumerate(fl)))
# all rounds, per field device s, for spread
print()
print('  per-field device s, every round (field index: values)')
for (b, sz, t), v in sorted(rows.items()):
    v = sorted(v)
    nf = len(v[0][9])
    print(f'  b{b} {sz} {t}: ' + ' | '.join(f'{i}:' + ','.join(f'{float(x[9][i]["jdevice"]):.1f}' for x in v if len(x[9]) > i) for i in range(nf)))
print()

# ---------------- profiles ----------------
print('== Profiles (p_*: tree E, GPU_PROFILE per field)')
PH = ['upload', 'inputs', 'top', 'bucket', 'join', 'check', 'read', 'probe', 'unattributed']
prof = {}
for p in sorted(glob.glob(f'{D}/p_*.log')):
    name = os.path.basename(p)[:-4]
    o = load(p)
    mode = name.split('_')[1]; size = name.split('_')[2]
    for i, g in enumerate(o['prof'][1:]):   # [0] is the warm-up field
        prof.setdefault((size, g['start'], mode), []).append((name, g))
    mhz, w = smi(name)
    print(f'  {name}: fields={len(o["prof"]) - 1} join={jit(name)} MHz={mhz and round(mhz)} W={w and round(w)} cap={SMI_LIMITS.get(name)}')
print()
for (size, start, mode), v in sorted(prof.items()):
    js = [num(g['join']) for _, g in v]
    g = v[0][1]
    dw = [num(x['device_wall']) for _, x in v]
    ph = {k: st.median([num(x[k]) for _, x in v]) for k in PH + ['top_fd', 'top_clip', 'device_wall', 'setup']}
    tot = sum(ph[k] for k in PH if k != 'probe')
    print(f'  {size} {start} {mode}: device_wall {ph["device_wall"]:.2f} (rounds {[round(x, 2) for x in dw]}) excl.probe {tot:.2f}; join {[round(x, 2) for x in js]}')
    if mode == 'c':
        print('     shares of the profiled field excl. probe: ' + '  '.join(f'{k} {ph[k]:.2f}s {100*ph[k]/tot:.1f}%' for k in PH if k != 'probe')
              + f'  | top_fd {ph["top_fd"]:.3f} top_clip {ph["top_clip"]:.3f} probe {ph["probe"]:.2f} setup {ph["setup"]:.2f}')
        cnt = {k: num(g.get(k, 'nan')) for k in ['slices', 'partitions', 'batches', 'slots', 'ntlay', 'nbp', 'tops', 'listed', 'pairs', 'padded_pairs', 'live_buckets', 'buckets', 'survivors', 'checked', 'spilled']}
        print('     counts: ' + ' '.join(f'{k}={int(x) if x is not None and x == x else x}' for k, x in cnt.items()))
        if cnt['pairs']:
            pr = cnt['pairs']
            nr = ROOTS[int(g['base'])]
            print(f'     mean tile {cnt["tops"]*nr/cnt["live_buckets"]:.0f} tops (kept tops x {nr} roots / live buckets) x {cnt["listed"]/cnt["live_buckets"]:.0f} entries; pass {cnt["survivors"]/pr*100:.2f}%; '
                  f'prefilter keeps {cnt["checked"]/cnt["survivors"]*100:.2f}%; lanes used {pr/cnt["padded_pairs"]*100:.1f}%')
            print(f'     per op: join {ph["join"]/pr*1e12:.3f} ps/pair; check {ph["check"]/cnt["checked"]*1e9:.3f} ns/check; '
                  f'top {ph["top"]/(cnt["ntlay"]*cnt["partitions"])*1e9:.3f} ns/top test (ntlay x partitions = {cnt["ntlay"]*cnt["partitions"]:.3e}); '
                  f'bucket {ph["bucket"]:.3f}s')
# ablation table
print()
print('  ablation (join s, median over rounds, per (size, start)): base=z, AND=a-z, walk=b-a, prefilter=p-b, stage=c-p')
for size in ['e16', 'e17']:
    starts = sorted({k[1] for k in prof if k[0] == size})
    for s0 in starts:
        j = {}
        for m in 'cazbp':
            if (size, s0, m) in prof:
                j[m] = st.median([num(g['join']) for _, g in prof[(size, s0, m)]])
        c = prof.get((size, s0, 'c'))
        if not c: continue
        tot = st.median([sum(num(g[k]) for k in PH if k != 'probe') for _, g in c])
        g = c[0][1]; pr = num(g['pairs']); sv = num(g['survivors'])
        parts = []
        if 'z' in j: parts.append(('base', j['z']))
        if 'a' in j and 'z' in j: parts.append(('AND', j['a'] - j['z']))
        if 'b' in j and 'a' in j: parts.append(('walk', j['b'] - j['a']))
        if 'p' in j and 'b' in j: parts.append(('prefilter', j['p'] - j['b']))
        if 'p' in j: parts.append(('stage', j['c'] - j['p']))
        if 'b' in j: parts.append(('prefilter+stage c-b', j['c'] - j['b']))
        if 'a' in j: parts.append(('survivor path c-a', j['c'] - j['a']))
        print(f'  {size} {s0}: modes ' + ' '.join(f'{m}={x:.2f}' for m, x in j.items()) + ' | ' +
              '  '.join(f'{n} {x:.2f}s ({100*x/tot:.1f}% of field; {x/pr*1e12:.3f} ps/pair)' for n, x in parts)
              + (f' | survivor path {(j["c"]-j["a"])/sv*1e12:.2f} ps/survivor' if 'a' in j else ''))
print()

# ---------------- screen ----------------
print('== Screen (s_*: E unprofiled, b64 1e16 fields 0.35 + 0.55; ratio = local base / variant)')
sc = []
for p in sorted(glob.glob(f'{D}/s_*.log'), key=os.path.getmtime):
    name = os.path.basename(p)[:-4]
    o = load(p)
    if not o['tp']: continue
    m = re.match(r's_(\w+?)_r(\d)(_spill\d)?$', name)
    sc.append((name, m.group(1), int(m.group(2)), bool(m.group(3)), float(o['tp']['secs']), jit(name), o['tp'].get('survivors'), o['tp'].get('checked')))
for i, (name, v, r, sp, secs, j, sv, ck) in enumerate(sc):
    if sp: print(f'  {name}: {secs:.2f} (spill variant, re-run) join={j}'); continue
    if v.startswith('base'):
        print(f'  {name}: {secs:.2f} join={j} surv={sv} chk={ck}'); continue
    bef = [x for x in sc[:i] if x[1].startswith('base') and x[2] == r and not x[3]]
    aft = [x for x in sc[i + 1:] if x[1].startswith('base') and x[2] == r and not x[3]]
    lb = [x[4] for x in bef[-1:] + aft[:1]]
    if not lb: lb = [x[4] for x in sc if x[1].startswith('base') and not x[3]]
    print(f'  {name}: {secs:.2f} x{st.mean(lb)/secs:.3f} (local base {st.mean(lb):.2f}) join={j} surv={sv} chk={ck}')

# ---------------- every other run (tiles t_, FD f_, Task B b_/bsan_, pinned pp_, FD profile pf_, exactness x_) ----------
print()
print('== Other runs (wall secs of the timed fields, counts, join_kernel regs+spill per process)')
for pre in ['t_', 'f_', 'bsan_', 'b_', 'pp_', 'pf_']:
    for p in sorted(glob.glob(f'{D}/{pre}*.log')):
        name = os.path.basename(p)[:-4]
        o = load(p)
        tps = []
        for line in open(p, errors='replace'):
            if 'JOIN THROUGHPUT' in line:
                d = kv(line); tps.append(f"b{d.get('base')} secs={d.get('secs')} surv={d.get('survivors')} chk={d.get('checked')}")
        mhz, w = smi(name)
        print(f'  {name}: ' + ' | '.join(tps) + f' join={jit(name)} cap={SMI_LIMITS.get(name)}')
for p in sorted(glob.glob(f'{D}/x_*.log')):
    t = open(p, errors='replace').read()
    m = re.search(r'b64 \[(\d+), \+(\d+)\), (\d+) partitions: .*survivors (\d+) checked (\d+)', t)
    print(f'  {os.path.basename(p)[:-4]}: ' + (f'field {m.group(1)} +{m.group(2)}, {m.group(3)} partitions, survivors {m.group(4)} checked {m.group(5)}' if m else '?') + (' ok' if 'test result: ok' in t else ' NOT OK'))
