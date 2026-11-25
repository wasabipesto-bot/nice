#!/usr/bin/env python3
"""analyze_mo.py OUT [main_base_fs]: window 2's tables from the logs of go_mo.sh. Per timing run: the fields' fs per
admissible n (warm-up field t 4095 dropped), the clock and power over the 0.5 s samples at >= 80 % busy; main's
bracket fields 2 and 6 against that morning's 90.83 s and 100.41 s (WINDOW-RESULTS.md), which scales the base mean
4.707 fs; the ratio; the stage profile per slice from the cumulative stops against the step-4S model's bands; the
sampled check's cost. Prints the outcome line of WINDOW-PLAN-2.md. python3 -I analyze_mo.py OUT
Window 3 (2026-11-25): also x_485 (a (4, 8, 5) field with the sampled check), the counts against window 2's logs
(REF = $REF or G2/build4s/window_1119 beside this directory), and task 3's w65_cc / w65_nc."""
import sys, os, re, glob, statistics as st

OUT = sys.argv[1]
BASE = float(sys.argv[2]) if len(sys.argv) > 2 else 4.707
MORNING = {'main_f2': 90.83, 'main_f6': 100.41}
# the step-4S model's bands per slice (ms, G2/build4s/model_4s.py --tag=head), cumulative stops
MODEL = {'tops (1)': (0.12, 0.24), 'parents (2-1)': (0.31, 0.35), 'main kernel (3-2)': (3.09, 3.35),
         'expansion (5-3)': (0.43, 0.56), 'check and the rest (6-5)': (0.055, 0.13)}
MODEL_SLICE = (4.01, 4.64)   # model_4s.py --tag=h5l (parents shared across digit 8)

def log(n):
    p = os.path.join(OUT, n + '.log')
    return open(p).read() if os.path.exists(p) else None

def clock(n):
    p = os.path.join(OUT, n + '.gpu')
    if not os.path.exists(p):
        return '(no samples)'
    rows = [dict(re.findall(r'(\w+)=([0-9.]+)', l)) for l in open(p)]
    busy = [r for r in rows if float(r.get('busy', 0)) >= 80]
    if not busy:
        return f'(0 busy samples of {len(rows)})'
    sc = st.median(float(r.get('sclk', 0)) for r in busy)
    pw = st.median(float(r.get('pw', 0)) for r in busy)
    return f'{sc:.0f} MHz, {pw:.0f} W ({len(busy)} busy samples)'

print('## Exactness')
for n in sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(OUT, '[xp]_*.log'))):
    t = log(n)
    ok = (re.search(r'test result: ok\. \d+ passed; 0 failed', t) is not None) or (
        n in ('x_496', 'x_485') and re.search(r'^SAMPLE .*equal', t, re.M) is not None and ' rc=0' in t)
    w = re.search(r' W (\d+)', t)
    print(f"- {n}: {'PASS' if ok else 'FAIL'}, W {w.group(1) if w else '?'}; {'; '.join(sorted(set(re.findall(r'(slice \d+: device tops = host tops \(\d+\)|COMPILE-ONLY[^\n]*)', t))))[:300]}")

def fields(n):
    t = log(n)
    if t is None:
        return None
    return [(int(a), float(b), float(c), int(d), int(e)) for a, b, c, d, e in
            re.findall(r'FIELD t (\d+) v .*?: ([0-9.]+) s = ([0-9.]+) fs per admissible n \| slices \d+ survivors (\d+) checked (\d+)', t)]

print('\n## Whole fields (fs per admissible n; warm-up t 4095 dropped)')
runs = {}
for n in sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(OUT, 'b_r*.log'))):
    f = [x for x in (fields(n) or []) if x[0] != 4095]
    if not f:
        print(f'- {n}: no fields'); continue
    m = st.mean(x[2] for x in f)
    runs[n] = m
    print(f"- {n}: {m:.4f} fs ({min(x[2] for x in f):.4f}-{max(x[2] for x in f):.4f}) over {len(f)} fields; {clock(n)}")
cnt = {}
for n in runs:
    for x in fields(n):
        cnt.setdefault(x[0], set()).add((x[3], x[4]))
diff = [t for t, v in cnt.items() if len(v) > 1]
print(f"- survivors and checked equal field for field across runs: {'yes' if not diff else 'NO: ' + str(diff)}")
REF = os.environ.get('REF') or os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'build4s', 'window_1119')
rc = {}
for p in glob.glob(os.path.join(REF, 'b_r*.log')):
    for a, b, c, d, e in re.findall(r'FIELD t (\d+) v .*?: ([0-9.]+) s = ([0-9.]+) fs per admissible n \| slices \d+ survivors (\d+) checked (\d+)', open(p).read()):
        rc.setdefault(int(a), set()).add((int(d), int(e)))
bad = [t for t in cnt if t in rc and cnt[t] != rc[t]]
print(f"- counts against 2026-11-19 ({len([t for t in cnt if t in rc])} fields compared): {'equal' if not bad else 'DIFFER: ' + str(bad)}")

