#!/usr/bin/env python3
"""T2.8 task 1: independent exact (Python big-integer) emptiness check of base-62 fields from range_start/range_end.
Argument, written from the definitions (not from the client's code):
 * every n in [a, e] has n^j in [a^j, e^j]; for the lowest c with floor(a^j/b^c) == floor(e^j/b^c), every n^j has
   exactly a^j's digits at positions >= c ("common digits"), and at position c-1 a digit in [lo, hi] where
   lo, hi = the digits of a^j and e^j there (the part above is equal, so floor(n^j/b^(c-1)) runs over a
   contiguous range with that fixed part);
 * a nice n has its len(n^2)+len(n^3) = b digits pairwise distinct, so: (1) lengths must sum to b; (2) the common
   digits of n^2 and n^3 together must be distinct; (3) Hall on the two domain positions: X = dom2 minus common,
   Y = dom3 minus common, need X, Y non-empty and |X u Y| >= 2.
 * if [a, e] fails, no n in it is nice; otherwise split it at multiples of the largest power b^m that cuts it and
   recurse (node budget per field).
usage: instant_check.py MODE ...   (see main)"""
import json, sys, collections
B = 62
def nd(x):
    n = 0
    while x: x //= B; n += 1
    return n
def digits_of(q):
    out = []
    while q: out.append(q % B); q //= B
    return out
def cert(a, e):
    """None if [a,e] provably has no nice n, else 'pass'. Also returns the reason code on failure."""
    common = []
    doms = []
    for j in (2, 3):
        A, E = a ** j, e ** j
        sp = nd(A)
        if nd(E) != sp: return "pass", None  # length change: not decided here
        c = 0; w = 1
        while A // w != E // w: c += 1; w *= B
        common += digits_of(A // w)[: sp - c] if A // w else []
        if c > 0:
            w1 = w // B
            lo, hi = (A // w1) % B, (E // w1) % B
            doms.append(set(range(lo, hi + 1)))
    if len(common) != len(set(common)): return None, "collision"
    m = set(common)
    if len(doms) == 2:
        X, Y = doms[0] - m, doms[1] - m
        if not X or not Y or len(X | Y) < 2: return None, "hall"
    elif len(doms) == 1:
        if not (doms[0] - m): return None, "hall"
    return "pass", None
def empty(a, e, budget):
    """(proved, reason, depth, nodes): explicit stack, depth-first."""
    if nd(a * a) + nd(a ** 3) != B or nd(e * e) + nd(e ** 3) != B: return False, "lengths", 0, 0
    r, why = cert(a, e)
    if r is None: return True, why, 0, 1
    nodes = 1; maxd = 0; reasons = collections.Counter()
    stack = [(a, e, 0)]
    while stack:
        lo, hi, d = stack.pop()
        w = 1
        while lo // (w * B) != hi // (w * B): w *= B
        # w is the largest power with lo//w != hi//w
        for q in range(lo // w, hi // w + 1):
            x, y = max(lo, q * w), min(hi, q * w + w - 1)
            nodes += 1
            if nodes > budget: return False, "budget", maxd, nodes
            r, why = cert(x, y)
            if r is None: reasons[why] += 1; maxd = max(maxd, d + 1); continue
            if x == y: return False, f"leaf n={x} passes", d + 1, nodes
            stack.append((x, y, d + 1))
    return True, "split:" + "+".join(sorted(reasons)), maxd, nodes
if __name__ == "__main__":
    fields = {f["id"]: f for f in json.load(open(sys.argv[1]))}
    ids = [int(x) for x in open(sys.argv[2]).read().split()]
    budget = int(sys.argv[3]); out = open(sys.argv[4], "w")
    for fid in ids:
        f = fields[fid]; a, e = int(f["range_start"]), int(f["range_end"]) - 1
        p, why, d, n = empty(a, e, budget)
        x = a / B ** 12
        out.write(json.dumps(dict(field_id=fid, proved=p, why=why, depth=d, nodes=n, x=x,
            lead2=(a * a) // B ** (nd(a * a) - 1), lead3=a ** 3 // B ** (nd(a ** 3) - 1))) + "\n"); out.flush()
