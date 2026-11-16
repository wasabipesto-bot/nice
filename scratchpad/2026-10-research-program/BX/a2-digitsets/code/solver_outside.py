"""E5c: CP-SAT (1 worker), FIXED decision order on OUTPUT digits (output-side / dual branching):
 'cmid'  = cube digits ordered by distance from the cube's middle, then n's digits
 'qcmid' = middle square and cube digits interleaved, then n's digits
 'clow'  = cube digits low to high (Hensel-like), then n's digits
Values: SELECT_MIN_VALUE. Compare branches with OPT tree / PSJ."""
import sys, time, json
from ortools.sat.python import cp_model
from cpsat_model_2608 import build_model, digit_splits, Collector

bases = [int(x) for x in sys.argv[1].split(",")]
order = sys.argv[2]
limit = float(sys.argv[3]) if len(sys.argv) > 3 else 250
for b in bases:
    tot = dict(b=b, order=order, time=0.0, conflicts=0, branches=0, sols=[], status=[])
    for (d, dsq, dcu) in digit_splits(b):
        model, a = build_model(b, d, dsq, dcu, redundant=False, residues=True)
        byname = {}
        for i, v in enumerate(model.proto.variables):
            byname[v.name] = model.get_int_var_from_proto_index(i)
        q = [byname[f"q{j}"] for j in range(dsq)]
        c = [byname[f"c{j}"] for j in range(dcu)]
        if order == "cmid":
            mid = (dcu - 1) / 2
            seq = sorted(c, key=lambda v: abs(int(v.name[1:]) - mid)) + a
        elif order == "qcmid":
            m3, m2 = (dcu - 1) / 2, (dsq - 1) / 2
            allv = [(abs(j - m2) / dsq, q[j]) for j in range(dsq)] + [(abs(j - m3) / dcu, c[j]) for j in range(dcu)]
            seq = [v for _, v in sorted(allv, key=lambda x: x[0])] + a
        else:
            seq = c + a
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
