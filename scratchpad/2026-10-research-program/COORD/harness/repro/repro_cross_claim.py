#!/usr/bin/env python3
"""A submission whose body describes another field than its claim (another client's claim id, or another field's
body) must be refused; so must a claim id that is not an integer."""
import os
from common import *
d = workdir("cross"); st = os.path.join(d, "state")
f1, f2, f3 = field(1), field(2), field(3, base=65, coord="midout:4,9,6")
wl = worklist(d, [f1, f2, f3])
p, port, _ = start(wl, st)
c1, c2, c3 = claim(port), claim(port), claim(port)
r1 = req(port, "POST", "/submit", body(c1["claim_id"], f2))          # field 2's body under field 1's claim
r2 = req(port, "POST", "/submit", body(str(c2["claim_id"]), f2))     # claim id as a string
r3 = req(port, "POST", "/submit", body(c3["claim_id"], dict(f3, coordinate="midout:4,8,5")))  # other coordinate
kill(p)
verdict(200 in (r1[0], r2[0], r3[0]), "other field's body: %s; string claim id: %s; other coordinate: %s"
        % (r1[0], r2[0], r3[0]))
