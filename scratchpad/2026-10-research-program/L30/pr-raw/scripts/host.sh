#!/bin/bash
# Host suite (non-ignored tests): gpu umbrella and default features, nice_common + nice_client.
source ~/.cargo/env
export CARGO_TARGET_DIR=/root/tgt
L=/root/l30pr
cd /root/src-pr
cargo clean --release -p nice_common -p nice_client > /dev/null 2>&1
( nice -n 10 cargo test --release -j 4 -p nice_common -p nice_client --features nice_client/gpu 2>&1; echo "rc=$?" ) > $L/host_gpu.log
( nice -n 10 cargo test --release -j 4 -p nice_common -p nice_client 2>&1; echo "rc=$?" ) > $L/host_default.log
echo HOST_DONE $(date -u +%T) > $L/host.done
