#!/usr/bin/env python3
"""B64: field starts at relative positions 0.05..0.95 of the base range, aligned to 1e17 from the range start, so each
1e16 field is the first tenth of the 1e17 field at the same position. python3 starts.py BASE -> 'f:start' lines."""
import sys
def icbrt(x):
    r = int(round(x ** (1/3)))
    while r**3 > x: r -= 1
    while (r+1)**3 <= x: r += 1
    return r
def isqrt(x):
    import math; return math.isqrt(x)
def rng(b):
    k = b // 5
    m = b % 5
    if m == 0: lo = icbrt(b**(3*k-1)); lo += (lo**3 < b**(3*k-1)); return lo, b**k
    if m == 2: hi = icbrt(b**(3*k+1)); hi += (hi**3 < b**(3*k+1)); return b**k, hi
    if m == 4:
        lo = isqrt(b**(2*k+1)); lo += (lo*lo < b**(2*k+1))
        hi = icbrt(b**(3*k+2)); hi += (hi**3 < b**(3*k+2)); return lo, hi
    raise SystemExit('base')
b = int(sys.argv[1]); lo, hi = rng(b)
print(f'# b{b} range [{lo}, {hi}) width {hi-lo:.4e}')
for i in range(10):
    f = 0.05 + 0.1 * i
    s = lo + (int(f * (hi - lo)) // 10**17) * 10**17
    print(f'{f:.2f}:{s}')
