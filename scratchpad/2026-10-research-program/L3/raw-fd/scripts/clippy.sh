#!/bin/bash
source ~/.cargo/env
cd /root/fd
export CARGO_TARGET_DIR=/root/tfast
cargo clippy -p nice_common --features gpu --release --all-targets 2>&1 | grep -E "^(warning|error)" -A8 | head -150
echo "== clippy exit ${PIPESTATUS[0]}"
