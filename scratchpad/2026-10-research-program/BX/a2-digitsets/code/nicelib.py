"""Small exact helpers for the a2-digitsets experiments (pure Python, small bases)."""
import math


def digits(x, b):
    out = []
    while x:
        out.append(x % b)
        x //= b
    return out or [0]


def ndig(x, b):
    c = 0
    while x:
        c += 1
        x //= b
    return max(c, 1)


def nice_range(b):
    """Maximal [lo, hi) with ndig(n^2)+ndig(n^3) == b (monotone in n)."""
    def f(n):
        return ndig(n * n, b) + ndig(n ** 3, b)
    # find first n with f(n) >= b
    lo, hi = 1, 2
    while f(hi) < b:
        hi *= 2
    while lo < hi:
        m = (lo + hi) // 2
        if f(m) < b:
            lo = m + 1
        else:
            hi = m
    start = lo
    if f(start) != b:
        return start, start
    lo, hi = start, start * 2 + 2
    while f(hi) <= b:
        hi *= 2
    while lo < hi:
        m = (lo + hi) // 2
        if f(m) <= b:
            lo = m + 1
        else:
            hi = m
    return start, lo


def residues(b):
    m = b - 1
    t = (b * (b - 1) // 2) % m
    return [r for r in range(m) if (r * r + r ** 3) % m == t]


def is_nice(n, b):
    seen = 0
    for x in (n * n, n ** 3):
        while x:
            bit = 1 << (x % b)
            if seen & bit:
                return False
            seen |= bit
            x //= b
    return seen == (1 << b) - 1


def top_cert(lo_n, hi_n, b):
    """Positions/digits of n^2 and n^3 constant over n in [lo_n, hi_n] (inclusive).
    Returns (list of (which, pos, digit)), or None if lengths differ (then only
    digits common to both ends at equal lengths are taken)."""
    out = []
    for which, e in ((2, 2), (3, 3)):
        a, z = lo_n ** e, hi_n ** e
        if ndig(a, b) != ndig(z, b):
            continue
        da, dz = digits(a, b), digits(z, b)
        for p in range(len(da) - 1, -1, -1):
            if da[p] == dz[p]:
                out.append((which, p, da[p]))
            else:
                break
    return out


def bottom_cert(r, k, b):
    """Low k digits of n^2 and n^3 for n = r mod b^k."""
    out = []
    M = b ** k
    for which, e in ((2, 2), (3, 3)):
        x = pow(r, e, M)
        for p in range(k):
            out.append((which, p, x % b))
            x //= b
    return out


def mask_of(cert):
    m = 0
    for _, _, d in cert:
        bit = 1 << d
        if m & bit:
            return None
        m |= bit
    return m
