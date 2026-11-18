#!/usr/bin/env python3
"""Exact base facts b62..b70 (range as common/src/base_range.rs, L, roots, admissible n). [M exact]"""
import math

def iroot_ceil(v, r):
    x = int(round(v ** (1.0 / r))) if v < 1e300 else 1 << (v.bit_length() // r + 1)
    # newton-safe adjust by bisection around x
    lo, hi = max(0, x - x // 10**6 - 10), x + x // 10**6 + 10
    while lo ** r >= v: lo //= 2
    while hi ** r < v: hi *= 2
    while lo < hi:
        m = (lo + hi) // 2
        if m ** r >= v: hi = m
        else: lo = m + 1
    return lo

def base_range(b):
    k = b // 5; m = b % 5
    if m == 0: return iroot_ceil(b ** (3 * k - 1), 3), b ** k
    if m == 2: return b ** k, iroot_ceil(b ** (3 * k + 1), 3)
    if m == 3: return iroot_ceil(b ** (3 * k + 1), 3), iroot_ceil(b ** (2 * k + 1), 2)
    if m == 4: return iroot_ceil(b ** (2 * k + 1), 2), iroot_ceil(b ** (3 * k + 2), 3)
    return None

def roots(b):
    m = b - 1; t = b * (b - 1) // 2 % m
    return [r for r in range(m) if (r * r + r ** 3) % m == t]

def facts(b):
    r = base_range(b)
    if r is None: return None
    s, e = r
    if e <= s or not roots(b): return None
    W = e - s; L = 0; x = e - 1
    while x: x //= b; L += 1
    R = len(roots(b))
    return dict(b=b, s=s, e=e, W=W, L=L, R=R, A=W * R / (b - 1))

if __name__ == '__main__':
    A64 = facts(64)['A']
    for b in [62, 64, 65, 66, 67, 68, 69, 70]:
        f = facts(b)
        if f is None:
            r = base_range(b)
            print(f"b{b}: range {None if r is None else (r[0] < r[1])} roots {len(roots(b))} -> no candidates"); continue
        print(f"b{b}: L={f['L']} W={f['W']:.4e} roots={f['R']} {roots(b)} A={f['A']:.4e} A/A64={f['A']/A64:.3f} "
              f"start/b^(L-1)={f['s']/b**(f['L']-1):.4f} end/b^(L-1)={f['e']/b**(f['L']-1):.4f} log2(start)={math.log2(f['s']):.3f} log2(end)={math.log2(f['e']):.3f}")