print('\n## Main bracket')
drift = []
for n, ref in MORNING.items():
    t = log(n)
    s = re.search(r'secs=([0-9.]+)', t or '')
    if s:
        drift.append(float(s.group(1)) / ref)
        r = open(os.path.join(REF, n + '.log')).read() if os.path.exists(os.path.join(REF, n + '.log')) else ''
        c1 = re.findall(r'survivors=(\d+) checked=(\d+)', t); c0 = re.findall(r'survivors=(\d+) checked=(\d+)', r)
        print(f"- {n}: {float(s.group(1)):.2f} s (morning of 11-18 {ref} s, x{float(s.group(1)) / ref:.4f}); {clock(n)}; counts {c1} vs 11-19 {'equal' if c1 == c0 else 'DIFFER ' + str(c0)}")
base = BASE * (st.mean(drift) if drift else 1.0)
print(f"- main base mean: {BASE} x {st.mean(drift) if drift else 1.0:.4f} = {base:.3f} fs")

g2 = st.median(runs.values()) if runs else None
if g2:
    print(f"\n## Ratio: {base:.3f} / {g2:.4f} = x{base / g2:.2f} (median of {len(runs)} runs; min-run x{base / min(runs.values()):.2f}); "
          f"model x{BASE / (MODEL_SLICE[1] * 1e-3 / 4.4679e12 * 1e15):.2f}-{BASE / (MODEL_SLICE[0] * 1e-3 / 4.4679e12 * 1e15):.2f} against 4.707")

print('\n## Stage profile, field 77777 (ms per slice = s per field / 4,096; cumulative stops)')
cum = {}
for s_ in (1, 2, 3, 5, 6):
    t = log(f's_{s_}') or ''
    k = re.search(r'slices per field Some\((\d+)\)', t)
    nsl = int(k.group(1)) if k else 4096   # a dry run's --slices K
    f = [x for x in (fields(f's_{s_}') or []) if x[0] == 77777]
    if not f:
        m = re.search(r'FIELD t 77777 timing stop \d+: ([0-9.]+) s', t)
        if m:
            cum[s_] = float(m.group(1)) / nsl * 1e3
    else:
        cum[s_] = f[0][1] / nsl * 1e3
prev = {2: 1, 3: 2, 5: 3, 6: 5}
names = {1: 'tops (1)', 2: 'parents (2-1)', 3: 'main kernel (3-2)', 5: 'expansion (5-3)', 6: 'check and the rest (6-5)'}
for s_ in (1, 2, 3, 5, 6):
    if s_ not in cum or (s_ in prev and prev[s_] not in cum):
        print(f"- {names[s_]}: missing"); continue
    v = cum[s_] - (cum[prev[s_]] if s_ in prev else 0)
    lo, hi = MODEL[names[s_]]
    flag = 'inside' if lo * 0.9 <= v <= hi * 1.1 else ('BELOW' if v < lo else 'ABOVE')
    print(f"- {names[s_]}: {v:.3f} ms (model {lo}-{hi}: {flag}); {clock('s_' + str(s_))}")
if 6 in cum:
    print(f"- slice: {cum[6]:.3f} ms (model {MODEL_SLICE[0]}-{MODEL_SLICE[1]})")

t = log('b_cc') or ''
m = re.search(r'SAMPLE t \d+ slice (\d+): equal; field ([0-9.]+) s, CPU thread ([0-9.]+) s, waited ([0-9.]+) s for it, device rerun ([0-9.]+) s', t)
print('\n## Sampled CPU check: ' + (f"slice {m.group(1)} equal; field {m.group(2)} s, CPU thread {m.group(3)} s, host waited {m.group(4)} s, rerun {m.group(5)} s" if m else 'missing or failed'))
for n in ('w_65', 'w65_cc', 'w65_nc'):
    t = log(n)
    if t:
        print(f'\n## Wide b65 ({n}; {clock(n)})')
        for l in t.splitlines():
            m = re.match(r'WIDE b65 t (\d+) .*?: ([0-9.]+) s = ([0-9.]+) fs per admissible n \| slices \d+ survivors (\d+) checked (\d+)', l)
            if m:
                print(f'- t {m.group(1)}: {m.group(3)} fs ({m.group(2)} s), survivors {m.group(4)} checked {m.group(5)}')
            elif 'sampled CPU check' in l or l.startswith('TOTAL'):
                print('- ' + l[:200])

if g2:
    r = base / g2
    print('\nOUTCOME: ' + ('T1 (>= x4.54, the model\'s band or above)' if r >= 4.54 else
                          'T2 (x4.0-4.54: below the band, above the 3080\'s x3.9: the stage above its band names the next piece)' if r >= 4.0 else
                          'T3 (< x4.0: the library path loses more on the card than on CUDA: stop and report the stage profile)'))
