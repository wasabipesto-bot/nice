#!/usr/bin/env python3
"""Host mirror of the join's per-pair digit chain at the production shape
(T2.4 soundness audit): bucket_kernel's digit columns and ext_q packing (key
level), join_kernel's key-digit terms (t2, t3, sigma, c3 unpacked from two
words), the top record's word 6 and D = w6 / b^(k - f0), the lean
fixed-point prefilter (ceil constants, mul_hi digits) and the bit-reversed
membership test, against the true digits of n^2 and n^3 (Python big ints).

Shape: f0 = 3, p = 2, k = 6, k2 = 8 (mid = 2), key level; bases 40-64; n
random in each base's nice band (digit count l from the band), plus n with
digit runs of 0 and b - 1 around positions 0-8.

Checks, per n:
  - fixed positions f0..f0+p (3, 4) of R'^2, R'^3 from the bucket columns
    equal n^2's and n^3's digits there;
  - the key digit's output digits (position 5) from t2, t3 equal n's;
  - the prefilter's digits (positions 6, 7) by the lean fixed point equal n's;
  - the lean verdict equals the definition: digits 0..7 of n^2 and n^3
    distinct (16 digits), and, for a random seed mask of digits from higher
    positions, none of positions 6, 7 in it.

Usage: python3 -I prefilter_chain.py [n_per_base]
"""
import random
import sys

def digits(x, b, n):
    out = []
    for _ in range(n):
        out.append(x % b)
        x //= b
    return out

def mul_hi(a, b):
    return ((a & 0xFFFFFFFF) * (b & 0xFFFFFFFF)) >> 32

def rev64(x):
    return int(format(x & (2**64 - 1), "064b")[::-1], 2)

def band(b):
    # n with s2 + s3 = b: n^2 has s2, n^3 has s3 digits. Take the l-digit
    # n range roughly: b^((b-1)/5) .. b^(b/5); exact digit counts are
    # filtered below.
    lo = int(round(b ** ((b - 1) / 5)))
    hi = int(round(b ** (b / 5)))
    return lo, hi

def ndig(x, b):
    n = 0
    while x:
        x //= b
        n += 1
    return n

def run_base(b, count, rng):
    f0, pp, k, k2 = 3, 2, 6, 8
    mid = k2 - k
    M = b ** (mid + 1)
    bm = b ** mid
    C = -(-(1 << 32) // (b * b))
    Q, R = divmod(1 << 32, b * b)
    lo, hi = band(b)
    bad = 0
    checked = 0
    for t in range(count):
        n = rng.randrange(lo, hi)
        if t % 4 == 1:
            # runs of b-1 / 0 in the low digits
            dd = digits(n, b, 12)
            for j in range(9):
                dd[j] = rng.choice([0, b - 1, dd[j]])
            n = n - n % b**12 + sum(d * b**j for j, d in enumerate(dd))
        if not (lo <= n < hi) or ndig(n * n, b) + ndig(n**3, b) != b:
            continue
        checked += 1
        n2, n3 = n * n, n**3
        D2, D3 = digits(n2, b, k2), digits(n3, b, k2)
        r0 = n % b**f0
        v = (n // b**f0) % b**pp
        dkey = (n // b ** (k - 1)) % b
        P = n // b**f0
        # bucket_kernel: digits of R' = r0 + v b^f0 (key digit 0), columns
        d = digits(r0, b, f0) + digits(v, b, pp) + [0] * (k2 - f0 - pp)
        sq, carry = [], 0
        for pos in range(k2):
            col = carry + sum(d[i] * d[pos - i] for i in range(pos + 1))
            sq.append(col % b)
            carry = col // b
        cu, carry = [], 0
        for pos in range(k2):
            col = carry + sum(sq[i] * d[pos - i] for i in range(pos + 1))
            cu.append(col % b)
            carry = col // b
        # fixed positions f0..f0+pp equal n's
        for j in range(f0, f0 + pp):
            if (sq[j], cu[j]) != (D2[j], D3[j]):
                bad += 1
        q2 = q3 = 0
        for jj in range(mid + 1):
            j = k2 - 1 - jj
            q2 = q2 * b + sq[j]
            q3 = q3 * b + cu[j]
        lo2 = 0
        for jj in range(mid + 1):
            lo2 = lo2 * b + sq[mid - jj]
        c3 = (3 * lo2) % M
        w0 = (q2 | ((c3 & 0x3FFF) << 18)) & 0xFFFFFFFF
        w1 = (q3 | ((c3 >> 14) << 18)) & 0xFFFFFFFF
        assert q2 < 1 << 18 and q3 < 1 << 18 and c3 < 1 << 18
        # join_kernel: key level terms
        sigma = r0  # f0 = mid + 1, v_digits = 0
        c3u = (w0 >> 18) | ((w1 >> 18) << 14)
        t2 = ((w0 & 0x3FFFF) + dkey * (2 * sigma)) % M
        t3 = ((w1 & 0x3FFFF) + dkey * c3u) % M
        g2, g3 = t2 % b, t3 % b
        if (g2, g3) != (D2[k - 1], D3[k - 1]):
            bad += 1
        ac2, ac3 = (t2 // b) * C, (t3 // b) * C
        rho = sigma % bm
        p3 = (3 * ((rho * rho) % bm)) % bm
        p2 = (2 * rho) % bm
        # top record word 6 and D
        w6 = (P // b**pp % b ** (k2 - f0 - pp)) * b**pp + v
        assert w6 == P % b ** (k2 - f0)
        dm = w6 // b ** (k - f0)
        dh = (dm * Q + (dm * R + b * b - 1) // (b * b)) & 0xFFFFFFFF
        f2 = (ac2 + p2 * dh) & 0xFFFFFFFF
        f3 = (ac3 + p3 * dh) & 0xFFFFFFFF
        h2 = mul_hi(f2, b)
        gg2 = mul_hi((f2 * b) & 0xFFFFFFFF, b)
        h3 = mul_hi(f3, b)
        gg3 = mul_hi((f3 * b) & 0xFFFFFFFF, b)
        if (gg2, h2, gg3, h3) != (D2[k], D2[k + 1], D3[k], D3[k + 1]):
            bad += 1
        # verdict: entry mask (positions 0..k-1, distinct by construction
        # for listed entries; here take it as computed) plus seed digits
        emask = 0
        dup = False
        for j in range(k):
            for x in (D2[j], D3[j]):
                if emask >> x & 1:
                    dup = True
                emask |= 1 << x
        if dup:
            continue  # never a listed entry
        seed = 0
        for _ in range(rng.randrange(0, 12)):
            seed |= 1 << rng.randrange(b)
        seed &= ~emask  # the AND passed: the top's mask misses the entry's
        seen = rev64(emask | seed)
        hit = 0
        for g in (gg2, gg3, h2, h3):
            hit |= ((seen << g) & (2**64 - 1)) >> 32
        lean = not (gg2 == gg3 or h2 == h3 or gg2 == h2 or gg2 == h3 or gg3 == h2
                    or gg3 == h3 or hit >= 1 << 31)
        mids = [D2[k], D3[k], D2[k + 1], D3[k + 1]]
        want = len(set(mids)) == 4 and not any((emask | seed) >> x & 1 for x in mids)
        if lean != want:
            bad += 1
    return checked, bad

def main():
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 20000
    rng = random.Random(0x7254)
    total_bad = 0
    for b in range(40, 65):
        checked, bad = run_base(b, count, rng)
        total_bad += bad
        print(f"b{b}: {checked} n in the band, {bad} mismatches")
    print(f"total mismatches: {total_bad}")

if __name__ == "__main__":
    main()
