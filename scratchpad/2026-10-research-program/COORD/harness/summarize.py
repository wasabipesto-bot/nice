#!/usr/bin/env python3
"""Summarize chaos.py --summary files: one row per file (runs, failed runs, runs failing each invariant class), and
the coverage (runs that exercised each event, client kind and reply; audit runs; audit disagreements).

usage: summarize.py SUM.jsonl [SUM.jsonl ...]
"""
import json, sys

CLASSES = ["S1", "S1/S4", "S2", "S3/S4", "S5", "S6", "S7", "H1", "H2", "H3", "H3/H4", "H4", "H5", "E1", "E2", "AUDIT",
           "HARNESS", "START", "DRAIN", "CLAIM"]
print("| file | runs | failed | " + " | ".join(CLASSES) + " |")
print("|---|---|---|" + "---|" * len(CLASSES))
cov = {}
for path in sys.argv[1:]:
    rows = [json.loads(l) for l in open(path)]
    per = {c: 0 for c in CLASSES}
    nf = 0
    ev, kd, st, nled, aud, h6 = {}, {}, {}, 0, 0, 0
    for r in rows:
        cls = {v.split(":")[0] for v in r["viol"]}
        for c in cls:
            per[c] = per.get(c, 0) + 1
        nf += bool(r["viol"])
        for x in r.get("ev_kinds", []):
            ev[x] = ev.get(x, 0) + 1
        for x in r.get("kinds", []):
            kd[x] = kd.get(x, 0) + 1
        for x in r.get("statuses", []):
            st[x] = st.get(x, 0) + 1
        nled += r.get("ledger_n", 0)
        aud += r.get("audit_rc") is not None
        h6 += bool(r.get("h6"))
    name = path.rsplit("/", 1)[-1].replace("sum-", "").replace(".jsonl", "")
    print("| %s | %d | %d | " % (name, len(rows), nf) + " | ".join(str(per[c]) if per[c] else "" for c in CLASSES) + " |")
    cov[name] = (len(rows), ev, kd, st, nled, aud, h6, per["AUDIT"])
print()
for name, (n, ev, kd, st, nled, aud, h6, ad) in cov.items():
    print("%s: %d runs, %d ledger events (claims, sends, replies); audit run on %d, disagreed on %d; "
          "H6 (first holder accepted after a reissue) seen in %d runs" % (name, n, nled, aud, ad, h6))
    print("  events (runs): " + ", ".join("%s %d" % kv for kv in sorted(ev.items())))
    print("  client kinds (runs): " + ", ".join("%s %d" % kv for kv in sorted(kd.items())))
    print("  replies (runs): " + ", ".join("%s %d" % kv for kv in sorted(st.items())))
