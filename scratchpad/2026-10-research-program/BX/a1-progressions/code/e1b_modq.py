"""E1b: middle output digits vs n mod q (q = 2..Q) and vs (n mod q, top digit of n).
Null-corrected determinacy D. Base b exhaustive (uint64 numpy, b <= 23)."""
import sys, numpy as np
from common import nice_range, ndig
from e1_entropy import H_cond
b = int(sys.argv[1]); Q = int(sys.argv[2])
lo, hi = nice_range(b); L = ndig(lo, b); L2 = ndig(lo*lo, b); L3 = ndig(lo**3, b)
n = np.arange(lo, hi, dtype=np.uint64); sq = n*n; cu = sq*n
mid = [('sq', p, ((sq // np.uint64(b)**np.uint64(p)) % np.uint64(b)).astype(np.int64)) for p in range(3, L2-3)] + \
      [('cu', p, ((cu // np.uint64(b)**np.uint64(p)) % np.uint64(b)).astype(np.int64)) for p in range(3, L3-4)]
rng = np.random.default_rng(3)
best = {}
for q in range(2, Q+1):
    x = (n % np.uint64(q)).astype(np.int64); xs = rng.permutation(x)
    for (w, p, y) in mid:
        h0 = H_cond(y, np.zeros_like(y), b)
        d = (H_cond(y, xs, b) - H_cond(y, x, b)) / h0
        if d > best.get((w, p), (-1, 0))[0]: best[(w, p)] = (d, q)
print(f'base {b} N={len(n)} q<= {Q}: max null-corrected D per middle position (D, q):')
print(' '.join(f'{w}{p}:{d:.3f}@{q}' for (w, p), (d, q) in best.items()))
