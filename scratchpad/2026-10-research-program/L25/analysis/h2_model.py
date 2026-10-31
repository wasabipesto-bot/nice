#!/usr/bin/env python3
"""H2 model of the Apple M4 miscompile applied to the join's cert_power.

cert_power long-divides a value X held in `nl` u32 limbs by K = chunk_div
(split16: two u32 steps per limb), once per pass, peeling chunk_digits
digits per pass. Every loop is unrolled, so each pass starts with rem = 0
and its first dividend is the bare `x[nl-1] >> 16`. Under H2 (the M4's
observed behaviour at every K but 12167) that division returns
`(x[nl-1] & 0xFFFF) // K` instead; the remainder is mul-sub with the
correct dividend. Report, per base, the fraction of n (random over the
base range, plus both ends) whose n^2 or n^3 digits come out wrong.
"""
import random, sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from topwords import base_range, chunk_u16
import math

M32 = (1 << 32) - 1

def digits_true(X, b, nd):
    out = []
    for _ in range(nd):
        out.append(X % b); X //= b
    return out

def cert_digits(X, nl, b, cd, K, sp, buggy):
    x = [(X >> (32 * j)) & M32 for j in range(nl)]
    passes = -(-sp // cd)
    out = []
    for _ in range(passes):
        rx = 0
        for jj in range(nl):
            j = nl - 1 - jj
            vx = x[j]
            c1 = (rx << 16) | (vx >> 16)
            if buggy and jj == 0:
                q1 = (vx & 0xFFFF) // K
            else:
                q1 = c1 // K
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (vx & 0xFFFF)) & M32
            q2 = c2 // K
            rx = (c2 - q2 * K) & M32
            x[j] = ((q1 << 16) | q2) & M32
        for _ in range(cd):
            out.append(rx % b); rx //= b
    return out[:sp]

def ndig(x, b):
    n = 0
    while x: x //= b; n += 1
    return n

random.seed(1)
bases = [int(a) for a in sys.argv[1:]] or list(range(20, 65))
print("base L  K      frac n^2 wrong  frac n^3 wrong  (H2 model, 2000 random n + ends)")
for b in bases:
    r = base_range(b)
    if not r or r[0] >= r[1]: continue
    lo, hi = r
    L = max(1, math.ceil((hi - 1).bit_length() / 32))
    cd, K = chunk_u16(b)
    ns = [lo, hi - 1] + [random.randrange(lo, hi) for _ in range(2000)]
    w2 = w3 = 0
    for n in ns:
        for e, nl, acc in ((2, 2 * L, 2), (3, 3 * L, 3)):
            X = n ** e
            sp = ndig(X, b)
            good = cert_digits(X, nl, b, cd, K, sp, False)
            assert good == digits_true(X, b, sp), (b, n, e)
            bad = cert_digits(X, nl, b, cd, K, sp, True)
            if bad != good:
                if e == 2: w2 += 1
                else: w3 += 1
    print(f"b{b:<3} {L}  {K:<6} {w2/len(ns):>8.3f}        {w3/len(ns):>8.3f}")
