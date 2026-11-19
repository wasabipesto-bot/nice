#!/usr/bin/env python3
"""Coordinate (k0, k1, q0) of BUILD-NOTES §2 / coord.rs, for alternative fixed-digit choices.
v = start + key*(H*b^k0) + (h-h0)*b^k0 + low, key = digits [k0,k1), h = n div b^k1; a field quantum
fixes digits [q0,k1) and is H*b^q0 v-values.  Checks the bijection on random n (exact integers)."""
import random
R = {64: (37778931862957161709568, 75557863725914323419136),
     65: (91953694755747944887348, 369720589101871337890625)}
def coord(b, k0, k1, q0):
    s, e = R[b]; h0 = s // b**k1; H = (e - 1) // b**k1 - h0 + 1
    return dict(b=b, s=s, e=e, k0=k0, k1=k1, q0=q0, h0=h0, H=H)
def v_of(c, n):
    b, k0, k1 = c['b'], c['k0'], c['k1']
    low = n % b**k0; key = (n // b**k0) % b**(k1 - k0); h = n // b**k1
    return c['s'] + key * (c['H'] * b**k0) + (h - c['h0']) * b**k0 + low
def n_of(c, v):
    b, k0, k1 = c['b'], c['k0'], c['k1']; x = v - c['s']
    key, rest = divmod(x, c['H'] * b**k0); hh, low = divmod(rest, b**k0)
    return (hh + c['h0']) * b**k1 + key * b**k0 + low
random.seed(1)
for b in (64, 65):
    for (k0, k1, q0) in ((4, 9, 6), (4, 8, 5), (4, 9, 7), (4, 9, 5)):
        c = coord(b, k0, k1, q0); s, e = c['s'], c['e']
        for _ in range(20000):
            n = random.randrange(s, e); v = v_of(c, n); assert n_of(c, v) == n
            # quantum index fixes digits [q0,k1)
            assert (v - s) // (c['H'] * b**q0) == (n // b**q0) % b**(k1 - q0)
        span = c['H'] * b**k1; pad = span - (e - s)
        fixed = list(range(q0, k1))
        print(f"b{b} (k0 {k0}, k1 {k1}, q0 {q0}): fixes digits {fixed}, H {c['H']}, quantum H*b^q0 = {c['H']*b**q0:.6e}"
              f" ({'2^%.2f' % ((c['H']*b**q0).bit_length()-1) if b == 64 else ''}), fields {b**(k1-q0)}, "
              f"slices (4,10) per field {b**(q0-4) * b**(9-k1)}, padding {pad:.3e} n ({pad/(e-s)*1e6:.4f} ppm), v end 2^{(s+span).bit_length()-1}"
              f" [bijection ok on 20,000 n]")
