#!/usr/bin/env python3
"""Model of the new prefilter long division (u32 arithmetic, overflow-checked)
against n mod K^p by definition. Every K that chunk_constants_u16 gives for
bases 10-40, limbs 1-4, pre_limbs 3 (and 1-4), random n plus edge values."""
import random
M32 = (1 << 32) - 1

def chk(x):
    assert 0 <= x <= M32, x
    return x

def new_alg(n, limbs, pre_limbs, K):
    nh = 2 * limbs
    Q, R = 65536 // K, 65536 % K
    words = [(n >> (32 * i)) & M32 for i in range(limbs)]
    v = []
    for w in words:
        v += [w & 0xFFFF, w >> 16]
    a = []
    for _ in range(pre_limbs):
        hi, lo = v[nh - 1], v[nh - 2]
        assert hi <= 0xFFFF and lo <= 0xFFFF
        t = chk(chk(hi * R) + lo)
        qt = t // K
        rem = chk(t - chk(qt * K))
        q = chk(chk(hi * Q) + qt)
        v[nh - 1], v[nh - 2] = q >> 16, q & 0xFFFF
        for j in range(nh - 3, -1, -1):
            assert rem < K
            c = chk((rem << 16) | v[j])
            qj = c // K
            rem = chk(c - chk(qj * K))
            v[j] = qj
            assert qj <= 0xFFFF
        a.append(rem)
    return a

def ref(n, pre_limbs, K):
    return [(n // K**r) % K for r in range(pre_limbs)]

def ku16(b):
    d = 1
    while d * b < 65536:
        d *= b
    return d

random.seed(1)
Ks = sorted({ku16(b) for b in range(10, 41)})
count = 0
for K in Ks:
    for limbs in (1, 2, 3, 4):
        top = 1 << (32 * limbs)
        ns = [0, 1, top - 1, top // 2, K - 1, K, K**3 - 1, K**3, (top - 1) // K * K]
        ns += [random.randrange(top) for _ in range(3000)]
        ns += [random.randrange(1 << random.randint(1, 32 * limbs)) for _ in range(3000)]
        for pre_limbs in (1, 2, 3, 4):
            for n in ns:
                n %= top
                assert new_alg(n, limbs, pre_limbs, K) == ref(n, pre_limbs, K), (n, limbs, pre_limbs, K)
                count += 1
print(f"Ks={Ks}")
print(f"{count} cases exact, no u32 overflow, every limb and quotient half <= 0xFFFF")
