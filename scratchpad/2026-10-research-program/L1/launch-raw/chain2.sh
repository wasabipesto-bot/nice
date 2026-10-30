#!/bin/bash
# Replaces chain.sh after the 1e14 A/B (chain.sh started before the
# experiment binary was staged, so its counters step found no binary).
cd /root
until grep -q AB14_DONE /root/logs/ab14.out 2>/dev/null; do sleep 10; done
./counters.sh > /root/logs/counters.out 2>&1
./ab16.sh B10 3 > /root/logs/ab16_B10.out 2>&1
./ab16.sh B20 3 > /root/logs/ab16_B20.out 2>&1
./nicemark.sh > /root/logs/nicemark.out 2>&1
./exact.sh pr > /root/logs/exact_pr.out 2>&1
./exact.sh main > /root/logs/exact_main.out 2>&1
echo CHAIN_DONE $(date -u +%T) > /root/logs/chain.done
