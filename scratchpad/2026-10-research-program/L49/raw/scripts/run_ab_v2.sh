#!/bin/bash
# Review follow-up sanity A/B: #247's head (caef70e, "base") against the
# amended branch ("pr"), 4 threads, b60 1e16 and b62 1e17 slice 0 (16
# partitions each), one round each way (base, PR; then PR, base). Before
# each pass: wait (up to 6 min) for the 1-min load to drop to <= 2 and log
# it. Then perf at 1 thread on both shapes and both binaries.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L49/raw
AB=/home/claude/projects/nice/.worktrees/pr-cpu-join-lean/target-ab
OUT=$R/ab-runs-v2.txt
CASES=(
 "b60e16_4t|60 1157209632114824200908 1e16 4 16"
 "b62e17s0_4t|62 4473066762334864396992 1e17 4 16 0"
)
load1() { cut -d' ' -f1 /proc/loadavg; }
for r in 1 2; do
  for i in $(seq 1 72); do
    awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break
    sleep 5
  done
  l=$(load1)
  flag=OK; awk -v l="$l" 'BEGIN{exit !(l > 2.0)}' && flag=DISCARD
  echo "#### round $r start $(date -u +%H:%M:%S) load $(cat /proc/loadavg) $flag" >> $OUT
  if (( r % 2 == 1 )); then ORDER="base pr"; else ORDER="pr base"; fi
  for c in "${CASES[@]}"; do
    name=${c%%|*}; args=${c#*|}
    for bin in $ORDER; do
      echo "### r$r $name $bin $(date -u +%H:%M:%S) load $(load1)" >> $OUT
      nice -n 19 $AB/$bin/l49_ab $args >> $OUT 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $OUT
P=$R/perf-runs-v2.txt
for shape in "b60e16|60 1157209632114824200908 1e16 1 4" "b62e17s0|62 4473066762334864396992 1e17 1 4 0"; do
  name=${shape%%|*}; args=${shape#*|}
  for bin in base pr; do
    for i in $(seq 1 72); do
      awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break
      sleep 5
    done
    echo "### $(date -u +%H:%M:%S) perf $name 1t $bin load $(cut -d' ' -f1 /proc/loadavg)" >> $P
    nice -n 19 perf record -q -F 1999 -D 3500 -o /tmp/l49perf.data -- $AB/$bin/l49_ab $args >> $P 2>&1
    perf report -i /tmp/l49perf.data --stdio --no-children --sort symbol 2>/dev/null | grep -v '^#' | grep -v '^$' | head -6 >> $P
    rm -f /tmp/l49perf.data
  done
done
echo "### perf done $(date -u +%H:%M:%S)" >> $P
