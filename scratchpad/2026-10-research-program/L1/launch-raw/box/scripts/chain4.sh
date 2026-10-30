#!/bin/bash
# Replaces chain3.sh after the sweep (chain3's counters step had a quoting
# bug: an expanded assignment ran as a command).
cd /root
until grep -q SWEEP_DONE /root/logs/sweep.out 2>/dev/null; do sleep 10; done
./counters.sh > /root/logs/counters.out 2>&1
./ab16.sh B10 3 > /root/logs/ab16_B10.out 2>&1
NOWAIT=1 ./race.sh > /root/logs/race.out 2>&1
./nicemark.sh > /root/logs/nicemark.out 2>&1
./ab16.sh B20 3 > /root/logs/ab16_B20.out 2>&1
./exact.sh pr > /root/logs/exact_pr.out 2>&1
./exact.sh main > /root/logs/exact_main.out 2>&1
echo CHAIN_DONE $(date -u +%T) > /root/logs/chain.done
