#!/bin/bash
# box: build the scratch branch's dump (CPU) and bench (CUDA) examples, and the real bench with the 3b ablation
source ~/.cargo/env; export CARGO_TARGET_DIR=/root/tgt; cd /root/nice
date -u; git log --oneline -1
cargo build --release -p nice_common --example mo_width_dump 2>&1 | grep -E '^(error|warning: unused)|-->|Finished' ; echo dump rc=${PIPESTATUS[0]}
cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example mo_width_bench --example midout_bench 2>&1 | grep -E '^error|-->|^\s+\||Finished' | head -80; echo bench rc=${PIPESTATUS[0]}
date -u
