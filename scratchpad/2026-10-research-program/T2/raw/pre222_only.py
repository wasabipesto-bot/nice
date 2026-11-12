#!/usr/bin/env python3
"""T2.3: fields whose qualified nice-only submissions are all from builds without #222 (9a4f7406, 8c088a28,
c72e2c6f, cb38b917, or no telemetry), per base; count and share of the base range."""
import collections
from census_cells import S, F
PRE = {"9a4f7406", "8c088a28", "c72e2c6f", "cb38b917", ""}
by = collections.defaultdict(list)
for s in S:
    if not s["disqualified"]: by[s["field_id"]].append((s["build"] or "")[:8])
for b in (58, 60):
    tot = sum(int(f["range_size"]) for f in F.values() if f["base_id"] == b)
    ids = [fid for fid, v in by.items() if F[fid]["base_id"] == b and all(x in PRE for x in v)]
    nonempty = None
    sz = sum(int(F[f]["range_size"]) for f in ids)
    print(f"base {b}: {len(ids):,} fields ({100*sz/tot:.1f} % of the range) have only pre-#222 qualified submissions")
