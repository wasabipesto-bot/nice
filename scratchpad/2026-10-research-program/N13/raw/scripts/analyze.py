#!/usr/bin/env python3
"""N13 analysis: python3 analyze.py DIR (the copy of demoux's out/). Every number is from the logs."""
import sys, re, glob, os, statistics as st
D = sys.argv[1]
def kv(l): return dict(re.findall(r'(\w+)=([-\w.:]+)', l))
def runs(pat):
    out = {}
    for p in sorted(glob.glob(f'{D}/{pat}.log')):
        n = os.path.basename(p)[:-4]; tps = []; fl = []; prof = []
        for l in open(p, errors='replace'):
            if 'JOIN THROUGHPUT' in l: tps.append(kv(l))
            elif 'FIELD i=' in l: fl.append(kv(l[l.index('FIELD i='):]))
            elif 'GPU_PROFILE base=' in l: prof.append(kv(l[l.index('GPU_PROFILE'):]))
        out[n] = (tps, fl, prof)
    return out
def gpu(n):
    p = f'{D}/{n}.gpu'
    if not os.path.exists(p): return ''
    sc, pw, ld = [], [], []
    for l in open(p):
        d = kv(l)
        try:
            if int(d.get('busy', 0)) >= 90:
                sc.append(int(re.sub(r'\D', '', d['sclk'].split(':')[-1]))); pw.append(int(d['pw']) / 1e6)
            ld.append(float(d['load']))
        except Exception: pass
    return f"sclk={st.mean(sc):.0f} W={st.mean(pw):.0f} load={st.mean(ld):.1f}" if sc else ''
print('== A/A and A (wall secs of the process\'s timed fields)')
A = runs('a*_*')
tab = {}
for n, (tps, fl, _) in A.items():
    if not tps: print(f'  {n}: incomplete'); continue
    t = tps[-1]
    print(f"  {n}: secs={t['secs']} survivors={t['survivors']} checked={t['checked']} slots={t['slots']} batches={t['batches']} | per field device " +
          ' '.join(f"{float(f['jdevice']):.2f}" for f in fl) + f" | {gpu(n)}")
    m = re.match(r'a_(\w+?)_(b\w+?)_r(\d)', n)
    if m: tab.setdefault((m.group(2), m.group(1)), {})[int(m.group(3))] = float(t['secs'])
print()
for (fs, tree), r in sorted(tab.items()):
    print(f'  {fs} {tree}: ' + ' '.join(f'r{k}={v:.2f}' for k, v in sorted(r.items())) + f'  median {st.median(r.values()):.2f}')
def ratio(fs, a, b):
    ra, rb = tab.get((fs, a), {}), tab.get((fs, b), {})
    c = sorted(set(ra) & set(rb))
    if c:
        x = [ra[k] / rb[k] for k in c]
        print(f'  {fs}: {a} / {b} per round {[round(v, 4) for v in x]} median x{st.median(x):.4f}')
print()
for fs in ['b62', 'b60']:
    ratio(fs, 'M', 'T250'); ratio(fs, 'T250', 'T251'); ratio(fs, 'M', 'T251')
for fs in ['b64e17', 'b64e16']:
    ratio(fs, 'T250', 'T254')
print()
print('== Profiles (p_*)')
for n, (tps, fl, prof) in runs('p_*').items():
    for g in prof[1:]:
        K = ['upload', 'inputs', 'top', 'bucket', 'join', 'check', 'read', 'probe', 'unattributed']
        tot = sum(float(g[k]) for k in K if k != 'probe')
        print(f"  {n} start={g['start'][:8]} size={g['size']}: total(excl probe)={tot:.2f} " + ' '.join(f"{k}={float(g[k]):.2f}({100*float(g[k])/tot:.1f}%)" for k in K if k != 'probe') +
              f" top_fd={g.get('top_fd')} top_clip={g.get('top_clip')} probe={g['probe']} slots={g['slots']} batches={g['batches']} pairs={g.get('pairs')} survivors={g['survivors']} checked={g['checked']} ntlay={g.get('ntlay')} partitions={g.get('partitions')} tops={g.get('tops')} listed={g.get('listed')} live_buckets={g.get('live_buckets')} padded={g.get('padded_pairs')}")
print()
print('== Screen (s_*)')
for n, (tps, fl, _) in runs('s_*').items():
    if tps: t = tps[-1]; print(f"  {n}: secs={t['secs']} slots={t['slots']} batches={t['batches']} survivors={t['survivors']} checked={t['checked']} {gpu(n)}")
print()
print('== Exactness (x_*)')
for p in sorted(glob.glob(f'{D}/x_*.log')):
    t = open(p, errors='replace').read()
    m = re.search(r'(b\d+ \[.*?), (\d+) partitions: (.*?)survivors (\d+) checked (\d+)', t)
    print(f"  {os.path.basename(p)[:-4]}: " + (m.group(0)[:220] if m else '?') + (' ok' if 'test result: ok' in t else ' NOT OK'))
