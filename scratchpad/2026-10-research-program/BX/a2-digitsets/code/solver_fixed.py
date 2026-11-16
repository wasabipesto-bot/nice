"""E5b: CP-SAT (1 worker) with a FIXED decision order on n's digits.
order: 'alt' = a_{L-1}, a_0, a_{L-2}, a_1, ... (two-sided tree); 'top' = MSD first; 'bot' = LSD first.
Compares branches/conflicts with the tree counts (tree_counts.py, alt_tree.py)."""
import sys, time, json
from ortools.sat.python import cp_model
from cpsat_model_2608 import build_model, digit_splits, Collector

bases = [int(x) for x in sys.argv[1].split(",")]
order = sys.argv[2]
limit = float(sys.argv[3]) if len(sys.argv) > 3 else 280
for b in bases:
    tot = dict(b=b, order=order, time=0.0, conflicts=0, branches=0, sols=[], status=[])
    for (d, dsq, dcu) in digit_splits(b):
        model, a = build_model(b, d, dsq, dcu, redundant=False, residues=True)
        if order == "alt":
            seq = []
            i, j = d - 1, 0
            while i >= j:
                seq.append(a[i]); i -= 1
                if j <= i:
                    seq.append(a[j]); j += 1
        elif order == "top":
            seq = a[::-1]
        else:
            seq = list(a)
        model.add_decision_strategy(seq, cp_model.CHOOSE_FIRST, cp_model.SELECT_MIN_VALUE)
        s = cp_model.CpSolver()
        s.parameters.num_workers = 1
        s.parameters.search_branching = cp_model.FIXED_SEARCH
        s.parameters.enumerate_all_solutions = True
        s.parameters.max_time_in_seconds = limit
        coll = Collector(a, b)
        t0 = time.time()
        st = s.solve(model, coll)
        tot["time"] += time.time() - t0
        tot["conflicts"] += s.num_conflicts
        tot["branches"] += s.num_branches
        tot["sols"] += coll.solutions
        tot["status"].append(s.status_name(st))
    print(json.dumps(tot), flush=True)
