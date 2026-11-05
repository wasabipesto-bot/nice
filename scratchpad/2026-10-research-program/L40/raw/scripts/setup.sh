#!/bin/bash
# setup.sh: remotes, trees (M = fork pr/join-top-record af21136 = upstream main 6f060a9 + #241; C = exp/join-walk-compact
# 77241bc, L37's COMPACT=2 reference; G = the group walk, starts at af21136), box facts.
set -x
L=/root/l40/logs; mkdir -p $L /root/l40/bin /root/l40/src /root/l40/sass
cd /root/nice
git remote add upstream https://github.com/wasabipesto/nice.git 2>/dev/null
git fetch -q origin pr/join-top-record exp/join-walk-compact
git worktree add -q --detach /root/l40/src/M af21136
git worktree add -q --detach /root/l40/src/C 77241bc
git worktree add -q -b pr/join-group-walk /root/l40/src/G af21136
for t in M C G; do (cd /root/l40/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version ) > $L/box-info.txt 2>&1
