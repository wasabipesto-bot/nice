#!/bin/bash
# clippy on the hybrid tree (the lint fix on fcd6581) as CI runs it: default features, and --features nice_client/gpu.
source ~/.cargo/env
cd /root/l34/src/Hc
export CARGO_TARGET_DIR=/root/tgt-clippy NICE_BUILD_SHA=test
( cargo clippy -p "*" --all-targets -- -D warnings; echo "clippy default rc=$?" ) > /root/l34/logs/clippy2_default.log 2>&1
( cargo clippy -p "*" --all-targets --features nice_client/gpu -- -D warnings; echo "clippy gpu rc=$?" ) > /root/l34/logs/clippy2_gpu.log 2>&1
echo CLIPPY_DONE $(date -u +%T) > /root/l34/logs/clippy2.done
