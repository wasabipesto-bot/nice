#!/bin/sh
# chain_AA.sh: the A/A pair (M twice, b60 1e16 at 0.55 + 0.85), to learn the noise and the speed.
W=/tmp/claude-exp-2026-11-11-amd; . $W/scripts/lists.sh
for r in 1 2; do NICE_TEST_JOIN_LIST=$B60 sh $W/scripts/wrun.sh aa_M_b60_r$r M 60 2 1e16; grep -h "JOIN THROUGHPUT" $W/out/aa_M_b60_r$r.log | grep -o "secs=[0-9.]*\|survivors=[0-9]*\|checked=[0-9]*" | tr '\n' ' '; echo; done
echo AA_DONE $(date -u +%T)
