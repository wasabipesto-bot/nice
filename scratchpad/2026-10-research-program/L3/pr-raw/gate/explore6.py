import re, os, sys
from seed_model import chunk16, to_limbs, M32
HERE = os.path.dirname(os.path.abspath(__file__))
obs = {}
for l in open(os.path.join(HERE, "..", "m4", "diag3.log")):
    m = re.match(r".*WRONG b(\d+) n=(\d+) cpu=\[\((\d+), 1\)\] fd=\[\((\d+), 1\)\]", l)
    if m:
        b, n, c, f = map(int, m.groups()); obs[(b, n)] = (c, f)

def digits(v, ndig, b, faults=()):
    """faults: set of (k, i, type)."""
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            c1 = ((rem << 16) | (x >> 16)) & M32
            q1 = c1 // K
            if (k, i, 'T1') in faults: q1 = (x // K) & M32
            if (k, i, 'T2') in faults: q1 = ((((rem << 16) | x) & M32) // K)
            if (k, i, 'T3') in faults: q1 = (x >> 16) // K
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = c2 // K
            if (k, i, 'T4') in faults: q2 = ((((r1 << 16) | x) & M32) // K)
            if (k, i, 'T5') in faults: q2 = (x // K) & M32
            rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b
                d = chunk - cq * b
                out.append(d); chunk = cq
    return out

P = {23: (795831, 3000, 9, 14, 1), 50: (26507984537059635, 400, 20, 30, 2)}
def score(b, sf, cf, N=None):
    s, cnt, ls, lc, limbs = P[b]; ok = 0
    cnt = N or cnt
    for n in range(s, s + cnt):
        sq = to_limbs(n*n, 2*limbs); cu = to_limbs(n**3, 3*limbs)
        true = len(set(digits(sq, ls, b) + digits(cu, lc, b)))
        gpu = obs.get((b, n), (true, true))[1]
        ok += len(set(digits(sq, ls, b, sf) + digits(cu, lc, b, cf))) == gpu
    return ok
if __name__ == "__main__":
    b = int(sys.argv[1]) if len(sys.argv) > 1 else 23
    s, cnt, ls, lc, limbs = P[b]
    e, K = chunk16(b)
    res = []
    types = ['T1', 'T2', 'T3', 'T4', 'T5']
    for which, nl, nd in (('S', 2*limbs, ls), ('C', 3*limbs, lc)):
        for k in range(-(-nd // e)):
            for i in range(nl):
                for t in types:
                    f = {(k, i, t)}
                    sc = score(b, f, ()) if which == 'S' else score(b, (), f)
                    res.append((sc, which, k, i, t))
    res.sort(reverse=True)
    print(f"b{b} single faults, best:", res[:12])
