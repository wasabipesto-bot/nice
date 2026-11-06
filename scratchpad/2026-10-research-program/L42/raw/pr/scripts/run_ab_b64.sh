#!/bin/bash
# b64 A/B (review follow-up): main (6f060a9) vs the amended PR, harness
# l42_ab, rounds interleaved with the order alternating per round; before
# each round wait (up to 6 min) for the 1-min load to drop to <= 2 and log
# it; a round that starts above 2 is marked DISCARD.
# and log it; a round that starts above 2 is marked DISCARD.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L42/raw/pr
AB=/home/claude/projects/nice/.worktrees/pr-cpu-join-fd/target-ab
OUT=$R/ab-runs-b64.txt
ROUNDS=${ROUNDS:-3}
FIRST=${FIRST:-1}
CASES=(
 "b64e16_1t|64 41242006262957161709568 1e16 1 4"
 "b64e16_4t|64 41242006262957161709568 1e16 4 16"
 "b64e14_4t|64 41242006262957161709568 1e14 4 0"
 "b64e14_1t|64 41242006262957161709568 1e14 1 0"
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
