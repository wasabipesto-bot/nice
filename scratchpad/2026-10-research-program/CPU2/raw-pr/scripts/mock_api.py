#!/usr/bin/env python3
"""Local stand-in for the claim/submit API (127.0.0.1 only): serves the
claim in $CLAIM_JSON for /claim/niceonly, appends each /submit body to
$SUBMIT_LOG. The production API is never contacted."""
import http.server, json, os, sys
class H(http.server.BaseHTTPRequestHandler):
    def _send(self, code, body):
        b = body.encode()
        self.send_response(code); self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        if self.path.startswith('/claim/niceonly'):
            self._send(200, open(os.environ['CLAIM_JSON']).read())
        else:
            self._send(404, '{}')
    def do_POST(self):
        n = int(self.headers.get('Content-Length', 0)); body = self.rfile.read(n).decode()
        with open(os.environ['SUBMIT_LOG'], 'a') as f: f.write(body + '\n')
        self._send(200, '{"ok":true}')
    def log_message(self, *a): pass
http.server.ThreadingHTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
