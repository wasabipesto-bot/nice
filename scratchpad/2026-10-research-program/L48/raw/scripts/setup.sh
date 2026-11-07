#!/bin/bash
# setup.sh: tree B = fork pr/join-lean-prefilter f3fb390 (main 6f060a9 + #241 + #246); box facts; lavapipe packages.
set -x
L=/root/l48/logs; mkdir -p $L /root/l48/bin /root/l48/src /root/l48/sass
cd /root/nice
git fetch -q origin pr/join-lean-prefilter
git worktree add -q --detach /root/l48/src/B f3fb390c
(cd /root/l48/src/B && echo "B $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi --query-gpu=driver_version,vbios_version --format=csv ) > $L/box-info.txt 2>&1
