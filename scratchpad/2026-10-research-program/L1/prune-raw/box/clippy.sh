#!/bin/bash
source ~/.cargo/env
cd /root/prune
cargo fmt --all --check && echo FMT_OK
cargo clippy -j 24 -p nice_common --all-targets --features gpu -- -D warnings 2>&1 | tail -30
echo "CLIPPY_EXIT ${PIPESTATUS[0]}"
