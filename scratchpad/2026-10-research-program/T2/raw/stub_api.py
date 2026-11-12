#!/usr/bin/env python3
"""Local stand-in for the nice API's claim and submit endpoints (T2.3 audit; runs on the box, 127.0.0.1 only).
GET /claim/niceonly hands out the next field of FIELDS (json list of {field_id, base, range_start, range_size});
POST /submit appends the client's full submission body (one JSON line) to OUT. Nothing is forwarded anywhere.
usage: stub_api.py PORT FIELDS.json OUT.jsonl"""
import json, sys, threading
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
port, fields_path, out_path = int(sys.argv[1]), sys.argv[2], sys.argv[3]
fields = json.load(open(fields_path)); nxt = [0]; lock = threading.Lock()
class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *a): sys.stderr.write("stub: " + fmt % a + "\n")
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
            # list exhausted: hand out a trivial padding field (base 10, 47..100, claim_id 1) so the client
            # keeps cycling and submits what it holds; padding submissions are ignored by the comparison
            f = dict(field_id=1, base=10, range_start=47, range_size=53)
        s, n = int(f["range_start"]), int(f["range_size"])
        # u128 values as bare JSON integers, as the real API sends them
        self._send(200, '{"claim_id":%d,"base":%d,"range_start":%d,"range_end":%d,"range_size":%d}' % (int(f["field_id"]), int(f["base"]), s, s + n, n))
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        if self.path.rstrip("/") != "/submit": return self._send(404, '"not found"')
        with lock:
            with open(out_path, "a") as o: o.write(body.decode().strip() + "\n")
        self._send(200, '"stub: recorded"')
ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
