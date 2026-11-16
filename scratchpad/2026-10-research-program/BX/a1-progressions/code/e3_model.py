"""E3 model: per-member cost of the flat prefix-suffix join (PSJ, N5 weights) over the whole range
vs inside the ramified family F_j = {n : p^j | n}, b = p*q, p prime exactly dividing b.
Family bottoms are x mod q^c (x = n/p^j), c <= 2j: q^c classes certify the low c digits of n^2 AND n^3.
Uniform-digit model P(m) = b!/((b-m)! b^m). Weights (AND units): list entry 50, pair 1, survivor 45.
Top certificate cT(t) = 2t - 2. Pairs must identify one member (top interval <= bottom modulus).
Reports per-member cost (generic per admissible-free n), and lambda bookkeeping."""
import sys, math
from common import nice_range, ndig
WE, WP, WS = 50.0, 1.0, 45.0
def P(b, m):
    m = int(round(m))
    if m > b: return 0.0
    return math.exp(sum(math.log(1 - i / b) for i in range(max(0, m))))
def generic(b, L, N):
    best = None
    for t in range(2, L + 1):
        for k in range(1, L + 1):
            if t + k < L: continue
            cT, cB = 2 * t - 2, 2 * k
            tops = N / b ** (L - t) * P(b, cT)
            bots = sum(min(b ** kk, N) * P(b, 2 * kk - 2) for kk in range(1, k + 1))  # every tree level: parents' survivors x b children
            cost = WE * (tops + bots) / N + WP * P(b, cT) * P(b, cB) + WS * P(b, cT + cB)
            if best is None or cost < best[0]: best = (cost, t, k)
    return best
def family(b, p, L, N, j):
    q = b // p; M = N / p ** j
    best = None
    for t in range(2, L + 1):
        for c in range(1, 2 * j + 1):
            if (L - t) * math.log(b) > j * math.log(p) + c * math.log(q): continue  # pair -> <= 1 member
            cT, cB = 2 * t - 2, 2 * c
            tops = N / b ** (L - t) * P(b, cT)
            bots = sum(min(q ** cc, M) * P(b, 2 * cc - 2) for cc in range(1, c + 1))  # every level of the q-adic tree
            cost = WE * (tops + bots) / M + WP * P(b, cT) * P(b, cB) + WS * P(b, cT + cB)
            if best is None or cost < best[0]: best = (cost, t, c, M)
    return best
if __name__ == '__main__':
    for arg in sys.argv[1:]:
        b, p = map(int, arg.split(':'))
        lo, hi = nice_range(b); L = ndig(lo, b); N = hi - lo
        g = generic(b, L, N)
        print(f'b{b} = {p}*{b//p}, L={L}, N={N:.2e}: generic {g[0]:.2e} AND-units/n at (t={g[1]}, k={g[2]})')
        for j in range(1, L):
            f = family(b, p, L, N, j)
            if f is None or f[3] < 1e3: break
            print(f'   j={j:2d} members {f[3]:.1e} (x{p**-j:.0e} of range): {f[0]:.2e}/member (t={f[1]}, c={f[2]})'
                  f'  per-member gain x{g[0]/f[0]:.2f}; cost of the slice / cost of the base = {f[0]*f[3]/(g[0]*N):.1e}')
