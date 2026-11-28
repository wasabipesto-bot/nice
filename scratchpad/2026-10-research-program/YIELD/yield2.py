#!/usr/bin/env python3
"""Which base is the best buy? Corrected 2026-11-28 (YIELD.2). yield.py (2026-11-26) used E_b = N_b * b!/b^b and so
left out the residue factor R_b of the project's published model
(../2026-08-cost-probability/METHODOLOGY.md section 2: lambda_b = range_b * b!/b^b * R_b * alpha_{b,3}/P6).
This script takes lambda from that model's own code (build.lam) and divides by the admissible work
N_b * R_b/(b-1). Run from anywhere; it changes directory to the model's folder to read alpha3.csv."""
import os, sys
M = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '2026-08-cost-probability')
os.chdir(M); sys.path.insert(0, M)
import build
rows = []
for b in range(58, 81):
    r = build.lam(b)
    if r is None or r[1] == 0: continue
    N, lam = r; R = round(build.residue_density(b) * (b - 1)); adm = N * R / (b - 1)
    rows.append((b, R, N, adm, lam, N and lam / R / build.alpha3_ratio(b)))
ref = next(r for r in rows if r[0] == 64)
print("base  R/(b-1)   n in range  admissible n  lambda (published model)  old E (no R)  lambda per admissible n (b64 = 1)  days at 1.0 fs  days at 3.0 fs")
for b, R, N, adm, lam, old in rows:
    y = (lam / adm) / (ref[4] / ref[3])
    print(f"{b:4d}  {R:2d}/{b-1:<3d}  {N:10.3e}  {adm:10.3e}  {lam:10.3e}               {old:9.2e}   {y:10.4f}                     {adm*1e-15/86400:10.0f}  {adm*3e-15/86400:10.0f}")
l64 = ref[4]; l65 = next(r for r in rows if r[0] == 65)[4]
print(f"\nbases 64 + 65: lambda {l64 + l65:.3e}; base 64 {l64/(l64+l65):.1%}, base 65 {l65/(l64+l65):.1%}")
# per day on two cards (fs per admissible n: RX 9070 XT 2026-11-19; RTX 3060 CUDA at f503a13c)
for card, f64, f65 in (("RX 9070 XT", 1.0, 3.02), ("RTX 3060", 3.28, 6.12)):
    a64 = ref[3]; a65 = next(r for r in rows if r[0] == 65)[3]
    d64 = a64 * f64 * 1e-15 / 86400; d65 = a65 * f65 * 1e-15 / 86400
    print(f"{card}: base 64 {d64:.0f} days, lambda/day {l64/d64:.2e}; base 65 {d65:.0f} days, lambda/day {l65/d65:.2e}; ratio b64/b65 per day {l64/d64/(l65/d65):.1f}; base 65 share of time {d65/(d64+d65):.0%}")
# where does the running total pass 1?
# (bases from 58 on: the frontier; the model's alpha3.csv starts at base 10 and ends where it ends)
cum = 0.0
for b in range(58, 171):
    try: r = build.lam(b)
    except KeyError: print(f"(no low-digit factor for base {b}: stopped)"); break
    if r is None: continue
    cum += r[1]
    if b in (64, 65, 70, 80, 90, 100, 110, 120) or (cum >= 1 and cum - r[1] < 1):
        print(f"cumulative lambda, bases 58..{b}: {cum:.4g}")
    if cum >= 1 and cum - r[1] < 1: break
