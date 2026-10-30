#!/bin/bash
# 1e16 A/B: 2 fields per base, interleaved, $2 rounds, budget $1 (B10 or B20).
# Trees: main and pr; under B10 also "barrier": the experiment binary (PR
# plus counters) at the PR's cap of 64 with NICE_EXP_FLUSH_SYNC=1, i.e. the
# PR with the flush-decision barrier.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
bud=$1; R=${2:-3}
if [ $bud = B10 ]; then e=NICE_TEST_JOIN_MAX_BUFFER=2684354560; trees="main pr barrier"; else e=NICE_TEST_JOIN_NOTHING=1; trees="main pr"; fi
for r in $(seq 1 $R); do
  for t in $trees; do
    echo "== $(date -u +%T) e16 round=$r budget=$bud tree=$t"
    if [ $t = barrier ]; then
      /root/run.sh /root/bin/exp e16_${bud}_${t}_r$r 1e16 2 $e NICE_EXP_SLOTS=64 NICE_EXP_FLUSH_SYNC=1
    else
      /root/run.sh /root/bin/$t e16_${bud}_${t}_r$r 1e16 2 $e
    fi
    /root/summ.sh /root/logs/e16_${bud}_${t}_r$r.log
  done
done
echo AB16_${bud}_DONE $(date -u +%T)
