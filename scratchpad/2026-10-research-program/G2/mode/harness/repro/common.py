"""Shared helpers for the smallest reproductions (standard library; 127.0.0.1 only).

Each repro_*.py takes the coordinator script's path (default: the worktree's) and exits 1 if the defect is
present, 0 if not. State goes to a fresh directory under $COORD_SCRATCH (or a temporary directory)."""
import http.client, json, os, signal, socket, subprocess, sys, tempfile, time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from mo import CLAIM, SUBMIT, C485, C496, field as _field, body as _body, t_of  # noqa: E402

Q, START = 2 ** 57, 2 ** 75
DEFAULT = os.path.expanduser("~/projects/nice/.worktrees/mo-mode/scripts/midout_coordinator.py")
SCRIPT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
PIDS = []


def field(t, base=64, coord=C485):
    return _field(t, base, coord)


def body(cid, w, **kw):
    return _body(cid, w, "repro", **kw)


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
    s, t = req(port, "GET", CLAIM)
    return json.loads(t) if s == 200 else None


def verdict(defect, msg):
    cleanup()
    print(("DEFECT PRESENT: " if defect else "ok: ") + msg)
    sys.exit(1 if defect else 0)
