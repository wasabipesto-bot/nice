"""E3 exact: pure bottom-up tree (prune on repeated certified low digits of n^2, n^3) over the whole
range vs over the ramified slice {p^j | n}, b = p*q. Counts every node created. Prints nodes per
member, leaves (members whose certified digits are all distinct, then fully checked) per member."""
import sys
from common import nice_range, ndig, digits, is_nice
def ok(vals_digits):
    return len(set(vals_digits)) == len(vals_digits)
def low_digits(v, b, k):
    out = []
    for _ in range(k):
        out.append(v % b); v //= b
    return out
def generic(b):
    lo, hi = nice_range(b); N = hi - lo
    level = [0]; mod = 1; nodes = 0; c = 0
    while mod < hi:
        new = []
        for r in level:
            for d in range(b):
                nodes += 1
                rr = r + d * mod
                cert = low_digits(rr * rr, b, c + 1) + low_digits(rr ** 3, b, c + 1)
                if ok(cert): new.append(rr)
        level = new; mod *= b; c += 1
    leaves = 0; nice = 0
    for r in level:
        for n in range(r + ((lo - r + mod - 1) // mod) * mod, hi, mod):
            leaves += 1; nice += is_nice(n, b)
    return N, nodes, leaves, nice
def family(b, p, j):
    q = b // p
    lo, hi = nice_range(b)
    xlo = -(-lo // p ** j); xhi = -(-hi // p ** j); M = xhi - xlo
    # state: (x mod Q, c, a) ; Q = q^c p^a
    level = [0]; c = a = 0; Q = 1; nodes = 0
    while Q < xhi:
        phase1 = c < 2 * j
        steps = [(dq, 0) for dq in range(q)] if phase1 else [(dq, dp) for dq in range(q) for dp in range(p)]
        newQ = Q * q * (1 if phase1 else p)
        new = []
        for r in level:
            # lift r (mod Q) to residues mod newQ: enumerate all lifts
            for t in range(newQ // Q):
                x = r + t * Q
                nodes += 1
                n = p ** j * x
                c2 = min(c + 1, (a + (0 if phase1 else 1)) + 2 * j); c3 = min(c + 1, (a + (0 if phase1 else 1)) + 3 * j)
                cert = low_digits(n * n, b, c2) + low_digits(n ** 3, b, c3)
                if ok(cert): new.append(x)
        level = new; Q = newQ; c += 1; a += (0 if phase1 else 1)
    leaves = 0; nice = 0
    for r in level:
        for x in range(r + ((xlo - r + Q - 1) // Q) * Q, xhi, Q):
            leaves += 1; nice += is_nice(p ** j * x, b)
    return M, nodes, leaves, nice
if __name__ == '__main__':
    b, p = int(sys.argv[1]), int(sys.argv[2])
    N, nodes, leaves, nice = generic(b)
    print(f'b{b} generic: members {N:.3e} nodes {nodes:.3e} ({nodes/N:.3e}/member) leaves {leaves:.3e} ({leaves/N:.3e}/member) nice {nice}', flush=True)
    for j in range(1, int(sys.argv[3]) + 1):
        M, nodes, leaves, nice = family(b, p, j)
        print(f'b{b} slice p^{j}: members {M:.3e} nodes {nodes:.3e} ({nodes/M:.3e}/member) leaves {leaves:.3e} ({leaves/M:.3e}/member) nice {nice}', flush=True)
