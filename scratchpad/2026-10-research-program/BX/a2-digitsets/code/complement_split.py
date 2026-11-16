"""E2: complement-set ("the middle must be exactly C") conditions on AND-survivor pairs.

For an admissible n whose prefix_t and residue_k certificates are each distinct and disjoint
(an AND survivor of the join at overlap o = t+k-L), let C = digits not yet used, and the
middle positions of n^2 (m2 of them) and n^3 (m3) be those not certified. Conditions tested:
 S1  (per-side computable: needs only n mod b-1, the join key): some X ⊆ C, |X| = m2,
     sum X ≡ n^2 - S(T2) - S(B2)  (mod b-1).
 S2  (needs n mod b+1, NOT per-side): the four-way split of C into the even/odd middle
     positions of n^2 and n^3 can meet both alternating-sum congruences mod b+1, jointly with S1.
 S3  bounds: the n^2 middle block value (determined by n) lies between the smallest and largest
     arrangement of some m2-subset of C (i.e. between min-arrangement of smallest m2 digits
     and max-arrangement of largest m2) -- the weakest value test; same for n^3.
Rejection rate = fraction of survivors failing. Usage: complement_split.py b t k samples seed"""
import sys, random
from nicelib import *


def split_feasible(C, m2, target, mod):
    # states: (count, sum mod) reachable by subsets
    st = {(0, 0)}
    for d in C:
        st |= {(c + 1, (s + d) % mod) for (c, s) in st if c < m2}
    return (m2, target % mod) in st


def split4_feasible(C, sizes, tq1, ta2, ta3, b):
    """sizes = (n2 even, n2 odd, n3 even, n3 odd) middle positions.
    Constraints: sum(n2 all) ≡ tq1 mod b-1; sum(n2 even)-sum(n2 odd) ≡ ta2 mod b+1;
    sum(n3 even)-sum(n3 odd) ≡ ta3 mod b+1."""
    M1, M2 = b - 1, b + 1
    st = {(0, 0, 0, 0, 0, 0)}  # c2e, c2o, c3e, q1, a2, a3   (c3o implied)
    used = 0
    for d in C:
        used += 1
        new = set()
        for (c2e, c2o, c3e, q1, a2, a3) in st:
            c3o = used - 1 - c2e - c2o - c3e
            if c2e < sizes[0]:
                new.add((c2e + 1, c2o, c3e, (q1 + d) % M1, (a2 + d) % M2, a3))
            if c2o < sizes[1]:
                new.add((c2e, c2o + 1, c3e, (q1 + d) % M1, (a2 - d) % M2, a3))
            if c3e < sizes[2]:
                new.add((c2e, c2o, c3e + 1, q1, a2, (a3 + d) % M2))
            if c3o < sizes[3]:
                new.add((c2e, c2o, c3e, q1, a2, (a3 - d) % M2))
        st = new
    return (sizes[0], sizes[1], sizes[2], tq1 % M1, ta2 % M2, ta3 % M2) in st


def main():
    b, t, k, samples, seed = map(int, sys.argv[1:6])
    rnd = random.Random(seed)
    lo, hi = nice_range(b)
    roots = residues(b)
    L = ndig(lo, b)
    W = b ** (L - t)
    surv = rej1 = rej2 = rej3 = 0
    tried = 0
    sizesC = []
    while surv < samples and tried < 3000000:
        tried += 1
        n = rnd.randrange(lo, hi)
        n += (rnd.choice(roots) - n) % (b - 1)  # move into a root class
        if n >= hi:
            continue
        P = n // W
        tc = top_cert(max(P * W, lo), min((P + 1) * W, hi) - 1, b)
        tc = [x for x in tc if x[1] >= k] if True else tc  # positions >= k as in the join
        mt = mask_of(tc)
        if mt is None:
            continue
        bc = bottom_cert(n % b ** k, k, b)
        mb = mask_of(bc)
        if mb is None or mt & mb:
            continue
        # dedupe positions (top and bottom may certify the same position of n^3/n^2? only if overlap)
        known = {}
        for w, p, d in tc + bc:
            known[(w, p)] = d
        used = 0
        for d in known.values():
            used |= 1 << d
        if bin(used).count("1") != len(known):
            continue  # same digit at two positions after dedupe -> not a survivor
        surv += 1
        C = [d for d in range(b) if not used >> d & 1]
        n2, n3 = n * n, n ** 3
        D2, D3 = digits(n2, b), digits(n3, b)
        mid2 = [p for p in range(len(D2)) if (2, p) not in known]
        mid3 = [p for p in range(len(D3)) if (3, p) not in known]
        assert len(C) == len(mid2) + len(mid3), (len(C), len(mid2), len(mid3))
        sizesC.append(len(C))
        r = n % (b - 1)
        S_known2 = sum(d for (w, p), d in known.items() if w == 2)
        tq1 = (r * r - S_known2) % (b - 1)
        ok1 = split_feasible(C, len(mid2), tq1, b - 1)
        rej1 += not ok1
        # alternating sums
        a2k = sum(d * (-1) ** p for (w, p), d in known.items() if w == 2)
        a3k = sum(d * (-1) ** p for (w, p), d in known.items() if w == 3)
        ta2 = (n2 % (b + 1) - a2k) % (b + 1)
        ta3 = (n3 % (b + 1) - a3k) % (b + 1)
        sizes = (sum(1 for p in mid2 if p % 2 == 0), sum(1 for p in mid2 if p % 2),
                 sum(1 for p in mid3 if p % 2 == 0), sum(1 for p in mid3 if p % 2))
        ok2 = ok1 and (b > 22 or split4_feasible(C, sizes, tq1, ta2, ta3, b))
        rej2 += not ok2
        # value bounds, n^2 middle block (contiguous? take the maximal run)
        ok3 = True
        for D, mid in ((D2, mid2), (D3, mid3)):
            if not mid:
                continue
            m = len(mid)
            val = sum(D[p] * b ** (p - mid[0]) for p in mid) if mid == list(range(mid[0], mid[0] + m)) else None
            if val is None:
                continue
            Cs = sorted(C)
            smallest = Cs[:m]
            largest = Cs[-m:]
            vmin = sum(dd * b ** i for i, dd in enumerate(sorted(smallest, reverse=True)))
            vmax = sum(dd * b ** i for i, dd in enumerate(sorted(largest)))
            if not (vmin <= val <= vmax):
                ok3 = False
        rej3 += not ok3
    print(f"b={b} L={L} t={t} k={k} tried={tried} survivors={surv} mean|C|={sum(sizesC)/max(1,len(sizesC)):.1f} "
          f"rej S1={rej1/max(1,surv):.4f} S1+S2={rej2/max(1,surv):.4f} S3={rej3/max(1,surv):.4f}")


main()
