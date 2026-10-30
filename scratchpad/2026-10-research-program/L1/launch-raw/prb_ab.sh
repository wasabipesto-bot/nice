#!/bin/bash
# The barrier's cost without instrumentation: the PR against the PR with
# the barrier (rp/launch-with-barrier), 10 GB budget. 1e14: 2 rounds
# interleaved; 1e16: 1 round.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
B10=NICE_TEST_JOIN_MAX_BUFFER=2684354560
for r in 2 3; do
  for t in pr prb; do
    echo "== $(date -u +%T) e14 round=$r tree=$t"
    /root/run.sh /root/bin/$t g14_B10_${t}_r$r 1e14 20 $B10
    /root/summ.sh /root/logs/g14_B10_${t}_r$r.log
  done
done
for t in pr prb; do
  echo "== $(date -u +%T) e16 tree=$t"
  /root/run.sh /root/bin/$t g16_B10_${t}_r1 1e16 2 $B10
  /root/summ.sh /root/logs/g16_B10_${t}_r1.log
done
echo PRB_DONE $(date -u +%T)
