#!/bin/bash
# setup.sh: tree E = fork exp/l51-profile (d813aea + profile + L51 switches), tree B = d813aea itself; box facts.
set -x
L=/root/l51/logs; mkdir -p $L /root/l51/bin /root/l51/src /root/l51/run /root/l51/ptx
cd /root/nice
git fetch -q origin exp/l51-profile pr/top-fd-round2
git worktree add -q --detach /root/l51/src/E origin/exp/l51-profile
git worktree add -q --detach /root/l51/src/B origin/pr/top-fd-round2
for t in E B; do (cd /root/l51/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi -q | grep -i -E "serial|vbios|bus id" ) > $L/box-info.txt 2>&1
