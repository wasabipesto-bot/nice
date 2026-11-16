#!/usr/bin/env python3
"""CP-SAT digit/carry model for square-cube pandigitals (theory review §6).

A number n with digits a_i (base b) is "nice" when the concatenated digits of
n² and n³ form a permutation of 0..b-1. The model:

  - input digits a_i, square digits q_j, cube digits c_j, carries r_j / s_j
  - schoolbook column equations with explicit carries:
      square (n·n):  r_j + Σ_{u+v=j} a_u·a_v       = q_j + b·r_{j+1}
      cube (n·n²):   s_j + Σ_{u+v=j} a_u·q_v       = c_j + b·s_{j+1}
  - AllDifferent over q ∪ c (exactly b digits → permutation)
  - redundant global carry-sum identities:
      (Σa)² − Σq = (b−1)·Σ_{j≥1} r_j
      (Σa)(Σq) − Σc = (b−1)·Σ_{j≥1} s_j
      Σq + Σc = b(b−1)/2
  - residue filter: digit sum of n restricted to the valid classes mod b−1
  - digit-length constraints via nonzero leading digits

For each base we enumerate the feasible digit-count splits (D, Dsq, Dcu) with
Dsq + Dcu = b and solve each as a separate model.
"""

import sys
import time
from ortools.sat.python import cp_model


