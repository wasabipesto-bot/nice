"""H2 against the M4's per-n results (diag3.log, run length 1)."""
from b23probe import obs, P
from seed_model import chunk16, to_limbs, M32
def digits(v, ndig, b, h2):
    v = list(v); n = len(v); e, K = chunk16(b); out = []
    for k in range(-(-ndig // e)):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii; x = v[i]
            c1 = ((rem << 16) | (x >> 16)) & M32
            q1 = (x & 0xFFFF) // K if (h2 and k == 0 and ii == 0 and K & (K - 1)) else c1 // K
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (x & 0xFFFF)) & M32
            q2 = c2 // K; rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b; out.append(chunk - cq * b); chunk = cq
    return out
for b, (s, cnt, ls, lc, limbs) in P.items():
    ok = okc = 0
    for n in range(s, s + cnt):
        sq = to_limbs(n*n, 2*limbs); cu = to_limbs(n**3, 3*limbs)
        true = len(set(digits(sq, ls, b, False) + digits(cu, lc, b, False)))
        gpu = obs.get((b, n), (true, true))[1]
        ok += len(set(digits(sq, ls, b, True) + digits(cu, lc, b, True))) == gpu
        okc += true == gpu
    print(f"b{b}: H2 reproduces the M4's unique count for {ok} of {cnt} n (the correct model: {okc})")
