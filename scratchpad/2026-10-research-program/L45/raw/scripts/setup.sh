#!/bin/bash
# setup.sh: tree E = fork exp/join-l45-measure (#246 f3fb390 + profile + L45 switches); box facts.
set -x
L=/root/l45/logs; mkdir -p $L /root/l45/bin /root/l45/src /root/l45/run /root/l45/ptx
cd /root/nice
git fetch -q origin exp/join-l45-measure pr/join-lean-prefilter
git worktree add -q --detach /root/l45/src/E origin/exp/join-l45-measure
(cd /root/l45/src/E && echo "E $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version ) > $L/box-info.txt 2>&1
