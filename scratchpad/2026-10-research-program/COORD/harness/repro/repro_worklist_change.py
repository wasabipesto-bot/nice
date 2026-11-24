#!/usr/bin/env python3
"""Field 0 searched and accepted; the coordinator restarted with the work list in another order: it must refuse,
since its records name fields by their index."""
import os
from common import *
d = workdir("wl"); st = os.path.join(d, "state")
f1, f2 = field(1), field(2)
wl = worklist(d, [f1, f2]); wl2 = worklist(d, [f2, f1], "work2.json")
p, port, _ = start(wl, st); c = claim(port); req(port, "POST", "/submit", body(c["claim_id"], f1)); kill(p)
p, port, s = start(wl2, st)
if s != "up":
    verdict(False, "restart with a reordered work list refused (%s)" % p.stderr.read().decode().strip()[-160:])
c2 = claim(port); stt = req(port, "GET", "/status")[1]; kill(p)
verdict(True, "reordered list accepted: status %s; next claim t=%s (t=1 was already searched, t=2 never)"
        % (stt, None if c2 is None else (c2["range_start"] - START) // Q))
