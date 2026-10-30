#!/bin/bash
source ~/.cargo/env
cd /root/fd
export CARGO_TARGET_DIR=/root/tfast CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 CARGO_PROFILE_RELEASE_INCREMENTAL=true
cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "^(error|warning)|Executable unittests|-->|^\s+\|" | head -80
echo "== test build exit ${PIPESTATUS[0]}"
if [ "${1:-}" = client ]; then cargo build --release -p nice_client --features gpu 2>&1 | tail -3; echo "== client build exit ${PIPESTATUS[0]}"; fi
