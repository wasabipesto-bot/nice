#!/usr/bin/env python3
"""T2.3 sample design (seed 20261112). Population of a cell = its qualified (not disqualified) nice-only
submissions with valid_numbers > 0 (non-empty fields; an empty field is decided by the CPU-side MSD
filter before any join runs). Targets: the three largest cells of a base (by range share) 149
(zero mismatches -> 95 % upper bound <= 2 %), other cells over 1 % of a base 59 (<= 5 %), smaller
cells 20 (<= 14 %), or the whole cell if smaller. Stratified over time: the cell's submissions sorted
by submit_time are cut into n equal strata and one is drawn uniformly from each. Each build's queue
is ordered so that any prefix holds the same fraction of every cell's sample (key (rank+u)/n).
Cells without counters (no telemetry) are listed as not checkable.
Writes sample.json (per cell: key, share, population, target, drawn rows) and queue_<build8>.json."""
import json, random, collections, math
from census_cells import S, F, cellkey
SEED = 20261112
rng = random.Random(SEED)
for s in S: s["base"] = F[s["field_id"]]["base_id"]
cells = collections.defaultdict(list)
for s in S:
    if not s["disqualified"]: cells[(s["base"],) + cellkey(s)].append(s)
rsz = {b: sum(int(f["range_size"]) for f in F.values() if f["base_id"] == b) for b in (58, 60)}
out = []
for b in (58, 60):
    ks = sorted([k for k in cells if k[0] == b], key=lambda k: -len(cells[k]))
    shares = {k: sum(int(F[s["field_id"]]["range_size"]) for s in cells[k]) / rsz[b] for k in ks}
    top3 = sorted(ks, key=lambda k: -shares[k])
    top3 = [k for k in top3 if k[1] != "no-telemetry"][:3]
    for k in ks:
        pop = sorted([s for s in cells[k] if s["valid"] not in (None, "0") or (s["valid"] is None and s["surv"] not in (None, "0"))], key=lambda s: (s["submit_time"], s["id"]))
        checkable = k[1] != "no-telemetry" and all(s["surv"] is not None for s in pop)
        tgt = 149 if k in top3 else 59 if shares[k] > 0.01 else 20
        n = min(tgt, len(pop)) if checkable else 0
        drawn = []
        for i in range(n):
            lo, hi = (i * len(pop)) // n, ((i + 1) * len(pop)) // n
            drawn.append(pop[rng.randrange(lo, hi)])
        rng.shuffle(drawn)
        out.append(dict(base=b, family=k[1], build=k[2], version=k[3], share=shares[k], subs=len(cells[k]),
                        population=len(pop), target=tgt, checkable=checkable, n=n,
                        drawn=[dict(sub_id=s["id"], field_id=s["field_id"], base=b, range_start=F[s["field_id"]]["range_start"],
                                    range_size=F[s["field_id"]]["range_size"], surv=s["surv"], chk=s["chk"],
                                    user=s["username"], submit_time=s["submit_time"], gpu=s["gpu"]) for s in drawn]))
json.dump(out, open("sample.json", "w"), indent=0)
q = collections.defaultdict(list)
for c in out:
    for r, row in enumerate(c["drawn"]):
        q[c["build"] + ("-cpu" if c["family"] == "CPU/none" else "") + f'_b{c["base"]}'].append(((r + rng.random()) / c["n"], dict(row, cell=f'{c["base"]}|{c["family"]}|{c["build"]}')))
for b8, items in q.items():
    items.sort(key=lambda x: x[0])
    json.dump([x[1] for x in items], open(f"queue_{b8}.json", "w"), indent=0)
    print(b8, len(items))
for c in out: print(c["base"], f'{c["family"][:30]:30s}', c["build"], f'{100*c["share"]:6.2f}%', c["population"], c["target"], c["n"], "" if c["checkable"] else "NOT CHECKABLE")
