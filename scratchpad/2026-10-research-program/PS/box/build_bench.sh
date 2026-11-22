#!/bin/bash
# box: build the CUDA bench (mo_width_bench) only
source ~/.cargo/env; export CARGO_TARGET_DIR=/root/tgt; cd /root/nice
date -u
cargo build --release -p nice_common --features cubecl-cuda --example mo_width_bench 2>&1 | grep -E '^error|^warning|-->|^\s+\||Finished' | head -120; echo bench rc=${PIPESTATUS[0]}
date -u
