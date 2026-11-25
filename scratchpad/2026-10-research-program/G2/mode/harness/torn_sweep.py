#!/usr/bin/env python3
"""Truncate each state file at every byte offset of its last record and restart the coordinator on it.

usage: torn_sweep.py [SCRIPT] [--audit PATH]   (state under $COORD_SCRATCH)

The state: three fields, three claims, field 0 accepted, field 1 accepted (the last record of submissions.jsonl).
For every cut in [start of the last record, end of file) of claims.jsonl and of submissions.jsonl (a write cut short
at any byte, or a full disk): the coordinator must start, its /status must be the state without that record (it
was never acknowledged), a new claim must be recorded after it, and a second restart must read the file again. With
--audit, the audit tool must read the truncated state (exit 1: incomplete, never 2: unreadable).
Exit 1 on the first offset that fails (printed), 0 if every offset passes.
"""
import os, shutil, subprocess, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "repro"))
audit = None
if "--audit" in sys.argv:
    k = sys.argv.index("--audit")
    audit = sys.argv[k + 1]
    del sys.argv[k:k + 2]
from common import *  # noqa: E402

d = workdir("sweep")
base = os.path.join(d, "base")
fl = [field(1), field(2), field(3), field(4)]
wl = worklist(d, fl)
p, port, s = start(wl, base)
cs = [claim(port) for _ in range(3)]
for c, f in zip(cs[:2], fl[:2]):
    assert req(port, "POST", SUBMIT, body(c["claim_id"], f))[0] == 200
kill(p)
fails, n = [], 0
for fn, want in (("claims.jsonl", {"claimed": 2, "searched": 2}), ("submissions.jsonl", {"claimed": 3, "searched": 1})):
    data = open(os.path.join(base, fn), "rb").read()
    s0 = data.rstrip(b"\n").rfind(b"\n") + 1
    for cut in range(s0, len(data)):
        n += 1
        st = os.path.join(d, "cut")
        shutil.rmtree(st, ignore_errors=True)
        shutil.copytree(base, st)
        with open(os.path.join(st, fn), "r+b") as f:
            f.truncate(cut)
        if audit:
            a = subprocess.run([sys.executable, audit, "--worklist", wl, "--state", st, "--quiet"], capture_output=True)
            if a.returncode != 1:
                fails.append("%s cut at %d: audit exit %d" % (fn, cut, a.returncode))
        p, port, s = start(wl, st)
        if s != "up":
            fails.append("%s cut at %d of %d: coordinator %s: %s" % (fn, cut, len(data), s,
                                                                    p.stderr.read().decode()[-160:].strip()))
            kill(p)
            break
        stt = json.loads(req(port, "GET", "/status")[1])
        if {k: stt[k] for k in want} != want:
            fails.append("%s cut at %d: status %s, want %s" % (fn, cut, stt, want))
        c = claim(port)
        kill(p)
        p, port, s = start(wl, st)
        stt2 = json.loads(req(port, "GET", "/status")[1]) if s == "up" else None
        kill(p)
        if s != "up" or c is None or stt2["claimed"] != stt["claimed"] + 1:
            fails.append("%s cut at %d: after one more claim (%s) the second restart gave %s %s" % (fn, cut, c, s, stt2))
        if fails:
            break
cleanup()
print("%d offsets tried; %s" % (n, "every one passed" if not fails else "FAILED: " + fails[0]))
sys.exit(1 if fails else 0)
