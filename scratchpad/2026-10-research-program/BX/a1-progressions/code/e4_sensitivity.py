"""E4: sensitivity of every output digit to every single digit of n. For random n in the range and each
digit position i of n, vary n_i over all b values and count how many distinct values output digit p takes
(1 = insensitive/certified without n_i; ~0.63b = pseudo-random; b = bijective). A middle digit that is
insensitive to some middle digit of n would be a partial-information handle."""
import sys, random
from common import nice_range, ndig, digits
b, S = int(sys.argv[1]), int(sys.argv[2])
lo, hi = nice_range(b); L = ndig(lo, b); L2 = ndig(lo*lo, b); L3 = ndig(lo**3, b)
random.seed(6)
acc = {}
for _ in range(S):
    n = random.randrange(lo, hi)
    nd = digits(n, b, L)
    for i in range(L):
        vals2 = [set() for _ in range(L2 + 1)]; vals3 = [set() for _ in range(L3 + 1)]
        base = n - nd[i] * b**i
        for d in range(b):
            m = base + d * b**i
            dd2 = digits(m*m, b, L2 + 1); dd3 = digits(m**3, b, L3 + 1)
            for p in range(L2): vals2[p].add(dd2[p])
            for p in range(L3): vals3[p].add(dd3[p])
        for p in range(L2): acc[('sq', p, i)] = acc.get(('sq', p, i), 0) + len(vals2[p])
        for p in range(L3): acc[('cu', p, i)] = acc.get(('cu', p, i), 0) + len(vals3[p])
print(f'b{b} L={L}: mean #distinct values of output digit (rows) when n digit i (cols, 0 = lowest) varies over b values; {S} samples')
print('       ' + ' '.join(f'i={i:<4d}' for i in range(L)))
for w, LL in (('sq', L2), ('cu', L3)):
    for p in range(LL):
        print(f'{w}{p:<4d} ' + ' '.join(f'{acc[(w, p, i)]/S:6.1f}' for i in range(L)))
