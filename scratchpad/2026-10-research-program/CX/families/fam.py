#!/usr/bin/env python3
"""CX round 2: do algebraically structured n come closer to nice than random n?  (director, 2026-11-25)

For each base b with a range, evaluate families of structured n inside the range and record, per family, the
largest number D of distinct digits among the b digits of n^2 and n^3 (nice = b), against random n of the same
range (mean, sd, and the best of as many random draws as the family has members).

Families:
  rat   n = floor(P*b^K/Q) + c   Q in {b-1, (b-1)^2, (b-1)^3, b+1, (b+1)^2, b^2-1, b^2+1, b^2+b+1, b^2-b+1,
                                       2..40}, P structured, c in -2..2
  lin   digits of n are (alpha*i + beta) mod b            (all alpha, beta)
  sq    n = isqrt(X) or isqrt(X)+1, X with digits (alpha*i+beta) mod b of n^2's length (n^2's top half is then X's)
  cb    n = icbrt(Y) or +1, Y with digits (alpha*i+beta) mod b of n^3's length
usage: fam.py B_LO B_HI [seed]   -> one line per (base, family) on stdout
"""
import sys, math, random
def icbrt(x):
    lo, hi = 0, 1 << ((x.bit_length() + 2) // 3 + 1)
    while lo < hi:
        m = (lo + hi + 1) // 2
        if m * m * m <= x: lo = m
        else: hi = m - 1
    return lo
def rng(b):
    for L2 in range(1, b):
        L3 = b - L2
        a = max(math.isqrt(b ** (L2 - 1) - 1) + 1, icbrt(b ** (L3 - 1) - 1) + 1)
        z = min(math.isqrt(b ** L2 - 1), icbrt(b ** L3 - 1))
        if z > a: return a, z + 1, L2, L3
    return None
def distinct(n, b):
    s = set(); x = n * n
    while x: x, r = divmod(x, b); s.add(r)
    x = n * n * n
    while x: x, r = divmod(x, b); s.add(r)
    return len(s)
def from_digits(ds, b):     # most significant first
    x = 0
    for d in ds: x = x * b + d
    return x
def fam_rat(b, lo, hi):
    Qs = {b - 1, (b - 1) ** 2, (b - 1) ** 3, b + 1, (b + 1) ** 2, b * b - 1, b * b + 1, b * b + b + 1, b * b - b + 1}
    Qs |= set(range(2, 41))
    for Q in sorted(Qs):
        if Q <= 400: Ps = range(1, Q)
        else:
            Ps = set(range(1, 201)) | set(range(Q - 200, Q)) | {p * (b - 1) + r for p in range(1, 31) for r in range(-6, 7)} \
                 | {p * (b + 1) + r for p in range(1, 31) for r in range(-6, 7)}
            Ps = sorted(p for p in Ps if 0 < p < Q)
        for P in Ps:
            # K with lo <= P*b^K/Q < hi
            K = 0; x = P // Q
            t = P
            while t // Q < lo: t *= b
            x = t // Q
            if x >= hi: continue
            for c in (-2, -1, 0, 1, 2):
                n = x + c
                if lo <= n < hi: yield n
def fam_lin(b, lo, hi, L):
    for alpha in range(b):
        for beta in range(1, b):
            n = from_digits([(beta + alpha * i) % b for i in range(L)], b)
            if lo <= n < hi: yield n
def fam_sq(b, lo, hi, L2):
    for alpha in range(b):
        for beta in range(1, b):
            X = from_digits([(beta + alpha * i) % b for i in range(L2)], b)
            r = math.isqrt(X)
            for n in (r, r + 1):
                if lo <= n < hi: yield n
def fam_cb(b, lo, hi, L3):
    for alpha in range(b):
        for beta in range(1, b):
            Y = from_digits([(beta + alpha * i) % b for i in range(L3)], b)
            r = icbrt(Y)
            for n in (r, r + 1):
                if lo <= n < hi: yield n
def main():
    blo, bhi = int(sys.argv[1]), int(sys.argv[2]); rnd = random.Random(int(sys.argv[3]) if len(sys.argv) > 3 else 20261125)
    for b in range(blo, bhi + 1):
        r = rng(b)
        if r is None or b % 4 == 3: continue
        lo, hi, L2, L3 = r
        L = len_n = 0; x = lo
        while x: x //= b; L += 1
        # random baseline
        R = [distinct(rnd.randrange(lo, hi), b) for _ in range(3000)]
        mu = sum(R) / len(R); sd = (sum((v - mu) ** 2 for v in R) / len(R)) ** 0.5
        for name, gen in (("rat", fam_rat(b, lo, hi)), ("lin", fam_lin(b, lo, hi, L)), ("sq", fam_sq(b, lo, hi, L2)), ("cb", fam_cb(b, lo, hi, L3))):
            best = (-1, None); cnt = 0; seen = set(); tail = {}
            for n in gen:
                if n in seen: continue
                seen.add(n); cnt += 1
                d = distinct(n, b)
                if d > best[0]: best = (d, n)
                if d >= b - 3: tail[b - d] = tail.get(b - d, 0) + 1
            if cnt == 0: continue
            # expected best of cnt random draws (normal approximation), and the family's z
            exp_best = mu + sd * math.sqrt(2 * math.log(max(cnt, 2)))
            rb = max(distinct(rnd.randrange(lo, hi), b) for _ in range(min(cnt, 20000)))
            print(f"b={b} fam={name} members={cnt} best={best[0]} missing={b-best[0]} z={(best[0]-mu)/sd:.2f} "
                  f"random: mean={mu:.1f} sd={sd:.2f} expbest~{exp_best:.1f} best_of_{min(cnt,20000)}={rb} "
                  f"near={dict(sorted(tail.items()))} n_best={best[1] if b-best[0] <= 1 else ''}", flush=True)
            if best[0] == b: print(f"*** NICE: base {b} n={best[1]} family {name}", flush=True)
main()
