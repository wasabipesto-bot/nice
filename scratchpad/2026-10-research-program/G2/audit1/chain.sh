#!/bin/bash
# after sweep 1: the key/group test alone on the card, then sweep 2 (300 more seeded slices)
cd /root/midout-audit; source ~/.cargo/env 2>/dev/null
while pgrep -f "audit_sweep" > /dev/null; do sleep 10; done
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || exit 1
export MIDOUT_CUDA=1
CARGO_TARGET_DIR=/root/t/auditf AUDIT_SLICES=502136830,712012851,806726610,0,1073741823,262143,46188,71583572,1073737727,4095 cargo test --offline --release -p nice_common --features cubecl-cuda --lib audit_key_and -- --ignored --nocapture > /root/audit/keys2.log 2>&1
(date -u; CARGO_TARGET_DIR=/root/t/audit AUDIT_SEED=20261119 AUDIT_N=300 AUDIT_THREADS=5 AUDIT_OUT=/root/audit/sweep2.jsonl cargo test --offline --release -p nice_common --features cubecl-cuda --lib audit_sweep -- --ignored --nocapture; date -u) > /root/audit/sweep2.log 2>&1
