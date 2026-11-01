#!/usr/bin/env python3
"""Desk checks run before the device tests (L31): the Moller-Granlund 2/1 pass and the digit
magic of cert_power32 against Python integers, and ndig_fast's multiply-shift for every bit
length, at the bases the certificate test uses."""
import math, random
M = (1 << 32) - 1
def chunk32(b):
    k, bb = 0, 1
    while bb * b <= M: bb *= b; k += 1
    return k, bb
def lz(x): return 32 - x.bit_length()
def mg(b):
    bb = chunk32(b)[1]; sh = lz(bb); dn = (bb << sh) & M
    return sh, dn, ((1 << 64) - 1) // dn - (1 << 32)
def magic(b):
    bb = chunk32(b)[1]; s = 31 - lz(b - 1); p = 1 << (32 + s); mc = -(-p // b)
    if mc < (1 << 32) and (bb - 1) * (mc * b - p) < p: return mc, s, True
    return p // b, s, False
def mulhi(a, b): return (a * b) >> 32
def div_pass(xw, b):
    k, bb = chunk32(b); sh, dn, v = mg(b); nl = len(xw)
    r = (xw[nl - 1] >> (32 - sh)) if sh > 0 else 0
    out = list(xw)
    for j in range(nl - 1, -1, -1):
        u0 = xw[j]
        if sh > 0:
            u0 = (u0 << sh) & M
            if j > 0: u0 |= xw[j - 1] >> (32 - sh)
        p_lo = (r * v) & M; p_hi = mulhi(r, v)
        q0 = (p_lo + u0) & M; cq = 1 if q0 < p_lo else 0
        q1 = (p_hi + r + cq + 1) & M
        rr = (u0 - q1 * dn) & M
        if rr > q0: q1 = (q1 - 1) & M; rr = (rr + dn) & M
        if rr >= dn: q1 = (q1 + 1) & M; rr = (rr - dn) & M
        out[j] = q1; r = rr
    return out, r >> sh
def ndig_magic(b, lmax):
    want = []
    for L in range(lmax + 1):
        i = 0
        while (b ** i).bit_length() <= L: i += 1
        want.append(i)
    lg = math.log(2) / math.log(b)
    for sh in range(12, 25):
        m0 = int((1 << sh) * lg)
        for m in range(max(1, m0 - 3), m0 + 4):
            for t in range(64):
                a = (1 << sh) - 1 - t
                if lmax * m + a >= 1 << 32: continue
                if all(((L * m + a) >> sh) == want[L] for L in range(lmax + 1)):
                    return m, sh, a
for b in [10, 12, 20, 30, 40, 47, 50, 57, 58, 60, 62, 64]:
    k, bb = chunk32(b); m = magic(b)
    for x in [0, 1, b - 1, b, bb - 1] + [random.randrange(bb) for _ in range(20000)]:
        q = mulhi(x, m[0]) >> m[1]; d = x - q * b
        if not m[2] and d >= b: q += 1; d -= b
        assert q == x // b and d == x % b, (b, x)
    for nl in [1, 2, 3, 4, 6, 9]:
        for _ in range(2000):
            X = random.getrandbits(random.randrange(1, 32 * nl + 1))
            xw = [(X >> (32 * i)) & M for i in range(nl)]
            out, rx = div_pass(xw, b)
            assert sum(w << (32 * i) for i, w in enumerate(out)) == X // bb and rx == X % bb, (b, nl, X)
        mm, sh, a = ndig_magic(b, 32 * nl)
        for _ in range(3000):
            d = random.getrandbits(random.randrange(0, 32 * nl + 1))
            ce = (d.bit_length() * mm + a) >> sh; c = max(ce - 1, 0)
            nd = c if d < b ** c else c + 1
            i = 0
            while b ** i <= d: i += 1
            assert nd == i, (b, d)
    print(f"b{b}: k={k} B={bb} mg(sh,dn,v)={mg(b)} digit magic={m} ndig magic(288)={ndig_magic(b, 288)}")
print("all ok")
