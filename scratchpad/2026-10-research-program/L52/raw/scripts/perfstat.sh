#!/bin/bash
# perf stat (counting, 1 thread, 4 sampled partitions; events from 3.5 s on,
# past the ~2.8 s slice setup) for #248's head (base) and this branch (pr),
# alternating, 2 rounds. Per partition = count x (ms/partition) / task-clock.
WT=/home/claude/projects/nice/.worktrees/l52-two-pass-scan
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L52/raw
O=$R/perfstat-runs.txt
load1() { cut -d' ' -f1 /proc/loadavg; }
for r in 1 2; do
  if (( r % 2 == 1 )); then ORDER="base pr"; else ORDER="pr base"; fi
  for sh in "b60e16|60 1157209632114824200908 1e16 1 4" "b62e17s0|62 4473066762334864396992 1e17 1 4 0"; do
    name=${sh%%|*}; args=${sh#*|}
    for bin in $ORDER; do
      for i in $(seq 1 36); do awk -v l="$(load1)" 'BEGIN{exit !(l <= 1.5)}' && break; sleep 5; done
      echo "### $(date -u +%H:%M:%S) r$r perfstat $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $O
      nice -n 19 perf stat -D 3500 -e cycles,instructions,branches,branch-misses,task-clock -x, -o $O.tmp -- $WT/bin/$bin/l52_ab $args >> $O 2>&1
      cat $O.tmp >> $O; rm -f $O.tmp
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $O
