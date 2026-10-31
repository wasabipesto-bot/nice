#!/usr/bin/env python3
"""Per base: limbs, split16 chunk constants, and the top word of each value a
split16 long division starts from (the word whose `>> 16` is the first
dividend when rem is a literal 0), over the base's whole n range."""
import math

def iroot_ceil(x, k):
    r = round(x ** (1.0 / k)) if x < 2**1000 else int(x ** (1.0/k))
    # integer refine
    r = int(r)
    while r ** k < x: r += 1
    while r > 0 and (r - 1) ** k >= x: r -= 1
    return r

def base_range(b):
    k = b // 5
    m = b % 5
    if m == 0: return iroot_ceil(b ** (3 * k - 1), 3), b ** k
    if m == 1: return None
    if m == 2: return b ** k, iroot_ceil(b ** (3 * k + 1), 3)
    if m == 3: return iroot_ceil(b ** (3 * k + 1), 3), iroot_ceil(b ** (2 * k + 1), 2)
    if m == 4: return iroot_ceil(b ** (2 * k + 1), 2), iroot_ceil(b ** (3 * k + 2), 3)

def chunk_u16(b):
    e, d = 0, 1
    while d * b < (1 << 16):
        d *= b; e += 1
    return e, d

def ndig(x, b):
    n = 0
    while x: x //= b; n += 1
    return n

def pow2(x): return x & (x - 1) == 0

print("base limbs  n_bits  cd16 K16   pow2?  | top word of: n (limbs) | n^2 (2L) | n^3 (3L)  [lo..hi of range]")
for b in range(10, 65):
    r = base_range(b)
    if not r: continue
    lo, hi = r
    if lo >= hi: continue
    nmax = hi - 1
    L = max(1, math.ceil(nmax.bit_length() / 32))
    cd, K = chunk_u16(b)
    def tw(x, nl): return x >> (32 * (nl - 1))
    s = []
    for e, nl in ((1, L), (2, 2 * L), (3, 3 * L)):
        s.append(f"{tw(lo**e, nl)}..{tw(nmax**e, nl)}")
    print(f"b{b:<3} L={L} bits={lo.bit_length()}-{nmax.bit_length():<3} cd={cd} K={K:<6} {'POW2' if pow2(K) else '    '} | " + " | ".join(s))
