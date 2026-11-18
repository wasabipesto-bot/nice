#!/usr/bin/env python3
"""Price G2 per admissible n at b64-70 from the measured counts (raw/sample/*.txt, [M]) and kernel v10's measured
b64 unit costs (../BENCH.md, [P]), with the changes the kernel needs above 64 as factor bands ([G]).
Compare with the widened-today baseline (today_wide.py, [D]). Output: raw/price_out.txt.

Unit costs at b64 (v10, RTX 3080, BENCH.md):
  prep 0.452 ms per super-unit over 9,298,544 depth-4 roots -> 48.6 ps per root scanned
  bottom side 18.5 ps per stored child (probes-off kernel; TUNE-RESULTS B1: that kernel is phase 1 only, so the
     transpose sits inside the word cost below)
  word 32.0 ps per kept 64-pair word, all-in (full - probes off): skip tests on flat incidences, list, OR, records
  tops 0.104 ns per tested top (B64.1 FD kernel), survivors 20 ps + 6.1 % x 84 ps (prefilter/stage + check)
"""
import glob, math, re, statistics as stt
from facts import facts

C64 = dict(root=48.6, child=18.5, kept=32.0, top=104.0, surv=20.0, check=84.0, passrate=0.061)
POP64 = 17  # slice loads per word in v10 (max top popcount 17, padded)

# factor bands above 64 (low, central, high) [G], each a multiplier on the b64 unit cost
def factors(b, popmax):
    if b <= 64:
        return dict(root=(1, 1, 1), child=(1, 1, 1), word=(1, 1, 1), top=(1, 1, 1), surv=(1, 1, 1), check=(1, 1, 1), other=(1.0, 1.0, 1.08))
    lw = popmax / POP64
    return dict(
        root=(1.5, 2.5, 4.0),     # digits by division by constants, 128-bit r^2/r^3 mod b^(k)
        child=(1.2, 1.5, 2.0),    # 128-bit child masks in phase 1; (c + a d) mod b instead of & 63
        word=(1.0, lw, lw * 1.15),  # LDS-bound: loads per word = padded popcount; +128-bit common test, probe tiling
        top=(1.3, 1.6, 2.0),      # FD tops with 128-bit masks; b62/b64 FD cost ratio 0.17/0.104 = 1.6 [P]
        surv=(1.0, 1.3, 1.6),     # 128-bit prefilter
        check=(2.0, 4.0, 6.0),    # generic full check (CPU: x6-10 above 64, JOIN-PAST-64)
        other=(1.0, 1.04, 1.12),  # launches, host; the review's 3-12 %
    )

def load(path):
    rows = []
    for line in open(path):
        if line.startswith('  PERADM'):
            v = dict(re.findall(r'(\w+) ([\d.e+-]+)', line.split('k ', 1)[1].split(' ', 1)[1]))
            rows.append({k: float(x) for k, x in v.items()})
        elif line.startswith('SU '):
            pm = int(re.search(r'pop_max (\d+)', line)[1]); kf = float(re.search(r'kept \d+ \(([\d.]+)\)', line)[1])
            rows.append({'_popmax': pm, '_keptfrac': kf, '_secs': float(re.search(r'\| ([\d.]+)s$', line.strip())[1])})
    out = []
    for i in range(0, len(rows) - 1, 2):
        r = dict(rows[i + 1]); r.update(rows[i]); out.append(r)
    return out

def cost(r, b, band):
    f = factors(b, r['_popmax'])
    i = {'low': 0, 'central': 1, 'high': 2}[band]
    parts = dict(
        prep=r['roots_scan'] * C64['root'] * f['root'][i],
        bottom=r['children'] * C64['child'] * f['child'][i],
        words=r['kept'] * C64['kept'] * f['word'][i],
        tops=r['tops_tested'] * C64['top'] * f['top'][i],
        surv=r['surv'] * (C64['surv'] * f['surv'][i] + C64['passrate'] * C64['check'] * f['check'][i]),
    )
    tot = sum(parts.values()) * f['other'][i]
    return {k: v * 1e3 for k, v in parts.items()}, tot * 1e3  # fs per admissible n

