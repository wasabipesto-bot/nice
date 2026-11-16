#!/usr/bin/env python3
"""Local stand-in for the nice API's claim and submit endpoints (T2.3's stub plus claim/submit timestamps; runs on the
box, 127.0.0.1 only). GET /claim/niceonly hands out the next field of FIELDS; POST /submit appends the client's full
body (one JSON line) to OUT, with the stub's receive time and the field's claim time added under "_stub".
Nothing is forwarded anywhere. usage: stub_api.py PORT FIELDS.json OUT.jsonl"""
import json, sys, threading, time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
port, fields_path, out_path = int(sys.argv[1]), sys.argv[2], sys.argv[3]
fields = json.load(open(fields_path)); nxt = [0]; lock = threading.Lock(); claimed = {}
class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *a): sys.stderr.write("stub: %.3f " % time.time() + fmt % a + "\n")
    def _send(self, code, body):
        b = body.encode(); self.send_response(code)
        self.send_header("Content-Type", "application/json"); self.send_header("Content-Length", str(len(b)))
        self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        if self.path.rstrip("/") != "/claim/niceonly": return self._send(404, '"not found"')
        with lock:
            f = fields[nxt[0]] if nxt[0] < len(fields) else None
            nxt[0] += 1
        if f is None:
            f = dict(field_id=1, base=10, range_start=47, range_size=53)
        claimed.setdefault(int(f["field_id"]), time.time())
        s, n = int(f["range_start"]), int(f["range_size"])
        self._send(200, '{"claim_id":%d,"base":%d,"range_start":%d,"range_end":%d,"range_size":%d}' % (int(f["field_id"]), int(f["base"]), s, s + n, n))
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if self.path.rstrip("/") != "/submit": return self._send(404, '"not found"')
        d = json.loads(body); d["_stub"] = dict(recv=time.time(), claim=claimed.get(int(d.get("claim_id", 0))))
        with lock:
            with open(out_path, "a") as o: o.write(json.dumps(d) + "\n")
        self._send(200, '"stub: recorded"')
ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
