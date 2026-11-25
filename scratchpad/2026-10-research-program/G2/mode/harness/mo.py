"""Shared by the harness (chaos.py, repro/common.py, torn_sweep.py): fields and submissions in the wire of the
midout mode (common/src/midout/wire.rs; POST /submit/midout), cut with a copy of the development server's port of
the coordinate arithmetic (scripts/midout_coordinator.py), so that base-65 fields are real fields."""
CLAIM, SUBMIT = "/claim/midout", "/submit/midout"
C485, C496 = "midout:4,8,5", "midout:4,9,6"


def iroot_ceil(x, k):
    """The least r >= 0 with r**k >= x (integers only)."""
    lo, hi = 0, 1 << (x.bit_length() // k + 1)
    while lo < hi:
        mid = (lo + hi) // 2
        if mid ** k >= x:
            hi = mid
        else:
            lo = mid + 1
    return lo


def base_range(b):
    """[start, end) of the n whose square and cube together have b digits (base_range.rs), or None."""
    k = b // 5
    m = b % 5
    if m == 0:
        return iroot_ceil(b ** (3 * k - 1), 3), b ** k
    if m == 2:
        return b ** k, iroot_ceil(b ** (3 * k + 1), 3)
    if m == 3:
        return iroot_ceil(b ** (3 * k + 1), 3), iroot_ceil(b ** (2 * k + 1), 2)
    if m == 4:
        return iroot_ceil(b ** (2 * k + 1), 2), iroot_ceil(b ** (3 * k + 2), 3)
    return None


def ndigits(x, b):
    n = 0
    while x > 0:
        x //= b
        n += 1
    return n


class Coord:
    """coord.rs's Coord::with_digits: v = start + key*(H*b^k0) + (h - h0)*b^k0 + low."""

    def __init__(self, b, k0, k1, q0):
        if not 3 <= b <= 128:
            raise ValueError("base %d outside 3-128" % b)
        r = base_range(b)
        if r is None:
            raise ValueError("base %d has no range" % b)
        self.b, (self.start, self.end) = b, r
        self.l = ndigits(self.end - 1, b)
        if not (k0 <= q0 < k1 <= self.l):
            raise ValueError("digit positions k0 %d <= q0 %d < k1 %d <= %d fail at base %d" % (k0, q0, k1, self.l, b))
        self.k0, self.k1, self.q0 = k0, k1, q0
        bk1 = b ** k1
        self.h0 = self.start // bk1
        self.hn = (self.end - 1) // bk1 - self.h0 + 1
        if self.start + self.hn * bk1 >= 1 << 128:
            raise ValueError("v overflows u128 at base %d" % b)

    def v_end(self):
        return self.start + self.hn * self.b ** self.k1

    def quantum(self):
        return self.hn * self.b ** self.q0

    def field_digits(self, v_start, v_size):
        """[t0, t1): the values of digits [q0, k1) of the field's n; ValueError if not whole quanta inside v."""
        q = self.quantum()
        if v_size <= 0:
            raise ValueError("empty field")
        if not (v_start >= self.start and v_start + v_size <= self.v_end()):
            raise ValueError("field outside the coordinate")
        if (v_start - self.start) % q or v_size % q:
            raise ValueError("field is not whole quanta of %d" % q)
        t0 = (v_start - self.start) // q
        return t0, t0 + v_size // q

    def n_count(self, v_start, v_size):
        """The n of the range the field holds (v_size less the padding): for one t and one h the n are the block
        [h*b^k1 + t*b^q0, + b^q0), full for every h but the first and the last, which are clipped to the range."""
        t0, t1 = self.field_digits(v_start, v_size)
        per_t, bk1 = self.b ** self.q0, self.b ** self.k1
        ends = [self.h0] + ([self.h0 + self.hn - 1] if self.hn > 1 else [])
        total = 0
        for t in range(t0, t1):
            total += max(self.hn - 2, 0) * per_t
            for h in ends:
                lo = h * bk1 + t * per_t
                total += max(min(lo + per_t, self.end) - max(lo, self.start), 0)
        return total

    def contains(self, n, v_start, v_size):
        """Whether n is one of the field's n: in the range, with digits [q0, k1) in [t0, t1)."""
        t0, t1 = self.field_digits(v_start, v_size)
        t = (n // self.b ** self.q0) % self.b ** (self.k1 - self.q0)
        return self.start <= n < self.end and t0 <= t < t1


def default_shape(c):
    """cpu::Shape::for_coord: (4, 10) for (4, 8, 5), else (k0, k1 + 1)."""
    return (4, 10) if (c.k0, c.k1, c.q0) == (4, 8, 5) else (c.k0, c.k1 + 1)


def slice_count(c, shape, v_start, v_size):
    """The slices of a field under shape (f0, k) (cpu::Shape::fits, slices_of); ValueError if it cannot search it."""
    f0, k = shape
    if not (f0 <= c.q0 and c.k1 < k <= c.l):
        raise ValueError("shape %d,%d cannot search fields fixing digits [%d, %d) of %d-digit n" % (
            f0, k, c.q0, c.k1, c.l))
    t0, t1 = c.field_digits(v_start, v_size)
    return (t1 - t0) * c.b ** (c.q0 - f0) * c.b ** (k - 1 - c.k1)


def is_nice(n, b):
    """n's square and cube together use every digit of base b exactly once."""
    seen = 0
    count = 0
    for x in (n * n, n * n * n):
        while x:
            x, d = divmod(x, b)
            if seen >> d & 1:
                return False
            seen |= 1 << d
            count += 1
    return count == b




_COORDS = {}


def coord(base, cid):
    k = (base, cid)
    if k not in _COORDS:
        _COORDS[k] = Coord(base, *map(int, cid.split(":")[1].split(",")))
    return _COORDS[k]


def field(t, base=64, coord_id=C485):
    """The field of one quantum t of a base's coordinate, as a work-list entry."""
    c = coord(base, coord_id)
    q = c.quantum()
    t %= (c.v_end() - c.start) // q
    v = c.start + t * q
    return {"base": base, "coordinate": coord_id, "range_start": v, "range_end": v + q,
            "range_size": c.n_count(v, q)}


def t_of(w):
    c = coord(w["base"], w["coordinate"])
    return (w["range_start"] - c.start) // c.quantum()


def body(cid, w, nonce="h", survivors=1, checked=1, nice=(), shape=None, slices=None):
    """A submission as the client builds it (client/src/midout_route.rs: submission), for field w under claim cid."""
    c = coord(w["base"], w["coordinate"])
    v, z = w["range_start"], w["range_end"] - w["range_start"]
    sh = shape or default_shape(c)
    return {"claim_id": cid, "username": nonce, "client_version": "3.4.9-dev",
            "field": {"base": w["base"], "coordinate": w["coordinate"], "v_start": str(v), "v_size": str(z),
                      "range_size": str(w["range_size"])},
            "nice_numbers": [str(x) for x in nice], "shape": "%d,%d" % sh,
            "survivors": survivors, "checked": checked,
            "slices": slice_count(c, sh, v, z) if slices is None else slices,
            "telemetry": {"build_sha": "0" * 40, "client_version": "3.4.9-dev", "device": "fake",
                          "processing_secs": 0.01, "pipeline": {"route": "midout", "coordinate": w["coordinate"],
                                                                "join": {"path": "fake"}}}}
