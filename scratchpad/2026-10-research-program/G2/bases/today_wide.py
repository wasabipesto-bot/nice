#!/usr/bin/env python3
"""Widened-today baseline per admissible n, b65-70, relative to b64. [D]
Method A (b65/68/69): exp/join-wide's measured CPU base averages (JOIN-PAST-64-PROPOSAL.md, core-s per number,
u128 masks) converted to per admissible n, ratio to b64 (6.0e-12, u64), times split-scan factor 0.86-0.91,
times the GPU's divergence track 1.0-1.3 and an unmeasured device third-word penalty 1.0-1.4 (the proposal's band).
Method B (all, needed for b70): stage model of today's b64 GPU profile (N22 shares), each stage scaled by its count
driver with the digit model + measured P_T(3) (raw/ptop_today36.txt); checked against method A at b65/68/69."""
import math, re
from facts import facts
def P(b, m):
    m = float(m); n = int(m); f = m - n
    v = math.prod(1 - i / b for i in range(n))
    return v * (1 - n / b) ** f
PT = {}; CT = {}
for line in open('raw/ptop_today36.txt'):
    g = re.match(r'PTOP b(\d+) f0 3 k 6 .* P_T ([\d.]+) .* mean cert digits ([\d.]+)', line)
    PT[int(g[1])] = float(g[2]); CT[int(g[1])] = float(g[3])
F = {b: facts(b) for b in (64, 65, 68, 69, 70)}
TODAY64 = 6.35  # fs per adm, same-session main, BENCH.md [M]
cpu = {64: 6.0e-12, 65: 2.66e-12, 68: 3.15e-12, 69: 2.29e-12}  # [M, Oct, Haswell]
A = {}
for b in (65, 68, 69):
    r = (cpu[b] * (b - 1) / F[b]['R']) / (cpu[64] * 63 / 8)
    A[b] = (r * 0.86, r * 0.91 * 1.3 * 1.4, r)
shares = dict(tops=13, surv=26 + 11 + 11, pairs=15 + 7, pern=17)  # b64 N22 profile, %
def drivers(b):
    f = F[b]; R = f['R']
    pern = (b - 1) / R
    tops = (b - 1) / (R * b ** 3) * 1.0
    pairs = PT[b] * P(b, 12)
    surv = pairs * P(b, CT[b] + 12) / (P(b, CT[b]) * P(b, 12))
    return dict(tops=tops, surv=surv, pairs=pairs, pern=pern)
d64 = drivers(64)
print("b   | method A CPU ratio (raw; band split..split*1.3*1.4) | method B stage model ratio | B stage ratios tops/surv/pairs/pern")
B = {}
for b in (65, 68, 69, 70):
    d = drivers(b)
    rr = {k: d[k] / d64[k] for k in d}
    B[b] = sum(shares[k] * rr[k] for k in shares) / sum(shares.values())
    a = A.get(b)
    astr = f"x{a[2]:.2f} (x{a[0]:.2f}-x{a[1]:.2f})" if a else "n/a (no wide-join data: n^3 > W4)"
    print(f"b{b} | {astr:38s} | x{B[b]:.2f} | " + ' '.join(f"{rr[k]:.2f}" for k in ('tops', 'surv', 'pairs', 'pern')))
print()
print("widened-today GPU cost per admissible n (fs) = 6.35 x ratio")
for b in (65, 68, 69):
    a = A[b]; print(f"b{b}: A central {TODAY64*a[2]:.1f} band {TODAY64*a[0]:.1f}-{TODAY64*a[1]:.1f}; B {TODAY64*B[b]:.1f}")
# b70: B, scaled by B's error against A where A exists
errs = [A[b][2] / B[b] for b in (65, 68, 69)]
lo, hi = min(errs), max(errs)
print(f"B vs A (A/B) at b65/68/69: {', '.join(f'{e:.2f}' for e in errs)}")
print(f"b70: B {TODAY64*B[70]:.1f} fs; corrected by A/B range -> {TODAY64*B[70]*lo:.1f}-{TODAY64*B[70]*hi:.1f}; with split/track/pen band {TODAY64*B[70]*lo*0.86:.1f}-{TODAY64*B[70]*hi*0.91*1.3*1.4:.1f}")
