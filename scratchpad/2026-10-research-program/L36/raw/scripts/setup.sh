#!/bin/bash
# setup.sh: remotes, trees (M = upstream main 04693ac, S = exp/join-all5, X = exp/top-fd-ablate; PR = profile tree from a tarball), box facts.
set -x
L=/root/l36/logs; mkdir -p $L /root/l36/bin /root/l36/src
cd /root/nice
git remote add upstream https://github.com/wasabipesto/nice.git 2>/dev/null
git fetch -q upstream main
git fetch -q origin exp/join-all5 exp/top-fd-ablate
git worktree add -q --detach /root/l36/src/M 04693ac
git worktree add -q --detach /root/l36/src/S 6ddab24
git worktree add -q --detach /root/l36/src/X db32f95
for t in M S X; do (cd /root/l36/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a ) > $L/box-info.txt 2>&1
