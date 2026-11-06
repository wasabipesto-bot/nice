#!/bin/bash
# setup.sh: fetch the base (fork pr/join-top-record 7832f89), tree B, box facts.
set -x
L=/root/l43/logs; mkdir -p $L /root/l43/bin /root/l43/src /root/l43/sass
cd /root/nice
git fetch -q origin pr/join-top-record
git worktree add -q --detach /root/l43/src/B 7832f89d
for t in B; do (cd /root/l43/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; nvcc --version ) > $L/box-info.txt 2>&1
