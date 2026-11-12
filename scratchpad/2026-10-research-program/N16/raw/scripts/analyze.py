#!/usr/bin/env python3
"""N16 analysis: python3 -I analyze.py OUTDIR [REF_MHZ REF_W]. Every table of the window (and of the box's runs).

Runs are $OUT/<prefix><mode>_<tag>_r<round>.log with a .gpu sample file beside each. Per run: wall secs of the timed
field(s), counts, launches (HOSTACC) and the medians of clock / power / busy over samples at >= 80 % busy. A run is
flagged OFF-POINT if its clock is below 97 % or its power below 90 % of the tag's base runs (mode c*/info) median, or of
REF_MHZ / REF_W when given (the card's operating point: 3150 MHz / 300 W on the RX 9070 XT yesterday).

Doubling modes: cost(part) = T(mode) - T(base), base = mean of the same round's base runs of that tag ([D]); the part's
share = cost / T(base). Counts must equal the base's (exact); a removal mode's counts differ by design (timing only).
"""
import sys, re, glob, os, statistics as st
D = sys.argv[1]
REF = (float(sys.argv[2]), float(sys.argv[3])) if len(sys.argv) > 3 else None
PAIRS = {'b62': 2.7898e13, 'b60': 4.0363e12}  # [M] N13 profile: b62 1e17 at 0.45; b60 1e16 at 0.55 (one field)
def kv(l): return dict(re.findall(r'(\w+)=([-\w.:]+)', l))
def gpu(p):
    sc, pw, bz = [], [], []
    if not os.path.exists(p): return None
    for l in open(p):
        d = kv(l)
        try:
            b = float(d['busy'])
        except Exception:
            continue
        bz.append(b)
        if b >= 80:
            try: sc.append(float(d['sclk'])); pw.append(float(d['pw']))
            except Exception: pass
    if not sc: return (0, 0, st.median(bz) if bz else 0, len(bz))
    return (st.median(sc), st.median(pw), st.median(bz), len(bz))
runs = []
for p in sorted(glob.glob(f'{D}/*_r[0-9].log')):
    n = os.path.basename(p)[:-4]
    m = re.match(r'(.*?)_(b\d\d)_r(\d)$', n)
    if not m: continue
    head, tag, r = m.groups()
    t = open(p, errors='replace').read()
    tp = [kv(l) for l in t.splitlines() if 'JOIN THROUGHPUT' in l]
    ha = [kv(l) for l in t.splitlines() if l.startswith('HOSTACC')]
    if not tp:
        print(f'  {n}: no result ({"panicked" if "panicked" in t else "incomplete"})'); continue
    g = gpu(p[:-4] + '.gpu') or (0, 0, 0, 0)
    mode = head.split('_', 1)[1] if head.startswith(('DM_', 'DD_')) else head
    runs.append(dict(n=n, mode=mode, tag=tag, r=int(r), secs=float(tp[-1]['secs']), surv=int(tp[-1]['survivors']),
                     chk=int(tp[-1]['checked']), batches=float(tp[-1]['batches']), slots=tp[-1]['slots'],
                     mhz=g[0], w=g[1], busy=g[2], ns=g[3], ha=ha[-1] if ha else {}, bin=head))
