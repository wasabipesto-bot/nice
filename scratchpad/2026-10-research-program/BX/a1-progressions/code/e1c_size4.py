"""E1c: E1 at L = 6 (b28) with views of exactly L-2 = 4 digit positions of n, 3M-sample, null-corrected.
Prints max D per output position over the 15 views and the view achieving it."""
import random, itertools, numpy as np
from common import nice_range, ndig, digits
from e1_entropy import H_cond
b = 28; S = 3_000_000
lo, hi = nice_range(b); L = ndig(lo, b); L2 = ndig(lo*lo, b); L3 = ndig(lo**3, b)
random.seed(4); ns = [random.randrange(lo, hi) for _ in range(S)]
D1 = np.array([digits(v, b, L) for v in ns], dtype=np.int64)
D2 = np.array([digits(v*v, b, L2) for v in ns], dtype=np.int64)
D3 = np.array([digits(v**3, b, L3) for v in ns], dtype=np.int64)
outs = [(f'sq{p}', D2[:, p]) for p in range(L2)] + [(f'cu{p}', D3[:, p]) for p in range(L3)]
rng = np.random.default_rng(9)
best = {}
for Sv in itertools.combinations(range(L), L - 2):
    x = np.zeros(S, dtype=np.int64)
    for i in Sv: x = x * b + D1[:, i]
    xs = rng.permutation(x)
    for name, y in outs:
        h0 = H_cond(y, np.zeros_like(y), b)
        d = (H_cond(y, xs, b) - H_cond(y, x, b)) / h0
        if d > best.get(name, (-9, None))[0]: best[name] = (d, Sv)
print(f'b{b} L={L} sample {S}, views = all {L-2}-subsets of n digit positions; max null-corrected D:')
print(' '.join(f'{k}:{v[0]:.2f}{list(v[1])}' for k, v in best.items()))
