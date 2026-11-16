# shared helpers for A1 experiments
def ndig(x, b):
    c = 0
    while x:
        x //= b; c += 1
    return c

def digits(x, b, width=None):
    out = []
    while x:
        out.append(x % b); x //= b
    if width is not None:
        out += [0] * (width - len(out))
    return out  # little-endian

def nice_range(b):
    """n with ndig(n^2)+ndig(n^3) == b (contiguous). Return (lo, hi) half-open."""
    import math
    # binary search for smallest n with total >= b, and smallest with total > b
    def tot(n): return ndig(n*n, b) + ndig(n**3, b)
    def first(target):
        lo, hi = 1, 1
        while tot(hi) < target: hi *= 2
        while lo < hi:
            mid = (lo + hi) // 2
            if tot(mid) >= target: hi = mid
            else: lo = mid + 1
        return lo
    lo = first(b); hi = first(b + 1)
    return lo, hi

def is_nice(n, b):
    d = digits(n*n, b) + digits(n**3, b)
    return len(d) == b and len(set(d)) == b
