#!/usr/bin/env python3
"""Local stand-in for the nice API on the box (127.0.0.1 only; nothing forwarded). GET /claim/validate returns the
row named by the file CUR (one field id) from ROWS.json in the server's ValidationData shape (base, field_id,
range_start, range_end, range_size, unique_distribution, nice_numbers); every request, and the body of any POST,
is appended to LOG as one JSON line. Any other path: 404. usage: stub_validate.py PORT ROWS.json CUR LOG"""
import json, sys, time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
port, rows_path, cur_path, log_path = int(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
rows = {int(r["field_id"]): r for r in json.load(open(rows_path))}
def log(d):
    with open(log_path, "a") as o: o.write(json.dumps(d) + "\n")
class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *a): pass
    def _send(self, code, body):
        b = body.encode(); self.send_response(code)
        self.send_header("Content-Type", "application/json"); self.send_header("Content-Length", str(len(b)))
        self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        log(dict(t=time.time(), method="GET", path=self.path))
        if self.path.rstrip("/") != "/claim/validate": return self._send(404, '"not found"')
        r = rows[int(open(cur_path).read().strip())]
        s, e = int(r["range_start"]), int(r["range_end"])
        self._send(200, '{"base":%d,"field_id":%d,"range_start":%d,"range_end":%d,"range_size":%d,"unique_distribution":[],"nice_numbers":[]}'
                   % (int(r["base"]), int(r["field_id"]), s, e, e - s))
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        log(dict(t=time.time(), method="POST", path=self.path, body=body.decode(errors="replace")))
        self._send(404, '"stub: nothing accepted"')
ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
