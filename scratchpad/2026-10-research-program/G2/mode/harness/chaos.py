#!/usr/bin/env python3
"""Chaos harness for scripts/midout_coordinator.py (standard library; 127.0.0.1 only), adapted 2026-11-25 to the
midout mode's wire (GET /claim/midout, POST /submit/midout with the typed body, replies canon / check /
already_recorded) and to its semantics: a field has one canon, a later accepted search of it is a check (H2, H6), an
identical resubmission under one claim is already_recorded and a different one 409, claims expire after
--claim-duration (was --reissue-after).

usage: chaos.py --script PATH [--runs N] [--seed S] [--jobs J] [--keep K] [--audit PATH] [--out DIR] [-v]

Each run (seed = S + i) cuts a random work list, starts the real coordinator as a subprocess (through trace_wrap.py,
which records the fsynced size of each state file), and lets fake clients speaking the client's wire format claim and
submit while a chaos thread kills the coordinator (SIGKILL), loses an unsynced tail at a random byte (power-loss
model), restarts it with a full disk (RLIMIT_FSIZE), with a changed work list, or starts a second coordinator on the
same state directory. Clients die between claim and submit, submit twice, late (after a reissue), with another
client's claim id, with another field's body, another route, a non-integer claim id, junk bodies and headers. Then
the clients stop, the state is compared with the live coordinator, the coordinator is restarted and drained with
--reissue-after 0 by one honest client, and the invariants of COORD/RESULTS.md §1 are checked from the state files
and from what every client was told. With --audit, the audit tool's verdict must agree with the checker's.

A failing run's state directory, ledger and coordinator log are kept under OUT/fail-<seed>/ (at most K of them).
Exit status: 0 if every run passed.
"""
import argparse, ctypes, http.client, json, os, random, resource, shutil, signal, socket, subprocess, sys, threading, time
from concurrent.futures import ProcessPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
WRAP = os.path.join(HERE, "trace_wrap.py")
sys.path.insert(0, HERE)
from mo import CLAIM, SUBMIT, C485, C496, field as _field, body as _body, t_of  # noqa: E402

Q, START = 2 ** 57, 2 ** 75
OK_KINDS = ("honest", "dup", "late")


def field(t, base=64, coord=C485):
    return _field(t, base, coord)


def ident(w):
    return (w["base"], w["coordinate"], w["range_start"], w["range_end"], w["range_size"])


def T(wk):
    """t of a field identity (for messages)."""
    return t_of({"base": wk[0], "coordinate": wk[1], "range_start": wk[2]})


def body(cid, work, nonce, **kw):
    """A submission as the client builds it (client/src/midout_route.rs: submission)."""
    return _body(cid, work, nonce, **kw)


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def req(port, method, path, obj=None, raw=None, timeout=3.0):
    """(status, text) or ("noreply", reason)."""
    try:
        h = http.client.HTTPConnection("127.0.0.1", port, timeout=timeout)
        b = raw if raw is not None else (None if obj is None else json.dumps(obj).encode())
        hd = {"Content-Type": "application/json"} if b is not None else {}
        h.request(method, path, body=b, headers=hd)
        r = h.getresponse()
        t = r.read().decode(errors="replace")
        h.close()
        return r.status, t
    except Exception as e:  # noqa: BLE001
        return "noreply", repr(e)


def raw_req(port, data, timeout=2.0):
    """Send raw bytes; (status, first line) or ("noreply", reason)."""
    try:
        s = socket.create_connection(("127.0.0.1", port), timeout=timeout)
        try:
            s.sendall(data)
        except (BrokenPipeError, ConnectionResetError):
            pass  # the server may answer and close before the whole body is sent (413): read what it said
        buf = b""
        while b"\r\n" not in buf:
            x = s.recv(4096)
            if not x:
                break
            buf += x
        s.close()
        line = buf.split(b"\r\n")[0].decode(errors="replace")
        parts = line.split()
        if len(parts) >= 2 and parts[1].isdigit():
            return int(parts[1]), line
        return "noreply", "no status line: %r" % line
    except Exception as e:  # noqa: BLE001
        return "noreply", repr(e)


def read_jsonl(path):
    """(records, problems): every line parsed; a torn last line is dropped and noted, any other bad line is a problem."""
    recs, probs, torn = [], [], False
    if not os.path.exists(path):
        return recs, probs, torn
    data = open(path, "rb").read()
    lines = data.split(b"\n")
    last_complete = data.endswith(b"\n")
    for k, ln in enumerate(lines):
        if k == len(lines) - 1:
            if ln == b"":
                break
            # no final newline: a torn record, never acknowledged
            torn = True
            break
        try:
            recs.append(json.loads(ln))
        except Exception as e:  # noqa: BLE001
            if k == len(lines) - 2 and not last_complete:
                torn = True
            else:
                probs.append("%s line %d unreadable: %s" % (os.path.basename(path), k + 1, e))
    return recs, probs, torn


