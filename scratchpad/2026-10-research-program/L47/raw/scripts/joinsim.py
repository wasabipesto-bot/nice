#!/usr/bin/env python3
"""L47: generate real overlap-join survivors (the pairs the GPU check kernel reads) for a field,
by the join's own conditions, and record per survivor what the check kernel would do.

Port of overlap_join.rs (fork pr/join-static-buckets 87958fd): Base::cert (cap = k), close_certificate,
JoinParams::for_length (t = L-3, k = 6, p = 2, f0 = L - t = 3), FieldSetup's k2 = k + mid (mid = 2).
A survivor is n = P*b^f0 + r0 (P a full top block of the field whose certificate M passes) with
- the 2*k2 output digits at positions 0..k2-1 of n^2 and n^3 distinct and disjoint from M
  (the AND: entry positions 0..k-1 vs M; the prefilter: positions k..k2-1 vs entry | M, seed = 1 on full blocks),
- n mod (b-1) a root of x^2 + x^3 = b(b-1)/2 (the bucket class).
Sampling: P uniform over the field's top prefixes (clipped end blocks excluded), every r0 of a kept top
enumerated by a digit DFS. Output: one JSON line per survivor.
"""
import json, random, sys

def ndig(x, b):
    n = 0
    while x > 0:
        x //= b; n += 1
    return n

def digits(x, b, n):
    out = []
    for _ in range(n):
        out.append(x % b); x //= b
    return out

class Base:
    def __init__(self, b, lo, hi):
        self.b = b
        self.l = ndig(hi, b); assert self.l == ndig(lo, b)
        self.s2 = ndig(lo * lo, b); self.s3 = ndig(lo ** 3, b)
        assert self.s2 == ndig(hi * hi, b) and self.s3 == ndig(hi ** 3, b)
        assert self.s2 + self.s3 == b
        m1 = b - 1
        tgt = (b * (b - 1) // 2) % m1
        self.roots = [r for r in range(m1) if (r * r + r ** 3) % m1 == tgt]

def close_certificate(mask, doms):
    forced = [False, False]
    fset = 0
    while True:
        changed = False
        for i, dom in enumerate(doms):
            if dom == 0 or forced[i]:
                continue
            free = dom & ~mask
            if free == 0:
                return None, 0
            if free & (free - 1) == 0:
                mask |= free; fset |= free; forced[i] = True; changed = True
        if not changed:
            return mask, fset

def cert(B, a, e, cap):
    """Base::cert; also returns (first certified position of n^2, of n^3, forced bits, pre-closure mask)."""
    b = B.b; top = b - 1
    mask = 0; doms = [0, 0]; cstart = [None, None]
    for j, (x, y, sp) in enumerate(((a * a, e * e, B.s2), (a ** 3, e ** 3, B.s3))):
        d = y - x
        c0 = max(cap, ndig(d, b))
        if c0 >= sp:
            cstart[j] = sp
            continue
        qx, rem = divmod(x, b ** c0)
        one_more = rem + d >= b ** c0
        dx = digits(qx, b, sp - c0)
        frm = 0
        if one_more:
            while dx[frm] == top:
                frm += 1
            doms[j] = (1 << dx[frm]) | (1 << (dx[frm] + 1))
            frm += 1
        cstart[j] = c0 + frm
        for dg in dx[frm:]:
            bit = 1 << dg
            if mask & bit:
                return None
            mask |= bit
    pre = mask
    m, fset = close_certificate(mask, doms)
    if m is None:
        return None
    return m, cstart[0], cstart[1], fset, pre

def survivors_of_top(B, P, w, f0, k2, M):
    """Every r0 in [0, w) with n = P*w + r0 a join survivor of top P (full block)."""
    b = B.b; m1 = b - 1
    assert f0 == 3 and k2 == 8
    pm = P % b ** (k2 - f0)              # n's digits f0..k2-1 (P mod b^5, record word 6)
    dsP = P % m1                          # digit sum of P mod (b - 1)
    out = []
    bk = [b ** i for i in range(k2 + 1)]
    def pos_digits(x, j):
        x2 = x * x; x3 = x2 * x
        return (x2 // bk[j]) % b, (x3 // bk[j]) % b
    # level 0
    for d0 in range(b):
        g2, g3 = pos_digits(d0, 0)
        if g2 == g3 or (M >> g2) & 1 or (M >> g3) & 1:
            continue
        s0 = (1 << g2) | (1 << g3)
        for d1 in range(b):
            x1 = d0 + d1 * b
            g2, g3 = pos_digits(x1, 1)
            bits = (1 << g2) | (1 << g3)
            if g2 == g3 or bits & (s0 | M):
                continue
            s1 = s0 | bits
            t = (min(B.roots) - dsP - d0 - d1)  # placeholder, replaced below
            for root in B.roots:
                t = (root - dsP - d0 - d1) % m1
                cands = [t] + ([t + m1] if t + m1 < b else [])
                for d2 in cands:
                    r0 = x1 + d2 * b * b
                    x = pm * w + r0      # n mod b^8
                    seen = s1; ok = True
                    for j in range(2, k2):
                        g2, g3 = pos_digits(x, j)
                        bits = (1 << g2) | (1 << g3)
                        if g2 == g3 or bits & (seen | M):
                            ok = False; break
                        seen |= bits
                    if ok:
                        out.append(r0)
    return out

def main():
    b = int(sys.argv[1]); s = int(sys.argv[2]); size = int(float(sys.argv[3]))
    want = int(sys.argv[4]); seed = int(sys.argv[5]) if len(sys.argv) > 5 else 1
    e = s + size
    B = Base(b, s, e - 1)
    L = B.l; t = L - 3; k = 6; f0 = L - t; k2 = 8
    w = b ** f0
    plo = -(-s // w); phi = (e - w) // w   # full blocks only
    rng = random.Random(seed)
    sampled = kept = nsurv = 0
    print(json.dumps({"meta": dict(b=b, s=s, e=e, L=L, s2=B.s2, s3=B.s3, f0=f0, k=k, k2=k2, roots=B.roots,
                                   plo=plo, phi=phi)}), flush=True)
    while nsurv < want:
        P = rng.randint(plo, phi)
        sampled += 1
        a = P * w; ee = a + w - 1
        c = cert(B, a, ee, k)
        if c is None:
            continue
        M, c2, c3, fset, pre = c
        kept += 1
        rs = survivors_of_top(B, P, w, f0, k2, M)
        for r0 in rs:
            n = P * w + r0
            print(json.dumps({"n": str(n), "P": str(P), "M": M, "c2": c2, "c3": c3, "F": fset}), flush=False)
        nsurv += len(rs)
        if sampled % 200 == 0:
            print(json.dumps({"progress": dict(sampled=sampled, kept=kept, surv=nsurv)}), file=sys.stderr, flush=True)
    print(json.dumps({"summary": dict(sampled=sampled, kept=kept, surv=nsurv)}), flush=True)

if __name__ == "__main__":
    main()
