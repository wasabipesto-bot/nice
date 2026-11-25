#!/usr/bin/env python3
"""A full disk (here RLIMIT_FSIZE 400 bytes, so the submission record cannot be written): the coordinator must not
say 'recorded', must not count the field as done in memory, and must leave no partial line; after a restart with
room the same submission must be accepted."""
import os, resource
from common import *
d = workdir("efbig"); st = os.path.join(d, "state")
wl = worklist(d, [field(1)])
lim = lambda: resource.setrlimit(resource.RLIMIT_FSIZE, (400, 400))
p, port, s = start(wl, st, preexec=lim)
c = claim(port)
r = req(port, "POST", SUBMIT, body(c["claim_id"], field(1)))
stt = req(port, "GET", "/status")
kill(p)
subs = os.path.join(st, "submissions.jsonl")
partial = os.path.exists(subs) and os.path.getsize(subs) > 0 and r[0] != 200
p, port, s2 = start(wl, st)
r2 = req(port, "POST", SUBMIT, body(c["claim_id"], field(1))) if s2 == "up" else ("-", "")
kill(p)
bad = r[0] == 200 or '"searched": 1' in stt[1] or partial or s2 != "up" or r2[0] != 200
verdict(bad, "full disk: submit %s, status %s, partial line left %s; after restart (%s) resubmit %s"
        % (r[0], stt[1], partial, s2, r2[0]))