class Coord:
    def __init__(self, run, script):
        self.run, self.script = run, script
        self.p, self.port, self.gen = None, None, 0
        self.lock = threading.Lock()

    def start(self, worklist, extra=(), fsize=None, state=None, port=None, wait=True):
        port = port or free_port()
        env = dict(os.environ, COORD_TRACE_DIR=self.run.trace)
        args = [sys.executable, WRAP, self.script, "--worklist", worklist, "--state", state or self.run.state,
                "--port", str(port)] + list(extra)

        def pre():
            # the coordinator dies with the harness process that started it (nothing is left running)
            ctypes.CDLL(None).prctl(1, signal.SIGKILL)  # PR_SET_PDEATHSIG
            if fsize is not None:
                resource.setrlimit(resource.RLIMIT_FSIZE, (fsize, fsize))
        # the log goes through a pipe, so that a file-size limit bites the state files only (a full log is
        # repro_log_full.py's case)
        p = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, env=env, preexec_fn=pre)
        self.run.pids.append(p.pid)

        def pump(src=p.stderr, path=self.run.log):
            with open(path, "ab") as log:
                for line in src:
                    log.write(line)
        threading.Thread(target=pump, daemon=True).start()
        t0 = time.time()
        while time.time() - t0 < 6:
            if p.poll() is not None:
                return p, port, ("exited", p.returncode)
            st, _ = req(port, "GET", "/status", timeout=0.5)
            if st == 200:
                return p, port, ("up", None)
            time.sleep(0.02)
        return p, port, ("timeout", None)

    def kill(self, p):
        if p is not None and p.poll() is None:
            os.kill(p.pid, signal.SIGKILL)
        if p is not None:
            p.wait()