def residue_classes(b):
    """Valid n mod (b-1) classes (mirrors residue_filter.rs)."""
    m = b - 1
    target = (b * (b - 1) // 2) % m
    return [r for r in range(m) if (r * r + r * r * r) % m == target]


def digit_splits(b):
    """Feasible (D, Dsq, Dcu) with Dsq+Dcu = b for some n with D digits."""
    splits = []
    for d in range(1, b):
        for dsq in (2 * d - 1, 2 * d):
            for dcu in (3 * d - 2, 3 * d - 1, 3 * d):
                if dsq + dcu != b:
                    continue
                # crude consistency: digit counts must be achievable for the
                # same n: n in [b^(d-1), b^d) implies n^2 in [b^(2d-2), b^(2d))
                # and n^3 in [b^(3d-3), b^(3d)) -- the fine check happens via
                # the leading-digit constraints, which make impossible splits
                # UNSAT quickly.
                splits.append((d, dsq, dcu))
    return splits


def build_model(b, d, dsq, dcu, redundant=True, residues=True,
                fix_low=None, lead_range=None):
    """Build the model for one digit split. Returns (model, a_vars).

    fix_low: optional (k, value) fixing n mod b^k (stride-style slice)
    lead_range: optional (lo, hi) bounds on the leading input digit
    """
    model = cp_model.CpModel()
    a = [model.new_int_var(0, b - 1, f"a{i}") for i in range(d)]
    q = [model.new_int_var(0, b - 1, f"q{j}") for j in range(dsq)]
    c = [model.new_int_var(0, b - 1, f"c{j}") for j in range(dcu)]

    model.add(a[d - 1] >= 1)
    if dsq >= 2:
        model.add(q[dsq - 1] >= 1)
    if dcu >= 2:
        model.add(c[dcu - 1] >= 1)

    # The permutation condition.
    model.add_all_different(q + c)

    # Square: products p[i][k] = a_i * a_k (i <= k).
    p = {}
    for i in range(d):
        for k in range(i, d):
            v = model.new_int_var(0, (b - 1) * (b - 1), f"p{i}_{k}")
            model.add_multiplication_equality(v, [a[i], a[k]])
            p[(i, k)] = v

    # Column sums for the square, with carries. Column j of n*n gets terms
    # a_u*a_v for u+v=j; sum bound gives the carry domain.
    r = [model.new_int_var(0, 0, "r0")]
    for j in range(2 * d - 1):
        terms = []
        max_sum = 0
        for u in range(max(0, j - d + 1), min(d, j + 1)):
            v = j - u
            if u > v:
                continue
            coeff = 1 if u == v else 2
            terms.append(coeff * p[(u, v)])
            max_sum += coeff * (b - 1) * (b - 1)
        max_in = max_sum + r[j].proto.domain[1]
        r.append(model.new_int_var(0, max_in // b, f"r{j + 1}"))
        col = r[j] + sum(terms)
        if j < dsq:
            model.add(col == q[j] + b * r[j + 1])
        else:
            # no digit slot: the split's dsq is too small unless col is 0
            model.add(col == b * r[j + 1])
    # top: remaining carry must produce exactly the remaining high digits
    # of the square. For j >= 2d-1 the only content is the carry chain; we
    # already required q's leading digit nonzero, and the last carry IS the
    # top digit(s). Handle by requiring the final carry to equal the value
    # of the digits above the last column, which for dsq <= 2d means either
    # 0 (dsq == 2d-1 exactly consumed) or q[2d-1] (dsq == 2d).
    if dsq == 2 * d:
        model.add(r[2 * d - 1] == q[2 * d - 1])
    else:
        model.add(r[2 * d - 1] == 0)

    # Cube: products t[i][j] = a_i * q_j, columns of n * n².
    t = {}
    for i in range(d):
        for j in range(dsq):
            v = model.new_int_var(0, (b - 1) * (b - 1), f"t{i}_{j}")
            model.add_multiplication_equality(v, [a[i], q[j]])
            t[(i, j)] = v

    s = [model.new_int_var(0, 0, "s0")]
    n_cols = d + dsq - 1
    for j in range(n_cols):
        terms = []
        max_sum = 0
        for i in range(max(0, j - dsq + 1), min(d, j + 1)):
            terms.append(t[(i, j - i)])
            max_sum += (b - 1) * (b - 1)
        max_in = max_sum + s[j].proto.domain[1]
        s.append(model.new_int_var(0, max_in // b, f"s{j + 1}"))
        col = s[j] + sum(terms)
        if j < dcu:
            model.add(col == c[j] + b * s[j + 1])
        else:
            model.add(col == b * s[j + 1])
    if dcu == n_cols + 1:
        model.add(s[n_cols] == c[dcu - 1])
    elif dcu <= n_cols:
        model.add(s[n_cols] == 0)

    if redundant:
        sum_a = sum(a)
        sum_q = sum(q)
        sum_c = sum(c)
        # Σq + Σc = b(b-1)/2 (digit sum of a permutation)
        model.add(sum_q + sum_c == b * (b - 1) // 2)
        # (Σa)² − Σq = (b−1)·Σ r_j
        sa = model.new_int_var(0, d * (b - 1), "sa")
        model.add(sa == sum_a)
        sa2 = model.new_int_var(0, (d * (b - 1)) ** 2, "sa2")
        model.add_multiplication_equality(sa2, [sa, sa])
        model.add(sa2 - sum_q == (b - 1) * sum(r[1:]))
        # (Σa)(Σq) − Σc = (b−1)·Σ s_j
        sq_tot = model.new_int_var(0, dsq * (b - 1), "sqt")
        model.add(sq_tot == sum_q)
        saq = model.new_int_var(0, d * (b - 1) * dsq * (b - 1), "saq")
        model.add_multiplication_equality(saq, [sa, sq_tot])
        model.add(saq - sum_c == (b - 1) * sum(s[1:]))

    if residues:
        classes = residue_classes(b)
        if not classes:
            model.add(a[0] < 0)  # dead base: force UNSAT
        else:
            sa_m = model.new_int_var(0, d * (b - 1), "sam")
            model.add(sa_m == sum(a))
            mod = model.new_int_var(0, b - 2, "mod")
            model.add_modulo_equality(mod, sa_m, b - 1)
            model.add_allowed_assignments([mod], [(x,) for x in classes])

    if fix_low is not None:
        k, value = fix_low
        for i in range(k):
            model.add(a[i] == (value // b**i) % b)

    if lead_range is not None:
        lo, hi = lead_range
        model.add(a[d - 1] >= lo)
        model.add(a[d - 1] <= hi)

    return model, a


class Collector(cp_model.CpSolverSolutionCallback):
    def __init__(self, a, b):
        super().__init__()
        self.a = a
        self.b = b
        self.solutions = []

    def on_solution_callback(self):
        n = sum(self.value(v) * self.b**i for i, v in enumerate(self.a))
        self.solutions.append(n)


def solve_base(b, workers=4, enumerate_all=True, time_limit=None,
               redundant=True, residues=True, fix_low=None, lead_range=None,
               verbose=False):
    """Solve every digit split for a base. Returns (solutions, seconds, status)."""
    total_time = 0.0
    solutions = []
    statuses = []
    for (d, dsq, dcu) in digit_splits(b):
        model, a = build_model(b, d, dsq, dcu, redundant, residues,
                               fix_low, lead_range)
        solver = cp_model.CpSolver()
        solver.parameters.num_workers = workers
        if time_limit:
            solver.parameters.max_time_in_seconds = time_limit
        t0 = time.time()
        if enumerate_all:
            solver.parameters.enumerate_all_solutions = True
            # enumeration requires a single worker in CP-SAT
            solver.parameters.num_workers = 1
            coll = Collector(a, b)
            status = solver.solve(model, coll)
            solutions.extend(coll.solutions)
        else:
            status = solver.solve(model)
            if status == cp_model.FEASIBLE or status == cp_model.OPTIMAL:
                n = sum(solver.value(v) * b**i for i, v in enumerate(a))
                solutions.append(n)
        dt = time.time() - t0
        total_time += dt
        statuses.append(solver.status_name(status))
        if verbose:
            print(f"  b={b} split (D={d}, Dsq={dsq}, Dcu={dcu}): "
                  f"{solver.status_name(status)} in {dt:.2f}s "
                  f"(conflicts {solver.num_conflicts}, branches {solver.num_branches})",
                  flush=True)
    return sorted(set(solutions)), total_time, statuses


def brute_force(b):
    """Reference: all nice numbers in base b by direct scan."""
    out = []
    # find n range: digits(n^2)+digits(n^3) == b
    def digits(x):
        cnt = 0
        while x:
            cnt += 1
            x //= b
        return max(cnt, 1)
    n = 2
    while digits(n * n) + digits(n * n * n) < b:
        n += 1
    while digits(n * n) + digits(n * n * n) == b:
        seen = 0
        ok = True
        for x in (n * n, n * n * n):
            while x:
                bit = 1 << (x % b)
                if seen & bit:
                    ok = False
                    break
                seen |= bit
                x //= b
            if not ok:
                break
        if ok and seen == (1 << b) - 1:
            out.append(n)
        n += 1
    return out


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "sanity"

    if mode == "sanity":
        print("=== E1: base 10 enumeration ===", flush=True)
        sols, dt, st = solve_base(10, verbose=True)
        print(f"solutions: {sols} in {dt:.2f}s (expect [69])")

    elif mode == "small":
        print("=== E2: small-base cross-check vs brute force ===", flush=True)
        for b in range(5, 17):
            ref = brute_force(b)
            sols, dt, st = solve_base(b)
            match = "OK" if sols == ref else f"MISMATCH ref={ref}"
            print(f"b={b}: cp-sat {sols} in {dt:.2f}s ... {match}", flush=True)

    elif mode == "scaling":
        print("=== E3: full-base exhaustion scaling ===", flush=True)
        for b in [14, 18, 20, 22, 25, 26, 30]:
            sols, dt, st = solve_base(b, verbose=True, time_limit=600)
            print(f"b={b}: exhausted in {dt:.2f}s, solutions {sols}, statuses {st}", flush=True)

    elif mode == "witness":
        b = int(sys.argv[2])
        limit = float(sys.argv[3]) if len(sys.argv) > 3 else 300.0
        print(f"=== witness search b={b}, limit {limit}s per split ===", flush=True)
        sols, dt, st = solve_base(b, enumerate_all=False, time_limit=limit,
                                  verbose=True)
        print(f"b={b}: {st} in {dt:.2f}s, solutions {sols}")
