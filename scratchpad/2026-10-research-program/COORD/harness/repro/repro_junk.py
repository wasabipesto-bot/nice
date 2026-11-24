#!/usr/bin/env python3
"""Malformed requests must get a 4xx at once and leave the coordinator serving: negative, non-numeric and huge
Content-Length, telemetry of the wrong type, a 2 MB otherwise valid body."""
import os, socket
from common import *
d = workdir("junk"); st = os.path.join(d, "state")
f1 = field(1); wl = worklist(d, [f1])
p, port, _ = start(wl, st); c = claim(port)
def raw(data):
    try:
        s = socket.create_connection(("127.0.0.1", port), timeout=2); s.sendall(data)
        b = s.recv(200); s.close(); return b.split(b"\r\n")[0].decode() or "no reply"
    except Exception as e:
        return "no reply (%s)" % type(e).__name__
b = json.dumps(body(c["claim_id"], f1)).encode()
tl = body(c["claim_id"], f1); tl["telemetry"] = [1]; tl = json.dumps(tl).encode()
big = body(c["claim_id"], f1); big["telemetry"]["pad"] = "x" * 2_000_000; big = json.dumps(big).encode()
res = {
    "Content-Length -1": raw(b"POST /submit HTTP/1.1\r\nContent-Length: -1\r\n\r\n" + b),
    "Content-Length abc": raw(b"POST /submit HTTP/1.1\r\nContent-Length: abc\r\n\r\n" + b),
    "Content-Length 1e13": raw(b"POST /submit HTTP/1.1\r\nContent-Length: 10000000000000\r\n\r\n" + b),
    "telemetry a list": raw(b"POST /submit HTTP/1.1\r\nContent-Length: %d\r\n\r\n%s" % (len(tl), tl)),
    "2 MB body": raw(b"POST /submit HTTP/1.1\r\nContent-Length: %d\r\n\r\n%s" % (len(big), big)),
}
alive = req(port, "GET", "/status")[0] == 200
kill(p)
bad = [k for k, v in res.items() if not v.startswith("HTTP/1.0 4")]
verdict(bool(bad) or not alive, "; ".join("%s -> %s" % kv for kv in res.items()) + "; alive after: %s" % alive)
