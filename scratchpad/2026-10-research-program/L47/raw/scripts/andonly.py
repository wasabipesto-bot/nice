#!/usr/bin/env python3
"""L47: the current check kernel's per-warp cost on AND-only survivors (no middle-digit prefilter: positions 0..5
distinct and disjoint from M; positions 6, 7 free), to price PROFILE-3's '300 ps per unprefiltered check'."""
import sys, os, random, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from joinsim import Base, cert
from warpsim import scan_passes, first_dup_chunk, digs
from sasscost import PRO, SQ_EXIT, EPI, CU_SETUP, SQ, CU, pass_cost
b, s, size = 62, 7997740455941656911841, 10**17
e = s + size; B = Base(b, s, e - 1); w = b ** 3; m1 = b - 1
plo = -(-s // w); phi = (e - w) // w
rng = random.Random(9); lanes = []
bk = [b ** i for i in range(9)]
while len(lanes) < 32 * 400:
    P = rng.randint(plo, phi)
    c = cert(B, P * w, P * w + w - 1, 6)
    if c is None: continue
    M = c[0]
    for _ in range(3000):   # random r0 of this top that pass the AND (positions 0..5) and the root test
        r0 = rng.randrange(w); n = P * w + r0
        if n % m1 not in B.roots: continue
        x = n % bk[6]; x2 = x * x; x3 = x2 * x; seen = 0; ok = True
        for j in range(6):
            g2 = (x2 // bk[j]) % b; g3 = (x3 // bk[j]) % b; bits = (1 << g2) | (1 << g3)
            if g2 == g3 or bits & (seen | M): ok = False; break
            seen |= bits
        if ok: lanes.append(n)
rng.shuffle(lanes)
agg = collections.Counter(); cubes = 0; nw = len(lanes) // 32
for i in range(nw):
    W = lanes[32 * i: 32 * i + 32]
    c = PRO + SQ_EXIT + EPI
    info = []
    for n in W:
        D2 = digs(n * n, b, B.s2); D3 = digs(n ** 3, b, B.s3)
        d = first_dup_chunk(D2, [], 0)
        info.append((d, D2, D3, n))
    ps = scan_passes(W[0] ** 2, b)
    npass = max((d or len(ps)) for d, *_ in info)
    for p in ps[:npass]: c += pass_cost(SQ, *p)
    live = [x for x in info if x[0] is None]
    if live:
        cubes += 1; c += CU_SETUP
        cps = scan_passes(W[0] ** 3, b)
        nc = max((first_dup_chunk(D3, D2, 0) or len(cps)) for _, D2, D3, _ in live)
        for p in cps[:nc]: c += pass_cost(CU, *p)
    agg += c
print(f'AND-only survivors (b62 1e17): {agg["n"]/nw:.1f} instr per warp-iteration ({agg["n"]/nw/32:.2f} per check), cube in {cubes/nw:.3f} of warps')
