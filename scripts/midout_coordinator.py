#!/usr/bin/env python3
"""A local coordinator for the middle-out route (development; standard library only; 127.0.0.1 only).

Serves fields of the middle-out coordinate in production's claim/submit wire format with one addition
(common/src/midout/wire.rs):

  GET  /claim/niceonly?coordinate=midout  -> 200 {"claim_id","base","range_start","range_end","range_size",
                                                  "coordinate":"midout:K0,K1,Q0"}  (range_* in v), or 204: none left
  POST /submit                            -> production's DataToServer; recorded as one JSON line
  GET  /status                            -> counts

Every other path is 404, so an ordinary client pointed here gets no work. `--legacy-path` (a test switch)
instead hands the same marked fields to /claim/niceonly and /claim/detailed, to show that the client's ordinary
routes refuse them.

The work list (`common/examples/midout_fields.rs` makes one) is a JSON list of
{"base","coordinate","range_start","range_end","range_size"}: the coordinate is a parameter of each field (an id
`midout:K0,K1,Q0` naming the coordinate's digit positions), handed to the client as it stands; this script knows
nothing of what it means (the client builds its coordinate from it and refuses one it does not know). `--coordinate ID`
(optional) refuses to start unless every field of the work list is in that coordinate. State lives in DIR: claims.jsonl (every claim issued) and
submissions.jsonl (every submission, accepted or not, with the field, the claim time, the receive time and the
whole body). A field is never handed out twice, across restarts too, unless --reissue-after SECONDS is given
(then a claim older than that without an accepted submission is handed out again). A submission is accepted
once per field, only for a claim this coordinator issued (an integer claim_id), only with telemetry pipeline.route
"midout", and only if telemetry pipeline names the claim's own field (coordinate; field.base, v_start, v_size,
range_size), as the client's route reports it.

usage: midout_coordinator.py --worklist W.json --state DIR [--port 8470] [--reissue-after S] [--legacy-path] [--coordinate ID]
"""
import argparse, fcntl, json, os, sys, threading, time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlsplit, parse_qs

ROUTE, COORD = "midout", "midout"

ap = argparse.ArgumentParser()
ap.add_argument("--worklist", required=True)
ap.add_argument("--state", required=True)
ap.add_argument("--port", type=int, default=8470)
ap.add_argument("--reissue-after", type=float, default=None)
ap.add_argument("--legacy-path", action="store_true")
ap.add_argument("--coordinate", default=None)
a = ap.parse_args()

fields = json.load(open(a.worklist))
for i, f in enumerate(fields):
    for k in ("base", "range_start", "range_end", "range_size"):
        if not isinstance(f.get(k), int) or f[k] < 0:
            sys.exit(f"work list entry {i}: bad {k}: {f.get(k)!r}")
    if f["range_end"] <= f["range_start"]:
        sys.exit(f"work list entry {i}: empty")
    c = f.get("coordinate")
    if not isinstance(c, str) or not c.startswith(COORD + ":"):
        sys.exit(f"work list entry {i}: coordinate {c!r} is not a middle-out coordinate id (midout:K0,K1,Q0)")
    if a.coordinate is not None and c != a.coordinate:
        sys.exit(f"work list entry {i}: coordinate {c!r}, not {a.coordinate!r}")
os.makedirs(a.state, exist_ok=True)
# one coordinator per state directory: the lock is held for the process's life (the kernel drops it when it dies)
lock_file = open(os.path.join(a.state, "lock"), "a")
try:
    fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    sys.exit("%s is in use by another coordinator (%s/lock is held): refusing to start" % (a.state, a.state))
claims_path = os.path.join(a.state, "claims.jsonl")
subs_path = os.path.join(a.state, "submissions.jsonl")
lock = threading.Lock()
claims = {}  # claim_id -> {"field": index, "time": t}
last_claim = {}  # field index -> (claim_id, time) of its latest claim
done = {}  # field index -> claim_id of the accepted submission
next_id = 1000


def load(path):
    """The records of a state file. A last line without its newline is a write cut short (a kill, a full disk): it
    was never acknowledged, so it is cut off, and the next record starts on a line of its own. Any other line that
    does not read stops the coordinator."""
    if not os.path.exists(path):
        return []
    data = open(path, "rb").read()
    whole = data.rfind(b"\n") + 1
    if whole < len(data):
        sys.stderr.write("coordinator: %s: cutting off a torn last line (%d bytes, never acknowledged)\n"
                         % (path, len(data) - whole))
        with open(path, "r+b") as o:
            o.truncate(whole)
            o.flush()
            os.fsync(o.fileno())
    recs = []
    for n, line in enumerate(data[:whole].splitlines(), 1):
        try:
            recs.append(json.loads(line))
        except ValueError as e:
            sys.exit("%s line %d does not read (%s): refusing to start" % (path, n, e))
    return recs


