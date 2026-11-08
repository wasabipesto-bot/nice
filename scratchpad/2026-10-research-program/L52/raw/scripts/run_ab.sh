#!/bin/bash
# A/B of #248's head (7f5260b, "base") against this branch ("pr"): harness
# l52_ab (sampled partitions of one slice, NiceMark's bit-reversed order,
# through CpuJoin::run_partition; public API only), two release binaries,
# rounds interleaved with the order alternating per round. Before each
# round: wait (up to 6 min) for the 1-min load to drop to <= 2; a round that
# starts above 2 is marked DISCARD. Each run logs the load and the busiest
# processes that are not this harness. Every run under nice -n 19.
# usage: CASESET=main|whole1t ROUNDS=3 FIRST=1 run_ab.sh
WT=/home/claude/projects/nice/.worktrees/l52-two-pass-scan
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L52/raw
ROUNDS=${ROUNDS:-3}
FIRST=${FIRST:-1}
CASESET=${CASESET:-main}
if [ "$CASESET" = main ]; then
  OUT=$R/ab-runs.txt
  CASES=(
   "b60e16_1t|60 1157209632114824200908 1e16 1 4"
   "b62e17s0_1t|62 4473066762334864396992 1e17 1 4 0"
   "b60e16_4t|60 1157209632114824200908 1e16 4 16"
   "b62e17s0_4t|62 4473066762334864396992 1e17 4 16 0"
   "b58e15_1t|58 104400216587923470200 1e15 1 32"
   "b58e15_4t|58 104400216587923470200 1e15 4 128"
   "b60e14_4t|60 1157209632114824200908 1e14 4 0"
   "b62e14_4t|62 4473156762334864396992 1e14 4 0"
   "b64e14_4t|64 41242006262957161709568 1e14 4 0"
  )
else
  OUT=$R/ab-runs-whole1t.txt
  CASES=(
   "b60e14_1t|60 1157209632114824200908 1e14 1 0"
   "b62e14_1t|62 4473156762334864396992 1e14 1 0"
   "b64e14_1t|64 41242006262957161709568 1e14 1 0"
  )
fi
load1() { cut -d' ' -f1 /proc/loadavg; }
others() { top -b -n1 -w 200 | awk 'NR>7 && $9+0 >= 20 && $12 != "l52_ab" && $12 != "top" {printf "%s(%s %s%%) ", $12, $2, $9}'; }
for r in $(seq $FIRST $((FIRST + ROUNDS - 1))); do
  for i in $(seq 1 72); do
    awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break
    sleep 5
  done
  l=$(load1)
  flag=OK; awk -v l="$l" 'BEGIN{exit !(l > 2.0)}' && flag=DISCARD
  echo "#### round $r start $(date -u +%H:%M:%S) load $(cat /proc/loadavg) $flag others: $(others)" >> $OUT
  if (( r % 2 == 1 )); then ORDER="base pr"; else ORDER="pr base"; fi
  for c in "${CASES[@]}"; do
    name=${c%%|*}; args=${c#*|}
    for bin in $ORDER; do
      echo "### r$r $name $bin $(date -u +%H:%M:%S) load $(load1) others: $(others)" >> $OUT
      nice -n 19 $WT/bin/$bin/l52_ab $args >> $OUT 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $OUT
