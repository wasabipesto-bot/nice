#!/usr/bin/env python3
"""E: prefix-suffix join (PSJ) model floor at b62/b64.
cost(f0,k) = N_T + N_B + pairs [flat AND]  or  N_T + N_B + survivors [ideal output-sensitive join]
N_T = W/b^f0 * P(cT(f0+1))  (children of certified parents), cT(f0) = 2(L-f0) - d_T
N_B = b^k * P(2k-2) (whole base, transversal units: built once)
pairs = A * P(cT(f0)) * P(2k);  survivors = A * P(cT(f0) + 2k)
Weights: w_list (list entry, in AND units), w_surv (survivor/check, in AND units)."""
import math, sys
sys.path.insert(0, '.')
from model import P, base_range, nroots
for b, dT in ((62, 2.56), (64, 1.62)):   # dT from measured mean cert digits at f0=3 (17.44 / 18.38 of 20)
    lo, hi = base_range(b); W = hi-lo; R = nroots(b); A = W*R/(b-1); L = 13
    cT = lambda f0: 2*(L-f0) - dT
    for wl, ws, tag in ((1, 1, "unit weights"), (50, 45, "weighted: list 50, survivor 45 AND-units")):
        best_flat = None; best_ov = None; rows = []
        for f0 in range(1, 8):
            for k in range(4, 13):
                if L - f0 + k <= L: continue
                NT = W / b**f0 * P(b, cT(f0+1) if f0+1 < L else 0)
                NB = b**k * P(b, 2*k-2)
                pairs = A * P(b, cT(f0)) * P(b, 2*k)
                surv = A * P(b, min(cT(f0) + 2*k, b-1))
                flat = wl*(NT+NB) + pairs + ws*surv
                ov = wl*(NT+NB) + ws*surv
                if best_flat is None or flat < best_flat[0]: best_flat = (flat, f0, k, NT, NB, pairs, surv)
                if best_ov is None or ov < best_ov[0]: best_ov = (ov, f0, k, NT, NB, pairs, surv)
        today = (wl*(W/b**3*P(b, cT(4)) + b**6*P(b, 10)) + A*P(b, cT(3))*P(b, 12) + ws*A*P(b, cT(3)+12))
        print(f"b={b} [{tag}] model today (f0 3,k 6, no prune) = {today:.2e}")
        for name, x in (("flat-join optimum", best_flat), ("ideal output-sensitive optimum", best_ov)):
            print(f"   {name}: cost={x[0]:.2e} at f0={x[1]} k={x[2]}  N_T={x[3]:.1e} N_B={x[4]:.1e} pairs={x[5]:.1e} surv={x[6]:.1e}  gain vs today x{today/x[0]:.1f}")
