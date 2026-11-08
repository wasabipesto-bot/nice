#!/bin/bash
# setup.sh: tree B = fork pr/top-fd-round2 d813aea (base); box facts. (L46's, retargeted to /root/l47.)
set -x
L=/root/l47/logs; mkdir -p $L /root/l47/bin /root/l47/src /root/l47/run /root/l47/ptx /root/l47/scripts
cd /root/nice
git fetch -q origin pr/top-fd-round2
git worktree add -q --detach /root/l47/src/B d813aea
(cd /root/l47/src/B && echo "B $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi --query-gpu=driver_version --format=csv ) > $L/box-info.txt 2>&1
