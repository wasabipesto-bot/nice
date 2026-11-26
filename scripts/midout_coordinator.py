#!/usr/bin/env python3
"""A development server for the midout mode (`nice_client midout`): standard library only, 127.0.0.1 only.

A DEVELOPMENT TOOL, not the API: it serves the two endpoints the server proposal for the middle-out mode gives the
API (common/src/midout/wire.rs names them), from a work list and a state directory instead of a database, so that the
mode can be run and tested end to end on one machine. Nothing in production calls it or reads its state.

  GET  /claim/midout   -> 200 {"claim_id","base","coordinate","range_start","range_end","range_size"} (range_* in v,
                          range_size = the n the field holds; JSON numbers), 204 nothing claimable, 503 a claim that
                          could not be recorded
  POST /submit/midout  -> the typed submission (wire::Submission: claim_id, username, client_version,
                          field {base, coordinate, v_start, v_size, range_size}, nice_numbers, shape, survivors,
                          checked, slices, telemetry; big integers as decimal strings); 200
                          {"submission_id": N, "status": "canon" | "check" | "already_recorded"}, or 4xx/503 with a
                          reason
  GET  /status         -> counts

Every other path is 404, so a client in another mode pointed here gets no work. `--legacy-path` (a test switch)
instead hands the same marked fields to /claim/niceonly and /claim/detailed, to show that the client's other modes
refuse them.

A submission passes these checks in order (the proposal's eight; the first failing one answers):
  1. it parses, claim_id is an integer, every key has its type, the body is at most 1 MiB (413) and its telemetry at
     most 16 KiB (413, refused, not dropped)                                                    -> 400 / 413
  2. claim_id is a claim this server issued                                                     -> 404
  3. field equals the claim's field (base, coordinate, v_start, v_size, range_size)            -> 422
  4. each nice number is in the field and is nice                                               -> 422
  5. shape is "F0,K" and can search the field, and slices = the field's slice count under it   -> 422
  6. the same claim submitted before: the same result -> 200 "already_recorded" with the stored id; another -> 409
  7. a field not searched yet -> 200 "canon" (also when its claim has expired)
  8. a field searched before -> 200 "check", compared with the canon (the same nice numbers, and the same counters if
     the same shape); an agreeing check marks the field checked twice
"The same result" (6) is everything but the telemetry: field, numbers, shape, counters, username, client_version.

Claims expire after --claim-duration seconds (default 3600, the API's hour): a field that is not searched yet is then
handed out again. A field is handed out once at a time otherwise, across restarts too.

The work list (`common/examples/midout_fields.rs` makes one) is a JSON list of
{"base","coordinate","range_start","range_end","range_size"}: the coordinate (an id `midout:K0,K1,Q0` naming its
digit positions) is a parameter of each field. At start every field is checked with this script's port of
`common/src/midout/coord.rs`: whole quanta of its coordinate, inside it, and `range_size` equal to the n it holds (so a
start is also a test of the port against the Rust that cut the list). `--coordinate ID` (optional) refuses to start
unless every field is in that coordinate. Overlapping fields are refused.

State lives in DIR: claims.jsonl (every claim issued) and submissions.jsonl (every submission answered with a
status, accepted or refused; a resubmission answered "already_recorded" is not written again), one JSON line each,
made durable before the reply. Every record names its field by index and by value, and a start whose work list no
longer has that field at that index is refused (fields may be appended). One coordinator per state directory (a lock
file). `scripts/midout_audit.py` checks a state directory against its work list.

Test switches: --drop-replies N closes the connection without a reply after each of the first N accepted
submissions has been recorded (a lost reply: the client must resubmit and get "already_recorded").

usage: midout_coordinator.py --worklist W.json --state DIR [--port 8470] [--claim-duration S] [--coordinate ID]
                             [--legacy-path] [--drop-replies N]
"""
import argparse, fcntl, json, os, re, sys, threading, time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlsplit

ROUTE = "midout"
MAX_BODY = 1 << 20  # a submission is about 1.5 kB
MAX_TELEMETRY = 16 * 1024  # wire::TELEMETRY_MAX_BYTES, serialized compactly


