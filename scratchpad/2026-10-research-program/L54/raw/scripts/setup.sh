#!/bin/bash
# setup.sh: trees B = fork pr/top-fd-round2 (d813aea), X = fork exp/join-and-codegen (worktrees of /root/nice); box facts.
set -x
L=/root/l54/logs; mkdir -p $L /root/l54/bin /root/l54/src /root/l54/run /root/l54/ptx /root/l54/sass /root/l54/cu
cd /root/nice
git fetch -q origin pr/top-fd-round2 exp/join-and-codegen
git worktree add -q --detach /root/l54/src/B origin/pr/top-fd-round2
git worktree add -q -B exp/join-and-codegen /root/l54/src/X origin/exp/join-and-codegen
for t in B X; do (cd /root/l54/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi -q | grep -i -E "serial|vbios|bus id"; source ~/.cargo/env; rustc --version; cargo --version ) > $L/box-info.txt 2>&1
