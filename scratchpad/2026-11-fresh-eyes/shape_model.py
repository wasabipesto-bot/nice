#!/usr/bin/env python3
"""Projection of the join's time per b62 base at other macro shapes, as a fraction of today's.

Today's shares of a b62 1e17 field on a 3080 (L51, after #249): base, AND, survivor path
(walk + prefilter + stage), check, top FD, setup. Counts per admissible n from mc_counts.py.
Knobs are the unknowns the N1 measurements are meant to replace:
  and_digit_exp : how the AND-only cost per pair scales with the entry's digit count (1 = linear)
  word          : 32 or 64 (pairs per chunk word; 64 halves the AND-only cost if it is load-bound)
  base_scale    : how the per-wave base cost per pair changes in the new tile shape
  child_cert    : cost of a child-only top certificate relative to a full FD step (f0 3 only)
  surv_cost     : cost per AND survivor relative to today (wider prefilter arithmetic at k 9)
"""
import itertools
TODAY = dict(base=0.11, and_=0.15, surv=0.30, check=0.12, tops=0.23, setup=0.05, other=0.04)
# today's counts per admissible n (f0 3, k 6, field prune at ~b^9.5): pairs, AND survivors; per base: top tests
C0 = dict(pairs=8.0e-3, surv=2.03e-4, tops=8.5e15, digits=12)
SHAPES = {
    "f0 4, k 9":  dict(pairs=7.98e-3, surv=2.67e-5, tops=1.4e14, digits=18, child=False),
    "f0 3, k 9":  dict(pairs=4.28e-3, surv=1.33e-5, tops=5.0e15, digits=18, child=True),
    "f0 4, k 8":  dict(pairs=1.486e-2, surv=8.0e-5, tops=1.4e14, digits=16, child=False),
    "f0 4, k 10": dict(pairs=4.10e-3, surv=6.7e-6, tops=1.4e14, digits=20, child=False),
}
def project(sh, and_digit_exp=1.0, word=32, base_scale=1.0, child_cert=1.0, surv_cost=1.3, bottoms=0.02):
    s = SHAPES[sh]
    pr = s["pairs"] / C0["pairs"]
    and_ = TODAY["and_"] * pr * (s["digits"] / C0["digits"]) ** and_digit_exp * (32 / word)
    base = TODAY["base"] * pr * base_scale
    sv = s["surv"] / C0["surv"]
    surv = TODAY["surv"] * sv * surv_cost
    check = TODAY["check"] * sv
    tops = TODAY["tops"] * s["tops"] / C0["tops"] * (child_cert if s["child"] else 1.0)
    total = and_ + base + surv + check + tops + bottoms + 0.01
    return total, dict(AND=and_, base=base, surv=surv, check=check, tops=tops)
if __name__ == "__main__":
    print(f"{'shape':11} {'word':>4} {'child':>5} {'frac of today':>13} {'speedup':>8}   breakdown")
    for sh, word, cc in itertools.product(SHAPES, (32, 64), (1.0, 0.33)):
        if cc != 1.0 and not SHAPES[sh]["child"]: continue
        t, br = project(sh, word=word, child_cert=cc)
        print(f"{sh:11} {word:>4} {cc:>5} {t:13.3f} {1/t:8.2f}   " + " ".join(f"{k} {v:.3f}" for k, v in br.items()))
    print("\nsensitivity, f0 4 k 9, u64: AND exponent 0.5/1.0, base x0.5/x1/x1.5")
    for e, bs in itertools.product((0.5, 1.0), (0.5, 1.0, 1.5)):
        t, _ = project("f0 4, k 9", and_digit_exp=e, word=64, base_scale=bs)
        print(f"  exp {e} base x{bs}: speedup {1/t:.2f}")
