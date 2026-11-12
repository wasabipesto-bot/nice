#!/usr/bin/env python3
"""Compact the stub's recorded submissions: claim_id, build, route, survivors, checked, run_secs, gpu, nice numbers."""
import json, sys
for fn in sys.argv[1:]:
    for line in open(fn):
        d = json.loads(line); t = d.get("telemetry") or {}; p = t.get("pipeline") or {}; j = p.get("join") or {}
        print(json.dumps(dict(field_id=d["claim_id"], build=(t.get("build_sha") or "")[:8], ver=d["client_version"], route=p.get("route"),
            surv=j.get("survivors"), chk=j.get("checked"), valid=p.get("valid_numbers"), secs=j.get("run_secs"),
            gpu=(t.get("hardware") or {}).get("gpu_model"), backend=(t.get("hardware") or {}).get("gpu_backend"), nice=d.get("nice_numbers"))))
