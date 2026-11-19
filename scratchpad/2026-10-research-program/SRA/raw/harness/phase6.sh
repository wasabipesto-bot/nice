#!/bin/bash
# upstream main (71eb5fc, no fix) in its own worktree and target dir: the CUDA device tests one at a time, to see
# whether the join test's allocation failure in the serial run is there without this change too
source ~/.cargo/env
cd /root/sra/nice
git worktree add -f /root/sra/base 71eb5fc > /dev/null 2>&1
cd /root/sra/base
export CARGO_TARGET_DIR=/root/sra/t-base
L=/root/sra/logs/phase6; mkdir -p $L
git log --oneline -1 > $L/base_head.txt
( nvidia-smi --query-gpu=timestamp,memory.used --format=csv,noheader -l 5 > $L/base_mem.csv ) & MP=$!
echo "$(date -u +%FT%TZ) start base_cuda_serial" >> $L/steps.log
cargo test --release --features cubecl-cuda -p nice_common -- --ignored --nocapture --test-threads=1 cubecl_cuda_ > $L/base_cuda_serial.log 2>&1
echo "$(date -u +%FT%TZ) end base_cuda_serial rc=$?" >> $L/steps.log
kill $MP
echo done > $L/done
