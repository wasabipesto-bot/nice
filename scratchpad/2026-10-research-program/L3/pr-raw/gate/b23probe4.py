import itertools
from b23probe3 import digits, obs, P, to_limbs
b = 23; s, cnt, ls, lc, limbs = P[b]
M32 = (1 << 32) - 1
res = []
for ss in [(3, 3, 2), (0, 3, 2), (1, 3, 2), (2, 3, 2)]:
    for cs in [(3, 3, 2), (0, 3, 2), (1, 3, 2), (2, 3, 2), (0, 0, 2), (1, 1, 2)]:
        ok = 0
        for n in range(s, s + cnt):
            sq = to_limbs(n*n, 2); cu = to_limbs(n**3, 3)
            t0 = sq[0] * n; t1 = sq[1] * n + (t0 >> 32)
            true = len(set(digits(sq, ls, b) + digits(cu, lc, b)))
            gpu = obs.get((b, n), (true, true))[1]
            ok += len(set(digits(sq, ls, b, ss, n*n) + digits(cu, lc, b, cs, t1))) == gpu
        res.append((ok, ss, cs))
res.sort(reverse=True); print(res[:8])
