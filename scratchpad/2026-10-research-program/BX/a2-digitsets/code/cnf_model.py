"""E5d: pure CNF + CDCL (CaDiCaL via python-sat) on the same digit/carry model as the CP-SAT one.
Binary digits (w bits each), Tseitin multipliers/adders for the schoolbook columns of n*n and
n*n^2, pairwise all-different over the b output digits, no residue constraint (CNF-unfriendly),
one CNF per digit split. Enumerates all solutions with blocking clauses.
Usage: cnf_model.py b1,b2,... [time_limit_s]"""
import sys, time, json, threading
from pysat.solvers import Cadical195
from cpsat_model_2608 import digit_splits


class CNF:
    def __init__(self):
        self.n = 0
        self.cl = []
        self.T = self.new()
        self.cl.append([self.T])

    def new(self):
        self.n += 1
        return self.n

    def AND(self, a, b):
        c = self.new()
        self.cl += [[-c, a], [-c, b], [c, -a, -b]]
        return c

    def OR(self, a, b):
        c = self.new()
        self.cl += [[c, -a], [c, -b], [-c, a, b]]
        return c

    def XOR(self, a, b):
        c = self.new()
        self.cl += [[-c, a, b], [-c, -a, -b], [c, -a, b], [c, a, -b]]
        return c

    def FA(self, a, b, cin):
        s = self.XOR(self.XOR(a, b), cin)
        co = self.OR(self.AND(a, b), self.AND(cin, self.XOR(a, b)))
        return s, co

    def add(self, x, y):
        """little-endian bit lists, result len max+1 (F = -T for zero)."""
        F = -self.T
        m = max(len(x), len(y))
        x = x + [F] * (m - len(x))
        y = y + [F] * (m - len(y))
        out = []
        c = F
        for i in range(m):
            s, c = self.FA(x[i], y[i], c)
            out.append(s)
        out.append(c)
        return out

    def mul(self, x, y):
        F = -self.T
        acc = [F]
        for i, yb in enumerate(y):
            row = [F] * i + [self.AND(xb, yb) for xb in x]
            acc = self.add(acc, row)
        return acc

    def const_mul(self, x, k):
        F = -self.T
        acc = [F]
        i = 0
        while k:
            if k & 1:
                acc = self.add(acc, [F] * i + x)
            k >>= 1
            i += 1
        return acc

    def eq(self, x, y):
        F = -self.T
        m = max(len(x), len(y))
        x = x + [F] * (m - len(x))
        y = y + [F] * (m - len(y))
        for a, b in zip(x, y):
            self.cl += [[-a, b], [a, -b]]

    def lt_const(self, x, k):
        """assert value(x) < k (k > 0): forbid every value >= k via lexicographic clauses."""
        m = len(x)
        if k >= 1 << m:
            return
        # value >= k  <=>  exists i: x_i=1, k_i=0, and higher bits of x >= ... use standard compare
        # forbid x >= k: for each prefix match on bits above i where k_i = 0 and x_i = 1 -> forbidden;
        # and x == k forbidden.
        bits = [(k >> i) & 1 for i in range(m)]
        for i in range(m):
            if bits[i] == 0:
                # higher bits equal to k's higher bits where k=1 requires x=1; x_i = 1 -> x > k
                cl = [-x[i]]
                for j in range(i + 1, m):
                    if bits[j] == 1:
                        cl.append(-x[j])
                    else:
                        cl.append(x[j])
                # clause says: NOT(x_i=1 and higher bits match k on 1s and x=0 where k=0)
                # simpler: forbid (x_i=1 and for j>i: x_j>=k_j with equality pattern) -> use exact
                self.cl.append([-x[i]] + [(-x[j] if bits[j] else x[j]) for j in range(i + 1, m)])
        # forbid x == k
        self.cl.append([(-x[j] if bits[j] else x[j]) for j in range(m)])

    def neq(self, x, y):
        d = [self.XOR(a, b) for a, b in zip(x, y)]
        self.cl.append(d)


