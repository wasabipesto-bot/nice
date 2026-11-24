"""Shared helpers for the smallest reproductions (standard library; 127.0.0.1 only).

Each repro_*.py takes the coordinator script's path (default: the worktree's) and exits 1 if the defect is
present, 0 if not. State goes to a fresh directory under $COORD_SCRATCH (or a temporary directory)."""
import http.client, json, os, signal, socket, subprocess, sys, tempfile, time

Q, START = 2 ** 57, 2 ** 75
DEFAULT = os.path.expanduser("~/projects/nice/.worktrees/midout-clean/scripts/midout_coordinator.py")
SCRIPT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
PIDS = []


def field(t, base=64, coord="midout:4,8,5"):
    v = START + t * Q
    return {"base": base, "coordinate": coord, "range_start": v, "range_end": v + Q, "range_size": Q}


def body(cid, w, route="midout"):
    v, z = w["range_start"], w["range_end"] - w["range_start"]
    return {"claim_id": cid, "username": "repro", "client_version": "3.4.9-dev", "unique_distribution": None,
            "nice_numbers": [],
            "telemetry": {"pipeline": {"route": route, "coordinate": w["coordinate"],
                                       "field": {"base": w["base"], "v_start": str(v), "v_size": str(z),
                                                 "t0": str((v - START) // Q), "quanta": "1",
                                                 "range_size": str(w["range_size"])}}}}


def workdir(name):
    base = os.environ.get("COORD_SCRATCH") or tempfile.gettempdir()
    d = tempfile.mkdtemp(prefix=name + "-", dir=base)
    return d


def worklist(d, fields, name="work.json"):
    p = os.path.join(d, name)
    json.dump(fields, open(p, "w"))
    return p


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def start(wl, state, *extra, wrap=None, env=None, preexec=None):
    """(Popen, port, 'up' | 'exited')."""
    port = free_port()
    pre = [sys.executable] + ([wrap] if wrap else [])
    p = subprocess.Popen(pre + [SCRIPT, "--worklist", wl, "--state", state, "--port", str(port)] + list(extra),
                         stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, env=env, preexec_fn=preexec)
    PIDS.append(p.pid)
    for _ in range(300):
        if p.poll() is not None:
            return p, port, "exited"
        if req(port, "GET", "/status", timeout=0.3)[0] == 200:
            return p, port, "up"
        time.sleep(0.02)
    return p, port, "timeout"


def kill(p):
    if p.poll() is None:
        os.kill(p.pid, signal.SIGKILL)
    p.wait()


def cleanup():
    for pid in PIDS:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass


def req(port, method, path, obj=None, raw=None, timeout=3.0, headers=None):
    try:
        h = http.client.HTTPConnection("127.0.0.1", port, timeout=timeout)
        b = raw if raw is not None else (None if obj is None else json.dumps(obj).encode())
        h.request(method, path, body=b, headers=headers or {})
        r = h.getresponse()
        t = r.read().decode(errors="replace")
        h.close()
        return r.status, t
    except Exception as e:  # noqa: BLE001
        return "noreply", repr(e)


def claim(port):
    s, t = req(port, "GET", "/claim/niceonly?coordinate=midout")
    return json.loads(t) if s == 200 else None


def verdict(defect, msg):
    cleanup()
    print(("DEFECT PRESENT: " if defect else "ok: ") + msg)
    sys.exit(1 if defect else 0)
