#!/bin/bash
source ~/.cargo/env
cd /root/l35/src/Cfmt
export CARGO_TARGET_DIR=/root/tgt_clippy NICE_BUILD_SHA=test
nice -n 10 cargo clippy -j 4 -p "*" --all-targets --features nice_client/gpu -- -D warnings > /root/l35/logs/clippy_gpu.log 2>&1; echo "clippy gpu rc=$?" >> /root/l35/logs/clippy_gpu.log
