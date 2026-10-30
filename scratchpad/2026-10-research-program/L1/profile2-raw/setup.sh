#!/bin/bash
# Build the profile tree on the Vast box (run under nohup). /root/nice = rp/gpu-profile-2.
source ~/.cargo/env
mkdir -p /root/p2
cd /root/nice
git fetch -q https://github.com/wasabipesto/nice.git main && echo "upstream main: $(git rev-parse --short FETCH_HEAD)"
git fetch -q origin rp/gpu-profile-2 && git checkout -q --detach FETCH_HEAD && echo "tree: $(git log --oneline -1)"
git log --oneline -4
nvidia-smi -q -d POWER > /root/p2/power.txt
nvidia-smi > /root/p2/nvidia-smi.txt
nproc > /root/p2/nproc.txt; cat /sys/fs/cgroup/cpu.max >> /root/p2/nproc.txt; lscpu | grep 'Model name' >> /root/p2/nproc.txt
J=10  # cgroup quota 9.6 CPUs (cpu.max 960000 100000) though nproc says 80
t0=$(date +%s)
cargo test --release -j $J -p nice_common --features gpu --no-run > /root/p2/testbuild.log 2>&1 || { echo "test build FAILED"; tail -40 /root/p2/testbuild.log; exit 1; }
bin=$(grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/p2/testbuild.log | head -1)
cp /root/nice/$bin /root/nice_common_test
md5sum /root/nice_common_test
echo "built in $(( $(date +%s) - t0 )) s from $bin commit=$(git rev-parse --short HEAD)"
echo SETUP_DONE $(date -u +%T)
