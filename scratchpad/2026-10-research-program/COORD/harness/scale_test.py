#!/usr/bin/env python3
"""The coordinator at the size of base 64: a work list of 262,144 fields and a state of K accepted fields (written
directly in the coordinator's record format, with a body of a real submission's size). Measures the start time, the
peak memory, and the latency of claims, submissions and /status; runs the audit tool on it.

usage: scale_test.py SCRIPT AUDIT K   (state under $COORD_SCRATCH; deleted at the end)
"""
import os, shutil, subprocess, sys, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "repro"))
from common import *  # noqa: E402

script, audit, K = sys.argv[1], sys.argv[2], int(sys.argv[3])
d = workdir("scale")
st = os.path.join(d, "state")
os.makedirs(st)
fl = [field(t) for t in range(262144)]
wl = worklist(d, fl)
t0 = time.time()
with open(os.path.join(st, "claims.jsonl"), "w") as c, open(os.path.join(st, "submissions.jsonl"), "w") as s:
    for i in range(K):
        cid = 1000 + i
        c.write(json.dumps({"claim_id": cid, "field": i, "time": 1.7e9 + i, "work": fl[i]}) + "\n")
        b = body(cid, fl[i])
        b["telemetry"]["pad"] = "x" * 900  # a real submission's body is about 1.5 kB
        s.write(json.dumps({"recv": 1.7e9 + i + 30, "claim_id": cid, "field": i, "claim_time": 1.7e9 + i,
                            "accepted": True, "reason": None, "work": fl[i], "submission": b}) + "\n")
sizes = {f: os.path.getsize(os.path.join(st, f)) for f in ("claims.jsonl", "submissions.jsonl")}
print("state written: %d accepted fields, claims %.1f MB, submissions %.1f MB, work list %.1f MB (%.1f s)"
      % (K, sizes["claims.jsonl"] / 1e6, sizes["submissions.jsonl"] / 1e6, os.path.getsize(wl) / 1e6, time.time() - t0))
import common  # noqa: E402
common.SCRIPT = script
t0 = time.time()
p, port, s = start(wl, st)
for _ in range(3000):
    if s == "up":
        break
    time.sleep(0.05)
    if req(port, "GET", "/status", timeout=0.5)[0] == 200:
        s = "up"
t_start = time.time() - t0
hwm = [l for l in open("/proc/%d/status" % p.pid) if l.startswith("VmHWM")][0].split()[1]
print("start: %s in %.1f s, peak memory %.0f MB" % (s, t_start, int(hwm) / 1024))
lat_c, lat_s = [], []
for _ in range(20):
    t = time.time(); c = claim(port); lat_c.append(time.time() - t)
    t = time.time(); r = req(port, "POST", "/submit", body(c["claim_id"], fl[(c["range_start"] - START) // Q])); lat_s.append(time.time() - t)
    assert r[0] == 200, r
t = time.time(); stt = req(port, "GET", "/status"); t_st = time.time() - t
print("claim latency max %.1f ms, submit max %.1f ms, /status %.1f ms: %s"
      % (1e3 * max(lat_c), 1e3 * max(lat_s), 1e3 * t_st, stt[1]))
kill(p)
t = time.time()
a = subprocess.run([sys.executable, audit, "--worklist", wl, "--state", st, "--quiet"], capture_output=True, text=True)
print("audit: rc %d in %.1f s: %s" % (a.returncode, time.time() - t, a.stdout.strip().splitlines()[-1]))
cleanup()
shutil.rmtree(d)