def build(b, d, dsq, dcu):
    c = CNF()
    w = (b - 1).bit_length()
    F = -c.T
    a = [[c.new() for _ in range(w)] for _ in range(d)]
    q = [[c.new() for _ in range(w)] for _ in range(dsq)]
    cu = [[c.new() for _ in range(w)] for _ in range(dcu)]
    for v in a + q + cu:
        c.lt_const(v, b)
    c.cl.append(a[d - 1])            # leading digit nonzero
    c.cl.append(q[dsq - 1])
    c.cl.append(cu[dcu - 1])
    # square columns
    r = [F]
    prods = {}
    for i in range(d):
        for k in range(i, d):
            prods[(i, k)] = c.mul(a[i], a[k])
    for j in range(2 * d - 1):
        col = list(r)
        for u in range(max(0, j - d + 1), min(d, j + 1)):
            v = j - u
            if u > v:
                continue
            p = prods[(u, v)]
            col = c.add(col, p if u == v else [F] + p)
        rn = [c.new() for _ in range(len(col))]
        if j < dsq:
            rhs = c.add(q[j], c.const_mul(rn, b))
        else:
            rhs = c.const_mul(rn, b)
        c.eq(col, rhs)
        r = rn
    hi_sq = [F]
    for j in range(dsq - 1, 2 * d - 2, -1):   # value of digits q[2d-1 ..] (Horner)
        hi_sq = c.add(c.const_mul(hi_sq, b), q[j])
    c.eq(r, hi_sq)
    # cube columns n * n^2
    s = [F]
    ncols = d + dsq - 1
    for j in range(ncols):
        col = list(s)
        for i in range(max(0, j - dsq + 1), min(d, j + 1)):
            col = c.add(col, c.mul(a[i], q[j - i]))
        sn = [c.new() for _ in range(len(col))]
        if j < dcu:
            rhs = c.add(cu[j], c.const_mul(sn, b))
        else:
            rhs = c.const_mul(sn, b)
        c.eq(col, rhs)
        s = sn
    hi_cu = [F]
    for j in range(dcu - 1, ncols - 1, -1):
        hi_cu = c.add(c.const_mul(hi_cu, b), cu[j])
    c.eq(s, hi_cu)
    outs = q + cu
    for i in range(len(outs)):
        for j in range(i + 1, len(outs)):
            c.neq(outs[i], outs[j])
    return c, a


def main():
    bases = [int(x) for x in sys.argv[1].split(",")]
    limit = float(sys.argv[2]) if len(sys.argv) > 2 else 250
    for b in bases:
        tot = dict(b=b, time=0.0, conflicts=0, decisions=0, sols=[], vars=0, clauses=0, status=[])
        for (d, dsq, dcu) in digit_splits(b):
            c, a = build(b, d, dsq, dcu)
            tot["vars"] += c.n
            tot["clauses"] += len(c.cl)
            S = Cadical195(bootstrap_with=c.cl)
            t0 = time.time()
            timer = threading.Timer(limit, lambda: S.interrupt())
            timer.start()
            st = "UNSAT"
            while True:
                res = S.solve_limited(expect_interrupt=True)
                if res is None:
                    st = "TIMEOUT"
                    break
                if not res:
                    break
                model = set(x for x in S.get_model() if x > 0)
                n = sum(sum(1 << k for k, v in enumerate(a[i]) if v in model) * b ** i for i in range(d))
                tot["sols"].append(n)
                S.add_clause([-v if v in model else v for dig in a for v in dig])
            timer.cancel()
            tot["time"] += time.time() - t0
            stats = S.accum_stats()
            tot["conflicts"] += stats.get("conflicts", 0)
            tot["decisions"] += stats.get("decisions", 0)
            tot["status"].append(st)
            S.delete()
        print(json.dumps(tot), flush=True)


main()
