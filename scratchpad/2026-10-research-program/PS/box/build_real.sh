#!/bin/bash
# box: the real bench (midout_bench, g2_kernel with the 3b ablation bit) for CUDA
source ~/.cargo/env; export CARGO_TARGET_DIR=/root/tgt; cd /root/nice
date -u
cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_bench 2>&1 | grep -E '^error|-->|Finished'; echo real rc=${PIPESTATUS[0]}
date -u
