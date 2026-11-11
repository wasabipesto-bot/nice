#!/bin/bash
# setup.sh: trees M = upstream/main, S = fork pr/check-d, E = fork exp/l51-profile, each + patch_harness.py; box facts.
set -x
R=/root/b64; L=$R/logs; mkdir -p $L $R/bin $R/src $R/run $R/ptx
cd /root/nice
git fetch -q origin pr/check-d exp/l51-profile; git fetch -q upstream main
git worktree add -q --detach $R/src/M upstream/main
git worktree add -q --detach $R/src/S origin/pr/check-d
git worktree add -q --detach $R/src/E origin/exp/l51-profile
for t in M S E; do python3 $R/scripts/patch_harness.py $R/src/$t; (cd $R/src/$t && echo "$t $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)"); done > $L/trees.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK > $L/power.txt
( nproc; free -g; df -h /root; lscpu | head -20; uname -a; /usr/local/cuda/bin/nvcc --version; nvidia-smi -q | grep -i -E "serial|vbios|bus id" ) > $L/box-info.txt 2>&1