class Run:
    def __init__(self, seed, script, out, verbose, stress=False):
        self.seed, self.script, self.verbose, self.stress = seed, script, verbose, stress
        self.rng = random.Random(seed)
        self.dir = os.path.join(out, "run-%d" % seed)
        shutil.rmtree(self.dir, ignore_errors=True)
        os.makedirs(self.dir)
        self.state = os.path.join(self.dir, "state")
        self.trace = os.path.join(self.dir, "trace")
        os.makedirs(self.trace)
        self.log = os.path.join(self.dir, "coord.log")
        self.pids = []
        self.ledger = []  # dicts
        self.llock = threading.Lock()
        self.viol = []
        self.events = []
        self.nonce = 0
        self.claimed_pool = []  # (cid, work) told to any client

    def note(self, **e):
        e["t"] = time.time()
        with self.llock:
            self.ledger.append(e)

    def v(self, inv, msg):
        self.viol.append("%s: %s" % (inv, msg))

    def next_nonce(self, kind, cid, work, client):
        with self.llock:
            self.nonce += 1
            return "s%d-c%d-n%d-%s" % (self.seed, client, self.nonce, kind)

    # ---------------------------------------------------------------- the run
    def go(self, audit=None):
        r = self.rng
        n = r.randint(50, 200) if self.stress else r.randint(2, 24)
        ts = r.sample(range(262144), n)
        wl = [field(t) for t in ts]
        if r.random() < 0.2:
            wl.append(field(r.randrange(262144), base=65, coord=C496))
        self.wl0 = list(wl)
        self.wl = list(wl)
        self.wpath = os.path.join(self.dir, "work.json")
        json.dump(self.wl, open(self.wpath, "w"))
        self.reissue = r.choice([None, 0.01, 0.03, 0.08]) if self.stress else r.choice([None, None, None, 0.15, 0.3, 0.6])
        self.extra = [] if self.reissue is None else ["--claim-duration", str(self.reissue)]
        self.co = Coord(self, self.script)
        p, port, st = self.co.start(self.wpath, self.extra)
        if st[0] != "up":
            self.v("START", "coordinator did not start: %s; log: %s" % (st, self.tail()))
            return self.finish(audit)
        self.cur = {"p": p, "port": port}
        self.gen = 1
        self.stop = threading.Event()
        nclients = r.randint(16, 32) if self.stress else r.randint(1, 6)
        threads = [threading.Thread(target=self.client, args=(k, random.Random(self.seed * 1000 + k)), daemon=True)
                   for k in range(nclients)]
        for t in threads:
            t.start()
        dur = r.uniform(0.6, 2.5)
        t_end = time.time() + dur
        nev = r.choice([0, 1, 1, 2, 3, 4])
        times = sorted(r.uniform(0.05, dur) for _ in range(nev))
        t0 = time.time()
        for et in times:
            time.sleep(max(0.0, t0 + et - time.time()))
            self.chaos(r.choices(["kill", "power", "tear", "fsize", "diskfull", "worklist", "second"],
                                 [3, 3, 3, 2, 2, 2, 2])[0])
        time.sleep(max(0.0, t_end - time.time()))
        self.stop.set()
        for t in threads:
            t.join(timeout=8)
        if any(t.is_alive() for t in threads):
            self.v("HARNESS", "a client thread did not stop")
        # live coordinator vs the files (S3)
        if self.cur["p"] is not None and self.cur["p"].poll() is None:
            st, txt = req(self.cur["port"], "GET", "/status")
            if st == 200:
                self.compare_status(json.loads(txt), "live, end of chaos")
        self.co.kill(self.cur["p"])
        # restart clean and drain with one honest client
        p, port, st = self.co.start(self.wpath, ["--claim-duration", "1e-9"])
        if st[0] != "up":
            self.v("S1/S4", "restart for the drain failed: %s; log: %s" % (st, self.tail()))
            return self.finish(audit)
        self.cur = {"p": p, "port": port}
        self.gen += 1
        sst, txt = req(port, "GET", "/status")
        if sst == 200:
            self.compare_status(json.loads(txt), "after restart")
        self.drain(port)
        self.co.kill(p)
        return self.finish(audit)

    def tail(self):
        try:
            return open(self.log, "rb").read()[-400:].decode(errors="replace").replace("\n", " | ")
        except OSError:
            return ""

    # ------------------------------------------------------------- chaos events
    def chaos(self, kind):
        r = self.rng
        self.events.append((round(time.time(), 3), kind))
        if kind == "second":
            p2, port2, st = self.co.start(self.wpath, self.extra)
            if st[0] == "up":
                self.v("S6", "a second coordinator started on the same state directory")
                # use it as a careless operator would: two claims, honest submissions
                for _ in range(2):
                    s, t = req(port2, "GET", CLAIM)
                    if s == 200:
                        c = json.loads(t)
                        w = {k: c[k] for k in ("base", "coordinate", "range_start", "range_end", "range_size")}
                        self.note(ev="claim", client=-1, cid=c["claim_id"], work=ident(w), gen=-1)
                        nn = self.next_nonce("honest", c["claim_id"], w, -1)
                        self.note(ev="send", client=-1, kind="honest", nonce=nn, cid=c["claim_id"], work=ident(w))
                        s2, t2 = req(port2, "POST", SUBMIT, body(c["claim_id"], w, nn))
                        self.note(ev="reply", client=-1, nonce=nn, status=s2, text=t2[:200])
                self.co.kill(p2)
            elif st[0] == "timeout":
                self.co.kill(p2)
            return
        if kind == "diskfull":
            # the disk fills under the running coordinator
            if self.cur["p"] is not None and self.cur["p"].poll() is None:
                have = max([os.path.getsize(os.path.join(self.state, fn)) for fn in ("claims.jsonl", "submissions.jsonl")
                            if os.path.exists(os.path.join(self.state, fn))] + [0])
                lim = have + r.randint(0, 900)
                try:
                    self.limited = True
                    resource.prlimit(self.cur["p"].pid, resource.RLIMIT_FSIZE, (lim, lim))
                    self.events.append(("diskfull", lim))
                except (ProcessLookupError, PermissionError) as e:
                    self.events.append(("diskfull-failed", repr(e)))
            return
        # every other event kills the coordinator first
        self.co.kill(self.cur["p"])
        self.cur["p"] = None
        if kind == "power":
            for fn in ("claims.jsonl", "submissions.jsonl"):
                path = os.path.join(self.state, fn)
                if not os.path.exists(path):
                    continue
                size = os.path.getsize(path)
                try:
                    dur = int(open(os.path.join(self.trace, fn + ".durable")).read().split()[0])
                except (OSError, ValueError, IndexError):
                    dur = 0
                cut = r.randint(min(dur, size), size)
                if cut < size:
                    with open(path, "r+b") as f:
                        f.truncate(cut)
                    self.events.append(("truncate", fn, size, cut, dur))
        if kind == "tear":
            # a write in flight when the process died: a prefix of a record that was never acknowledged
            fn = r.choice(["claims.jsonl", "submissions.jsonl"])
            path = os.path.join(self.state, fn)
            lines = open(path, "rb").read().splitlines() if os.path.exists(path) else []
            if lines:
                rec = r.choice(lines).replace(b'"claim_id": ', b'"claim_id": 9')
                cut = r.randint(1, len(rec))  # up to the whole record without its newline
                with open(path, "ab") as f:
                    f.write(rec[:cut])
                self.events.append(("tear", fn, cut, len(rec)))
        fsize = None
        wl = self.wl
        if kind == "fsize":
            have = max([os.path.getsize(os.path.join(self.state, fn)) for fn in ("claims.jsonl", "submissions.jsonl")
                        if os.path.exists(os.path.join(self.state, fn))] + [0])
            fsize = have + r.randint(0, 2500)
            self.limited = True
        if kind == "worklist":
            hist = self.fields_with_history()
            if len(hist) >= 2 and r.random() < 0.6:
                a, b = r.sample(sorted(hist), 2)
                bad = list(self.wl)
                how = r.choice(["swap", "edit", "shorten"])
                if how == "swap":
                    bad[a], bad[b] = bad[b], bad[a]
                elif how == "edit":  # another range for a field with history
                    bad[a] = field(t_of(bad[a]) + 1 + r.randrange(1000) * 300)
                else:  # the work list cut short before a field with history
                    bad = bad[:max(a, b)]
                bp = os.path.join(self.dir, "work-changed.json")
                json.dump(bad, open(bp, "w"))
                p, port, st = self.co.start(bp, self.extra)
                self.events.append((how, a, b, st[0]))
                if st[0] == "up":
                    self.v("S7", "a restart with the work list changed (%s, fields %d, %d with history) was not refused"
                           % (how, a, b))
                    self.cur = {"p": p, "port": port}
                    self.gen += 1
                    time.sleep(r.uniform(0.05, 0.3))  # clients use it
                    self.co.kill(p)
                    self.cur["p"] = None
                elif st[0] == "timeout":
                    self.co.kill(p)
            else:
                # append a new field: allowed
                t = r.randrange(262144)
                if all(ident(field(t)) != ident(w) for w in self.wl):
                    self.wl = self.wl + [field(t)]
                    json.dump(self.wl, open(self.wpath, "w"))
                    self.events.append(("append", t))
                wl = self.wl
        p, port, st = self.co.start(self.wpath, self.extra, fsize=fsize)
        if st[0] != "up":
            self.v("S1/S4", "restart after %s failed: %s; log: %s" % (kind, st, self.tail()))
            if st[0] == "timeout":
                self.co.kill(p)
            # try once more without a limit so the run can go on
            p, port, st = self.co.start(self.wpath, self.extra)
            if st[0] != "up":
                self.cur = {"p": None, "port": port}
                return
        self.cur = {"p": p, "port": port}
        self.gen += 1

    def fields_with_history(self):
        out = set()
        recs, _, _ = read_jsonl(os.path.join(self.state, "claims.jsonl"))
        for c in recs:
            if isinstance(c.get("field"), int):
                out.add(c["field"])
        return out

    # ------------------------------------------------------------------ clients
    def client(self, k, r):
        idle = 0
        while not self.stop.is_set():
            port, gen = self.cur["port"], self.gen
            if self.cur["p"] is None:
                time.sleep(0.02)
                continue
            t_req = time.time()
            s, t = req(port, "GET", CLAIM, timeout=2)
            if s == "noreply":
                time.sleep(0.02)
                continue
            if s == 204:
                idle += 1
                time.sleep(r.uniform(0.01, 0.08))
                continue
            if s != 200:
                self.v("CLAIM", "claim answered %s %s" % (s, t[:120]))
                time.sleep(0.05)
                continue
            c = json.loads(t)
            cid = c["claim_id"]
            w = {kk: c[kk] for kk in ("base", "coordinate", "range_start", "range_end", "range_size")}
            self.note(ev="claim", client=k, cid=cid, work=ident(w), gen=gen, t_req=t_req)
            with self.llock:
                self.claimed_pool.append((cid, w))
            kinds = ["honest", "die", "dup", "cross", "wrongbody", "slices", "notnice", "redo", "typeid", "junk",
                     "unknown"]
            wts = [50, 8, 8, 6, 6, 3, 3, 4, 4, 6, 2]
            if self.reissue is not None:
                kinds.append("late")
                wts.append(10)
            kind = r.choices(kinds, wts)[0]
            time.sleep(r.uniform(0, 0.03))
            if kind == "die":
                continue
            if kind == "late":
                time.sleep(self.reissue * r.uniform(1.2, 2.5))
                self.submit(k, r, cid, w, "late")
                continue
            if kind in ("cross", "wrongbody", "slices", "notnice", "typeid", "unknown", "junk"):
                self.bad(k, r, kind, cid, w)
            s_h, t_h, d_h = self.submit(k, r, cid, w, "honest")
            if kind == "dup":
                # the same body again (a reply the client did not get): already_recorded, never a second record
                time.sleep(r.uniform(0, 0.05))
                self.submit(k, r, cid, w, "dup", b=d_h, keep_name=True)
            if kind == "redo":
                # the same claim with another result: 409 once the first is recorded, never accepted
                d2 = dict(d_h, survivors=d_h["survivors"] + 1)
                self.submit(k, r, cid, w, "redo", b=d2)

    def submit(self, k, r, cid, w, kind, b=None, cid_sent=None, keep_name=False):
        """(status, text, body). keep_name: resend the body as it is (its username is the first send's nonce)."""
        nn = b["username"] if keep_name else self.next_nonce(kind, cid, w, k)
        d = b if b is not None else body(cid, w, nn)
        if b is not None and not keep_name:
            d = dict(d, username=nn)
        self.note(ev="send", client=k, kind=kind, nonce=nn, cid=cid if cid_sent is None else cid_sent, work=ident(w))
        for attempt in range(60):  # like the client: retry while there is no reply
            port, gen = self.cur["port"], self.gen
            if self.cur["p"] is None:
                time.sleep(0.03)
                continue
            s, t = req(port, "POST", SUBMIT, d, timeout=3)
            if s == "noreply":
                self.note(ev="reply", client=k, nonce=nn, status="noreply", text=t[:120], gen=gen)
                time.sleep(0.03)
                continue
            self.note(ev="reply", client=k, nonce=nn, status=s, text=t[:200], gen=gen)
            if s >= 500 and attempt < 59:
                time.sleep(0.03)
                continue
            return s, t, d
        return "noreply", "", d

    def bad(self, k, r, kind, cid, w):
        if kind == "cross":
            with self.llock:
                others = [(c2, w2) for c2, w2 in self.claimed_pool if c2 != cid and ident(w2) != ident(w)]
            if not others:
                return
            c2, w2 = r.choice(others)
            # own field's body under another client's claim id
            self.submit(k, r, cid, w, "cross", b=body(c2, w, ""), cid_sent=c2)
        elif kind == "wrongbody":
            others = [x for x in self.wl if ident(x) != ident(w)]
            cands = others + [field(r.randrange(262144), base=65, coord=C496), dict(w, coordinate=C496),
                              dict(w, coordinate=C485)]
            # a body for another field only (the base-65 field is already midout:4,9,6: that one is no change)
            w2 = r.choice([x for x in cands if ident(x) != ident(w)])
            self.submit(k, r, cid, w, "wrongbody", b=body(cid, w2, ""))
        elif kind == "slices":
            good = body(cid, w, "")
            self.submit(k, r, cid, w, "slices", b=body(cid, w, "", slices=good["slices"] + r.choice([1, -1, 4096])))
        elif kind == "notnice":
            c = w["range_start"]  # a number that is not nice (and in no field: v is not n)
            self.submit(k, r, cid, w, "notnice", b=body(cid, w, "", nice=[r.choice([c, 69, 2 ** 75 + 1])]))
        elif kind == "typeid":
            self.submit(k, r, cid, w, "typeid", b=body(r.choice([str(cid), cid + 0.25, float(cid)]), w, ""))
        elif kind == "unknown":
            self.submit(k, r, cid, w, "unknown", b=body(r.choice([7, 10 ** 30, -1, 0]), w, ""))
        elif kind == "junk":
            self.junk(k, r, cid, w)

    def junk(self, k, r, cid, w):
        port, gen = self.cur["port"], self.gen
        if self.cur["p"] is None:
            return
        j = r.choice(["notjson", "list", "tellist", "negcl", "nancl", "hugecl", "oversize", "nocl", "deep", "bigtel",
                      "numstr"])
        b = json.dumps(body(cid, w, "junk")).encode()
        if j == "notjson":
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: 5\r\n\r\n{not "
        elif j == "list":
            x = b"[1,2,3]"
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: %d\r\n\r\n%s" % (len(x), x)
        elif j == "tellist":
            d = body(cid, w, "junk")
            d["telemetry"] = [1]
            x = json.dumps(d).encode()
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: %d\r\n\r\n%s" % (len(x), x)
        elif j == "deep":  # the field as a list
            d = body(cid, w, "junk")
            d["field"] = [d["field"]]
            x = json.dumps(d).encode()
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: %d\r\n\r\n%s" % (len(x), x)
        elif j == "numstr":  # v_start as a JSON number, not a decimal string
            d = body(cid, w, "junk")
            d["field"]["v_start"] = int(d["field"]["v_start"])
            x = json.dumps(d).encode()
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: %d\r\n\r\n%s" % (len(x), x)
        elif j == "bigtel":  # telemetry over 16 KiB in an otherwise honest body: refused (413), not dropped
            d = body(cid, w, "junk")
            d["telemetry"]["pad"] = "x" * 17000
            x = json.dumps(d).encode()
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: %d\r\n\r\n%s" % (len(x), x)
        elif j == "negcl":
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: -1\r\n\r\n" + b
        elif j == "nancl":
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: abc\r\n\r\n" + b
        elif j == "hugecl":
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: 10000000000000\r\n\r\n" + b
        elif j == "nocl":
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\n\r\n" + b
        else:  # oversize: an otherwise honest body of 2 MB
            nn = self.next_nonce("oversize", cid, w, k)
            d = body(cid, w, nn)
            d["telemetry"]["pad"] = "x" * 2_000_000
            x = json.dumps(d).encode()
            self.note(ev="send", client=k, kind="oversize", nonce=nn, cid=cid, work=ident(w))
            data = b"POST /submit/midout HTTP/1.1\r\nHost: x\r\nContent-Length: %d\r\n\r\n%s" % (len(x), x)
        s, line = raw_req(port, data, timeout=2.0)
        self.note(ev="junk", client=k, kind=j, status=s, text=line[:120], gen=gen)
        # a body refused by its Content-Length alone may be cut off by the server's close (reset) before the
        # reply is read: refused, not accepted, and the coordinator must still serve
        closed = s == "noreply" and j in ("oversize", "hugecl") and ("Reset" in line or "Broken" in line)
        full = s == 503 and getattr(self, "limited", False)  # a full disk: "not recorded", the documented answer
        bad = (s == "noreply" and not closed) or (s != "noreply" and ((s >= 500 and not full) or s == 200))
        if bad and self.gen == gen and self.cur["p"] is not None and self.cur["p"].poll() is None:
            s2, _ = req(port, "GET", "/status", timeout=1)
            if s2 == 200 and self.gen == gen:
                self.v("H5", "junk %s answered %s (%s) by a live coordinator" % (j, s, line[:80]))

    def drain(self, port):
        for _ in range(4 * len(self.wl) + 20):
            t_req = time.time()
            s, t = req(port, "GET", CLAIM)
            if s == 204:
                return
            if s != 200:
                self.v("DRAIN", "claim answered %s %s" % (s, t[:120]))
                return
            c = json.loads(t)
            w = {kk: c[kk] for kk in ("base", "coordinate", "range_start", "range_end", "range_size")}
            self.note(ev="claim", client=99, cid=c["claim_id"], work=ident(w), gen=self.gen, drain=True, t_req=t_req)
            nn = self.next_nonce("honest", c["claim_id"], w, 99)
            self.note(ev="send", client=99, kind="honest", nonce=nn, cid=c["claim_id"], work=ident(w))
            s2, t2 = req(port, "POST", SUBMIT, body(c["claim_id"], w, nn))
            self.note(ev="reply", client=99, nonce=nn, status=s2, text=t2[:200], gen=self.gen)
        self.v("DRAIN", "did not end in 204")

    # ------------------------------------------------------------------ checks
    def compare_status(self, st, when):
        claims, _, _ = read_jsonl(os.path.join(self.state, "claims.jsonl"))
        subs, _, _ = read_jsonl(os.path.join(self.state, "submissions.jsonl"))
        done = {ident(s["work"]) for s in subs if s.get("accepted") and isinstance(s.get("work"), dict)}
        if st.get("searched") != len(done):
            self.v("S3/S4", "%s: /status searched %s, files hold %d searched fields" % (when, st.get("searched"),
                                                                                     len(done)))

    def finish(self, audit):
        claims, p1, torn1 = read_jsonl(os.path.join(self.state, "claims.jsonl"))
        subs, p2, torn2 = read_jsonl(os.path.join(self.state, "submissions.jsonl"))
        for p in p1 + p2:
            self.v("S1", p)
        if torn1 or torn2:
            self.v("S1", "a torn last line survived the final restart and drain (claims %s, submissions %s)" % (torn1, torn2))
        L = self.ledger
        sends = {e["nonce"]: e for e in L if e["ev"] == "send"}
        replies = {}
        for e in L:
            if e["ev"] == "reply":
                replies.setdefault(e["nonce"], []).append(e)
        # claim ids told to clients: unique
        told = {}
        for e in L:
            if e["ev"] == "claim":
                if e["cid"] in told and told[e["cid"]] != e["work"]:
                    self.v("S5", "claim id %s told for two fields" % e["cid"])
                told.setdefault(e["cid"], e["work"])
        file_claims = {}
        for c in claims:
            cid = c.get("claim_id")
            if cid in file_claims:
                self.v("S5", "claim id %s twice in claims.jsonl" % cid)
            file_claims[cid] = c
        # acknowledged claims are on disk
        for cid, wk in told.items():
            if cid not in file_claims:
                self.v("S2", "claim %s was acknowledged but is not in claims.jsonl" % cid)
            elif isinstance(file_claims[cid].get("work"), dict) and ident(file_claims[cid]["work"]) != wk:
                self.v("S5", "claim %s on disk names another field than the client was told" % cid)
        # H1: per field, claims told (chaos phase, not the drain) spaced by reissue_after; none after acceptance
        by_field = {}
        for e in L:
            if e["ev"] == "claim" and not e.get("drain"):
                by_field.setdefault(e["work"], []).append(e)
        for wk, es in by_field.items():
            ids = sorted({e["cid"] for e in es})
            if self.reissue is None and len(ids) > 1:
                self.v("H1", "field t=%d handed out under %d claims without --reissue-after: %s"
                       % (T(wk), len(ids), ids))
            elif self.reissue is not None:
                ts = sorted(e["t"] for e in es)
                for a, b in zip(ts, ts[1:]):
                    if b - a < self.reissue - 0.05:
                        self.v("H1", "field t=%d reissued after %.3f s < %s" % (T(wk), b - a, self.reissue))
        # H1 again on the coordinator's own clock (claims.jsonl), exactly: a reissue only after reissue_after
        drain_ids = {e["cid"] for e in L if e["ev"] == "claim" and e.get("drain")}
        fb = {}
        for c in claims:
            if isinstance(c.get("work"), dict) and c.get("claim_id") not in drain_ids:
                fb.setdefault(ident(c["work"]), []).append(c.get("time", 0))
        for wk, ts in fb.items():
            if self.reissue is None and len(ts) > 1:
                self.v("H1", "field t=%d has %d claims on disk without --reissue-after" % (T(wk), len(ts)))
            elif self.reissue is not None:
                for a, b in zip(ts, ts[1:]):
                    if b - a < self.reissue - 1e-9:
                        self.v("H1", "field t=%d reissued after %.4f s < %s on the coordinator's clock"
                               % (T(wk), b - a, self.reissue))
        accepted = {}
        acc_times = {}
        for s in subs:
            if not s.get("accepted"):
                continue
            wk = ident(s["work"]) if isinstance(s.get("work"), dict) else None
            accepted.setdefault(wk, []).append(s)
            acc_times.setdefault(wk, s.get("recv"))
            sub = s.get("submission") or {}
            nn = sub.get("username")
            snd = sends.get(nn)
            if snd is None:
                self.v("H4", "accepted submission %r for claim %s was never sent by a client" % (nn, s.get("claim_id")))
                continue
            if snd["kind"] not in OK_KINDS:
                self.v("H3/H4", "a '%s' submission (%s) was accepted for t=%d" % (snd["kind"], nn, T(wk)))
            if snd["work"] != wk:
                self.v("H4", "field t=%d accepted from a submission for t=%d (%s)"
                       % (T(wk), T(snd["work"]), nn))
            if told.get(s.get("claim_id")) != wk:
                self.v("H3", "field t=%d accepted under claim %s, which clients were told is %s"
                       % (T(wk), s.get("claim_id"), told.get(s.get("claim_id"))))
            fc = file_claims.get(s.get("claim_id"))
            if fc is None:
                self.v("H3", "accepted claim %s is not in claims.jsonl" % s.get("claim_id"))
        for wk, ss in accepted.items():
            canons = [x for x in ss if x.get("status") == "canon"]
            if len(canons) != 1 or ss[0].get("status") != "canon":
                self.v("H2", "field t=%d has %d canons, first status %s (claims %s)"
                       % (T(wk), len(canons), ss[0].get("status"), [x.get("claim_id") for x in ss]))
            cids = [x.get("claim_id") for x in ss]
            if len(set(cids)) != len(cids):
                self.v("H2", "field t=%d: two accepted records under one claim (%s)" % (T(wk), cids))
            self.checks = getattr(self, "checks", 0) + len(ss) - 1
        # H1: no claim of a field that was requested after a client had been told the field's submission was recorded
        told_rec = {}
        for nn, rs in replies.items():
            for x in rs:
                if x["status"] == 200:
                    wk = sends[nn]["work"]
                    told_rec[wk] = min(told_rec.get(wk, x["t"]), x["t"])
        for e in L:
            if e["ev"] == "claim" and e["work"] in told_rec and e.get("t_req", 0) > told_rec[e["work"]]:
                self.v("H1", "field t=%d claimed (claim %s, requested %.3f s after its submission was told recorded)"
                       % (T(e["work"]), e["cid"], e["t_req"] - told_rec[e["work"]]))
        # H6 evidence: a field accepted from its first holder after it had been reissued to another client
        self.h6 = 0
        for wk, ss in accepted.items():
            for x in ss:
                others = [e for e in by_field.get(wk, []) if e["cid"] != x.get("claim_id") and e["t"] < x.get("recv", 0)]
                if others and min(e["cid"] for e in others) > x.get("claim_id", 0):
                    self.h6 += 1
        # acknowledged submissions are on disk, as accepted, for their own claim
        acc_cids = {s.get("claim_id") for ss in accepted.values() for s in ss}
        for nn, rs in replies.items():
            if any(x["status"] == 200 for x in rs):
                snd = sends[nn]
                if snd["kind"] not in OK_KINDS:
                    self.v("H3/H4", "a '%s' submission got 200 (%s)" % (snd["kind"], nn))
                if snd["cid"] not in acc_cids:
                    self.v("S2", "submission %s (claim %s, t=%d) was told 'recorded' but is not accepted on disk"
                           % (nn, snd["cid"], T(snd["work"])))
        # E1/E2: after the drain, every field of the work list has exactly one canon, nothing else
        wset = {ident(w) for w in self.wl}
        for wk in wset:
            nc = sum(1 for x in accepted.get(wk, []) if x.get("status") == "canon")
            if nc != 1:
                self.v("E1", "field t=%d has %d canons at the end" % (T(wk), nc))
        for wk in accepted:
            if wk not in wset:
                self.v("E2", "accepted field %s is not in the work list" % (wk,))
        self.fileviol = file_verdict(self.wl, claims, subs, p1 + p2)
        self.audit_rc = None
        if audit:
            a = subprocess.run([sys.executable, audit, "--worklist", self.wpath, "--state", self.state, "--quiet"],
                               capture_output=True, text=True, timeout=60)
            self.audit_rc = a.returncode
            if (a.returncode == 0) != (not self.fileviol):
                self.v("AUDIT", "audit rc %d disagrees with the checker's file verdict (%s): %s"
                       % (a.returncode, self.fileviol[:3] or "all accepted exactly once", (a.stdout + a.stderr)[-300:]))
        return self.viol


def _num(x):
    if isinstance(x, bool):
        return None
    if isinstance(x, int):
        return x
    if isinstance(x, str) and x.isdigit():
        return int(x)
    return None


def file_verdict(wl, claims, subs, unreadable):
    """The checker's own verdict from the files alone (independent of the audit tool): the list of reasons the
    state is not "every field of the work list accepted exactly once, legitimately"; empty if it is."""
    out = list(unreadable)
    wid = [ident(w) for w in wl]
    cl = {}
    for c in claims:
        w = c.get("work")
        if isinstance(w, dict):
            wk = ident(w)
        elif isinstance(c.get("field"), int) and 0 <= c["field"] < len(wl):
            wk = wid[c["field"]]
        else:
            wk = None
        cl.setdefault(c.get("claim_id"), []).append(wk)
    acc = {}
    for s in subs:
        if not s.get("accepted"):
            continue
        w = s.get("work")
        if not isinstance(w, dict):
            out.append("accepted record without its field")
            continue
        wk = ident(w)
        if s.get("status") == "canon":
            acc[wk] = acc.get(wk, 0) + 1
        elif s.get("status") != "check":
            out.append("accepted record with status %r" % (s.get("status"),))
        elif acc.get(wk, 0) == 0:
            out.append("a check before its field's canon")
        cid = s.get("claim_id")
        if cl.get(cid) is None:
            out.append("accepted claim %s not in claims.jsonl" % cid)
        elif set(cl[cid]) != {wk}:
            out.append("accepted claim %s names another field in claims.jsonl" % cid)
        d = s.get("submission")
        if not isinstance(d, dict):
            out.append("accepted record without a body")
            continue
        if type(d.get("claim_id")) is not int or d.get("claim_id") != cid:
            out.append("accepted body's claim id %r" % (d.get("claim_id"),))
        f = d.get("field")
        if not isinstance(f, dict):
            out.append("accepted body without its field")
            continue
        if (f.get("coordinate") != w["coordinate"] or f.get("base") != w["base"]
                or _num(f.get("v_start")) != w["range_start"] or _num(f.get("v_size")) != w["range_end"] - w["range_start"]
                or _num(f.get("range_size")) != w["range_size"]):
            out.append("accepted body describes another field than its claim")
    for wk in wid:
        if acc.get(wk, 0) != 1:
            out.append("field %s has %d canons" % (wk[2], acc.get(wk, 0)))
    for wk in acc:
        if wk not in set(wid):
            out.append("accepted field not in the work list")
    return out


def one(args):
    seed, script, out, keep, verbose, audit, stress = args
    run = Run(seed, script, out, verbose, stress)
    try:
        viol = run.go(audit)
    except Exception as e:  # noqa: BLE001
        import traceback
        viol = ["HARNESS: %s" % traceback.format_exc()]
    finally:
        for pid in run.pids:
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            try:
                os.waitpid(pid, os.WNOHANG)
            except ChildProcessError:
                pass
    res = {"seed": seed, "viol": viol, "events": run.events, "reissue": getattr(run, "reissue", None),
           "fields": len(getattr(run, "wl", [])), "ledger_n": len(run.ledger),
           "kinds": sorted({e["kind"] for e in run.ledger if e["ev"] in ("send", "junk")}),
           "statuses": sorted({str(e["status"]) for e in run.ledger if e["ev"] in ("reply", "junk")}),
           "ev_kinds": sorted({e[1] if isinstance(e[0], float) else e[0] for e in run.events}),
           "audit_rc": getattr(run, "audit_rc", None), "h6": getattr(run, "h6", 0), "checks": getattr(run, "checks", 0), "file_verdict_ok": not getattr(run, "fileviol", [1])}
    if viol:
        json.dump(run.ledger, open(os.path.join(run.dir, "ledger.json"), "w"), default=str)
        json.dump(res, open(os.path.join(run.dir, "result.json"), "w"), default=str, indent=1)
        fails = sorted(x for x in os.listdir(out) if x.startswith("fail-"))
        if len(fails) < keep:
            os.rename(run.dir, os.path.join(out, "fail-%d" % seed))
        else:
            shutil.rmtree(run.dir, ignore_errors=True)
    else:
        shutil.rmtree(run.dir, ignore_errors=True)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--script", required=True)
    ap.add_argument("--runs", type=int, default=100)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--jobs", type=int, default=3)
    ap.add_argument("--keep", type=int, default=20)
    ap.add_argument("--audit", default=None)
    ap.add_argument("--out", default=os.environ.get("COORD_OUT", os.path.expanduser(
        "~/projects/nice/scratchpad/2026-10-research-program/G2/mode/chaos")))
    ap.add_argument("--summary", default=None, help="write one JSON line per run here")
    ap.add_argument("--stress", action="store_true", help="16-32 clients, 50-200 fields, reissue 0.01-0.08 s or none")
    ap.add_argument("-v", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    script = os.path.abspath(a.script)
    audit = os.path.abspath(a.audit) if a.audit else None
    jobs = [(a.seed + i, script, a.out, a.keep, a.v, audit, a.stress) for i in range(a.runs)]
    kinds, cov_ev, cov_k, cov_s = {}, {}, {}, {}
    nfail = 0
    sm = open(a.summary, "w") if a.summary else None
    t0 = time.time()
    with ProcessPoolExecutor(a.jobs) as ex:
        for res in ex.map(one, jobs):
            if sm:
                sm.write(json.dumps(res, default=str) + "\n")
            if res.get("h6"):
                cov_ev["(H6: accepted from the first holder after a reissue)"] = cov_ev.get("(H6: accepted from the first holder after a reissue)", 0) + 1
            if res.get("checks"):
                cov_ev["(a check recorded)"] = cov_ev.get("(a check recorded)", 0) + 1
            if res.get("audit_rc") is not None:
                cov_ev["(audit run)"] = cov_ev.get("(audit run)", 0) + 1
            for x in res["ev_kinds"]:
                cov_ev[x] = cov_ev.get(x, 0) + 1
            for x in res["kinds"]:
                cov_k[x] = cov_k.get(x, 0) + 1
            for x in res["statuses"]:
                cov_s[x] = cov_s.get(x, 0) + 1
            for x in res["viol"]:
                kinds.setdefault(x.split(":")[0], []).append(res["seed"])
            if res["viol"]:
                nfail += 1
                if a.v:
                    print("seed %d FAIL:" % res["seed"], *res["viol"][:6], sep="\n  ")
    print("%d runs (seeds %d..%d) in %.0f s: %d failed" % (a.runs, a.seed, a.seed + a.runs - 1, time.time() - t0, nfail))
    print("  runs exercising each event: " + ", ".join("%s %d" % kv for kv in sorted(cov_ev.items())))
    print("  runs exercising each client kind: " + ", ".join("%s %d" % kv for kv in sorted(cov_k.items())))
    print("  runs seeing each reply: " + ", ".join("%s %d" % kv for kv in sorted(cov_s.items())))
    for k, seeds in sorted(kinds.items()):
        print("  %-8s %5d violations in %d runs, first seeds %s" % (k, len(seeds), len(set(seeds)), sorted(set(seeds))[:8]))
    sys.exit(1 if nfail else 0)


if __name__ == "__main__":
    main()
