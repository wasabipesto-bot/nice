#!/usr/bin/env python3
"""analyze.py LOGDIR: per timing run (s54_*, nm_*): time/rates, mean SM clock and median power over samples with
utilization >= 30 % (busy), share of samples at >= 90 % utilization, power cap; then M/F ratios per round."""
import sys, os, re, json, glob, statistics as st
d = sys.argv[1]
def smi(name):
    rows = []
    for line in open(os.path.join(d, name + '.smi')):
        p = [x.strip() for x in line.split(',')]
        if len(p) < 8: continue
        try: rows.append((float(p[1].split()[0]), float(p[3].split()[0]), float(p[4].split()[0]), int(p[5]), float(p[6].split()[0])))
        except ValueError: pass
    busy = [r for r in rows if r[4] >= 30]
    return (st.mean(r[0] for r in busy) if busy else 0, st.median(r[1] for r in busy) if busy else 0,
            rows[0][2] if rows else 0, len(busy) / max(1, len(rows)), max((r[3] for r in rows), default=0))
out = {}
for f in sorted(glob.glob(os.path.join(d, 's54*.log'))):
    n = os.path.basename(f)[:-4]; t = open(f).read()
    m = re.search(r'secs=([0-9.]+)', t)
    if not m: continue
    clk, pw, cap, busy, tmax = smi(n)
    out[n] = float(m.group(1))
    print(f"{n:12} {float(m.group(1)):8.3f} s  SM {clk:6.0f} MHz  power {pw:6.1f} W (cap {cap:.0f})  busy {busy*100:4.0f}%  max {tmax} C")
for r in (1, 2, 3):
    if f's54_M_r{r}' in out and f's54_F_r{r}' in out:
        print(f"s54 round {r}: M/F = {out[f's54_M_r{r}']/out[f's54_F_r{r}']:.4f}")
nm = {}
for f in sorted(glob.glob(os.path.join(d, 'nm_*.json'))):
    n = os.path.basename(f)[:-5]
    try: j = json.load(open(f))
    except Exception: continue
    clk, pw, cap, busy, tmax = smi(n)
    sc = {s['key']: s.get('rate') for s in j['scenarios'] if s.get('rate')}
    nm[n] = (j.get('score'), sc)
    print(f"{n:10} score {j.get('score')!s:>22}  SM {clk:6.0f} MHz  power {pw:6.1f} W (cap {cap:.0f})  busy {busy*100:4.0f}%  " + '  '.join(f"{k} {v:.4e}" for k, v in sc.items()))
for r in (1, 2, 3, 4):
    a, b = nm.get(f'nm_M_r{r}'), nm.get(f'nm_F_r{r}')
    if a and b:
        ratios = {k: b[1][k] / a[1][k] for k in a[1] if k in b[1]}
        sa = a[0]['nicemark'] if isinstance(a[0], dict) else a[0]; sb = b[0]['nicemark'] if isinstance(b[0], dict) else b[0]
        print(f"NiceMark round {r}: F/M score {sb/sa if sa and sb else float('nan'):.4f}  " + '  '.join(f"{k} x{v:.4f}" for k, v in ratios.items()))
