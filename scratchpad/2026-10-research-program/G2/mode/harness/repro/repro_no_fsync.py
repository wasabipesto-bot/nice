#!/usr/bin/env python3
"""An acknowledged claim or submission must be fsynced before the reply (a power loss keeps only fsynced bytes).
Run under trace_wrap.py, which records the fsynced size of each state file; compare it with the size at the reply."""
import os, sys
from common import *
wrap = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "trace_wrap.py")
d = workdir("fsync"); st = os.path.join(d, "state"); tr = os.path.join(d, "trace"); os.makedirs(tr)
wl = worklist(d, [field(1)])
p, port, s = start(wl, st, wrap=wrap, env=dict(os.environ, COORD_TRACE_DIR=tr))
def durable(fn):
    try: return int(open(os.path.join(tr, fn + ".durable")).read().split()[0])
    except OSError: return 0
c = claim(port)
a = (durable("claims.jsonl"), os.path.getsize(os.path.join(st, "claims.jsonl")))
r = req(port, "POST", SUBMIT, body(c["claim_id"], field(1)))
b = (durable("submissions.jsonl"), os.path.getsize(os.path.join(st, "submissions.jsonl")))
kill(p)
verdict(a[0] < a[1] or b[0] < b[1] or r[0] != 200,
        "after the replies: claims %d of %d bytes durable, submissions %d of %d (submit %s)" % (a + b + (r[0],)))
