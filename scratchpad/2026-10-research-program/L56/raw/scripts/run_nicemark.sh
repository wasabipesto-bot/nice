#!/bin/bash
# NiceMark CPU nice-only sweep (--benchmark, no --gpu), 4 threads, 150 s
# budget, 1cce00d ("base") and this branch ("pr") interleaved with the
# order alternating per round. Before each run: wait (up to 6 min) for the
# 1-min load to drop to <= 2 and log it (DISCARD above 2). Nothing is
# uploaded (the client does not upload without --benchmark-upload when
# non-interactive).
WT=/home/claude/projects/nice/.worktrees/l56-seeded-check
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L56/raw
OUT=$R/nicemark-runs.txt
ROUNDS=${ROUNDS:-4}
FIRST=${FIRST:-1}
load1() { cut -d' ' -f1 /proc/loadavg; }
others() { top -b -n1 -w 200 | awk 'NR>7 && $9+0 >= 20 && $12 != "nice_client" && $12 != "top" {printf "%s(%s %s%%) ", $12, $2, $9}'; }
for r in $(seq $FIRST $((FIRST + ROUNDS - 1))); do
  if (( r % 2 == 1 )); then ORDER="base pr"; else ORDER="pr base"; fi
  for bin in $ORDER; do
    for i in $(seq 1 72); do
      awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break
      sleep 5
    done
    l=$(load1)
    flag=OK; awk -v l="$l" 'BEGIN{exit !(l > 2.0)}' && flag=DISCARD
    echo "### r$r $bin start $(date -u +%H:%M:%S) load $(cat /proc/loadavg) $flag others: $(others)" >> $OUT
    nice -n 19 $WT/bin/$bin/nice_client niceonly --benchmark --threads 4 --benchmark-secs 150 --benchmark-json \
      > $R/nicemark-r$r-$bin.json 2> $R/nicemark-r$r-$bin.stderr
    echo "### r$r $bin end $(date -u +%H:%M:%S) exit $? load $(cat /proc/loadavg) others: $(others)" >> $OUT
  done
done
echo "### done $(date -u +%H:%M:%S)" >> $OUT
