#!/bin/sh
# chain_A2.sh: supplementary A at b62 1e17 on the heavy field 0.45 (the 0.35 field of chain_A is empty at 1e17):
# M, T250, T251, 3 rounds, order rotated.
W=/tmp/claude-exp-2026-11-11-amd; . $W/scripts/lists.sh; O=$W/out
one() { n=$1; shift; NICE_TEST_JOIN_LIST=$L sh $W/scripts/wrun.sh $n "$@"; echo "$(date -u +%T) $n $(grep -h 'JOIN THROUGHPUT' $O/$n.log | grep -o 'base=[0-9]*\|secs=[0-9.]*\|survivors=[0-9]*\|checked=[0-9]*\|slots=[0-9]*' | tr '\n' ' ')"; }
for r in 1 2 3; do
  case $r in 1) T="M T250 T251";; 2) T="T250 T251 M";; 3) T="T251 M T250";; esac
  for t in $T; do [ -e $W/stop ] && exit 0; L=$B62H one a_${t}_b62h_r$r $t 62 1 1e17; done
done
echo A2_DONE $(date -u +%T)
