#!/usr/bin/env python3
"""Compact the stub's recorded submissions (from T2/raw/extract.py, plus stub claim/receive times and join details)."""
import json, sys
for fn in sys.argv[1:]:
    for line in open(fn):
        d = json.loads(line)
        if d.get("claim_id") == 1: continue
        t = d.get("telemetry") or {}; p = t.get("pipeline") or {}; j = p.get("join") or {}; st = d.get("_stub") or {}
        print(json.dumps(dict(file=fn.split('/')[-1], field_id=d["claim_id"], build=(t.get("build_sha") or "")[:8], ver=d.get("client_version"),
            route=p.get("route"), surv=j.get("survivors"), chk=j.get("checked"), valid=p.get("valid_numbers"), secs=j.get("run_secs"),
            setup=j.get("setup_secs"), slices=j.get("slices"), slots=j.get("slots"), min_slots=j.get("min_slots"),
            retried=j.get("retried_partitions"), total=p.get("total_secs"), proc=t.get("processing_secs"),
            wall=(st["recv"] - st["claim"]) if st.get("claim") else None,
            gpu=(t.get("hardware") or {}).get("gpu_model"), backend=(t.get("hardware") or {}).get("gpu_backend"), nice=d.get("nice_numbers", d.get("numbers")))))
