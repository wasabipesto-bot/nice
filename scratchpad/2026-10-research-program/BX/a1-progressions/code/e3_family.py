"""E3: ramified p-adic families. b = p*q, p prime, p exactly divides b. F_j = {n : p^j | n}.
Check (a) n^2 mod b^c, n^3 mod b^c are functions of x mod q^c (x = n/p^j) when c <= 2j (resp 3j),
(b) whether niceness-relevant statistics are the same in F_j as in the whole range:
    - P(low c digits of n^2 and n^3 all distinct) (2c digits)
    - distribution of the number of distinct digits among all b output digits."""
import sys, random
from collections import Counter
from common import nice_range, ndig, digits
b, p, j, c, S = map(int, sys.argv[1:6])
q = b // p; assert b % p == 0 and q % p != 0
lo, hi = nice_range(b); L = ndig(lo, b)
random.seed(11)
def sample_family(k):
    xs_lo = -(-lo // p**j); xs_hi = (hi - 1) // p**j
    return [p**j * random.randint(xs_lo, xs_hi) for _ in range(k)]
def sample_all(k):
    return [random.randint(lo, hi - 1) for _ in range(k)]
def stats(ns, name):
    cnt0 = 0; low_ok = 0; dist = Counter(); check = {}
    func_ok = True
    for n in ns:
        d2 = digits(n*n, b); d3 = digits(n**3, b)
        low = d2[:c] + d3[:c]
        if d2[0] == d3[0]: continue
        cnt0 += 1
        low_ok += len(set(low)) == len(low)
        dist[len(set(d2 + d3))] += 1
        key = (n // p**j) % q**c
        val = (n*n % b**c, n**3 % b**c)
        if name == 'family':
            if check.setdefault(key, val) != val: func_ok = False
    tot = cnt0; print(f'  P(last digits of n^2,n^3 distinct) = {cnt0/len(ns):.3f}')
    mean = sum(k*v for k, v in dist.items()) / tot
    tail = sum(v for k, v in dist.items() if k >= b - 4) / tot
    print(f'{name:7s} N={tot} P(low 2c={2*c} distinct | last pair ok)={low_ok/tot:.4f}  mean #distinct={mean:.3f}  P(#distinct>=b-4)={tail:.2e}',
          f' [x mod q^c determines low c of n^2,n^3: {func_ok}]' if name == 'family' else '')
    return dist
print(f'base {b} = {p}*{q}, L={L}, j={j}, c={c}')
stats(sample_family(S), 'family')
stats(sample_all(S), 'all')
