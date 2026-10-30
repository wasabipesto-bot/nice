#!/bin/bash
# Replaces chain4.sh after the counters: the 1e14 A/B with the 64 cap, the
# race runs, then the rest with the final PR binary.
cd /root
until grep -q COUNTERS_DONE /root/logs/counters.out 2>/dev/null && [ -f /root/bin/pr64/nice_common_test ]; do sleep 10; done
./ab14b.sh > /root/logs/ab14b.out 2>&1
./race2.sh > /root/logs/race2.out 2>&1
./ab16.sh B10 3 > /root/logs/ab16_B10.out 2>&1
./nicemark.sh > /root/logs/nicemark.out 2>&1
./ab16.sh B20 2 > /root/logs/ab16_B20.out 2>&1
./exact.sh pr > /root/logs/exact_pr.out 2>&1
echo CHAIN_DONE $(date -u +%T) > /root/logs/chain.done
