#!/bin/bash
# A/B: old (41b4b405) vs new (exp/cpu-top-skip) [vs old with MAX_STEPS 12],
# harness cpu2_ab (contiguous partitions of one slice on one thread, one
# scratch: the client's order). Rounds interleaved, order rotating per round.
# Before each round wait (up to 6 min) for the 1-min load <= 2; a round that
# starts above is marked HIGHLOAD. Every run under nice -n 19, one at a time.
# usage: BINS="old new" ROUNDS=6 OUT=... run_ab.sh
D=/home/claude/projects/nice/scratchpad/2026-10-research-program/CPU2/raw
BIN=$D/bin
ROUNDS=${ROUNDS:-6}
BINS=(${BINS:-old new})
OUT=${OUT:-$D/ab-runs.txt}
CASES=(
 "b60e16|60 1157209632114824200908 1e16 0 2400 32"
 "b62e17s0|62 4473066762334864396992 1e17 0 2400 32"
 "b64e17s0|64 71779931862957161709568 1e17 0 2400 12"
)
load1() { cut -d' ' -f1 /proc/loadavg; }
others() { top -b -n1 -w 200 | awk 'NR>7 && $9+0 >= 20 && $12 != "cpu2_ab" && $12 != "top" {printf "%s(%s %s%%) ", $12, $2, $9}'; }
n=${#BINS[@]}
for r in $(seq 1 $ROUNDS); do
  for i in $(seq 1 72); do
    awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break
    sleep 5
  done
  flag=OK; awk -v l="$(load1)" 'BEGIN{exit !(l > 2.0)}' && flag=HIGHLOAD
  echo "#### round $r start $(date -u +%H:%M:%S) load $(cat /proc/loadavg) $flag others: $(others)" >> $OUT
  order=()
  for k in $(seq 0 $((n-1))); do order+=(${BINS[$(( (k + r) % n ))]}); done
  for c in "${CASES[@]}"; do
    name=${c%%|*}; args=${c#*|}
    for bin in "${order[@]}"; do
      echo "### r$r $name $bin $(date -u +%H:%M:%S) load $(load1) others: $(others)" >> $OUT
      nice -n 19 $BIN/$bin $args >> $OUT 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $OUT
