#!/bin/bash
# Interleaved A/B of the real client: for each round, for each case, both
# binaries back to back, the order alternating per round (and per case).
# Usage: ab.sh <rounds> <first-round> <case>...   case = tag:base:start:size:threads:slices:parts
R=$1; F=$2; shift 2
LOG=/root/out/ab.log
for r in $(seq $F $((F + R - 1))); do
  i=0
  for c in "$@"; do
    IFS=: read tag b s sz t sl pa <<< "$c"
    if (( (r + i) % 2 == 1 )); then ORDER="main br"; else ORDER="br main"; fi
    for bin in $ORDER; do
      echo "start r$r $tag $bin $(date -u +%H:%M:%S) load $(cat /proc/loadavg)" >> $LOG
      /root/run_one.sh $bin r$r-$tag $b $s $sz $t "$sl" "$pa"
      echo "end r$r $tag $bin $(date -u +%H:%M:%S)" >> $LOG
    done
    i=$((i + 1))
  done
done
echo "done $(date -u +%H:%M:%S)" >> $LOG
