#!/usr/bin/env python3
"""M2 search: a test window whose first block is clipped short enough to be
unseeded (certificate floor < k2) and holds a prefilter survivor, at shape
t = L-1, k = L-1 (f0 = 1, mid = 2, so the fixed-point path). Approximate
model of the join (the real test confirms): certificate positions >= c_j =
max(k, ndig(e^j - a^j)), raised while a^j and e^j differ above c_j; None if
the certified digits repeat; the bottom: digits of n^2, n^3 below k distinct
and missing the certificate; the prefilter by its definition (mid_mirror)."""
import sys
def digs(x, b):
    out = []
    while x:
        out.append(x % b); x //= b
    return out
def ndig(x, b):
    return len(digs(x, b))
def cert(a, e, k, b):
    mask = []
    floor = None
    for j in (2, 3):
        A, E = a ** j, e ** j
        c = max(k, ndig(E - A, b))
        while A // b ** c != E // b ** c:
            c += 1
        mask += digs(A // b ** c, b)
        floor = c if floor is None else min(floor, c)
    if len(set(mask)) != len(mask):
        return None, floor
    return set(mask), floor
def low(x, b, n):
    return [(x // b ** i) % b for i in range(n)]
def search(b, L, k, lo, hi, want=5):
    k2 = k + 2
    found = 0
    # first block of a window starting at s: [s, s | (b-1)] (f0 = 1, w = b)
    for s in range(lo, hi):
        m = b - (s % b)          # numbers in the first block
        if m > b // 2 or m < 1:
            continue
        a, e = s, s + m - 1
        c, floor = cert(a, e, k, b)
        if c is None or floor >= k2:
            continue
        for n in range(a, e + 1):
            l2, l3 = low(n * n, b, k2), low(n ** 3, b, k2)
            bot = l2[:k] + l3[:k]
            if len(set(bot)) != len(bot) or set(bot) & c:
                continue
            # join survivor; the prefilter (unseeded: seen = bottom digits)
            mids = [l2[k], l3[k], l2[k + 1], l3[k + 1]]
            if len(set(mids)) == 4 and not (set(mids) & set(bot)):
                print(f"b{b} L{L} k{k}: s={s} block [{a}, {e}] ({m} numbers) floor {floor} < k2 {k2}; survivor n={n}")
                found += 1
                break
        if found >= want:
            return
b = int(sys.argv[1]); L = int(sys.argv[2])
search(b, L, L - 1, int(sys.argv[3]), int(sys.argv[4]))
