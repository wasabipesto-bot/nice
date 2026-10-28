#!/bin/bash
# Part 2 (L3): detailed-mode GPU vs CPU benchmarks and a dmon trace.
set -u
B=/root/nice/target/release/nice_client
O=/root/runs/l3
mkdir -p $O
export NICE_API_BASE=http://127.0.0.1:9   # offline: never reach the real API
cat /sys/fs/cgroup/cpu.max > $O/cpu_max.txt 2>&1
nvidia-smi -q -d CLOCK,POWER,PERFORMANCE > $O/nvidia_smi_q_before.txt 2>&1
echo "# $(date -u +%FT%TZ) gpu 120" > $O/gpu120.log
RUST_LOG=info $B detailed --gpu --benchmark --benchmark-secs 120 < /dev/null >> $O/gpu120.log 2>&1
echo "# $(date -u +%FT%TZ) cpu 120 threads 16" > $O/cpu120.log
RUST_LOG=info $B detailed --benchmark --benchmark-secs 120 --threads 16 < /dev/null >> $O/cpu120.log 2>&1
echo "# $(date -u +%FT%TZ) gpu 300 + dmon" > $O/gpu300.log
nvidia-smi dmon -s um -d 2 -o T > $O/dmon300.log 2>&1 &
DM=$!
RUST_LOG=info $B detailed --gpu --benchmark --benchmark-secs 300 < /dev/null >> $O/gpu300.log 2>&1
kill $DM
nvidia-smi -q -d CLOCK,POWER,PERFORMANCE > $O/nvidia_smi_q_after.txt 2>&1
echo "# done $(date -u +%FT%TZ)" >> $O/gpu300.log
