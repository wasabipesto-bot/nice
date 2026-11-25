#!/usr/bin/env python3
"""Two coordinators started on one state directory by mistake: the second must refuse to start."""
import os
from common import *
d = workdir("two"); st = os.path.join(d, "state")
wl = worklist(d, [field(1), field(2)])
pa, porta, _ = start(wl, st); pb, portb, sb = start(wl, st)
if sb != "up":
    verdict(False, "the second coordinator refused to start (%s)" % pb.stderr.read().decode().strip()[-120:])
ca, cb = claim(porta), claim(portb)
verdict(True, "both up; A handed claim %s on t=%d, B handed claim %s on t=%d"
        % (ca["claim_id"], t_of(ca), cb["claim_id"], t_of(cb)))
