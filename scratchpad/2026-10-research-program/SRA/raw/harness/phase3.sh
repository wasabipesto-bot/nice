#!/bin/bash
# CUDA device tests again, one test at a time: in parallel the test threads share one CubeCL CUDA client and its
# memory pools, the process reached the card's 20 GB, an allocation failed, and two join tests saw NotRun.
source ~/.cargo/env
cd /root/sra/nice
export CARGO_TARGET_DIR=/root/sra/target
L=/root/sra/logs/phase3; mkdir -p $L
while [ ! -f /root/sra/logs/phase2/done ]; do sleep 10; done
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
( nvidia-smi --query-gpu=timestamp,memory.used --format=csv,noheader -l 5 > $L/mem.csv ) & MP=$!
echo "$(date -u +%FT%TZ) start cuda_serial" >> $L/steps.log
cargo test --release --features cubecl-cuda -p nice_common -- --ignored --nocapture --test-threads=1 cubecl_cuda_ > $L/cuda_serial.log 2>&1
echo "$(date -u +%FT%TZ) end cuda_serial rc=$?" >> $L/steps.log
kill $MP
echo done > $L/done
