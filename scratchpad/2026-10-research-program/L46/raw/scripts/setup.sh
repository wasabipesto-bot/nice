#!/bin/bash
# setup.sh: trees B = fork pr/join-lean-prefilter f3fb390 (base), S = fork exp/join-static-buckets (this lead); box facts.
set -x
L=/root/l46/logs; mkdir -p $L /root/l46/bin /root/l46/src /root/l46/run /root/l46/ptx
cd /root/nice
git fetch -q origin pr/join-lean-prefilter
git worktree add -q --detach /root/l46/src/B f3fb390c
(cd /root/l46/src/B && echo "B $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version ) > $L/box-info.txt 2>&1
