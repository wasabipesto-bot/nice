#!/usr/bin/env python3
"""A local coordinator for the middle-out route (development; standard library only; 127.0.0.1 only).

Serves fields of the middle-out coordinate in production's claim/submit wire format with one addition
(common/src/midout/wire.rs):

  GET  /claim/niceonly?coordinate=midout  -> 200 {"claim_id","base","range_start","range_end","range_size",
                                                  "coordinate":"midout"}  (range_* in v), or 204: none left
  POST /submit                            -> production's DataToServer; recorded as one JSON line
  GET  /status                            -> counts

Every other path is 404, so an ordinary client pointed here gets no work. `--legacy-path` (a test switch)
instead hands the same marked fields to /claim/niceonly and /claim/detailed, to show that the client's ordinary
routes refuse them.

The work list (`common/examples/midout_fields.rs` makes one) is a JSON list of
{"base","range_start","range_end","range_size"}. State lives in DIR: claims.jsonl (every claim issued) and
submissions.jsonl (every submission, accepted or not, with the field, the claim time, the receive time and the
whole body). A field is never handed out twice, across restarts too, unless --reissue-after SECONDS is given
(then a claim older than that without an accepted submission is handed out again). A submission is accepted
once per field, only for a claim this coordinator issued, and only with telemetry pipeline.route "midout".

usage: midout_coordinator.py --worklist W.json --state DIR [--port 8470] [--reissue-after S] [--legacy-path]
"""
import argparse, json, os, sys, threading, time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlsplit, parse_qs

ROUTE, COORD = "midout", "midout"

ap = argparse.ArgumentParser()
ap.add_argument("--worklist", required=True)
ap.add_argument("--state", required=True)
ap.add_argument("--port", type=int, default=8470)
ap.add_argument("--reissue-after", type=float, default=None)
ap.add_argument("--legacy-path", action="store_true")
a = ap.parse_args()

fields = json.load(open(a.worklist))
for i, f in enumerate(fields):
    for k in ("base", "range_start", "range_end", "range_size"):
        if not isinstance(f.get(k), int) or f[k] < 0:
            sys.exit(f"work list entry {i}: bad {k}: {f.get(k)!r}")
    if f["range_end"] <= f["range_start"]:
        sys.exit(f"work list entry {i}: empty")
os.makedirs(a.state, exist_ok=True)
claims_path = os.path.join(a.state, "claims.jsonl")
subs_path = os.path.join(a.state, "submissions.jsonl")
lock = threading.Lock()
claims = {}  # claim_id -> {"field": index, "time": t}
last_claim = {}  # field index -> (claim_id, time) of its latest claim
done = {}  # field index -> claim_id of the accepted submission
next_id = 1000
# resume
if os.path.exists(claims_path):
    for line in open(claims_path):
        c = json.loads(line)
        claims[c["claim_id"]] = c
        last_claim[c["field"]] = (c["claim_id"], c["time"])
        next_id = max(next_id, c["claim_id"] + 1)
if os.path.exists(subs_path):
    for line in open(subs_path):
        s = json.loads(line)
        if s.get("accepted"):
            done[s["field"]] = s["claim_id"]
sys.stderr.write("coordinator: %d fields, %d claimed, %d done (resumed), port %d, reissue_after %s, legacy_path %s\n"
                 % (len(fields), len(last_claim), len(done), a.port, a.reissue_after, a.legacy_path))


def next_field(now):
    for i in range(len(fields)):
        if i in done:
            continue
        lc = last_claim.get(i)
        if lc is None or (a.reissue_after is not None and now - lc[1] >= a.reissue_after):
            return i
    return None


class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write("coordinator: %.3f %s\n" % (time.time(), fmt % args))

    def _send(self, code, obj=None):
        b = b"" if obj is None else json.dumps(obj).encode()
        self.send_response(code)
        if obj is not None:
            self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def _claim(self):
        global next_id
        now = time.time()
        with lock:
            i = next_field(now)
            if i is None:
                return self._send(204)
            cid = next_id
            next_id += 1
            c = {"claim_id": cid, "field": i, "time": now}
            claims[cid] = c
            last_claim[i] = (cid, now)
            with open(claims_path, "a") as o:
                o.write(json.dumps(c) + "\n")
        f = fields[i]
        self._send(200, {"claim_id": cid, "base": f["base"], "range_start": f["range_start"],
                         "range_end": f["range_end"], "range_size": f["range_size"], "coordinate": COORD})

    def do_GET(self):
        u = urlsplit(self.path)
        q = parse_qs(u.query)
        path = u.path.rstrip("/")
        if path == "/claim/niceonly" and q.get("coordinate") == [COORD]:
            return self._claim()
        if a.legacy_path and path in ("/claim/niceonly", "/claim/detailed"):
            return self._claim()
        if path == "/status":
            with lock:
                return self._send(200, {"fields": len(fields), "claimed": len(last_claim), "done": len(done)})
        self._send(404, "this coordinator serves only middle-out fields: GET /claim/niceonly?coordinate=midout")

    def do_POST(self):
        recv = time.time()
        if urlsplit(self.path).path.rstrip("/") != "/submit":
            return self._send(404, "not found")
        raw = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try:
            d = json.loads(raw)
            cid = int(d["claim_id"])
        except Exception as e:  # noqa: BLE001 (record anything malformed as rejected)
            return self._send(400, "malformed submission: %s" % e)
        with lock:
            c = claims.get(cid)
            route = (((d.get("telemetry") or {}).get("pipeline") or {}).get("route"))
            reason = None
            if c is None:
                reason, code = "unknown claim", 404
            elif c["field"] in done:
                reason, code = "field already submitted (claim %d)" % done[c["field"]], 409
            elif route != ROUTE:
                reason, code = "telemetry pipeline.route is %r, not %r" % (route, ROUTE), 422
            else:
                code = 200
                done[c["field"]] = cid
            rec = {"recv": recv, "claim_id": cid, "field": None if c is None else c["field"],
                   "claim_time": None if c is None else c["time"], "accepted": reason is None, "reason": reason,
                   "work": None if c is None else fields[c["field"]], "submission": d}
            with open(subs_path, "a") as o:
                o.write(json.dumps(rec) + "\n")
        self._send(code, "recorded" if reason is None else "rejected: " + reason)


ThreadingHTTPServer(("127.0.0.1", a.port), H).serve_forever()
