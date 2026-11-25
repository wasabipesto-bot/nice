#!/usr/bin/env python3
"""(2026-11-25) A complete record written just before a kill but never fsynced is read at the next start like any
other, and the midout wire then acknowledges it: a resubmission of it is answered "already_recorded". It must be made
durable before the restart serves anything, or a power loss after that reply loses an acknowledged record.
Run under trace_wrap.py: a submission is recorded, the kill is modelled by marking its bytes not durable, the server
restarts, the client resubmits; after the reply every byte of submissions.jsonl must be durable."""
import os
from common import *
wrap = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "trace_wrap.py")
d = workdir("unsynced"); st = os.path.join(d, "state"); tr = os.path.join(d, "trace"); os.makedirs(tr)
f1 = field(1); wl = worklist(d, [f1])
env = dict(os.environ, COORD_TRACE_DIR=tr)
p, port, s = start(wl, st, wrap=wrap, env=env)
c = claim(port)
r1 = req(port, "POST", SUBMIT, body(c["claim_id"], f1))
kill(p)
subs = os.path.join(st, "submissions.jsonl")
# the kill came between the write and its fsync: only what was there before the record is durable
open(os.path.join(tr, "submissions.jsonl.durable"), "w").write("0\n".ljust(24))
p, port, s = start(wl, st, wrap=wrap, env=env)
r2 = req(port, "POST", SUBMIT, body(c["claim_id"], f1))
dur = int(open(os.path.join(tr, "submissions.jsonl.durable")).read().split()[0])
size = os.path.getsize(subs)
kill(p)
verdict(r2[0] == 200 and dur < size, "first reply %s; after the restart the resubmission got %s %s with %d of %d bytes "
        "durable" % (r1[0], r2[0], r2[1][:60], dur, size))
