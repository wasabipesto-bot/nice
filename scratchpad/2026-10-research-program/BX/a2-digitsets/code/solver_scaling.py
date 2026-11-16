"""E5a: CP-SAT (1 worker) exhaustion cost vs base, counting conflicts/branches.
Uses the 2026-08 model (copied) with redundant=False, residues=True (its fastest config)."""
import sys, time, json
from ortools.sat.python import cp_model
from cpsat_model_2608 import build_model, digit_splits, Collector

bases = [int(x) for x in sys.argv[1].split(",")]
limit = float(sys.argv[2]) if len(sys.argv) > 2 else 500
for b in bases:
    tot = dict(b=b, time=0.0, conflicts=0, branches=0, props=0, sols=[], status=[])
    for (d, dsq, dcu) in digit_splits(b):
        model, a = build_model(b, d, dsq, dcu, redundant=False, residues=True)
        s = cp_model.CpSolver()
        s.parameters.num_workers = 1
        s.parameters.enumerate_all_solutions = True
        s.parameters.max_time_in_seconds = limit
        coll = Collector(a, b)
        t0 = time.time()
        st = s.solve(model, coll)
        tot["time"] += time.time() - t0
        tot["conflicts"] += s.num_conflicts
        tot["branches"] += s.num_branches
        tot["props"] += s.response_proto.num_integer_propagations + s.response_proto.num_binary_propagations
        tot["sols"] += coll.solutions
        tot["status"].append(s.status_name(st))
    print(json.dumps(tot), flush=True)
