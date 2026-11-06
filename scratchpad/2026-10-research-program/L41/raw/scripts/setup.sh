#!/bin/bash
# setup.sh: trees (B = the base 7832f89 = fork pr/join-top-record), box facts.
set -x
L=/root/l41/logs; mkdir -p $L /root/l41/bin /root/l41/src /root/l41/sass
cd /root/nice
git fetch -q origin pr/join-top-record
git worktree add -q --detach /root/l41/src/B 7832f89
for t in B; do (cd /root/l41/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs) $(date -u +%T)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi --query-gpu=name,vbios_version,driver_version --format=csv ) > $L/box-info.txt 2>&1
