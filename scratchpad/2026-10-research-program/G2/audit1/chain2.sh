#!/bin/bash
# after chain.sh: sweep 3 (400 more seeded slices); stops itself at 01:10 UTC (the test is killed; finished lines stay)
cd /root/midout-audit; source ~/.cargo/env 2>/dev/null
while pgrep -f "chain.sh" > /dev/null; do sleep 10; done
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || exit 1
export MIDOUT_CUDA=1
left=$(( $(date -u -d "01:10" +%s) - $(date -u +%s) ))
[ $left -lt 0 ] && left=$(( left + 86400 ))
(date -u; CARGO_TARGET_DIR=/root/t/audit AUDIT_SEED=20261120 AUDIT_N=400 AUDIT_THREADS=5 AUDIT_OUT=/root/audit/sweep3.jsonl timeout $left cargo test --offline --release -p nice_common --features cubecl-cuda --lib audit_sweep -- --ignored --nocapture; date -u) > /root/audit/sweep3.log 2>&1
