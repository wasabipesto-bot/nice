#!/usr/bin/env python3
"""base mean of today's main from a run_main.sh output: wall from the warm-up's submit to the last submit / admissible n"""
import json, sys
rows = [json.loads(l) for l in open(sys.argv[1])]
rows = [r for r in rows if r.get("claim_id") != 1]
rows.sort(key=lambda r: r["_stub"]["recv"])
warm = [r for r in rows if r["claim_id"] == 900000][0]
timed = [r for r in rows if r["claim_id"] != 900000]
t0 = warm["_stub"]["recv"]; t1 = max(r["_stub"]["recv"] for r in timed)
adm = len(timed) * 1e17 * 8 / 63
print(f"fields {len(timed)}, wall {t1 - t0:.1f} s, {(t1 - t0) / adm * 1e15:.3f} fs per admissible n")
for r in timed:
    c = r["_stub"]; print(r["claim_id"], f"claim->recv {c['recv'] - c['claim']:.1f} s", {k: r[k] for k in r if k not in ("_stub",) and not isinstance(r[k], (list, dict))})
