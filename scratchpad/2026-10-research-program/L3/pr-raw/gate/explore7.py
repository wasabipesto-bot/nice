import re, os, itertools
from seed_model import chunk16, to_limbs, M32
from explore6 import obs, P
def digits(v, ndig, b, q1f=None, q2f=None):
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            c1 = ((rem << 16) | (x >> 16)) & M32
            top0 = (k == 0 and ii == 0)
            q1 = (q1f(x, v[i-1]) & M32) // K if (top0 and q1f) else c1 // K
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = (q2f(x, v[i-1], r1) & M32) // K if (top0 and q2f) else c2 // K
            rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b; out.append(chunk - cq * b); chunk = cq
    return out
Q1 = {'ok': None, 'lo>>16': lambda h, l: l >> 16, 'lo': lambda h, l: l, 'lo&ffff': lambda h, l: l & 0xFFFF,
      'hi': lambda h, l: h, 't>>16': lambda h, l: ((h << 32) | l) >> 16, 'hi<<16|lo>>16': lambda h, l: (h << 16) | (l >> 16)}
Q2 = {'ok': None, 'r1|lo&ffff': lambda h, l, r: (r << 16) | (l & 0xFFFF), 'r1|lo>>16': lambda h, l, r: (r << 16) | (l >> 16),
      'r1|hi': lambda h, l, r: (r << 16) | h, 'lo': lambda h, l, r: l, 'r1|lo': lambda h, l, r: (r << 16) | l}
def score(b, sq1, sq2, cq1, cq2):
    s, cnt, ls, lc, limbs = P[b]; ok = 0
    for n in range(s, s + cnt):
        sq = to_limbs(n*n, 2*limbs); cu = to_limbs(n**3, 3*limbs)
        true = len(set(digits(sq, ls, b) + digits(cu, lc, b)))
        gpu = obs.get((b, n), (true, true))[1]
        ok += len(set(digits(sq, ls, b, Q1[sq1], Q2[sq2]) + digits(cu, lc, b, Q1[cq1], Q2[cq2]))) == gpu
    return ok
res = []
for sq1, sq2 in itertools.product(Q1, Q2):
    res.append((score(23, sq1, sq2, 'ok', 'ok'), sq1, sq2))
res.sort(reverse=True); print("b23 S-top variants:", res[:8])
