#!/bin/bash
# A/B of main (6f060a9) against the PR on ivory: harness l42_ab (public API:
# sampled partitions of one slice through CpuJoin::run_partition), two
# binaries, rounds interleaved with the order alternating per round.
# Before each round: wait (up to 6 min) for the 1-min load to drop to <= 2
# and log it; a round that starts above 2 is marked DISCARD.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L42/raw/pr
AB=/home/claude/projects/nice/.worktrees/pr-cpu-join-fd/target-ab
OUT=$R/ab-runs.txt
ROUNDS=${ROUNDS:-3}
FIRST=${FIRST:-1}
CASES=(
 "b60e16_1t|60 1157209632114824200908 1e16 1 4"
 "b62e17s0_1t|62 4473066762334864396992 1e17 1 4 0"
 "b60e14_1t|60 1157209632114824200908 1e14 1 0"
 "b62e14_1t|62 4473156762334864396992 1e14 1 0"
 "b60e16_4t|60 1157209632114824200908 1e16 4 16"
 "b62e17s0_4t|62 4473066762334864396992 1e17 4 16 0"
 "b60e14_4t|60 1157209632114824200908 1e14 4 0"
 "b62e14_4t|62 4473156762334864396992 1e14 4 0"
)
load1() { cut -d' ' -f1 /proc/loadavg; }
for r in $(seq $FIRST $((FIRST + ROUNDS - 1))); do
  for i in $(seq 1 72); do
    awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break
    sleep 5
  done
  l=$(load1)
  flag=OK; awk -v l="$l" 'BEGIN{exit !(l > 2.0)}' && flag=DISCARD
  echo "#### round $r start $(date -u +%H:%M:%S) load $(cat /proc/loadavg) $flag" >> $OUT
  if (( r % 2 == 1 )); then ORDER="main pr"; else ORDER="pr main"; fi
  for c in "${CASES[@]}"; do
    name=${c%%|*}; args=${c#*|}
    for bin in $ORDER; do
      echo "### r$r $name $bin $(date -u +%H:%M:%S) load $(load1)" >> $OUT
      nice -n 19 $AB/$bin/l42_ab $args >> $OUT 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $OUT
