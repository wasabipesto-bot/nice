#!/usr/bin/env python3
"""NM: the GPU check kernel's gate on a sample of checked survivors (raw/sample.txt,
lines "base n"): the gate takes n^2's digits and n^3's low 2*gl digits (gl = 5 limbs,
GATE_DIGITS = 10) and passes when they are distinct. With a tolerance m it would pass
when at most m of them repeat. Prints, per base, the pass rate at m = 0..3 and the
fraction of planes of W lanes with at least one passing lane (the planes that build
the rest of n^3), and the full repeat histogram of the sample.
"""
import sys
from collections import Counter, defaultdict

def digits(x, b):
    out = []
    while x:
        x, r = divmod(x, b)
        out.append(r)
    return out

def main(path):
    by = defaultdict(list)
    for line in open(path):
        b, n = line.split()
        by[int(b)].append(int(n))
    for b in sorted(by):
        ns = by[b]
        gate_rep = Counter()
        full_rep = Counter()
        joint = Counter()
        for n in ns:
            d2 = digits(n * n, b)
            d3 = digits(n ** 3, b)
            g = d2 + d3[:10]
            gr = len(g) - len(set(g))
            fr = len(d2) + len(d3) - len(set(d2 + d3))
            gate_rep[gr] += 1
            full_rep[fr] += 1
            joint[(min(gr, 4), min(fr, 4))] += 1
        N = len(ns)
        print(f"b{b}: {N} sampled checked survivors (1/1024 of those checked)")
        for m in range(4):
            p = sum(c for r, c in gate_rep.items() if r <= m) / N
            planes = {W: 1 - (1 - p) ** W for W in (32, 64)}
            print(f"  gate tolerance {m}: pass {p:.3e}; planes with a passing lane: W32 {planes[32]:.3e}, W64 {planes[64]:.3e}")
        print("  gate repeats histogram:", sorted(gate_rep.items())[:12])
        print("  full repeats histogram:", sorted(full_rep.items())[:12])
        print("  joint (gate<=4, full<=4):", {k: v for k, v in sorted(joint.items()) if k[1] <= 4})

if __name__ == "__main__":
    main(sys.argv[1])
