import re, os, itertools
from seed_model import chunk16, to_limbs, M32
HERE = os.path.dirname(os.path.abspath(__file__))
obs = {}
for l in open(os.path.join(HERE, "..", "m4", "diag3.log")):
    m = re.match(r".*WRONG b(\d+) n=(\d+) cpu=\[\((\d+), 1\)\] fd=\[\((\d+), 1\)\]", l)
    if m:
        b, n, c, f = map(int, m.groups()); obs[(b, n)] = (c, f)

def digits(v, ndig, b, combo):
    """combo = (q1src, r1src, lowsrc, q2mode): sources 'x' (the top limb, hi)
    or 'y' (the limb below, lo) for the top limb's first step only."""
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            if k == 0 and i == n - 1:
                y = v[i - 1]
                src = {'x': x, 'y': y}
                q1 = (src[combo[0]] >> 16) // K
                c1 = src[combo[1]] >> 16
                r1 = (c1 - q1 * K) & M32
                c2 = ((r1 << 16) | (src[combo[2]] & 0xFFFF)) & M32
                q2 = c2 // K
                rem = (c2 - q2 * K) & M32
                v[i] = ((q1 << 16) | q2) & M32
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

P = {23: (795831, 3000, 9, 14, 1), 50: (26507984537059635, 400, 20, 30, 2)}
combos = list(itertools.product('xy', repeat=3))
for cs in combos:
    for cc in [('x','x','x')] + [c for c in combos if c != ('x','x','x')]:
        res = {}
        for b, (s, cnt, ls, lc, limbs) in P.items():
            ok = 0
            for n in range(s, s + cnt):
                sq = to_limbs(n*n, 2*limbs); cu = to_limbs(n**3, 3*limbs)
                true = len(set(digits(sq, ls, b, ('x','x','x')) + digits(cu, lc, b, ('x','x','x'))))
                gpu = obs.get((b, n), (true, true))[1]
                ok += len(set(digits(sq, ls, b, cs) + digits(cu, lc, b, cc))) == gpu
            res[b] = ok
        if res[23] > 1000 or res[50] > 100:
            print("S", ''.join(cs), "C", ''.join(cc), res)
