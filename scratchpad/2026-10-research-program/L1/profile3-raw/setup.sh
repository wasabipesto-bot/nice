#!/bin/bash
# Build the profile tree on the Vast box (run under nohup). /root/nice = fork clone; tree = rp/gpu-profile-3.
source ~/.cargo/env
mkdir -p /root/p3
cd /root/nice
git fetch -q https://github.com/wasabipesto/nice.git main && echo "upstream main: $(git rev-parse --short FETCH_HEAD)"
git fetch -q origin rp/gpu-profile-3 && git checkout -q --detach FETCH_HEAD && echo "tree: $(git log --oneline -1)"
git log --oneline -4
nvidia-smi -q -d POWER > /root/p3/power.txt
nvidia-smi -q -d CLOCK > /root/p3/clocks.txt
nvidia-smi > /root/p3/nvidia-smi.txt
nproc > /root/p3/nproc.txt; cat /sys/fs/cgroup/cpu.max >> /root/p3/nproc.txt; lscpu | grep 'Model name' >> /root/p3/nproc.txt; free -g >> /root/p3/nproc.txt
J=10  # cgroup quota 9.6 CPUs (cpu.max 960000 100000) though nproc says 40
t0=$(date +%s)
cargo test --release -j $J -p nice_common --features gpu --no-run > /root/p3/testbuild.log 2>&1 || { echo "test build FAILED"; tail -40 /root/p3/testbuild.log; exit 1; }
bin=$(grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/p3/testbuild.log | head -1)
cp /root/nice/$bin /root/nice_common_test
md5sum /root/nice_common_test
echo "built in $(( $(date +%s) - t0 )) s from $bin commit=$(git rev-parse --short HEAD)"
echo SETUP_DONE $(date -u +%T)
