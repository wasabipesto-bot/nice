"""Host model of the PR's stepped-slot arithmetic (review only)."""
import random
M32 = 0xFFFFFFFF

def pack(digits, nw):
    ws = [0]*nw
    for i, d in enumerate(digits):
        ws[i//4] |= d << (8*(i % 4))
    return ws

def unpack(ws, n):
    return [(ws[i//4] >> (8*(i % 4))) & 0xFF for i in range(n)]

def val(ws, n, b):
    return sum(d * b**i for i, d in enumerate(unpack(ws, n)))

def biased_word(x, y, cin, b):
    bias = (256-b)*0x01010101
    fix = 256-b
    t = (x + y + bias + cin) & M32
    c = ((t >> 31) ^ 1)
    return (t - ((t >> 7) & 0x01010101)*fix) & M32, c

def fd_add_top(x, y, wy, kd, b):  # #240's full ripple
    x = list(x); cin = 0
    for w in range(wy):
        x[w], cin = biased_word(x[w], y[w], cin, b)
    for w in range(wy, kd):
        x[w], cin = biased_word(x[w], 0, cin, b)
    return x

def fd_add_carry(x, y, wy, kd, b):  # PR: early exit
    x = list(x); cin = 0
    for w in range(wy):
        x[w], cin = biased_word(x[w], y[w], cin, b)
    if wy < kd and cin != 0:
        for w in range(wy, kd):
            x[w], cin = biased_word(x[w], 0, cin, b)
    return x

def fd_add_small_old(x, c, kd, b):
    y = [c] + [0]*(kd-1)
    return fd_add_top(x, y, kd, kd, b)

def fd_add_small_new(x, c, kd, b):
    x = list(x)
    x[0], cin = biased_word(x[0], c, 0, b)
    if kd > 1 and cin != 0:
        for w in range(1, kd):
            x[w], cin = biased_word(x[w], 0, cin, b)
    return x

def add_words_old(x, y, ny, nx):
    x = list(x); c = 0
    for j in range(nx):
        c += x[j] + (y[j] if j < ny else 0)
        x[j] = c & M32; c >>= 32
    return x

def add_words_new(x, y, ny, nx):
    x = list(x); c = 0
    for j in range(ny):
        c += x[j] + y[j]; x[j] = c & M32; c >>= 32
    if ny < nx and c != 0:
        for j in range(ny, nx):
            c += x[j]; x[j] = c & M32; c >>= 32
    return x

def sub_words(x, y, ny, nx):
    x = list(x); c = 1
    for j in range(ny):
        c += x[j] + (y[j] ^ M32); x[j] = c & M32; c >>= 32
    if ny < nx and c == 0:
        for j in range(ny, nx):
            c += x[j] + M32; x[j] = c & M32; c >>= 32
    return x, 1 - c

def words(v, n):
    return [(v >> (32*j)) & M32 for j in range(n)]

def wval(ws):
    return sum(w << (32*j) for j, w in enumerate(ws))

def check_adds(trials=200000):
    rnd = random.Random(1)
    for _ in range(trials):
        b = rnd.randint(2, 128)
        kd = rnd.randint(1, 6); wy = rnd.randint(1, kd)
        n = 4*kd
        # x below b^(n-1) so that the sum fits (as the kernel's invariant)
        xd = [rnd.randrange(b) for _ in range(n)]; xd[-1] = 0
        if rnd.random() < 0.3:  # long runs of b-1 to force ripples
            for i in range(rnd.randint(0, n-1)):
                xd[i] = b-1
        yd = [rnd.randrange(b) for _ in range(4*wy)] + [0]*(4*(kd-wy))
        if rnd.random() < 0.5: yd[-1] = 0
        x, y = pack(xd, kd), pack(yd, kd)
        if val(x, n, b) + val(y, n, b) >= b**n:
            continue
        o, nw = fd_add_top(x, y, wy, kd, b), fd_add_carry(x, y, wy, kd, b)
        assert o == nw, (b, kd, wy)
        assert val(nw, n, b) == val(x, n, b) + val(y, n, b)
        c = rnd.randrange(b)
        if val(x, n, b) + c < b**n:
            assert fd_add_small_old(x, c, kd, b) == fd_add_small_new(x, c, kd, b)
        nx = rnd.randint(1, 9); ny = rnd.randint(1, nx)
        xv = rnd.getrandbits(32*nx); yv = rnd.getrandbits(32*ny)
        if rnd.random() < 0.3: xv |= (1 << (32*nx)) - (1 << (32*ny))  # all-ones above y
        if rnd.random() < 0.3: xv &= (1 << (32*ny))  # zeros above y (borrow ripple)
        xw, yw = words(xv, nx), words(yv, ny)
        assert add_words_old(xw, yw, ny, nx) == add_words_new(xw, yw, ny, nx)
        r, br = sub_words(xw, yw, ny, nx)
        assert wval(r) == (xv - yv) % (1 << (32*nx)) and br == (1 if yv > xv else 0)
    print("adds/subs: early exits identical to the full ripple in", trials, "trials")

def bits(x): return x.bit_length()

def check_step_bounds():
    # fd_step_words: c2 = 2wδ < 2w², k3 = 6w²δ < 6w³, Δ3(P-1) = 3wδ(2a + 2w - 1), a + w - 1 < 2^(32 limbs)
    worst = []
    for b in range(10, 65):
        for f0 in range(1, 40):
            w = b**f0
            if w >= 1 << 32: break
            for limbs in (1, 2, 3):
                nc2 = min(-(-bits(2*w*w)//32), 3, 2*limbs)
                nk3 = min(-(-bits(6*w**3)//32), 4, 3*limbs)
                nd3 = min(-(-(bits(3*w*w) + 32*limbs + 2)//32), 3*limbs)
                d = w - 1
                c2 = 2*w*d; k3 = 6*w*w*d
                amax = (1 << (32*limbs)) - w   # largest block start with e < 2^(32 limbs)
                if amax < w: continue          # no block P >= 1 fits these limbs: vacuous
                del3 = 3*w*d*(2*amax + 2*w - 1)
                ok = c2 < 1 << (32*nc2) and (k3 < 1 << (32*nk3) or k3 >= 1 << (96*limbs)) \
                     and (del3 < 1 << (32*nd3) or del3 >= 1 << (96*limbs))
                # the kernel's arrays: c2 3 words, k3 4 words; truncation by nl2/nl3 means
                # the value itself exceeds the array (only when it cannot occur in range)
                if not ok:
                    worst.append((b, f0, limbs, nc2, nk3, nd3))
    print("step-word bounds: violations", worst[:10], len(worst))

def ndig(x, b):
    i, p = 0, 1
    while p <= x:
        p *= b; i += 1
    return i

def check_c0_carry(trials=3000):
    """The carried (c0, dm) against a fresh c0 and carry test each P, over
    ranges that cross powers of b (small b, f0 so crossings happen)."""
    rnd = random.Random(2)
    crossings = 0
    for _ in range(trials):
        b = rnd.randint(3, 64)
        f0 = rnd.randint(1, 3)
        w = b**f0
        limbs = rnd.randint(1, 3)
        cap = rnd.randint(0, 6)
        P0 = rnd.randint(1, 4000)
        L = rnd.randint(2, 300)
        Pmax = P0 + L
        amax = Pmax*w + w
        if amax >= 1 << (32*limbs):
            continue
        for k in (2, 3):
            nl = k*limbs
            emax = (Pmax*w + w - 1)**k
            sp = ndig(emax, b)       # the power's digit count at the range's end
            def dk(P):
                a = P*w; e = a + w - 1
                return e**k - a**k
            def c0f(P):
                return max(cap, min(ndig(dk(P), b), sp))
            # seed
            P = P0
            c0 = c0f(P)
            N = 1 << (32*nl)
            dm = (b**c0 - 1 - dk(P)) % N
            d = dk(P)
            if k == 2:
                stepf = lambda P: 2*w*(w-1)
            else:
                stepf = lambda P: 3*w*(w-1)*(2*P*w + 2*w - 1)  # Δ3(P) = d3(P+1) - d3(P)
            for P in range(P0 + 1, Pmax + 1):
                s = stepf(P - 1)
                assert s == dk(P) - dk(P - 1)
                dmw, br = sub_words(words(dm, nl), words(s, nl), nl, nl)
                dm = wval(dmw)
                if c0 < sp and br:
                    crossings += 1
                    d_rec = (b**c0 - 1 - dm) % N
                    assert d_rec == dk(P), "recovered d"
                    c0 = c0f(P) if True else None
                    c0 = max(cap, min(ndig(d_rec, b), sp))
                    dm = (b**c0 - 1 - d_rec) % N
                assert c0 == c0f(P), ("c0", b, f0, P, c0, c0f(P))
                if c0 < sp:
                    assert dm == b**c0 - 1 - dk(P)
                    # carry test: x mod b^c0 > dm  <=>  (x mod b^c0) + d >= b^c0
                    x = (P*w)**k
                    rem = x % b**c0
                    assert (rem > dm) == (rem + dk(P) >= b**c0)
    print("carried c0/dm: matched fresh c0 and the carry test; re-formings exercised:", crossings)

def check_ballot():
    for psize in (4, 8, 16, 32, 64, 128):
        for _ in range(2000):
            kept = [random.random() < 0.4 for _ in range(psize)]
            bal = [0]*4
            for l, k in enumerate(kept):
                if k: bal[l >> 5] |= 1 << (l & 31)
            ranks = []
            for lane in range(psize):
                wi = lane >> 5; lt = ((1 << (lane & 31)) - 1) & M32
                n = pre = 0
                for k in range(4):
                    mk = M32 if wi > k else (lt if wi == k else 0)
                    n += bin(bal[k]).count("1"); pre += bin(bal[k] & mk).count("1")
                assert n == sum(kept)
                if kept[lane]: ranks.append(pre)
            assert sorted(ranks) == list(range(sum(kept)))
    print("ballot ranks: dense and unique for planes of 4-128 lanes")
    # cubecl-cpp's HIP/Metal dialects return {u32(ballot), 0, 0, 0}: on wave64
    bad = 0
    for _ in range(2000):
        kept = [random.random() < 0.4 for _ in range(64)]
        full = sum(1 << l for l, k in enumerate(kept) if k)
        bal = [full & M32, 0, 0, 0]
        ranks = []; n_seen = None
        for lane in range(64):
            wi = lane >> 5; lt = ((1 << (lane & 31)) - 1) & M32
            n = pre = 0
            for k in range(4):
                mk = M32 if wi > k else (lt if wi == k else 0)
                n += bin(bal[k]).count("1"); pre += bin(bal[k] & mk).count("1")
            n_seen = n
            if kept[lane]: ranks.append(pre)
        if sorted(ranks) != list(range(sum(kept))) or n_seen != sum(kept):
            bad += 1
    print(f"wave64 with a truncated 32-bit ballot: {bad}/2000 planes get wrong counts/ranks")

if __name__ == "__main__":
    check_ballot()
    check_step_bounds()
    check_adds()
    check_c0_carry()
