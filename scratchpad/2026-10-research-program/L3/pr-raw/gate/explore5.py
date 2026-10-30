import re, os
from seed_model import chunk16, to_limbs, M32
HERE = os.path.dirname(os.path.abspath(__file__))
obs = {}
for l in open(os.path.join(HERE, "..", "m4", "diag3.log")):
    m = re.match(r".*WRONG b(\d+) n=(\d+) cpu=\[\((\d+), 1\)\] fd=\[\((\d+), 1\)\]", l)
    if m:
        b, n, c, f = map(int, m.groups()); obs[(b, n)] = (c, f)

def digits(v, ndig, b, chunks=()):
    """H1: in chunk k in `chunks`, the top limb's first quotient is v/K
    instead of (v >> 16)/K (the shift is lost for the quotient only)."""
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            c1 = ((rem << 16) | (x >> 16)) & M32
            q1 = (x // K) if (ii == 0 and (chunks == 'all' or k in chunks)) else c1 // K
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = c2 // K; rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b; out.append(chunk - cq * b); chunk = cq
    return out

P = {23: (795831, 3000, 9, 14, 1), 50: (26507984537059635, 400, 20, 30, 2)}
for sch, cch in [((), ()), ((0,), ()), ('all', ()), ((), 'all'), ('all', 'all'), ((0,), (0,))]:
    res = {}
    for b, (s, cnt, ls, lc, limbs) in P.items():
        ok = 0
        for n in range(s, s + cnt):
            sq = to_limbs(n*n, 2*limbs); cu = to_limbs(n**3, 3*limbs)
            true = len(set(digits(sq, ls, b) + digits(cu, lc, b)))
            gpu = obs.get((b, n), (true, true))[1]
            ok += len(set(digits(sq, ls, b, sch) + digits(cu, lc, b, cch))) == gpu
        res[b] = f"{ok}/{cnt}"
    print(f"S chunks {str(sch):6s} C chunks {str(cch):6s}", res)
