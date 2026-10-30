"""b23 per-n (run length 1): which chunk-0 limb step, with the quotient read
from the low 16 bits instead of the high 16 (`(X & 0xFFFF)` for `X >> 16`
inside c1 = (rem << 16) | (X >> 16)), reproduces the M4's unique counts."""
import itertools
from explore6 import obs, P
from seed_model import chunk16, to_limbs, M32
def digits(v, ndig, b, sites=()):
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            c1 = ((rem << 16) | (x >> 16)) & M32
            if (k, i) in sites:
                q1 = (((rem << 16) | (x & 0xFFFF)) & M32) // K
            else:
                q1 = c1 // K
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = c2 // K; rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b; out.append(chunk - cq * b); chunk = cq
    return out
def score(b, ss, cs):
    s, cnt, ls, lc, limbs = P[b]; ok = 0
    for n in range(s, s + cnt):
        sq = to_limbs(n*n, 2*limbs); cu = to_limbs(n**3, 3*limbs)
        true = len(set(digits(sq, ls, b) + digits(cu, lc, b)))
        gpu = obs.get((b, n), (true, true))[1]
        ok += len(set(digits(sq, ls, b, ss) + digits(cu, lc, b, cs))) == gpu
    return ok
if __name__ == "__main__":
    for b in (23, 50):
        limbs = P[b][4]
        Ss = [()] + [((0, i),) for i in range(2*limbs)] + [tuple((0, i) for i in range(2*limbs))]
        Cs = [()] + [((0, i),) for i in range(3*limbs)] + [tuple((0, i) for i in range(3*limbs))]
        res = sorted(((score(b, ss, cs), ss, cs) for ss in Ss for cs in Cs), reverse=True)
        print(f"b{b}", P[b][1], "n:", res[:5], flush=True)
