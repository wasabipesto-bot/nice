#!/bin/bash
# Partitions per launch swept on the experiment binary (PR + counters,
# NICE_EXP_SLOTS caps the plan), 1e14, 20 fields per base, this card's own
# budget (so every cap up to ~175 fits), 2 rounds interleaved.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
[ -n "$NOWAIT" ] || until grep -q RACE_DONE /root/logs/race.out 2>/dev/null; do sleep 15; done
for r in 1 2; do
  for s in 16 32 64 96 128 max; do
    tag=sweep_s${s}_r$r
    if [ $s = max ]; then se=NICE_EXP_NONE=1; else se=NICE_EXP_SLOTS=$s; fi
    echo "== $(date -u +%T) $tag"
    /root/run.sh /root/bin/exp $tag 1e14 20 $se
    /root/summ.sh /root/logs/$tag.log
  done
done
echo SWEEP_DONE $(date -u +%T)
