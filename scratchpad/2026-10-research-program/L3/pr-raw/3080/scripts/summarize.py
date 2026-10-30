#!/usr/bin/env python3
"""Summarize the protocol logs: P1 NiceMark detailed GPU, P2 2e9 windows, P4 1e10 windows.
Medians over rounds; spread = lowest and highest round relative to the median.
dmon: median power (W) and SM clock (MHz) over the samples with power > 100 W."""
import glob, os, re, statistics as st, sys
D = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..', 'logs', 'proto')
TREES = ['main', 'rb', 'fd']

def spread(v):
    m = st.median(v)
    return m, (min(v) / m - 1) * 100, (max(v) / m - 1) * 100

def dmon(path):
    pw, clk = [], []
    for line in open(path):
        f = line.split()
        if len(f) >= 7 and f[0][0].isdigit() and ':' in f[0]:
            try:
                p, c = float(f[2]), float(f[6])
            except ValueError:
                continue
            if p > 100:
                pw.append(p); clk.append(c)
    if not pw:
        return None
    return st.median(pw), min(clk), st.median(clk), max(clk), len(pw)

def fmt_rounds(v, e=True):
    return ' '.join((f'{x:.3e}' if e else f'{x:.0f}') for x in v)

# P1
print('## P1 NiceMark detailed GPU (150 s)')
p1 = {}
for t in TREES:
    for r in (1, 2, 3):
        p = f'{D}/p1_{t}_r{r}.txt'
        if not os.path.exists(p):
            continue
        txt = open(p).read()
        rows = {}
        for m in re.finditer(r'^\s*(b\d+_detailed\S*)\s+.*?([\d.]+e\d+|[\d,.]+)\s*$', txt, re.M):
            pass
        for line in txt.splitlines():
            m = re.match(r'\s*(b\d+_detailed)\s', line)
            if m:
                rows[m.group(1)] = line
        score = re.search(r'NiceMark: (\d+)', txt)
        backend = re.search(r'GPU initialized: (.*)', txt)
        p1.setdefault(t, []).append((rows, score.group(1) if score else None, backend.group(1) if backend else None))
for t, runs in p1.items():
    for k, (rows, score, be) in enumerate(runs):
        print(t, k + 1, score, be)
        for key, line in rows.items():
            print('   ', line.strip())
meds = {}
for key in ('b40_detailed', 'b50_detailed', 'score'):
    for t in TREES:
        if t not in p1:
            continue
        v = []
        for rows, score, _ in p1[t]:
            if key == 'score':
                if score:
                    v.append(float(score))
            elif key in rows:
                v.append(float(rows[key].split()[-2]))
        if not v:
            continue
        m, lo, hi = spread(v)
        meds[(key, t)] = m
        rel = ''
        if ('%s' % key, 'main') in meds and t != 'main':
            rel += f" x{m / meds[(key, 'main')]:.3f} vs main"
        if (key, 'rb') in meds and t == 'fd':
            rel += f" x{m / meds[(key, 'rb')]:.3f} vs rb"
        print(f"P1 {key} {t:>4}: {fmt_rounds(v, key != 'score')} | median {m:.4g} ({lo:+.1f}/{hi:+.1f} %){rel}")

def fdbench(prefix):
    out = {}
    for p in sorted(glob.glob(f'{D}/{prefix}_*_b*_r*.txt')):
        m = re.search(rf'{prefix}_(\w+)_b(\d+)_r(\d)\.txt$', p)
        if not m or m.group(1) not in TREES:
            continue
        t, b, r = m.group(1), int(m.group(2)), int(m.group(3))
        rates, fps = [], set()
        for line in open(p):
            mm = re.search(r'rate ([\d.e+]+) misses (\d+) fp (\w+)', line)
            if mm:
                rates.append(float(mm.group(1))); fps.add(mm.group(3))
        if rates:
            d = dmon(f'{D}/{prefix}_dmon_{t}_b{b}_r{r}.txt')
            out.setdefault((b, t), []).append((st.median(rates), rates, fps, d))
    return out

for prefix, title in (('p2', 'P2 2e9-number windows'), ('p4', 'P4 1e10-number windows')):
    print(f'\n## {title}: median of reps per round; rounds; median (spread)')
    res = fdbench(prefix)
    for b in sorted({b for b, _ in res}):
        base_med = None
        for t in TREES:
            if (b, t) not in res:
                continue
            v = [x[0] for x in res[(b, t)]]
            m, lo, hi = spread(v)
            if t == 'main':
                base_med = m
            fps = set().union(*[x[2] for x in res[(b, t)]])
            ds = [x[3] for x in res[(b, t)] if x[3]]
            dtxt = ''
            if ds:
                dtxt = f" | {st.median(d[0] for d in ds):.0f} W, SM {min(d[1] for d in ds):.0f}-{max(d[3] for d in ds):.0f} MHz (median {st.median(d[2] for d in ds):.0f})"
            x = f' x{m / base_med:.2f}' if base_med else ''
            print(f'b{b} {t:>4}: {fmt_rounds(v)} | {m:.3e} ({lo:+.1f}/{hi:+.1f} %){x} fp {",".join(sorted(fps))}{dtxt}')

print('\n## P1 dmon (samples > 100 W)')
for t in TREES:
    for r in (1, 2, 3):
        p = f'{D}/p1_dmon_{t}_r{r}.txt'
        if os.path.exists(p):
            d = dmon(p)
            if d:
                print(f'{t} r{r}: power median {d[0]:.0f} W, SM clock min {d[1]:.0f} median {d[2]:.0f} max {d[3]:.0f} MHz over {d[4]} s')

print('\n## P1 dmon split in halves (first half = b40_detailed, second = b50_detailed; samples > 100 W)')
for t in TREES:
    rows = []
    for r in (1, 2, 3):
        p = f'{D}/p1_dmon_{t}_r{r}.txt'
        if not os.path.exists(p):
            continue
        pw, clk = [], []
        for line in open(p):
            f = line.split()
            if len(f) >= 7 and ':' in f[0]:
                try:
                    pp, c = float(f[2]), float(f[6])
                except ValueError:
                    continue
                if pp > 100:
                    pw.append(pp); clk.append(c)
        h = len(pw) // 2
        # drop 3 samples around the switch
        a, b = slice(2, h - 2), slice(h + 2, len(pw) - 2)
        rows.append((st.median(pw[a]), st.median(clk[a]), st.median(pw[b]), st.median(clk[b])))
    if rows:
        print(f"{t:>4}: b40 {' '.join(f'{x[0]:.0f}W/{x[1]:.0f}MHz' for x in rows)} | b50 {' '.join(f'{x[2]:.0f}W/{x[3]:.0f}MHz' for x in rows)}")
