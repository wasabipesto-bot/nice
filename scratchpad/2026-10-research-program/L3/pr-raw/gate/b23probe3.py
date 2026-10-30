"""b23 per-n: the S top-limb step's three 16-bit inputs (q1's dividend, r1's
minuend, c2's low half) each read from one of the four 16-bit fields of
t = n*n (bits 0-15, 16-31, 32-47, 48-63; correct = 48-63, 48-63, 32-47)."""
import itertools
from explore6 import obs, P
from seed_model import chunk16, to_limbs, M32
def digits(v, ndig, b, srcs=None, t=None):
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            if srcs and k == 0 and ii == 0:
                f = [(t >> (16 * j)) & 0xFFFF for j in range(4)]
                q1 = f[srcs[0]] // K
                r1 = (f[srcs[1]] - q1 * K) & M32
                c2 = ((r1 << 16) | f[srcs[2]]) & M32
            else:
                c1 = ((rem << 16) | (x >> 16)) & M32
                q1 = c1 // K; r1 = (c1 - q1 * K) & M32
                c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = c2 // K; rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b; out.append(chunk - cq * b); chunk = cq
    return out
b = 23; s, cnt, ls, lc, limbs = P[b]
res = []
for srcs in itertools.product(range(4), range(4), range(4)):
    ok = 0
    for n in range(s, s + cnt):
        sq = to_limbs(n*n, 2); cu = to_limbs(n**3, 3)
        true = len(set(digits(sq, ls, b) + digits(cu, lc, b)))
        gpu = obs.get((b, n), (true, true))[1]
        ok += len(set(digits(sq, ls, b, srcs, n*n) + digits(cu, lc, b))) == gpu
    res.append((ok, srcs))
res.sort(reverse=True); print(res[:8])
