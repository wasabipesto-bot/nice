#!/bin/bash
# setup.sh (round 2): tree S = fork pr/join-static-buckets 87958fd (#249 on #246/#241); box facts.
set -x
L=/root/l48/logs; mkdir -p $L /root/l48/bin /root/l48/src /root/l48/sass
cd /root/nice
git fetch -q origin pr/join-static-buckets
git worktree add -q --detach /root/l48/src/S 87958fd9
(cd /root/l48/src/S && echo "S $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs common/src/join_plan.rs | cut -c1-8 | tr '\n' ' ')") > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi --query-gpu=driver_version,vbios_version,memory.total --format=csv ) > $L/box-info.txt 2>&1
