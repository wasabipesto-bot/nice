#!/bin/bash
# setup.sh: tree B = 87958fd (#249 head, fork pr/join-static-buckets); box facts. Tree N added by addtree.sh.
set -x
L=/root/l53/logs; mkdir -p $L /root/l53/bin /root/l53/src /root/l53/run /root/l53/ptx
cd /root/nice
git fetch -q origin pr/join-static-buckets
git worktree add -q --detach /root/l53/src/B 87958fd
(cd /root/l53/src/B && echo "B $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") >> $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi -q | grep -i -E "serial|vbios|bus id"; uptime ) > $L/box-info.txt 2>&1
