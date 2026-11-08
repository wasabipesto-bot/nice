#!/bin/bash
# L50 chain 2: MAX_STEPS sweep (instrumented build), recording + check bench,
# in-place A/B of the two-pass scan and the seeded check.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L50/raw
WT=/home/claude/projects/nice/.worktrees/l50-cpu-roadmap
B=$WT/bin
gate() { for i in $(seq 1 30); do l=$(cut -d' ' -f1 /proc/loadavg); awk "BEGIN{exit !($l <= 1.5)}" && return; sleep 10; done; }
A60="60 1157209632114824200908 1e16"
A62="62 4473066762334864396992 1e17"
A58="58 104400216587923470200 1e15"
# The b58 NiceMark field (1e15): the instrumented split once, 1 and 4 threads.
for args in "$A58 1 32" "$A58 4 128"; do
  gate
  echo "### $(date -u +%H:%M:%S) prof b58e15 [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $R/coarse-runs.txt
  nice -n 19 $B/prof $args >> $R/coarse-runs.txt 2>&1
done
O=$R/steps-runs.txt
for round in 1 2; do
  for ms in 4 8 16 32; do
    for sh in "b60e16|$A60 1 4" "b62e17s0|$A62 1 4 0"; do
      name=${sh%%|*}; args=${sh#*|}
      gate
      echo "### $(date -u +%H:%M:%S) r$round steps $ms $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $O
      L50_MAX_STEPS=$ms nice -n 19 $B/prof $args >> $O 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $O
C=$R/check-bench.txt
mkdir -p $WT/rec
echo "### $(date -u +%H:%M:%S) record" >> $C
nice -n 19 env L50_RECORD=$WT/rec/b60e16.bin $B/prof $A60 1 1 >> $C 2>&1
nice -n 19 env L50_RECORD=$WT/rec/b62e17s0.bin $B/prof $A62 1 1 0 >> $C 2>&1
for b in "60|b60e16" "62|b62e17s0"; do
  gate
  echo "### $(date -u +%H:%M:%S) checkbench ${b#*|} load $(cut -d' ' -f1-3 /proc/loadavg)" >> $C
  nice -n 19 $B/checkbench ${b%%|*} $WT/rec/${b#*|}.bin 3 >> $C 2>&1
done
echo "#### done $(date -u +%H:%M:%S)" >> $C
X=$R/ab-runs.txt
bins=(plain scan2 check scan2check)
for round in 1 2 3; do
  if [ $((round % 2)) = 0 ]; then order=(scan2check check scan2 plain); else order=(plain scan2 check scan2check); fi
  for sh in "b60e16 1t|$A60 1 4" "b62e17s0 1t|$A62 1 4 0" "b60e16 4t|$A60 4 16" "b62e17s0 4t|$A62 4 16 0" "b58e15 1t|$A58 1 32"; do
    name=${sh%%|*}; args=${sh#*|}
    for bin in "${order[@]}"; do
      gate
      echo "### $(date -u +%H:%M:%S) r$round $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $X
      nice -n 19 $B/$bin $args >> $X 2>&1
    done
  done
done
for sh in "b60e14 4t|60 1157209632114824200908 1e14 4 0" "b62e14 4t|62 4473156762334864396992 1e14 4 0"; do
  name=${sh%%|*}; args=${sh#*|}
  for bin in plain scan2check; do
    gate
    echo "### $(date -u +%H:%M:%S) r1 $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $X
    nice -n 19 $B/$bin $args >> $X 2>&1
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $X
