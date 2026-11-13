#!/bin/bash
# builds3.sh: after builds2, tree E at the head of exp/n21-walk-loop -> X4 (production features), Xd4 (SPIR-V dump).
W=/root/n21
until grep -q "BUILDS2_DONE" $W/out/builds2.out; do sleep 10; done
cd $W/wt/E && git fetch -q origin exp/n21-walk-loop && git checkout -q --detach origin/exp/n21-walk-loop && git log --oneline -1
JOBS=16 bash $W/scripts/build.sh E X4
TSUF=-dump JOBS=16 bash $W/scripts/build.sh E Xd4 gpu,cubecl-spirv,cubecl/spirv-dump
JOBS=16 bash $W/scripts/build.sh E X4n gpu
echo BUILDS3_DONE $(date -u +%T)
