"""Predict the M4 sweep's pass/fail per window (diag2.log: 1e5 numbers at the
range start and mid-range, production shape: runs of 128 from the window
start) under a seed-fault hypothesis, by exact simulation: the faulty seed
gives digit arrays S', C' for each run's first n; the steps are exact base-b
additions of the (unaffected) differences, so S'_k = S' + ((n+k)^2 - n^2)
mod b^ls and likewise C'.  Compares histograms with the true ones."""
import sys
from seed_model import chunk16, to_limbs, M32
from params import rng, nd  # noqa
def digits_fault(v, ndig, b, fault):
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            c1 = ((rem << 16) | (x >> 16)) & M32
            q1 = c1 // K
            if fault and k == 0 and ii == 0 and (K & (K - 1)):  # not a power of two
                q1 = x // K       # H1: the >> 16 is lost for the quotient
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = c2 // K; rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b; out.append(chunk - cq * b); chunk = cq
    return out
def from_digits(d, b):
    x = 0
    for di in reversed(d): x = x * b + di
    return x
def uniq(x, b, L):
    s = set()
    for _ in range(L): s.add(x % b); x //= b
    return s
def window(b, start, w, fault_s=True, fault_c=False, run=128):
    lo, hi = rng(b)
    limbs = max(1, -(-(hi - 1).bit_length() // 32))
    ls, lc = nd(lo * lo, b), nd(lo ** 3, b)
    MS, MC = b ** ls, b ** lc
    hist_t, hist_m = {}, {}
    wrong = 0
    for r0 in range(start, start + w, run):
        Sp = from_digits(digits_fault(to_limbs(r0 * r0, 2 * limbs), ls, b, fault_s), b)
        Cp = from_digits(digits_fault(to_limbs(r0 ** 3, 3 * limbs), lc, b, fault_c), b)
        for n in range(r0, min(r0 + run, start + w)):
            t = len(uniq(n * n, b, ls) | uniq(n ** 3, b, lc))
            m = len(uniq((Sp + n * n - r0 * r0) % MS, b, ls) | uniq((Cp + n ** 3 - r0 ** 3) % MC, b, lc))
            hist_t[t] = hist_t.get(t, 0) + 1; hist_m[m] = hist_m.get(m, 0) + 1
            wrong += t != m
    moved = sum(abs(hist_t.get(k, 0) - hist_m.get(k, 0)) for k in set(hist_t) | set(hist_m)) // 2
    return wrong, moved
if __name__ == "__main__":
    import re
    W = []
    for l in open("../m4/diag2.log"):
        m = re.search(r"SWEEP b(\d+) (start|mid) \[(\d+), \+(\d+)\): fd (exact|MISMATCH) \(>= (\d+) moved\)", l)
        if m: W.append((int(m[1]), m[2], int(m[3]), int(m[4]), m[5], int(m[6])))
    only = set(map(int, sys.argv[1:]))
    agree = 0
    for b, what, s, w, verdict, moved in W:
        if only and b not in only: continue
        wr, mv = window(b, s, w)
        pred = "exact" if wr == 0 else "MISMATCH"
        agree += pred == verdict
        print(f"b{b} {what:5s} M4 {verdict:8s} (moved {moved:5d})  model {pred:8s} (wrong {wr:6d}, moved {mv:5d}) {'' if pred == verdict else '<-- differs'}", flush=True)
    print("agree", agree)
