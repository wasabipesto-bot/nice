"""b23 per-n: single-site half-swap faults anywhere in S's and C's digit
conversion (any chunk, any limb, either division, and the digit peel)."""
from explore6 import obs, P
from seed_model import chunk16, to_limbs, M32
def digits(v, ndig, b, site=None):
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            c1 = ((rem << 16) | (x >> 16)) & M32
            q1 = c1 // K
            if site == (k, i, 'q1lo'): q1 = (((rem << 16) | (x & 0xFFFF)) & M32) // K
            if site == (k, i, 'q1norem'): q1 = (x >> 16) // K
            if site == (k, i, 'q1remlo'): q1 = (((rem & 0xFFFF) << 16 | (x >> 16)) & M32) // K
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = c2 // K
            if site == (k, i, 'q2hi'): q2 = (((r1 << 16) | (x >> 16)) & M32) // K
            if site == (k, i, 'q2nor1'): q2 = (x & 0xFFFF) // K
            if site == (k, i, 'q2r1hi'): q2 = (r1 >> 16) // K
            rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b
                if site == (k, j, 'peel_lo'): cq = (chunk & 0xFFFF) // b
                if site == (k, j, 'peel_hi'): cq = (chunk >> 16) // b
                out.append((chunk - cq * b) & M32); chunk = cq
    return out
def uniq(ds, b): return len(set(ds))
def score(b, ssite, csite):
    s, cnt, ls, lc, limbs = P[b]; ok = 0
    for n in range(s, s + cnt):
        sq = to_limbs(n*n, 2*limbs); cu = to_limbs(n**3, 3*limbs)
        true = len(set(digits(sq, ls, b) + digits(cu, lc, b)))
        gpu = obs.get((b, n), (true, true))[1]
        ok += len(set(digits(sq, ls, b, ssite) + digits(cu, lc, b, csite))) == gpu
    return ok
if __name__ == "__main__":
    b = 23; s, cnt, ls, lc, limbs = P[b]; e, K = chunk16(b)
    T = ['q1lo', 'q1norem', 'q1remlo', 'q2hi', 'q2nor1', 'q2r1hi']
    res = []
    for which, nl, nd in (('S', 2*limbs, ls), ('C', 3*limbs, lc)):
        for k in range(-(-nd // e)):
            for i in range(nl):
                for t in T:
                    st = (k, i, t)
                    res.append((score(b, st, None) if which == 'S' else score(b, None, st), which, st))
            for j in range(e):
                for t in ('peel_lo', 'peel_hi'):
                    st = (k, j, t)
                    res.append((score(b, st, None) if which == 'S' else score(b, None, st), which, st))
    res.sort(key=lambda r: -r[0]); print(res[:10])
