#!/bin/bash
# setup.sh: remotes, trees (M = upstream main 6f060a9, S = scalar record loads, V = vec4 record loads), box facts.
set -x
L=/root/l38/logs; mkdir -p $L /root/l38/bin /root/l38/src /root/l38/sass
cd /root/nice
git remote add upstream https://github.com/wasabipesto/nice.git 2>/dev/null
git fetch -q upstream main
git fetch -q origin exp/join-top-record-scalar exp/join-top-record-vec
git worktree add -q --detach /root/l38/src/M 6f060a9
git worktree add -q --detach /root/l38/src/S origin/exp/join-top-record-scalar
git worktree add -q --detach /root/l38/src/V origin/exp/join-top-record-vec
for t in M S V; do (cd /root/l38/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; nvcc --version ) > $L/box-info.txt 2>&1
