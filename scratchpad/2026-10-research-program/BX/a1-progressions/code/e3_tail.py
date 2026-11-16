"""Tail of #distinct output digits over ALL members of the range vs the slice p^j | n
(proxy for p_nice per member). Exhaustive for small b, sampled otherwise."""
import sys, random
from collections import Counter
from common import nice_range, digits
b, p, jmax, S = map(int, sys.argv[1:5])
lo, hi = nice_range(b)
def tail(ns):
    cnt = Counter(len(set(digits(n*n, b) + digits(n**3, b))) for n in ns)
    tot = len(ns)
    return tot, [sum(v for k, v in cnt.items() if k >= b - d) / tot for d in range(0, 6)]
random.seed(2)
def members(j):
    step = p ** j; first = -(-lo // step) * step
    M = (hi - 1 - first) // step + 1
    if M <= S: return [first + i * step for i in range(M)]
    return [first + step * random.randrange(M) for _ in range(S)]
for j in range(0, jmax + 1):
    tot, t = tail(members(j))
    print(f'b{b} j={j} sample {tot}: P(#distinct >= b-d) d=0..5: ' + ' '.join(f'{x:.2e}' for x in t))
