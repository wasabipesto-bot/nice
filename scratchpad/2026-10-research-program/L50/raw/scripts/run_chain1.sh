#!/bin/bash
# L50 chain 1: coarse rdtsc split (prof build), perf of the plain build
# (cycles, instructions, branch-misses), perf of the split build (sub-phases).
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L50/raw
WT=/home/claude/projects/nice/.worktrees/l50-cpu-roadmap
B=$WT/bin
PD=$WT/perf
gate() { for i in $(seq 1 30); do l=$(cut -d' ' -f1 /proc/loadavg); awk "BEGIN{exit !($l <= 1.5)}" && return; sleep 10; done; }
shapes=(
 "b60e16|60 1157209632114824200908 1e16 1 4|60 1157209632114824200908 1e16 4 16"
 "b62e17s0|62 4473066762334864396992 1e17 1 4 0|62 4473066762334864396992 1e17 4 16 0"
 "b60e14|60 1157209632114824200908 1e14 1 0|60 1157209632114824200908 1e14 4 0"
 "b62e14|62 4473156762334864396992 1e14 1 0|62 4473156762334864396992 1e14 4 0"
)
O=$R/coarse-runs.txt
for sh in "${shapes[@]}"; do
  IFS='|' read -r name a1 a4 <<< "$sh"
  for args in "$a1" "$a4"; do
    gate
    echo "### $(date -u +%H:%M:%S) prof $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $O
    nice -n 19 $B/prof $args >> $O 2>&1
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $O
P=$R/perf-runs.txt
for sh in "${shapes[@]}"; do
  IFS='|' read -r name a1 a4 <<< "$sh"
  for th in 1 4; do
    args=$a1; [ $th = 4 ] && args=$a4
    case $name in b6?e14) D="";; *) D="-D 3500";; esac
    gate
    echo "### $(date -u +%H:%M:%S) perf plain $name ${th}t [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $P
    nice -n 19 perf record -q -F 1999 $D -e cycles -e instructions -e branch-misses -o $PD/plain-$name-${th}t.data -- $B/plain $args >> $P 2>&1
  done
done
for name in b60e16 b62e17s0; do
  for th in 1; do
    case $name in b60e16) args="60 1157209632114824200908 1e16 1 4";; *) args="62 4473066762334864396992 1e17 1 4 0";; esac
    gate
    echo "### $(date -u +%H:%M:%S) perf split $name ${th}t [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $P
    nice -n 19 perf record -q -F 1999 -D 3500 -e cycles -e instructions -e branch-misses -o $PD/split-$name-${th}t.data -- $B/split $args >> $P 2>&1
    gate
    echo "### $(date -u +%H:%M:%S) time plain $name ${th}t [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $P
    nice -n 19 $B/plain $args >> $P 2>&1
    echo "### $(date -u +%H:%M:%S) time split $name ${th}t [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $P
    nice -n 19 $B/split $args >> $P 2>&1
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $P
