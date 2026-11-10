#!/bin/bash
# setup.sh: trees E = fork exp/l51-profile 14f87cd (L51's profile + ablation modes on d813aea; its join_kernel is
# byte-identical to upstream main c0c357a's), T = upstream/main c0c357a + the N1 tile harness (files copied in).
set -x
L=/root/n1/logs; mkdir -p $L /root/n1/bin /root/n1/src /root/n1/run /root/n1/ptx
cd /root/nice
git fetch -q origin exp/l51-profile
git worktree add -q --detach /root/n1/src/E 14f87cd
git worktree add -q -B exp/n1-gpu-tile /root/n1/src/T c0c357a
for t in E T; do (cd /root/n1/src/$t && echo "$t $(git log --oneline -1)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi -q | grep -i -E "serial|vbios|bus id"; source ~/.cargo/env; rustc --version; cargo --version ) > $L/box-info.txt 2>&1
