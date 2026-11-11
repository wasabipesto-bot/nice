#!/usr/bin/env python3
"""Independent mirror of top_fd_kernel's packed-digit arithmetic at b = 64
(and a few other bases for contrast), against Python big integers.

Mirrors (common/src/cubecl_join.rs at 5e10c9c3):
  fd_add_small / fd_add_carry / fd_add_top (biased packed-digit adds, u32 wrap)
  fd_digits_trim (split16 long division with the limb trim, u16 chunk consts)
  top_fd_seed + top_fd_step (S, C, dS, dC, ddC recurrence)
  cert_power_fd (word scan, run/runc, popcount dup, one_more via dm borrow)
and checks them against direct big-int digits and a reference certificate.
"""
import random, sys

M32 = 0xFFFFFFFF
STATS = {'one_more': 0, 'dup': 0, 'bit63': 0, 'recarry': 0}

def pack(v, b, nw):
    w = [0] * nw
    for i in range(4 * nw):
        d = v % b; v //= b
        w[i // 4] |= d << (8 * (i % 4))
    assert v == 0, "value does not fit"
    return w

def unpack(w, b):
    v = 0
    for i in reversed(range(4 * len(w))):
        d = (w[i // 4] >> (8 * (i % 4))) & 0xFF
        assert d < b, f"byte {i} = {d} not a digit"
        v = v * b + d
    return v

def biased_word(x, y, cin, b):
    bias = ((256 - b) * 0x01010101) & M32
    fix = 256 - b
    t = (x + y + bias + cin) & M32
    c = ((t >> 31) ^ 1)
    t = (t - ((t >> 7) & 0x01010101) * fix) & M32
    return t, c

def fd_add_small(x, c, kd, b):
    t, cin = biased_word(x[0], c, 0, b)
    x[0] = t
    if kd > 1 and cin:
        for w in range(1, kd):
            x[w], cin = biased_word(x[w], 0, cin, b)

def fd_add_carry(x, y, wy, kd, b):
    cin = 0
    for w in range(wy):
        x[w], cin = biased_word(x[w], y[w], cin, b)
    if wy < kd and cin:
        for w in range(wy, kd):
            x[w], cin = biased_word(x[w], 0, cin, b)

def fd_add_top(x, y, wy, kd, b):
    # fd_add_top: same biased add over all kd words (carry always propagated)
    cin = 0
    for w in range(kd):
        yy = y[w] if w < wy else 0
        x[w], cin = biased_word(x[w], yy, cin, b)

def chunk_u16(b):
    e, d = 0, 1
    while d * b < (1 << 16):
        d *= b; e += 1
    return e, d

def pow_limbs16_len(k, e):
    v = k ** e
    n = 0
    while True:
        n += 1
        v >>= 16
        if v == 0:
            return n

def fd_digits_trim(val, nl, q, b):
    cd, cdiv = chunk_u16(b)
    v = [(val >> (16 * i)) & 0xFFFF for i in range(nl)]
    out = [0] * ((q + 3) // 4 + 1)
    passes = -(-q // cd)
    for p in range(passes):
        lp = max(2, min(nl, pow_limbs16_len(b, q - p * cd)))
        top, nxt = lp - 1, lp - 2
        cx = ((v[top] << 16) | v[nxt]) & M32
        assert v[top] < (1 << 16)
        qx = cx // cdiv
        rx = cx - qx * cdiv
        v[top] = qx >> 16
        v[nxt] = qx & 0xFFFF
        for jj in range(2, lp):
            j = lp - 1 - jj
            c1 = (rx << 16) | v[j]
            assert c1 <= M32
            q1 = c1 // cdiv
            rx = c1 - q1 * cdiv
            v[j] = q1
        for i in range(cd):
            pos = p * cd + i
            if pos < q:
                dx = rx % b; rx //= b
                out[pos // 4] |= dx << (8 * (pos % 4))
    assert all(x == 0 for x in v), "value above b^q left over"
    return out

def ndig(x, b):
    n = 0
    while x:
        x //= b; n += 1
    return n

def ref_cert(x, y, sp, cap, b):
    """cert_power's results from big ints: (mask, dup, dom_lo, dom_hi, c0)."""
    c0 = max(cap, min(ndig(y - x, b), sp))
    X, Y = x // b ** c0, y // b ** c0
    dX = [(x // b ** i) % b for i in range(sp)]
    if c0 >= sp:
        return 0, 0, 1, 0, c0
    if X == Y:
        ds = dX[c0:sp]
        m = 0
        for d in ds: m |= 1 << d
        return m, int(len(set(ds)) != len(ds)), 1, 0, c0
    assert Y == X + 1
    q = c0
    while dX[q] == b - 1:
        q += 1
    ds = dX[q + 1:sp]
    m = 0
    for d in ds: m |= 1 << d
    return m, int(len(set(ds)) != len(ds)), dX[q], dX[q] + 1, c0

def word_value(word, b):
    return (word & 0xFF) + b * (((word >> 8) & 0xFF) + b * (((word >> 16) & 0xFF) + b * (word >> 24)))

def popc64(m):
    return bin(m & 0xFFFFFFFF).count("1") + bin(m >> 32).count("1")

def cert_power_fd(qw, dm, c0, nl, sp, b, z):
    """Mirror of cert_power_fd; dm as an int (nl u32 words), rem mod 2^(32 nl)."""
    rem = 0
    run = runc = 0
    in_run = True
    dlo = qend = 0
    if c0 < z:
        m = z - c0
        run = 1; runc = 1 if m >= 2 else 0
        in_run = False; qend = c0
    nw = -(-(sp - z) // 4)
    for j in range(nw):
        p0 = z + 4 * j
        wend = min(p0 + 4, sp)
        word = qw[j]
        low = 0
        if c0 >= wend:
            low = word_value(word, b)
        elif in_run:
            for i in range(4):
                pos = p0 + i
                if pos < sp:
                    dx = (word >> (8 * i)) & 0xFF
                    above = c0 <= pos
                    bit = (1 << dx) if above else 0
                    assert dx < 64
                    run |= bit
                    runc |= 0 if in_run else bit
                    ends = above and in_run and dx != b - 1
                    if ends: dlo = dx; qend = pos
                    in_run = in_run and not ends
                    low += 0 if above else dx * b ** i
        else:
            wb = 0
            for i in range(4):
                pos = p0 + i
                if pos < sp:
                    dx = (word >> (8 * i)) & 0xFF
                    wb |= 1 << dx
            run |= wb; runc |= wb
        if p0 < c0:
            # add_scaled_pow: sum is below b^(p0+4); u32 words, carry kept inside nl
            rem = (rem + low * b ** p0) % (1 << (32 * nl))
    nabove = sp - c0 if c0 < sp else 0
    dup = int(popc64(run) != nabove)
    nc = (sp - 1 - qend) if not in_run else 0
    dupc = int(popc64(runc) != nc)
    one_more = False
    if c0 < sp:
        one_more = rem > dm   # dm - rem borrows
    if one_more:
        return runc, dupc, dlo, dlo + 1
    return run, dup, 1, 0

def iroot(x, k):
    """Exact integer k-th root by bisection."""
    lo_, hi_ = 0, 1 << (x.bit_length() // k + 2)
    while lo_ < hi_:
        mid = (lo_ + hi_ + 1) // 2
        if mid ** k <= x: lo_ = mid
        else: hi_ = mid - 1
    return lo_

def check_base(b, tq, s2, s3, f0, cap, trials, rng, steps):
    q2, q3 = s2 - 2 * f0, s3 - 3 * f0
    wq1, wq2, wdc, wq3 = -(-(tq + 1) // 4), -(-q2 // 4), -(-(q2 + 1) // 4), -(-q3 // 4)
    w = b ** f0
    limbs = 3
    nl2, nl3 = 2 * limbs, 3 * limbs
    Pmax = b ** tq
    # The prefixes whose block lies in [b^(l-1), b^l) in practice; adversarial ones too.
    special = [Pmax - 1, Pmax - 2, Pmax // b, Pmax // b + 1, Pmax // 2, Pmax - b,
               (Pmax - 1) // (b - 1) * (b - 1), b ** (tq - 1) * (b - 1) - 1]
    # P near a square root of b^m - 1 (P^2 digits all b-1 near the top)
    for m in range(q2 - 3, q2 + 1):
        r = iroot(b ** m - 1, 2)
        special += [r - 2, r - 1, r]
    for m in range(q3 - 4, q3 + 1):
        r = iroot(b ** m - 1, 3)
        special += [r - 2, r - 1, r]
    pass
    # Prefixes of the base's live range: P^2 < b^q2 and P^3 < b^q3, with n^3 of s3 digits.
    hi = min(iroot(b ** q2 - 1, 2), iroot(b ** q3 - 1, 3), Pmax - 1)
    lo = max(iroot(b ** (q3 - 1), 3), iroot(b ** (q2 - 1), 2), 1)
    special += [lo, lo + 1, hi - steps, hi - steps - 1]
    for m in range(1, s3 + 1):
        for k in (2, 3):
            # the smallest P with e^k - a^k >= b^m, by bisection
            dk = lambda PP: (PP * w + w - 1) ** k - (PP * w) ** k
            l_, h_ = 0, Pmax
            while l_ < h_:
                mid = (l_ + h_) // 2
                if dk(mid) >= b ** m: h_ = mid
                else: l_ = mid + 1
            special += [l_ - steps // 2, l_ - 1, l_ - steps + 1]
    special = [p for p in special if lo <= p and p + steps <= hi]
    starts = special + [rng.randrange(lo, hi - steps) for _ in range(trials)]
    ncert = 0
    for P0 in starts:
        # seed via fd_digits_trim (as top_fd_seed: ph 4 limbs, p2 8, p3 12)
        pd = fd_digits_trim(P0, 4, tq, b)[:wq1]
        sq = fd_digits_trim(P0 ** 2, 8, q2, b)[:wq2]
        cu = fd_digits_trim(P0 ** 3, 12, q3, b)[:wq3]
        assert unpack(pd, b) == P0 and unpack(sq, b) == P0 ** 2 and unpack(cu, b) == P0 ** 3
        ds = list(pd); fd_add_top(ds, pd, wq1, wq1, b); fd_add_small(ds, 1, wq1, b)
        u = [sq[i] if i < wq2 else 0 for i in range(wdc)]
        fd_add_top(u, pd, wq1, wdc, b)
        dc = list(u); fd_add_top(dc, u, wdc, wdc, b); fd_add_top(dc, u, wdc, wdc, b); fd_add_small(dc, 1, wdc, b)
        fd_add_small(pd, 1, wq1, b)
        ddc = list(pd); fd_add_top(ddc, pd, wq1, wq1, b); fd_add_top(ddc, pd, wq1, wq1, b)
        u3 = list(ddc); fd_add_top(ddc, u3, wq1, wq1, b)
        assert unpack(ds, b) == 2 * P0 + 1
        assert unpack(dc, b) == 3 * P0 * P0 + 3 * P0 + 1
        assert unpack(ddc, b) == 6 * P0 + 6
        P = P0
        def fresh(PP):
            aa, ee = PP * w, PP * w + w - 1
            d2_, d3_ = ee * ee - aa * aa, ee ** 3 - aa ** 3
            c0a_ = max(cap, min(ndig(d2_, b), s2)); c0b_ = max(cap, min(ndig(d3_, b), s3))
            return c0a_, c0b_, (b ** c0a_ - 1 - d2_) % (1 << (32 * nl2)), (b ** c0b_ - 1 - d3_) % (1 << (32 * nl3))
        c0a, c0b, dm2, dm3 = fresh(P0)
        dd = w - 1
        c2v, k3v = 2 * w * dd, 6 * w * w * dd
        del3 = 3 * w * dd * (2 * P0 * w + 2 * w - 1)
        for s in range(steps):
            if s:
                br2 = dm2 < c2v; dm2 = (dm2 - c2v) % (1 << (32 * nl2))
                br3 = dm3 < del3; dm3 = (dm3 - del3) % (1 << (32 * nl3))
                del3 += k3v
                assert del3 < (1 << (32 * nl3))
                if c0a < s2 and br2:
                    d2r = (b ** c0a - 1 - dm2) % (1 << (32 * nl2))
                    c0a = max(cap, min(ndig(d2r, b), s2)); dm2 = (b ** c0a - 1 - d2r) % (1 << (32 * nl2))
                    STATS['recarry'] += 1
                if c0b < s3 and br3:
                    d3r = (b ** c0b - 1 - dm3) % (1 << (32 * nl3))
                    c0b = max(cap, min(ndig(d3r, b), s3)); dm3 = (b ** c0b - 1 - d3r) % (1 << (32 * nl3))
                    STATS['recarry'] += 1
                assert (c0a, c0b, dm2, dm3) == fresh(P + 1), (b, P + 1, 'carried c0/dm')
            if s:
                fd_add_carry(sq, ds, wq1, wq2, b); fd_add_small(ds, 2, wq1, b)
                fd_add_carry(cu, dc, wdc, wq3, b); fd_add_carry(dc, ddc, wq1, wdc, b)
                fd_add_small(ddc, 6, wq1, b)
                P += 1
            assert unpack(sq, b) == P * P, (b, P0, s)
            assert unpack(cu, b) == P ** 3, (b, P0, s)
            assert unpack(ds, b) == 2 * P + 1
            assert unpack(dc, b) == 3 * P * P + 3 * P + 1
            assert unpack(ddc, b) == 6 * P + 6
            # certificates of the block a = P w, e = a + w - 1
            a, e = P * w, P * w + w - 1
            for (k, sp, qw, nl) in ((2, s2, sq, nl2), (3, s3, cu, nl3)):
                x, y = a ** k, e ** k
                if y >= b ** sp or x < b ** (sp - 1):
                    continue  # not this field's digit count
                d = y - x
                c0 = max(cap, min(ndig(d, b), sp))
                dm = (b ** c0 - 1 - d) % (1 << (32 * nl))
                got = cert_power_fd(qw, dm, c0, nl, sp, b, k * f0)
                STATS['one_more'] += got[2] <= got[3]
                STATS['dup'] += got[1]
                STATS['bit63'] += (got[0] >> 63) & 1
                rm, rdup, rlo, rhi, _ = ref_cert(x, y, sp, cap, b)
                assert got == (rm, rdup, rlo, rhi), (b, P, k, got, (rm, rdup, rlo, rhi))
                ncert += 1
    return len(starts), ncert

def adversarial_words(b, rng, n):
    """Byte-level: random digit vectors incl. all-(b-1), sums carrying through every byte."""
    for _ in range(n):
        kd = rng.randint(1, 10)
        mode = rng.randrange(4)
        def vec():
            if mode == 0: return [b - 1] * (4 * kd)
            if mode == 1: return [rng.choice([0, b - 1, b - 2, 1]) for _ in range(4 * kd)]
            return [rng.randrange(b) for _ in range(4 * kd)]
        dx, dy = vec(), vec()
        x = sum(d * b ** i for i, d in enumerate(dx)) % b ** (4 * kd - 1)
        ymax = b ** (4 * kd - 1) - 1 - x
        y = sum(d * b ** i for i, d in enumerate(dy)) % (ymax + 1) if ymax > 0 else 0
        wy = rng.randint(1, kd)
        y %= b ** (4 * wy)
        if x + y >= b ** (4 * kd): continue
        xw, yw = pack(x, b, kd), pack(y, b, wy)
        fd_add_carry(xw, yw, wy, kd, b)
        assert unpack(xw, b) == x + y, (b, x, y)
        c = rng.randrange(b)
        if x + c < b ** (4 * kd):
            xw = pack(x, b, kd); fd_add_small(xw, c, kd, b)
            assert unpack(xw, b) == x + c

if __name__ == "__main__":
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    rng = random.Random(seed)
    # (b, l, s2, s3, f0, cap=k) -- b64 production: n 13 digits, n^2 26, n^3 38, f0 = 3, k = 4
    cases = [(64, 13, 26, 38, 3, 4), (64, 13, 26, 38, 2, 4), (62, 13, 25, 37, 3, 4), (60, 12, 24, 36, 3, 4)]
    for b in (64, 62, 128, 10):
        adversarial_words(b, rng, 20000)
        print(f"b{b}: 20000 biased adds ok")
    for (b, l, s2, s3, f0, cap) in cases:
        tq = l - f0
        n, nc = check_base(b, tq, s2, s3, f0, cap, trials=60, rng=rng, steps=200)
        print(f"b{b} f0={f0}: {n} seeds x 200 steps, {nc} certificates ok; cumulative {STATS}")

def dm_crossings(b, s2, s3, f0, cap, limbs=3, steps=400):
    """The carried c0/dm recurrence alone, across every c0 change of either
    power reachable with P < 2^64 (outside the live range too)."""
    w, dd = b ** f0, b ** f0 - 1
    nl2, nl3 = 2 * limbs, 3 * limbs
    M2, M3 = 1 << (32 * nl2), 1 << (32 * nl3)
    def fresh(PP):
        aa, ee = PP * w, PP * w + w - 1
        d2_, d3_ = ee * ee - aa * aa, ee ** 3 - aa ** 3
        c0a_ = max(cap, min(ndig(d2_, b), s2)); c0b_ = max(cap, min(ndig(d3_, b), s3))
        return c0a_, c0b_, (b ** c0a_ - 1 - d2_) % M2, (b ** c0b_ - 1 - d3_) % M3
    n = cross = 0
    for k in (2, 3):
        for m in range(1, (s2 if k == 2 else s3) + 1):
            dk = lambda PP: (PP * w + w - 1) ** k - (PP * w) ** k
            l_, h_ = 0, (1 << 64) - 1 - steps
            if dk(h_) < b ** m: continue
            while l_ < h_:
                mid = (l_ + h_) // 2
                if dk(mid) >= b ** m: h_ = mid
                else: l_ = mid + 1
            P0 = max(1, l_ - steps // 2)
            c0a, c0b, dm2, dm3 = fresh(P0)
            del3 = 3 * w * dd * (2 * P0 * w + 2 * w - 1)
            c2v, k3v = 2 * w * dd, 6 * w * w * dd
            for P in range(P0 + 1, P0 + steps):
                br2 = dm2 < c2v; dm2 = (dm2 - c2v) % M2
                br3 = dm3 < del3; dm3 = (dm3 - del3) % M3
                del3 += k3v
                if c0a < s2 and br2:
                    d2r = (b ** c0a - 1 - dm2) % M2
                    c0a = max(cap, min(ndig(d2r, b), s2)); dm2 = (b ** c0a - 1 - d2r) % M2; cross += 1
                if c0b < s3 and br3:
                    d3r = (b ** c0b - 1 - dm3) % M3
                    c0b = max(cap, min(ndig(d3r, b), s3)); dm3 = (b ** c0b - 1 - d3r) % M3; cross += 1
                assert (c0a, c0b, dm2, dm3) == fresh(P), (b, P)
                n += 1
    return n, cross

if __name__ == "__main__":
    for (b, s2, s3, f0) in ((64, 26, 38, 3), (64, 26, 38, 2)):
        n, cross = dm_crossings(b, s2, s3, f0, 4)
        print(f"b{b} f0={f0}: carried c0/dm over {n} steps, {cross} re-forms: ok")
