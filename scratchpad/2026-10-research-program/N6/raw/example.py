#!/usr/bin/env python3
"""Worked example of one top test (Python mirror of Base::cert_parts) for the
description in RESULTS.md: python3 example.py"""
def digits(x, b):
    out = []
    while x:
        out.append(x % b); x //= b
    return out
def ndig(x, b):
    return len(digits(x, b))
def cert(a, e, b, cap):
    L = ndig(e, b); res = []
    for j in (2, 3):
        x, y = a**j, e**j; sp = ndig(x, b); d = y - x
        c0 = max(cap, ndig(d, b))
        if c0 >= sp:
            res.append((j, sp, c0, sp, None, [])); continue
        q, r = divmod(x, b**c0)
        one_more = r + d >= b**c0
        dx = digits(q, b) + [0] * (sp - c0 - len(digits(q, b)))
        run = 0; dom = None
        if one_more:
            while dx[run] == b - 1: run += 1
            dom = (dx[run], dx[run] + 1); run += 1
        res.append((j, sp, c0, c0 + run, dom, list(reversed(dx[run:]))))
    return res
for b, s in ((60, 1_366_405_974_057_412_100_454), (62, 7_997_740_455_941_656_911_841), (64, 41_242_006_262_957_161_709_568)):
    L = ndig(s, b); f0 = 3
    print(f"b{b}: L={L}, n2 digits {ndig(s*s,b)}, n3 digits {ndig(s**3,b)}, leading digit of n {s // b**(L-1)}")
    P0 = s // b**5 + 7  # some parent block (depth L-5)
    for name, a, w in (("parent (depth L-5, b^5 numbers)", P0 * b**5, b**5),
                       ("mid (depth L-4, b^4 numbers)", P0 * b**5, b**4),
                       ("pair (depth L-3, b^3 numbers)", P0 * b**5 + 1234 * b**3, b**3)):
        r = cert(a, a + w - 1, b, 6)
        print(f"  {name}:")
        for j, sp, c0, frm, dom, com in r:
            print(f"    n^{j}: c0={c0}, common positions {frm}..{sp-1} ({sp-frm} digits), dom {dom}, digits top-down {com}")