broken = None  # set when a failed write could not be undone: nothing more is written until a restart


def append(path, rec):
    """Append one record and make it durable (flush + fsync) before anyone is told. On failure (a full disk) the
    file is cut back to where it was and the error returned, so memory and disk stay equal; None on success."""
    global broken
    if broken:
        return broken
    b = (json.dumps(rec) + "\n").encode()
    fd = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o644)
    try:
        size = os.fstat(fd).st_size
        try:
            done_b = 0
            while done_b < len(b):
                done_b += os.write(fd, b[done_b:])
            os.fsync(fd)
            return None
        except OSError as e:
            try:
                os.ftruncate(fd, size)
                os.fsync(fd)
            except OSError as e2:
                broken = "a failed write to %s could not be undone (%s): restart the coordinator" % (path, e2)
            return "%s: %s" % (path, e)
    finally:
        os.close(fd)


# resume
for c in load(claims_path):
    claims[c["claim_id"]] = c
    last_claim[c["field"]] = (c["claim_id"], c["time"])
    next_id = max(next_id, c["claim_id"] + 1)
for s in load(subs_path):
    if s.get("accepted"):
        done[s["field"]] = s["claim_id"]
for path in (claims_path, subs_path):
    if not os.path.exists(path):
        open(path, "a").close()
dfd = os.open(a.state, os.O_RDONLY)
os.fsync(dfd)  # the files' directory entries
os.close(dfd)
sys.stderr.write("coordinator: %d fields, %d claimed, %d done (resumed), port %d, reissue_after %s, legacy_path %s\n"
                 % (len(fields), len(last_claim), len(done), a.port, a.reissue_after, a.legacy_path))


def mismatch(d, f):
    """Why a submission's body does not describe field f, or None if it does: the client reports the field it
    searched in telemetry.pipeline (coordinate; field.base, v_start, v_size, range_size, as numbers or decimal
    strings), and a body for another field must not be recorded under this field's claim."""
    def num(x):
        return x if type(x) is int else int(x) if isinstance(x, str) and x.isdigit() else None
    tel = d.get("telemetry")
    pl = tel.get("pipeline") if isinstance(tel, dict) else None
    fd = pl.get("field") if isinstance(pl, dict) else None
    if not isinstance(fd, dict):
        return "telemetry pipeline.field is missing"
    want = {"coordinate": f["coordinate"], "base": f["base"], "v_start": f["range_start"],
            "v_size": f["range_end"] - f["range_start"], "range_size": f["range_size"]}
    got = {"coordinate": pl.get("coordinate"), "base": num(fd.get("base")), "v_start": num(fd.get("v_start")),
           "v_size": num(fd.get("v_size")), "range_size": num(fd.get("range_size"))}
    bad = ["%s %r (the claim's field: %r)" % (k, got[k], want[k]) for k in want if got[k] != want[k]]
    return "the submission describes another field: " + ", ".join(bad) if bad else None


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
            c = {"claim_id": cid, "field": i, "time": now}
            err = append(claims_path, c)
            if err:
                return self._send(503, "claim not recorded: %s" % err)
            next_id += 1
            claims[cid] = c
            last_claim[i] = (cid, now)
        f = fields[i]
        self._send(200, {"claim_id": cid, "base": f["base"], "range_start": f["range_start"],
                         "range_end": f["range_end"], "range_size": f["range_size"], "coordinate": f["coordinate"]})

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
            cid = d["claim_id"]
            if type(cid) is not int:
                raise ValueError("claim_id %r is not an integer" % (cid,))
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
            elif mismatch(d, fields[c["field"]]):
                reason, code = mismatch(d, fields[c["field"]]), 422
            else:
                code = 200
            rec = {"recv": recv, "claim_id": cid, "field": None if c is None else c["field"],
                   "claim_time": None if c is None else c["time"], "accepted": reason is None, "reason": reason,
                   "work": None if c is None else fields[c["field"]], "submission": d}
            err = append(subs_path, rec)
            if err:
                return self._send(503, "submission not recorded: %s" % err)
            if reason is None:
                done[c["field"]] = cid
        self._send(code, "recorded" if reason is None else "rejected: " + reason)


ThreadingHTTPServer(("127.0.0.1", a.port), H).serve_forever()
