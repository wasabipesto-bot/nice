"""Exact model of the FD kernel's seed (split16 path, wgpu) with candidate
Metal miscompilations, scored against the M4's per-n results (diag3.log:
run length 1, so only the seeded digits of S = n^2 and C = n^3 matter).

Fault family (from the 2026-10-06 M4 finding: `uint(ulong(a)*ulong(b) >> 32) / K`
divides the LOW half): in fd_to_digits' first division of the top limb, the
quotient is computed from the low half of the 64-bit value whose high half the
top limb is. In the kernel that low half is always the limb just below
(v[top-1]), for S and C at one and two limbs.
"""
import re, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
M32 = (1 << 32) - 1

def chunk16(b):
    e, p = 0, 1
    while p * b < (1 << 16):
        p *= b; e += 1
    return e, p

def to_limbs(x, k):
    return [(x >> (32 * i)) & M32 for i in range(k)]

def fd_to_digits(v, ndig, b, fault):
    """The kernel's split16 fd_to_digits on limbs v (little-endian), with
    `fault` in {None, 'q1', 'c1', 'q1q2'} applied to the top limb's first
    division of chunk 0 only."""
    v = list(v); n = len(v)
    e, K = chunk16(b)
    out = []
    nchunks = -(-ndig // e)
    for k in range(nchunks):
        rem = 0
        for ii in range(n):
            i = n - 1 - ii
            vi = v[i]
            top = (k == 0 and i == n - 1)
            c1 = ((rem << 16) | (vi >> 16)) & M32
            if top and fault in ('q1', 'q1q2'):
                q1 = ((v[i - 1] >> 16)) // K  # quotient from the low half
            elif top and fault == 'c1':
                c1 = (v[i - 1] >> 16)
                q1 = c1 // K
            else:
                q1 = c1 // K
            r1 = (c1 - q1 * K) & M32
            c2 = ((r1 << 16) | (vi & 0xFFFF)) & M32
            if top and fault == 'q1q2':
                c2l = ((r1 << 16) | (v[i - 1] & 0xFFFF)) & M32
                q2 = c2l // K
            else:
                q2 = c2 // K
            rem = (c2 - q2 * K) & M32
            v[i] = ((q1 << 16) | q2) & M32
        chunk = rem
        for j in range(e):
            if k * e + j < ndig:
                cq = chunk // b
                out.append(chunk - cq * b)
                chunk = cq
    return out

def nlimbs(b):
    # limbs from the base's range end (gpu_config::n_limbs)
    from params_lib import rng
    lo, hi = rng(b)
    return max(1, -(-(hi - 1).bit_length() // 32))

def uniques(n, b, ls, lc, limbs, fs, fc):
    sq = to_limbs(n * n, 2 * limbs)
    cu = to_limbs(n ** 3, 3 * limbs)
    d = fd_to_digits(sq, ls, b, fs) + fd_to_digits(cu, lc, b, fc)
    return len(set(d))

if __name__ == "__main__":
    sys.path.insert(0, HERE)
    obs = {}
    for l in open(os.path.join(HERE, "..", "m4", "diag3.log")):
        m = re.match(r".*WRONG b(\d+) n=(\d+) cpu=\[\((\d+), 1\)\] fd=\[\((\d+), 1\)\]", l)
        if m:
            b, n, c, f = map(int, m.groups()); obs[(b, n)] = (c, f)
    P = {23: (795831, 3000, 9, 14, 1), 50: (26507984537059635, 400, 20, 30, 2)}
    faults = [None, 'q1', 'c1', 'q1q2']
    print("fault on S / fault on C -> n whose GPU unique count the model reproduces")
    for fs in faults:
        for fc in faults:
            res = {}
            for b, (s, cnt, ls, lc, limbs) in P.items():
                ok = 0
                for n in range(s, s + cnt):
                    true = uniques(n, b, ls, lc, limbs, None, None)
                    gpu = obs.get((b, n), (true, true))[1]
                    ok += uniques(n, b, ls, lc, limbs, fs, fc) == gpu
                res[b] = f"{ok}/{cnt}"
            print(f"S {str(fs):5s} C {str(fc):5s}  b23 {res[23]:>9s}  b50 {res[50]:>7s}")
