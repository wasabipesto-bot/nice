#!/bin/bash
# The whole L52 measurement chain, in order: tests, perf stat, the main A/B
# (3 rounds), NiceMark (4 rounds), the 1-thread whole-field A/B (3 rounds).
S=/home/claude/projects/nice/scratchpad/2026-10-research-program/L52/raw/scripts
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L52/raw
echo "chain start $(date -u +%H:%M:%S)" >> $R/chain.log
$S/tests.sh; echo "tests done $(date -u +%H:%M:%S)" >> $R/chain.log
$S/perfstat.sh; echo "perfstat done $(date -u +%H:%M:%S)" >> $R/chain.log
CASESET=main ROUNDS=3 $S/run_ab.sh; echo "ab main done $(date -u +%H:%M:%S)" >> $R/chain.log
ROUNDS=4 $S/run_nicemark.sh; echo "nicemark done $(date -u +%H:%M:%S)" >> $R/chain.log
CASESET=whole1t ROUNDS=3 $S/run_ab.sh; echo "ab whole1t done $(date -u +%H:%M:%S)" >> $R/chain.log
