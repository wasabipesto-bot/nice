#!/usr/bin/env python3
"""L47 review M2: the deterministic (adversarial + edge) n that synthetic() keeps per shape, a port of the test's
adversarial() and synthetic() edges and filter. python3 edge_count.py"""
def nd(x, b):
    n = 0
    while x: x //= b; n += 1
    return n
def root_above(s, k, b, l):
    t = b ** s; a, z = 0, b ** l + 1
    while a < z:
        m = (a + z) // 2
        if m ** k >= t: z = m
        else: a = m + 1
    return a
def adversarial(b, l):
    top, low = b ** l - 1, b ** (l - 1)
    def alt(first):
        a = 0
        for i in range(l):
            d = b - 1 if (i + first) % 2 == 0 else 0
            a = a * b + (1 if i == 0 and d == 0 else d)
        return a
    v = [top, low, low + 1, alt(0), alt(1)]
    for i in range(l):
        v += [top - (b - 1) * b ** i, low + b ** i - 1]
    for f in (3, 8):
        if f < l:
            w = b ** f; v += [top // w * w, low // w * w + w - 1]
    return [n for n in v if low <= n <= top and n < 2 ** 96]
def edges(b, l, s2, s3, f0):
    lo = max(b ** (l - 1), root_above(s2 - 1, 2, b, l), root_above(s3 - 1, 3, b, l))
    hi = min(b ** l, root_above(s2, 2, b, l), root_above(s3, 3, b, l))
    ns = adversarial(b, l)
    r2, r3 = root_above(s2, 2, b, l), root_above(s3, 3, b, l)
    ns += [lo, lo + 1, hi - 1, hi - 2, r2 - 1, r3 - 1]
    for i in range(1, l):
        p = b ** i
        for e in (lo, hi - 1):
            ns += [e // p * p, e // p * p + p - 1, e // p * p + p]
    h = l // 2; p = b ** h
    alt = lambda first: sum(b ** j * (b - 1 if (j + first) % 2 == 0 else 0) for j in range(h))
    for e in (lo, hi - 1):
        top = e // p * p; ns += [top, top + p - 1, top + alt(0), top + alt(1)]
    keep = sorted({n for n in ns if lo <= n < hi and n // b ** f0 < 2 ** 64 and nd(n * n, b) == s2 and nd(n ** 3, b) == s3})
    adv = sorted({n for n in adversarial(b, l) if lo <= n < hi and nd(n * n, b) == s2 and nd(n ** 3, b) == s3})
    return len(adv), len(keep), lo, hi
for (b, l, s2, s3, f0) in [(42, 9, 17, 25, 3), (50, 10, 20, 30, 3), (57, 12, 23, 34, 3), (60, 12, 24, 36, 3), (62, 13, 25, 37, 3), (64, 13, 26, 38, 3), (64, 13, 26, 38, 2), (20, 4, 8, 12, 1)]:
    a, k, lo, hi = edges(b, l, s2, s3, f0)
    print(f"b{b} l{l} s2={s2} s3={s3} f0={f0}: adversarial kept before {a}, adversarial+edge kept now {k}")
