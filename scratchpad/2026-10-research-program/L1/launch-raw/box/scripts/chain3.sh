#!/bin/bash
# Replaces chain2.sh (same steps, reordered so the counters, the
# partitions-per-launch sweep and the race runs come early).
cd /root
until grep -q AB14_DONE /root/logs/ab14.out 2>/dev/null; do sleep 10; done
./counters.sh > /root/logs/counters.out 2>&1
NOWAIT=1 ./sweep.sh > /root/logs/sweep.out 2>&1
./ab16.sh B10 3 > /root/logs/ab16_B10.out 2>&1
NOWAIT=1 ./race.sh > /root/logs/race.out 2>&1
./nicemark.sh > /root/logs/nicemark.out 2>&1
./ab16.sh B20 3 > /root/logs/ab16_B20.out 2>&1
./exact.sh pr > /root/logs/exact_pr.out 2>&1
./exact.sh main > /root/logs/exact_main.out 2>&1
echo CHAIN_DONE $(date -u +%T) > /root/logs/chain.done
