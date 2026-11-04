#!/bin/bash
# setup.sh: remotes, trees (A = exp/join-l37-ablate = main 6f060a9 + profile + ablation switches), box facts.
set -x
L=/root/l37/logs; mkdir -p $L /root/l37/bin /root/l37/src
cd /root/nice
git remote add upstream https://github.com/wasabipesto/nice.git 2>/dev/null
git fetch -q upstream main
git fetch -q origin exp/join-l37-ablate
git worktree add -q --detach /root/l37/src/A origin/exp/join-l37-ablate
git worktree add -q --detach /root/l37/src/M 6f060a9
for t in A M; do (cd /root/l37/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; nvcc --version ) > $L/box-info.txt 2>&1
