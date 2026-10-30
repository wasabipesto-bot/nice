import re, os, itertools
from seed_model import chunk16, to_limbs, M32
HERE = os.path.dirname(os.path.abspath(__file__))
obs = {}
for l in open(os.path.join(HERE, "..", "m4", "diag3.log")):
    m = re.match(r".*WRONG b(\d+) n=(\d+) cpu=\[\((\d+), 1\)\] fd=\[\((\d+), 1\)\]", l)
    if m:
        b, n, c, f = map(int, m.groups()); obs[(b, n)] = (c, f)

def digits(v, ndig, b, lost=()):
    """`lost`: limb indices i whose chunk-0 `v[i] >> 16` loses its shift
    (c1 = (rem << 16) | v[i])."""
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            hi16 = x if (k == 0 and i in lost) else (x >> 16)
            c1 = ((rem << 16) | hi16) & M32
            q1 = c1 // K; r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = c2 // K; rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b; out.append(chunk - cq * b); chunk = cq
    return out

P = {23: (795831, 3000, 9, 14, 1), 50: (26507984537059635, 400, 20, 30, 2)}
def score(b, sl, cl):
    s, cnt, ls, lc, limbs = P[b]; ok = 0
    for n in range(s, s + cnt):
        sq = to_limbs(n*n, 2*limbs); cu = to_limbs(n**3, 3*limbs)
        true = len(set(digits(sq, ls, b) + digits(cu, lc, b)))
        gpu = obs.get((b, n), (true, true))[1]
        ok += len(set(digits(sq, ls, b, sl) + digits(cu, lc, b, cl))) == gpu
    return ok
best = []
for b in (23, 50):
    limbs = P[b][4]
    S_opts = [tuple(c) for r in range(0, 2*limbs+1) for c in itertools.combinations(range(2*limbs), r)]
    C_opts = [tuple(c) for r in range(0, 3*limbs+1) for c in itertools.combinations(range(3*limbs), r)]
    res = []
    for sl in S_opts:
        for cl in C_opts:
            res.append((score(b, sl, cl), sl, cl))
    res.sort(reverse=True)
    print(f"b{b} top:", res[:6])
