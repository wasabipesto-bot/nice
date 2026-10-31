#!/usr/bin/env python3
"""Model of the fixed cert_power digit scan: 16-bit limbs from the u32
schoolbook, top pair first. Checks digits against Python for random n at
every base 40-64, and that no u32 intermediate overflows."""
import random, math
from topwords import base_range, chunk_u16
M32 = (1 << 32) - 1

def school16(x, y):  # 16-bit limb schoolbook in u32, as top_kernel does
    out = [0] * (len(x) + len(y))
    for i in range(len(x)):
        c = 0
        for j in range(len(y)):
            t = x[i] * y[j] + out[i + j] + c
            assert t <= M32
            out[i + j] = t & 0xFFFF
            c = t >> 16
        out[i + len(y)] = c
    return out

def digits(xh, b, cd, K, sp):
    x = list(xh); nh = len(x); out = []
    for _ in range(-(-sp // cd)):
        c = (x[nh - 1] << 16) | x[nh - 2]
        assert c <= M32
        q = c // K; r = c - q * K
        x[nh - 1] = q >> 16; x[nh - 2] = q & 0xFFFF
        for j in range(nh - 3, -1, -1):
            c = (r << 16) | x[j]
            assert c <= M32
            q = c // K; r = c - q * K; x[j] = q
        for _ in range(cd):
            out.append(r % b); r //= b
    return out[:sp]

random.seed(7)
for b in range(40, 65):
    rg = base_range(b)
    if not rg or rg[0] >= rg[1]: continue
    lo, hi = rg
    L = max(1, math.ceil((hi - 1).bit_length() / 32))
    cd, K = chunk_u16(b)
    for n in [lo, hi - 1] + [random.randrange(lo, hi) for _ in range(300)]:
        h = [(n >> (16 * i)) & 0xFFFF for i in range(2 * L)]
        sq = school16(h, h); cu = school16(sq, h)
        assert sum(v << (16 * i) for i, v in enumerate(sq)) == n * n
        assert sum(v << (16 * i) for i, v in enumerate(cu)) == n ** 3
        for X, xh in ((n * n, sq), (n ** 3, cu)):
            sp = 0; t = X
            while t: t //= b; sp += 1
            want = []; t = X
            for _ in range(sp): want.append(t % b); t //= b
            assert digits(xh, b, cd, K, sp) == want, (b, n)
print("fixed cert_power model: digits exact, no u32 overflow, bases 40-64")
