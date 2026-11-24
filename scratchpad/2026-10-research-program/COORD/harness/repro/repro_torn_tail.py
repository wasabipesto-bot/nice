#!/usr/bin/env python3
"""A kill mid-write leaves a torn last line (no newline): the restart must treat it as not acknowledged.
One claim, kill, append half a record to claims.jsonl, restart; then one more claim, kill, restart again."""
import os
from common import *
d = workdir("torn"); st = os.path.join(d, "state")
wl = worklist(d, [field(1), field(2), field(3)])
p, port, s = start(wl, st); c1 = claim(port); kill(p)
open(os.path.join(st, "claims.jsonl"), "ab").write(b'{"claim_id": 1001, "fie')
p, port, s = start(wl, st)
if s != "up":
    verdict(True, "restart with a torn last line: coordinator %s: %s" % (s, p.stderr.read().decode()[-200:]))
c2 = claim(port); kill(p)
p, port, s = start(wl, st)
if s != "up":
    verdict(True, "the record after the torn line was glued onto it: second restart %s" % s)
c3 = claim(port)
ids = [c["claim_id"] for c in (c1, c2, c3)]; flds = [c["range_start"] for c in (c1, c2, c3)]
verdict(len(set(ids)) != 3 or len(set(flds)) != 3, "claims %s on three distinct fields" % ids)
