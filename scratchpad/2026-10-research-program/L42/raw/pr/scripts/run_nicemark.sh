#!/bin/bash
# NiceMark CPU nice-only sweep (no --gpu), 4 threads, 150 s budget, main and
# the PR interleaved with the order alternating per round. Load logged and
# waited for as in run_ab.sh.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L42/raw/pr
AB=/home/claude/projects/nice/.worktrees/pr-cpu-join-fd/target-ab
OUT=$R/nicemark-runs.txt
ROUNDS=${ROUNDS:-4}
FIRST=${FIRST:-1}
load1() { cut -d' ' -f1 /proc/loadavg; }
for r in $(seq $FIRST $((FIRST + ROUNDS - 1))); do
  if (( r % 2 == 1 )); then ORDER="main pr"; else ORDER="pr main"; fi
  for bin in $ORDER; do
    for i in $(seq 1 72); do
      awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break
      sleep 5
    done
    l=$(load1)
    flag=OK; awk -v l="$l" 'BEGIN{exit !(l > 2.0)}' && flag=DISCARD
    echo "### r$r $bin start $(date -u +%H:%M:%S) load $(cat /proc/loadavg) $flag" >> $OUT
    nice -n 19 $AB/$bin/nice_client niceonly --threads 4 --benchmark-secs 150 --benchmark-json \
      > $R/nicemark-r$r-$bin.json 2> $R/nicemark-r$r-$bin.stderr
    echo "### r$r $bin end $(date -u +%H:%M:%S) exit $?" >> $OUT
  done
done
echo "### done $(date -u +%H:%M:%S)" >> $OUT
