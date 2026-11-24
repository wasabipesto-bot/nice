#!/usr/bin/env python3
"""The disk fills while the coordinator runs, and its log (stderr to a file on the same disk) can no longer grow,
though the state files still can (here: RLIMIT_FSIZE set on the running process to the log's size). A claim and a
submission that were recorded on disk must still be answered."""
import os, resource, subprocess
from common import *
d = workdir("logfull"); st = os.path.join(d, "state")
f1 = field(1); wl = worklist(d, [f1])
logp = os.path.join(d, "coord.log"); log = open(logp, "wb")
port = free_port()
p = subprocess.Popen([sys.executable, SCRIPT, "--worklist", wl, "--state", st, "--port", str(port)], stdout=log, stderr=log)
PIDS.append(p.pid)
for _ in range(200):
    if req(port, "GET", "/status", timeout=0.3)[0] == 200: break
    time.sleep(0.02)
for _ in range(30): req(port, "GET", "/status")       # grow the log past the state files
lim = os.path.getsize(logp)
resource.prlimit(p.pid, resource.RLIMIT_FSIZE, (lim, lim))
r1 = req(port, "GET", "/claim/niceonly?coordinate=midout")
claimed = os.path.getsize(os.path.join(st, "claims.jsonl")) > 0
cid = None
try: cid = json.loads(open(os.path.join(st, "claims.jsonl")).readline())["claim_id"]
except Exception: pass
r2 = req(port, "POST", "/submit", body(cid, f1)) if cid else ("-", "")
subs = open(os.path.join(st, "submissions.jsonl")).read() if os.path.exists(os.path.join(st, "submissions.jsonl")) else ""
kill(p)
verdict(r1[0] != 200 or (cid and '"accepted": true' in subs and r2[0] != 200),
        "log full (limit %d): claim %s (on disk: %s), submit %s (accepted on disk: %s)"
        % (lim, r1[0], claimed, r2[0], '"accepted": true' in subs))
