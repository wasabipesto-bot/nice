#!/bin/bash
# setup.sh: trees (B = fork pr/join-top-record af21136 = upstream main 6f060a9 + #241, the base; E = the 8-word entry
# record with r0 in it; F = the 4-word entry record with r0 from bp_r), box facts.
set -x
L=/root/l39/logs; mkdir -p $L /root/l39/bin /root/l39/src /root/l39/sass
cd /root/nice
git fetch -q origin pr/join-top-record exp/join-bottom-record-r8 exp/join-bottom-record-r4
git worktree add -q --detach /root/l39/src/B af21136
git worktree add -q --detach /root/l39/src/E origin/exp/join-bottom-record-r8
git worktree add -q --detach /root/l39/src/F origin/exp/join-bottom-record-r4
for t in B E F; do (cd /root/l39/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; cat /sys/fs/cgroup/cpu.max; free -g; df -h /root; lscpu | head -20; uname -a; nvcc --version; nvidia-smi -q | grep -i "vbios\|driver version\|cuda version" ) > $L/box-info.txt 2>&1