def main():
    A64 = facts(64)['A']
    today = {64: (6.35, 6.35, 6.35)}
    # widened-today bands from today_wide.py output (fs): (low, central, high)
    for line in open('raw/today_wide.txt'):
        g = re.match(r'b(\d+): A central ([\d.]+) band ([\d.]+)-([\d.]+)', line)
        if g: today[int(g[1])] = (float(g[3]), float(g[2]), float(g[4]))
        g = re.match(r'b70: B ([\d.]+) fs; corrected by A/B range -> ([\d.]+)-([\d.]+); with split/track/pen band ([\d.]+)-([\d.]+)', line)
        if g: today[70] = (float(g[4]), (float(g[2]) + float(g[3])) / 2, float(g[5]))
    YR = 3.156e7
    print("== counts per admissible n, mean over super-units (relative SE of the mean) [M]")
    keys = ['roots_scan', 'children', 'tops_tested', 'tops', 'pairs', 'flat', 'kept', 'words_nz', 'surv']
    res = {}
    for path in sorted(glob.glob('raw/sample/b*_*.txt')):
        g = re.search(r'b(\d+)_(\d+)_(\d+)\.txt', path); b, f0, k = int(g[1]), int(g[2]), int(g[3])
        rs = load(path)
        if not rs: continue
        n = len(rs)
        mean = {kk: stt.mean(r[kk] for r in rs) for kk in keys}
        se = {kk: (stt.stdev(r[kk] for r in rs) / math.sqrt(n) / mean[kk] if n > 1 and mean[kk] else float('nan')) for kk in keys}
        pm = max(r['_popmax'] for r in rs); kf = stt.mean(r['_keptfrac'] for r in rs)
        m = dict(mean); m['_popmax'] = pm
        res[(b, f0, k)] = (m, n, se, kf, rs)
        print(f"b{b} ({f0},{k}) n_su={n} pop_max {pm} kept/flat {kf:.3f} | " + ' '.join(f"{kk} {mean[kk]:.3e}({se[kk]*100:.1f}%)" for kk in keys))
    print()
    print("== G2 cost per admissible n (fs) [D: M counts x P unit costs x G factors]; per-SU spread of the central")
    for (b, f0, k), (m, n, se, kf, rs) in res.items():
        lo = cost(m, b, 'low')[1]; ce_parts, ce = cost(m, b, 'central'); hi = cost(m, b, 'high')[1]
        su = [cost(r, b, 'central')[1] for r in rs]
        print(f"b{b} ({f0},{k}): low {lo:.3f} central {ce:.3f} high {hi:.3f} | SU range {min(su):.3f}-{max(su):.3f} | "
              + ' '.join(f"{p}={v:.3f}" for p, v in ce_parts.items()))
    print()
    print("== table: best shape per base")
    print("base | adm/adm64 | shape | G2 fs/adm (low-central-high) | widened today fs/adm (low-central-high) | ratio (worst-central-best) | 3080 card-years G2 | card-years today")
    for b in (64, 65, 68, 69, 70):
        cands = [(cost(v[0], b, 'central')[1], key) for key, v in res.items() if key[0] == b]
        if not cands: continue
        ce, key = min(cands)
        m = res[key][0]
        lo, hi = cost(m, b, 'low')[1], cost(m, b, 'high')[1]
        # sampling error: widen by 2 SE of the dominant count (kept)
        s = res[key][2]['kept']; s = 0 if math.isnan(s) else s
        lo, hi = lo * (1 - 2 * s), hi * (1 + 2 * s)
        tl, tc, th = today[b]
        A = facts(b)['A']
        cy = lambda fs: A * fs * 1e-15 / YR
        print(f"b{b} | x{A/A64:.2f} | ({key[1]},{key[2]}) | {lo:.2f}-{ce:.2f}-{hi:.2f} | {tl:.1f}-{tc:.1f}-{th:.1f} | "
              f"x{tl/hi:.1f}-x{tc/ce:.1f}-x{th/lo:.1f} | {cy(lo):.2f}-{cy(ce):.2f}-{cy(hi):.2f} | {cy(tl):.1f}-{cy(tc):.1f}-{cy(th):.1f}")

if __name__ == '__main__':
    main()
