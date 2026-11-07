#!/bin/bash
# NiceMark CPU nice-only sweep (--benchmark, no --gpu), 4 threads, 150 s
# budget, #247's head ("base") and this branch ("pr") interleaved with the
# order alternating per round. Before each run: wait (up to 6 min) for the
# 1-min load to drop to <= 2 and log it. Nothing is uploaded (the client
# does not upload without --benchmark-upload when non-interactive).
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L49/raw
AB=/home/claude/projects/nice/.worktrees/pr-cpu-join-lean/target-ab
OUT=$R/nicemark-runs.txt
ROUNDS=${ROUNDS:-4}
FIRST=${FIRST:-1}
load1() { cut -d' ' -f1 /proc/loadavg; }
for r in $(seq $FIRST $((FIRST + ROUNDS - 1))); do
  if (( r % 2 == 1 )); then ORDER="base pr"; else ORDER="pr base"; fi
  for bin in $ORDER; do
    for i in $(seq 1 72); do
      awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break
      sleep 5
    done
    l=$(load1)
    flag=OK; awk -v l="$l" 'BEGIN{exit !(l > 2.0)}' && flag=DISCARD
    echo "### r$r $bin start $(date -u +%H:%M:%S) load $(cat /proc/loadavg) $flag" >> $OUT
    nice -n 19 $AB/$bin/nice_client niceonly --benchmark --threads 4 --benchmark-secs 150 --benchmark-json \
      > $R/nicemark-r$r-$bin.json 2> $R/nicemark-r$r-$bin.stderr
    echo "### r$r $bin end $(date -u +%H:%M:%S) exit $?" >> $OUT
  done
done
echo "### done $(date -u +%H:%M:%S)" >> $OUT
