#!/bin/bash
# The flush-decision race and the extra barrier's cost (trimmed race.sh):
# the experiment binary (PR + counters), NICE_EXP_FLUSH_SYNC 0 and 1
# interleaved, the 10 GB card's budget, the cap at 64 as in the PR. 1e14: 20 fields per base, 3 rounds.
# (The 1e16 cost runs inside ab16.sh B10 as its third tree.)
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
for r in 1 2 3; do
  for sync in 0 1; do
    tag=race_e14_sync${sync}_r$r
    echo "== $(date -u +%T) $tag"
    /root/run.sh /root/bin/exp $tag 1e14 20 NICE_TEST_JOIN_MAX_BUFFER=2684354560 NICE_EXP_SLOTS=64 NICE_EXP_FLUSH_SYNC=$sync
    /root/summ.sh /root/logs/$tag.log
  done
done
echo RACE_DONE $(date -u +%T)
