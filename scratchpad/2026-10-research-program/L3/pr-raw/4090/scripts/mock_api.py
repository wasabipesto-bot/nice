#!/usr/bin/env python3
"""Minimal local stand-in for the nice API (claim/detailed + submit only), so
nice_client runs its production field path offline. Serves the same field on
every claim; stores every submission body. Usage:
  mock_api.py PORT BASE RANGE_START RANGE_SIZE OUTDIR
"""
import json, sys, time, os, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

port, base, start, size, outdir = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), int(float(sys.argv[4])), sys.argv[5]
os.makedirs(outdir, exist_ok=True)
lock = threading.Lock()
state = {"claims": 0, "submits": 0}

class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass
    def _send(self, code, body):
        b = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)
    def do_GET(self):
        if self.path.startswith("/claim/detailed"):
            with lock:
                state["claims"] += 1
                cid = state["claims"]
            body = '{"claim_id": %d, "base": %d, "range_start": %d, "range_end": %d, "range_size": %d}' % (cid, base, start, start + size, size)
            with open(os.path.join(outdir, "events.log"), "a") as f:
                f.write(f"{time.time():.3f} claim {cid}\n")
            self._send(200, body)
        else:
            self._send(404, '{"error":"not mocked"}')
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(n)
        if self.path.startswith("/submit"):
            with lock:
                state["submits"] += 1
                k = state["submits"]
            with open(os.path.join(outdir, f"submit_{k}.json"), "wb") as f:
                f.write(data)
            with open(os.path.join(outdir, "events.log"), "a") as f:
                f.write(f"{time.time():.3f} submit {k}\n")
            self._send(200, '{"ok":true}')
        else:
            self._send(404, '{"error":"not mocked"}')

ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
