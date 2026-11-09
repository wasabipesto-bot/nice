#!/bin/bash
# perf record (cycles, instructions, branch-misses; 1 thread, 2 sampled
# partitions; from 3.5 s on, past the slice setup) of 1cce00d (base) and
# this branch (pr), alternating; per-symbol shares by perfsym.py. Then perf
# stat (counting; 4 partitions, 2 rounds alternating). Data in /tmp, not kept.
WT=/home/claude/projects/nice/.worktrees/l56-seeded-check
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L56/raw
S=$R/scripts
P=/tmp/l56-wip/perf; mkdir -p $P
O=$R/perf-runs.txt
load1() { cut -d' ' -f1 /proc/loadavg; }
gate() { for i in $(seq 1 36); do awk -v l="$(load1)" 'BEGIN{exit !(l <= 1.5)}' && break; sleep 5; done; }
for sh in "b60e16|60 1157209632114824200908 1e16 1 2" "b62e17s0|62 4473066762334864396992 1e17 1 2 0"; do
  name=${sh%%|*}; args=${sh#*|}
  for bin in base pr; do
    gate
    echo "### $(date -u +%H:%M:%S) perf record $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $O
    nice -n 19 perf record -N -q -F 1999 -e cycles,instructions,branch-misses -D 3500 -o $P/$bin-$name.data -- $WT/bin/$bin/l52_ab $args >> $O 2>&1
    python3 $S/perfsym.py $P/$bin-$name.data 14 >> $O 2>&1
  done
done
O=$R/perfstat-runs.txt
for r in 1 2; do
  if (( r % 2 == 1 )); then ORDER="base pr"; else ORDER="pr base"; fi
  for sh in "b60e16|60 1157209632114824200908 1e16 1 4" "b62e17s0|62 4473066762334864396992 1e17 1 4 0"; do
    name=${sh%%|*}; args=${sh#*|}
    for bin in $ORDER; do
      gate
      echo "### $(date -u +%H:%M:%S) r$r perfstat $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $O
      nice -n 19 perf stat -D 3500 -e cycles,instructions,branches,branch-misses,task-clock -x, -o $O.tmp -- $WT/bin/$bin/l52_ab $args >> $O 2>&1
      cat $O.tmp >> $O; rm -f $O.tmp
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $O
