# Independent re-implementation of check_kernel (pr/check-d 0f3332d) from the kernel text,
# with u32 overflow assertions and dividend tracking, against Python big-int digits.
import random, sys
M32 = (1 << 32) - 1
def ilog2(x): return x.bit_length() - 1
def magic(d):
    s = ilog2(d); k = 32 + s
    m = -(-(1 << k) // d)
    assert m < (1 << 32)
    return m, s
MAXDIV = {}
def d_div(x, d, tag):
    assert 0 <= x <= M32, (x, d, tag)
    MAXDIV[tag] = max(MAXDIV.get(tag, 0), x)
    if d & (d - 1) == 0:
        return x >> (d.bit_length() - 1)
    m, s = magic(d)
    q = ((x * m) >> 32) >> s
    assert q == x // d, ("magic wrong", x, d)
    return q
def u32(x, tag):
    assert 0 <= x <= M32, ("u32 overflow", tag, x)
    return x
def inv_mod(o, bits): return pow(o, -1, 1 << bits)

def part_limbs(x, pend, nn, o, c, l, base):
    pd = pend
    if c > 0:
        if o % 2 == 1:
            if c == 1:
                nn[o // 2] = u32(pend + x * base, 'pl1')
            else:
                q = d_div(x, base, 'part_b')
                nn[o // 2] = u32(pend + (x - q * base) * base, 'pl2')
                x = q
        o2 = o + o % 2; c2 = c - o % 2
        for q in range(c2 // 2):
            if q + 1 == c2 // 2 and c2 % 2 == 0:
                nn[o2 // 2 + q] = x
            else:
                qq = d_div(x, base * base, 'part_bb')
                nn[o2 // 2 + q] = x - qq * base * base
                x = qq
        if c2 % 2 == 1:
            if o2 + c2 == l:
                nn[(l - 1) // 2] = x
            else:
                pd = x
    return pd

def wide_div(v, d):
    x3 = v[1] >> 16
    q3 = d_div(x3, d, 'wide')
    x2 = ((x3 - q3 * d) << 16) | (v[1] & 0xFFFF)
    q2 = d_div(x2, d, 'wide')
    x1 = ((x2 - q2 * d) << 16) | (v[0] >> 16)
    q1 = d_div(x1, d, 'wide')
    x0 = ((x1 - q1 * d) << 16) | (v[0] & 0xFFFF)
    q0 = d_div(x0, d, 'wide')
    v[1] = (q3 << 16) | q2
    v[0] = (q1 << 16) | q0
    return x0 - q0 * d

def part_limbs_wide(v, pend, nn, o, c, l, base):
    pd = pend
    if o % 2 == 1:
        r = wide_div(v, base)
        nn[o // 2] = pend + r * base
    o2 = o + o % 2; c2 = c - o % 2
    for q in range(c2 // 2):
        r = wide_div(v, base * base)
        nn[o2 // 2 + q] = r
    if c2 % 2 == 1:
        if o2 + c2 == l:
            nn[(l - 1) // 2] = v[0]
        else:
            pd = v[0]
    return pd

def popc(x): return bin(x).count('1')

def kernel(base, l, s2, s3, f0, k2, g, p, w6, r0):
    bb = base * base
    nl = -(-l // 2); ql = -(-s2 // 2); cl = -(-s3 // 2)
    gl = min(g // 2, cl - 1)
    f0c = min(f0, l); k2c = min(k2, l); hdig = l - min(k2, l)
    hwide = base ** hdig > (1 << 31)
    D = base ** (k2 - f0)
    hz = (D & -D).bit_length() - 1
    hinv = inv_mod(D >> hz, 64)
    x = (p - w6) & ((1 << 64) - 1)
    nn = [None] * nl
    pend = part_limbs(r0, 0, nn, 0, f0c, l, base)
    pend = part_limbs(w6, pend, nn, f0c, k2c - f0c, l, base)
    if hdig > 0:
        if hwide:
            h = ((x >> hz) * hinv) & ((1 << 64) - 1)
            hv = [h & M32, h >> 32]
            part_limbs_wide(hv, pend, nn, k2c, hdig, l, base)
        else:
            h = (((x >> hz) & M32) * (hinv & M32)) & M32
            part_limbs(h, pend, nn, k2c, hdig, l, base)
    assert None not in nn
    sq = [None] * ql; carry = 0; mask = 0
    def put2(mask, y):
        hi = d_div(y, base, 'split'); lo = y - hi * base
        assert lo < 64 and hi < 64
        return mask | (1 << lo) | (1 << hi)
    for k in range(ql):
        s = 0
        for i in range(nl):
            if 2 * i < k and k < i + nl:
                s = u32(s + nn[i] * nn[k - i], 'sq_s')
        x2 = u32(carry + s * 2, 'sq_x2')
        if k % 2 == 0 and k // 2 < nl:
            x2 = u32(x2 + nn[k // 2] * nn[k // 2], 'sq_x2b')
        if k + 1 == ql:
            sq[k] = x2
            if s2 % 2 == 0: mask = put2(mask, x2)
            else:
                assert x2 < base; mask |= 1 << x2
        else:
            q = d_div(x2, bb, 'col2'); y = x2 - q * bb
            sq[k] = y; carry = q; mask = put2(mask, y)
    carry = 0
    for k in range(gl):
        x3 = carry
        for j in range(nl):
            if j <= k and k - j < ql:
                x3 = u32(x3 + sq[k - j] * nn[j], 'cu_gate')
        q = d_div(x3, bb, 'col3'); carry = q
        mask = put2(mask, x3 - q * bb)
    seen = popc(mask)
    passed = seen == s2 + 2 * gl
    for k in range(gl, cl):  # count mode: always
        x3 = carry
        for j in range(nl):
            if j <= k and k - j < ql:
                x3 = u32(x3 + sq[k - j] * nn[j], 'cu_rest')
        if k + 1 == cl:
            if s3 % 2 == 0: mask = put2(mask, x3)
            else:
                assert x3 < base; mask |= 1 << x3
        else:
            q = d_div(x3, bb, 'col3'); carry = q
            mask = put2(mask, x3 - q * bb)
    return popc(mask), passed, mask, nn

def digits(x, b):
    d = []
    while x: d.append(x % b); x //= b
    return d

def reference(base, s2, s3, gl, n):
    d2 = digits(n * n, base); d3 = digits(n ** 3, base)
    assert len(d2) == s2 and len(d3) == s3
    mask = 0
    for d in d2 + d3: mask |= 1 << d
    seen = d2 + d3[:2 * gl]
    return popc(mask), len(set(seen)) == len(seen), mask

def ndig(x, b): return len(digits(x, b))

def iroot_ceil(t, k):
    # least m with m**k >= t
    lo, hi = 0, 1
    while hi ** k < t: hi *= 2
    while lo < hi:
        m = (lo + hi) // 2
        if m ** k >= t: hi = m
        else: lo = m + 1
    return lo

def band(base, s2, s3, l):
    lo = max(base ** (l - 1), iroot_ceil(base ** (s2 - 1), 2), iroot_ceil(base ** (s3 - 1), 3))
    hi = min(base ** l, iroot_ceil(base ** s2, 2), iroot_ceil(base ** s3, 3))
    return lo, hi

def run_shape(base, l, s2, s3, f0, k2, g, ns):
    cl = -(-s3 // 2); gl = min(g // 2, cl - 1)
    W = base ** f0; Mm = base ** (k2 - f0)
    cnt = 0
    for n in ns:
        p = n // W; r0 = n % W; w6 = p % Mm
        if p >= 1 << 64: continue
        u, ps, m, nn = kernel(base, l, s2, s3, f0, k2, g, p, w6, r0)
        ru, rps, rm = reference(base, s2, s3, gl, n)
        assert (u, ps, m) == (ru, rps, rm), (base, n, (u, ps, m), (ru, rps, rm))
        # n from limbs
        v = 0
        for x in reversed(nn): v = v * base * base + x
        assert v == n
        cnt += 1
    return cnt

if __name__ == '__main__':
    random.seed(int(sys.argv[1]) if len(sys.argv) > 1 else 1)
    total = 0
    # production shapes: bases 40-64, f0=3, k2=8, the nice band (s2+s3=b)
    for b in range(40, 65):
        for l in range(7, 15):
            for s2 in (2 * l - 1, 2 * l):
                s3 = b - s2
                if not (3 * l - 2 <= s3 <= 3 * l): continue
                lo, hi = band(b, s2, s3, l)
                if lo >= hi: continue
                ns = set([lo, lo + 1, hi - 1, hi - 2])
                # n whose square / cube is just below a power of b (top digits b-1)
                for s, k in ((s2, 2), (s3, 3)):
                    t = iroot_ceil(b ** s, k) - 1
                    if lo <= t < hi: ns.add(t)
                for _ in range(3000): ns.add(random.randrange(lo, hi))
                # n with many b-1 digits inside the band
                for i in range(l):
                    x = hi - 1 - (hi - 1) % b ** i + (b ** i - 1)
                    if lo <= x < hi: ns.add(x)
                total += run_shape(b, l, s2, s3, 3, 8, 10, sorted(ns))
                print(f"b{b} l{l} s2={s2} s3={s3} band [{lo},{hi}) ok", flush=True)
    print("total", total)
    print("max dividends by tag:")
    for k, v in sorted(MAXDIV.items()):
        print(f"  {k}: {v} (2^{v.bit_length() if v else 0} bits)")