isbase = lambda m: re.fullmatch(r'(c\d?|info|c_nohost)', m) is not None
for tag in sorted({x['tag'] for x in runs}):
    R = [x for x in runs if x['tag'] == tag and not x['n'].startswith(('DM_', 'DD_'))]
    if not R: continue
    B = [x for x in R if isbase(x['mode'])]
    if not B: continue
    ref = REF or (st.median(x['mhz'] for x in B), st.median(x['w'] for x in B))
    cnt = (B[0]['surv'], B[0]['chk'])
    print(f'== {tag}: base runs ' + ', '.join(f"{x['n']} {x['secs']:.2f}s {x['mhz']:.0f}MHz {x['w']:.0f}W" for x in B) +
          f'  | operating point {ref[0]:.0f} MHz {ref[1]:.0f} W | base counts {cnt[0]} / {cnt[1]}')
    if len(B) > 1:
        bs = [x['secs'] for x in B]
        print(f'   base spread: mean {st.mean(bs):.2f} s, min {min(bs):.2f}, max {max(bs):.2f} ({100*(max(bs)-min(bs))/st.mean(bs):.1f} %)')
    print(f"   {'mode':10s} {'r':>2s} {'secs':>8s} {'MHz':>6s} {'W':>5s} {'busy':>4s} {'Δs vs base':>10s} {'% base':>7s} {'ps/pair':>7s}  counts  batches launches  point")
    by = {}
    for x in R:
        rb = [y['secs'] for y in B if y['r'] == x['r']] or [y['secs'] for y in B]
        base = st.mean(rb)
        d = x['secs'] - base
        ex = 'exact' if (x['surv'], x['chk']) == cnt else f"DIFF {x['surv']}/{x['chk']}"
        off = 'ok' if (x['mhz'] >= 0.97 * ref[0] and x['w'] >= 0.90 * ref[1]) else 'OFF-POINT'
        pp = f"{1e12*d/PAIRS[tag]:7.3f}" if tag in PAIRS and not isbase(x['mode']) else '      -'
        la = x['ha'].get('launches', '-')
        print(f"   {x['mode']:10s} {x['r']:2d} {x['secs']:8.2f} {x['mhz']:6.0f} {x['w']:5.0f} {x['busy']:4.0f} {d:+10.2f} {100*d/base:+6.1f}% {pp}  {ex:6s} {x['batches']:7.0f} {la:>8s}  {off}")
        by.setdefault(x['mode'], []).append(100 * d / base)
    print('   per mode, mean % of base over rounds: ' + ', '.join(f"{m} {st.mean(v):+.1f}% (n={len(v)})" for m, v in by.items() if not isbase(m)))
    # host accounting
    H = [x for x in R if x['ha']]
    if H:
        print('   host accounting (process sums over the timed fields):')
        for x in H:
            h = x['ha']; b = max(float(h.get('batches', 1)), 1)
            print(f"     {x['n']:22s} batches={h.get('batches')} launches={h.get('launches')} fences_pending={h.get('fences_pending')} reads={h.get('reads')} "
                  f"encode={h.get('encode_s')}s fence={h.get('fence_s')}s wait={h.get('wait_s')}s read={h.get('read_s')}s "
                  f"| per batch encode {1e3*float(h.get('encode_s', 0))/b:.3f} ms wait {1e3*float(h.get('wait_s', 0))/b:.3f} ms | wall {x['secs']:.2f}s")
    # launches: secs against batches (modes c, s1, s2, s4, vram)
    L = [x for x in R if re.fullmatch(r'(c\d?|info|s\d|vram)', x['mode'])]
    if len({x['batches'] for x in L}) >= 2:
        xs = [x['batches'] for x in L]; ys = [x['secs'] for x in L]
        mx, my = st.mean(xs), st.mean(ys)
        sl = sum((a - mx) * (b - my) for a, b in zip(xs, ys)) / sum((a - mx) ** 2 for a in xs)
        print(f'   launches: secs = {my - sl*mx:.2f} + {1e3*sl:.3f} ms x batches  (fit over {len(L)} runs: ' +
              ', '.join(f"{x['mode']} {x['batches']:.0f}:{x['secs']:.2f}" for x in L) + ')')
    print()
DM = [x for x in runs if x['n'].startswith(('DM_', 'DD_'))]
if DM:
    print('== Task D: main (M) against exp/n14-wgpu-dense-plan (D)')
    for tag in sorted({x['tag'] for x in DM}):
        for r in sorted({x['r'] for x in DM}):
            m = [x for x in DM if x['tag'] == tag and x['r'] == r and x['n'].startswith('DM_')]
            d = [x for x in DM if x['tag'] == tag and x['r'] == r and x['n'].startswith('DD_')]
            if m and d:
                print(f"   {tag} r{r}: M {m[0]['secs']:.2f}s ({m[0]['mhz']:.0f}MHz {m[0]['w']:.0f}W, {m[0]['batches']:.0f} batches) "
                      f"D {d[0]['secs']:.2f}s ({d[0]['mhz']:.0f}MHz {d[0]['w']:.0f}W, {d[0]['batches']:.0f} batches) x{m[0]['secs']/d[0]['secs']:.3f} "
                      f"counts {'same' if (m[0]['surv'], m[0]['chk']) == (d[0]['surv'], d[0]['chk']) else 'DIFFER'}")
X = sorted(glob.glob(f'{D}/x*_*.log'))
if X:
    print('== Exactness (dense compare against the CPU join)')
    for p in X:
        t = open(p, errors='replace').read()
        m = re.search(r'partitions: (.*)', t)
        print(f"   {os.path.basename(p)[:-4]:18s} {'ok' if 'test result: ok' in t else 'NOT OK'}  {m.group(1)[:150] if m else ''}")
I = [l for p in glob.glob(f'{D}/*.log') for l in open(p, errors='replace') if l.startswith(('EXP_INFO', 'EXP_PLANE'))]
if I:
    print('== Device lines'); [print('   ' + l.rstrip()) for l in sorted(set(I))]
