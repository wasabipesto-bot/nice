#!/bin/bash
# The flush-decision race at 1e16 (main's layout family) and the barrier's
# cost: the experiment binary (PR + counters), NICE_EXP_FLUSH_SYNC 0 and 1
# interleaved. Determinism: b62 1e16, 2 fields, x2 each. Cost: 1e14 and
# 1e16 at the 10 GB budget, 2 rounds.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
[ -n "$NOWAIT" ] || until [ -f /root/logs/chain.done ]; do sleep 15; done
B10=NICE_TEST_JOIN_MAX_BUFFER=2684354560
for r in 1 2; do
  for sync in 0 1; do
    tag=race_e14_sync${sync}_r$r
    echo "== $(date -u +%T) $tag"
    /root/run.sh /root/bin/exp $tag 1e14 20 $B10 NICE_EXP_FLUSH_SYNC=$sync
    /root/summ.sh /root/logs/$tag.log
  done
done
for r in 1 2; do
  for sync in 0 1; do
    tag=race_e16_sync${sync}_r$r
    echo "== $(date -u +%T) $tag"
    /root/run.sh /root/bin/exp $tag 1e16 2 $B10 NICE_EXP_FLUSH_SYNC=$sync
    /root/summ.sh /root/logs/$tag.log
  done
done
echo RACE_DONE $(date -u +%T)