# ---------------------------------------------------------------- the coordinate (a port of coord.rs and cpu::Shape)

def iroot_ceil(x, k):
    """The least r >= 0 with r**k >= x (integers only)."""
    lo, hi = 0, 1 << (x.bit_length() // k + 1)
    while lo < hi:
        mid = (lo + hi) // 2
        if mid ** k >= x:
            hi = mid
        else:
            lo = mid + 1
    return lo


def base_range(b):
    """[start, end) of the n whose square and cube together have b digits (base_range.rs), or None."""
    k = b // 5
    m = b % 5
    if m == 0:
        return iroot_ceil(b ** (3 * k - 1), 3), b ** k
    if m == 2:
        return b ** k, iroot_ceil(b ** (3 * k + 1), 3)
    if m == 3:
        return iroot_ceil(b ** (3 * k + 1), 3), iroot_ceil(b ** (2 * k + 1), 2)
    if m == 4:
        return iroot_ceil(b ** (2 * k + 1), 2), iroot_ceil(b ** (3 * k + 2), 3)
    return None


def ndigits(x, b):
    n = 0
    while x > 0:
        x //= b
        n += 1
    return n


class Coord:
    """coord.rs's Coord::with_digits: v = start + key*(H*b^k0) + (h - h0)*b^k0 + low."""

    def __init__(self, b, k0, k1, q0):
        if not 3 <= b <= 128:
            raise ValueError("base %d outside 3-128" % b)
        r = base_range(b)
        if r is None:
            raise ValueError("base %d has no range" % b)
        self.b, (self.start, self.end) = b, r
        self.l = ndigits(self.end - 1, b)
        if not (k0 <= q0 < k1 <= self.l):
            raise ValueError("digit positions k0 %d <= q0 %d < k1 %d <= %d fail at base %d" % (k0, q0, k1, self.l, b))
        self.k0, self.k1, self.q0 = k0, k1, q0
        bk1 = b ** k1
        self.h0 = self.start // bk1
        self.hn = (self.end - 1) // bk1 - self.h0 + 1
        if self.start + self.hn * bk1 >= 1 << 128:
            raise ValueError("v overflows u128 at base %d" % b)

    def v_end(self):
        return self.start + self.hn * self.b ** self.k1

    def quantum(self):
        return self.hn * self.b ** self.q0

    def field_digits(self, v_start, v_size):
        """[t0, t1): the values of digits [q0, k1) of the field's n; ValueError if not whole quanta inside v."""
        q = self.quantum()
        if v_size <= 0:
            raise ValueError("empty field")
        if not (v_start >= self.start and v_start + v_size <= self.v_end()):
            raise ValueError("field outside the coordinate")
        if (v_start - self.start) % q or v_size % q:
            raise ValueError("field is not whole quanta of %d" % q)
        t0 = (v_start - self.start) // q
        return t0, t0 + v_size // q

    def n_count(self, v_start, v_size):
        """The n of the range the field holds (v_size less the padding): for one t and one h the n are the block
        [h*b^k1 + t*b^q0, + b^q0), full for every h but the first and the last, which are clipped to the range."""
        t0, t1 = self.field_digits(v_start, v_size)
        per_t, bk1 = self.b ** self.q0, self.b ** self.k1
        ends = [self.h0] + ([self.h0 + self.hn - 1] if self.hn > 1 else [])
        total = 0
        for t in range(t0, t1):
            total += max(self.hn - 2, 0) * per_t
            for h in ends:
                lo = h * bk1 + t * per_t
                total += max(min(lo + per_t, self.end) - max(lo, self.start), 0)
        return total

    def contains(self, n, v_start, v_size):
        """Whether n is one of the field's n: in the range, with digits [q0, k1) in [t0, t1)."""
        t0, t1 = self.field_digits(v_start, v_size)
        t = (n // self.b ** self.q0) % self.b ** (self.k1 - self.q0)
        return self.start <= n < self.end and t0 <= t < t1


def default_shape(c):
    """cpu::Shape::for_coord: (4, 10) for (4, 8, 5), else (k0, k1 + 1)."""
    return (4, 10) if (c.k0, c.k1, c.q0) == (4, 8, 5) else (c.k0, c.k1 + 1)


def slice_count(c, shape, v_start, v_size):
    """The slices of a field under shape (f0, k) (cpu::Shape::fits, slices_of); ValueError if it cannot search it."""
    f0, k = shape
    if not (f0 <= c.q0 and c.k1 < k <= c.l):
        raise ValueError("shape %d,%d cannot search fields fixing digits [%d, %d) of %d-digit n" % (
            f0, k, c.q0, c.k1, c.l))
    t0, t1 = c.field_digits(v_start, v_size)
    return (t1 - t0) * c.b ** (c.q0 - f0) * c.b ** (k - 1 - c.k1)


def is_nice(n, b):
    """n's square and cube together use every digit of base b exactly once."""
    seen = 0
    count = 0
    for x in (n * n, n * n * n):
        while x:
            x, d = divmod(x, b)
            if seen >> d & 1:
                return False
            seen |= 1 << d
            count += 1
    return count == b


COORD_ID = re.compile(r"^midout:(0|[1-9][0-9]*),(0|[1-9][0-9]*),(0|[1-9][0-9]*)$")
DECIMAL = re.compile(r"^(0|[1-9][0-9]*)$")
SHAPE = re.compile(r"^(0|[1-9][0-9]*),(0|[1-9][0-9]*)$")


def coord_of(base, cid):
    m = COORD_ID.match(cid) if isinstance(cid, str) else None
    if not m:
        raise ValueError("coordinate %r is not a middle-out coordinate id (midout:K0,K1,Q0)" % (cid,))
    return Coord(base, *map(int, m.groups()))


# ---------------------------------------------------------------- start

ap = argparse.ArgumentParser(description="A development server for the midout mode (see the header).")
ap.add_argument("--worklist", required=True)
ap.add_argument("--state", required=True)
ap.add_argument("--port", type=int, default=8470)
ap.add_argument("--claim-duration", type=float, default=3600.0,
                help="seconds after which a claim on a field not yet searched expires (default 3600)")
ap.add_argument("--coordinate", default=None)
ap.add_argument("--legacy-path", action="store_true")
ap.add_argument("--drop-replies", type=int, default=0)
a = ap.parse_args()
if a.claim_duration <= 0:
    sys.exit("--claim-duration must be positive")

fields = json.load(open(a.worklist))
coords = []
for i, f in enumerate(fields):
    for k in ("base", "range_start", "range_end", "range_size"):
        if type(f.get(k)) is not int or f[k] < 0:
            sys.exit(f"work list entry {i}: bad {k}: {f.get(k)!r}")
    if f["range_end"] <= f["range_start"]:
        sys.exit(f"work list entry {i}: empty")
    if a.coordinate is not None and f.get("coordinate") != a.coordinate:
        sys.exit(f"work list entry {i}: coordinate {f.get('coordinate')!r}, not {a.coordinate!r}")
    try:
        c = coord_of(f["base"], f.get("coordinate"))
        n = c.n_count(f["range_start"], f["range_end"] - f["range_start"])
    except ValueError as e:
        sys.exit(f"work list entry {i}: {e}")
    if n != f["range_size"]:
        sys.exit(f"work list entry {i}: range_size {f['range_size']}, but the field holds {n} n")
    coords.append(c)
prev = {}
for i in sorted(range(len(fields)), key=lambda i: (fields[i]["base"], fields[i]["coordinate"], fields[i]["range_start"])):
    k = (fields[i]["base"], fields[i]["coordinate"])
    if k in prev and fields[i]["range_start"] < fields[prev[k]]["range_end"]:
        sys.exit("work list entries %d and %d overlap" % (prev[k], i))
    prev[k] = i
os.makedirs(a.state, exist_ok=True)
# the state directory's own entry, in case it was just created
_pfd = os.open(os.path.dirname(os.path.abspath(a.state)), os.O_RDONLY)
os.fsync(_pfd)
os.close(_pfd)
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
level = {}  # field index -> 1 searched once, 2 checked by an agreeing second search
canon = {}  # field index -> the canon's result (see result_of)
by_claim = {}  # claim_id -> (submission_id, result) of its accepted submission
next_id = 1000
next_sub = 1
dropped = 0


def load(path):
    """The records of a state file, read line by line. A last line without its newline is a write cut short (a
    kill, a full disk): it was never acknowledged, so it is cut off, and the next record starts on a line of its own.
    Any other line that does not read stops the coordinator."""
    if not os.path.exists(path):
        return
    whole = 0
    with open(path, "rb") as f:
        for n, line in enumerate(f, 1):
            if not line.endswith(b"\n"):
                break
            try:
                yield json.loads(line)
            except ValueError as e:
                sys.exit("%s line %d does not read (%s): refusing to start" % (path, n, e))
            whole += len(line)
    if whole < os.path.getsize(path):
        sys.stderr.write("coordinator: %s: cutting off a torn last line (%d bytes, never acknowledged)\n"
                         % (path, os.path.getsize(path) - whole))
        with open(path, "r+b") as o:
            o.truncate(whole)
            o.flush()
            os.fsync(o.fileno())


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
        try:
            os.close(fd)
        except OSError:
            pass  # after a good fsync the record is durable whatever close says; after a failed one, that is reported


def same_field(path, n, rec):
    """A record names its field by index and by value: refuse to start unless the work list still has that field at
    that index (a changed work list would make the record mean another field; fields may be appended)."""
    i, w = rec.get("field"), rec.get("work")
    if not isinstance(i, int) or not 0 <= i < len(fields) or w != fields[i]:
        sys.exit("%s line %d names field %r = %s, but the work list has %s there: refusing to start (a record must "
                 "keep meaning its own field)" % (path, n, i, json.dumps(w), json.dumps(fields[i]) if
                                                   isinstance(i, int) and 0 <= i < len(fields) else "nothing"))
    return i


def result_of(d):
    """What a resubmission must repeat: the body without its telemetry."""
    return {k: d[k] for k in ("username", "client_version", "field", "nice_numbers", "shape", "survivors", "checked",
                              "slices")}


def agrees(r, c):
    """A check agrees with the canon: the same nice numbers, and the same counters if the same shape."""
    if r["nice_numbers"] != c["nice_numbers"]:
        return False
    return r["shape"] != c["shape"] or all(r[k] == c[k] for k in ("survivors", "checked", "slices"))


def accept(i, cid, sid, r):
    """Apply an accepted submission to memory; its status."""
    by_claim[cid] = (sid, r)
    if i not in level:
        level[i], canon[i] = 1, r
        return "canon"
    if level[i] == 1 and agrees(r, canon[i]):
        level[i] = 2
    return "check"


# resume
for n, c in enumerate(load(claims_path), 1):
    if c["claim_id"] in claims:
        sys.exit("%s line %d: claim id %d recorded twice: refusing to start" % (claims_path, n, c["claim_id"]))
    claims[c["claim_id"]] = {"field": same_field(claims_path, n, c), "time": c["time"]}
    last_claim[c["field"]] = (c["claim_id"], c["time"])
    next_id = max(next_id, c["claim_id"] + 1)
for n, s in enumerate(load(subs_path), 1):
    if s.get("submission_id") is not None:
        next_sub = max(next_sub, s["submission_id"] + 1)
    if s.get("accepted"):
        i = same_field(subs_path, n, s)
        cid = s["claim_id"]
        if claims.get(cid, {}).get("field") != i or cid in by_claim:
            sys.exit("%s line %d: field %d accepted under claim %d, which is %s: refusing to start" % (
                subs_path, n, i, cid, "accepted before" if cid in by_claim else "not its claim on record"))
        st = accept(i, cid, s["submission_id"], result_of(s["submission"]))
        if st != s.get("status"):
            sys.exit("%s line %d: recorded as %r, but the records before it make it %r: refusing to start" % (
                subs_path, n, s.get("status"), st))
for path in (claims_path, subs_path):
    # what was read is made durable before anything is served: a complete record written just before a kill but not
    # yet fsynced reads like any other, and it is now acknowledged (a resubmission of it is answered
    # "already_recorded", a field it searched is never handed out again), so it must survive a power loss too
    fd = os.open(path, os.O_RDWR | os.O_CREAT, 0o644)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)
dfd = os.open(a.state, os.O_RDONLY)
os.fsync(dfd)  # the files' directory entries
os.close(dfd)
sys.stderr.write("coordinator: %d fields, %d claimed, %d searched (resumed), port %d, claim_duration %s, "
                 "legacy_path %s\n" % (len(fields), len(last_claim), len(level), a.port, a.claim_duration,
                                       a.legacy_path))


def next_field(now):
    for i in range(len(fields)):
        if i in level:
            continue
        lc = last_claim.get(i)
        if lc is None or now - lc[1] >= a.claim_duration:
            return i
    return None


def body_problem(d):
    """Why a parsed body is not a submission (400), or None."""
    if not isinstance(d, dict):
        return "not a JSON object"
    want = {"claim_id": int, "username": str, "client_version": str, "field": dict, "nice_numbers": list,
            "shape": str, "survivors": int, "checked": int, "slices": int}
    for k, t in want.items():
        if k not in d:
            return "%s is missing" % k
        if type(d[k]) is not t:
            return "%s %r is not of type %s" % (k, d[k], t.__name__)
    for k in ("survivors", "checked", "slices"):
        if d[k] < 0:
            return "%s %d is negative" % (k, d[k])
    if d.get("telemetry") is not None and not isinstance(d["telemetry"], dict):
        return "telemetry is not an object"
    f = d["field"]
    if type(f.get("base")) is not int or not isinstance(f.get("coordinate"), str):
        return "field.base must be an integer and field.coordinate a string"
    for k in ("v_start", "v_size", "range_size"):
        if not (isinstance(f.get(k), str) and DECIMAL.match(f[k])):
            return "field.%s %r is not a decimal string" % (k, f.get(k))
    for x in d["nice_numbers"]:
        if not (isinstance(x, str) and DECIMAL.match(x)):
            return "nice number %r is not a decimal string" % (x,)
    return None


def field_problem(d, i):
    """Checks 3-5 against field i: why the body is not a search of it (422), or None."""
    w, c = fields[i], coords[i]
    v_start, v_size = w["range_start"], w["range_end"] - w["range_start"]
    f = d["field"]
    want = {"base": w["base"], "coordinate": w["coordinate"], "v_start": str(v_start), "v_size": str(v_size),
            "range_size": str(w["range_size"])}
    bad = ["%s %r (the claim's: %r)" % (k, f.get(k), want[k]) for k in want if f.get(k) != want[k]]
    if bad:
        return "the submission describes another field: " + ", ".join(bad)
    nums = [int(x) for x in d["nice_numbers"]]
    if nums != sorted(set(nums)):
        return "nice_numbers are not ascending and distinct"
    for n in nums:
        if not c.contains(n, v_start, v_size):
            return "nice number %d is not in the field" % n
        if not is_nice(n, w["base"]):
            return "%d is not nice in base %d" % (n, w["base"])
    m = SHAPE.match(d["shape"])
    if not m:
        return "shape %r is not F0,K" % d["shape"]
    try:
        want_slices = slice_count(c, (int(m.group(1)), int(m.group(2))), v_start, v_size)
    except ValueError as e:
        return str(e)
    if d["slices"] != want_slices:
        return "slices %d, but the field has %d slices under shape %s" % (d["slices"], want_slices, d["shape"])
    if d["checked"] > d["survivors"]:
        return "checked %d exceeds survivors %d" % (d["checked"], d["survivors"])
    return None


class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        try:
            sys.stderr.write("coordinator: %.3f %s\n" % (time.time(), fmt % args))
            sys.stderr.flush()
        except (OSError, ValueError):  # a full disk under the log must not cost a reply
            pass

    def _send(self, code, obj=None):
        b = b"" if obj is None else (obj.encode() if isinstance(obj, str) else json.dumps(obj).encode())
        self.send_response(code)
        if obj is not None:
            self.send_header("Content-Type", "text/plain" if isinstance(obj, str) else "application/json")
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
            c = {"claim_id": cid, "field": i, "time": now, "work": fields[i]}
            err = append(claims_path, c)
            if err:
                return self._send(503, "claim not recorded: %s" % err)
            next_id += 1
            claims[cid] = {"field": i, "time": now}
            last_claim[i] = (cid, now)
        f = fields[i]
        self._send(200, {"claim_id": cid, "base": f["base"], "coordinate": f["coordinate"],
                         "range_start": f["range_start"], "range_end": f["range_end"], "range_size": f["range_size"]})

    def do_GET(self):
        path = urlsplit(self.path).path.rstrip("/")
        if path == "/claim/midout":
            return self._claim()
        if a.legacy_path and path in ("/claim/niceonly", "/claim/detailed"):
            return self._claim()
        if path == "/status":
            with lock:
                return self._send(200, {"fields": len(fields), "claimed": len(last_claim), "searched": len(level),
                                        "checked": sum(1 for v in level.values() if v >= 2),
                                        "submissions": len(by_claim)})
        self._send(404, "this server offers only middle-out fields: GET /claim/midout, POST /submit/midout")

    def do_POST(self):
        global next_sub, dropped
        recv = time.time()
        if urlsplit(self.path).path.rstrip("/") != "/submit/midout":
            return self._send(404, "not found")
        n = self.headers.get("Content-Length", "")
        if not n.isdigit() or int(n) > MAX_BODY:
            self.close_connection = True
            return self._send(413 if n.isdigit() else 400, "Content-Length %r: want 0..%d" % (n, MAX_BODY))
        raw = self.rfile.read(int(n))
        try:
            d = json.loads(raw)
        except ValueError as e:
            return self._send(400, "malformed submission: %s" % e)
        why = body_problem(d)
        if why:
            return self._send(400, "malformed submission: %s" % why)
        # UTF-8 bytes, as the client measures it (json.dumps would escape every non-ASCII character to 6-12 bytes)
        tel = len(json.dumps(d.get("telemetry"), separators=(",", ":"), ensure_ascii=False).encode())
        if tel > MAX_TELEMETRY:
            return self._send(413, "telemetry of %d bytes: at most %d" % (tel, MAX_TELEMETRY))
        cid = d["claim_id"]
        with lock:
            c = claims.get(cid)
            if c is None:
                return self._send(404, "unknown claim %d" % cid)
            i = c["field"]
            why = field_problem(d, i)
            r = result_of(d)
            status, sid, code = None, None, 422
            if not why and cid in by_claim:
                sid, before = by_claim[cid]
                if before == r:
                    return self._send(200, {"submission_id": sid, "status": "already_recorded"})
                why, code = "claim %d was submitted before with another result (submission %d)" % (cid, sid), 409
            rec = {"recv": recv, "claim_id": cid, "field": i, "claim_time": c["time"], "accepted": why is None,
                   "reason": why, "status": None, "submission_id": None, "work": fields[i], "submission": d}
            if why is None:
                sid = next_sub
                rec["submission_id"] = sid
                # the status this record gets, computed without changing memory until the write is durable
                rec["status"] = "canon" if i not in level else "check"
            err = append(subs_path, rec)
            if err:
                return self._send(503, "submission not recorded: %s" % err)
            if why is not None:
                return self._send(code, "rejected: " + why)
            next_sub += 1
            status = accept(i, cid, sid, r)
            drop = dropped < a.drop_replies
            if drop:
                dropped += 1
        if drop:
            # test switch: the record is durable, the reply is lost
            self.close_connection = True
            return
        self._send(200, {"submission_id": sid, "status": status})


server = ThreadingHTTPServer(("127.0.0.1", a.port), H)
# the port bound (the one asked for, or the system's choice under --port 0), once the socket listens
sys.stderr.write("coordinator: listening on 127.0.0.1:%d\n" % server.server_address[1])
sys.stderr.flush()
server.serve_forever()
