#!/bin/sh
# chain_A.sh: A/A pair, then A. Per round (order rotated): b62 1e17 at 0.35 + 0.55 and b60 1e16 at 0.55 + 0.85 for
# M, T250, T251; b64 1e17 and 1e16 at 0.55 for T250, T254. One process per (tree, field set); 3 rounds.
W=/tmp/claude-exp-2026-11-11-amd; . $W/scripts/lists.sh
O=$W/out
s() { grep -h "JOIN THROUGHPUT" $O/$1.log | grep -o "base=[0-9]*\|secs=[0-9.]*\|survivors=[0-9]*\|checked=[0-9]*" | tr '\n' ' '; }
one() { n=$1; shift; NICE_TEST_JOIN_LIST=$L sh $W/scripts/wrun.sh $n "$@"; echo "$(date -u +%T) $n $(s $n)"; }
echo A_START $(date -u +%T)
for r in 1 2; do L=$B60 one aa_M_b60_r$r M 60 2 1e16; done
for r in 1 2 3; do
  case $r in 1) T="M T250 T251";; 2) T="T250 T251 M";; 3) T="T251 M T250";; esac
  for t in $T; do
    [ -e $W/stop ] && exit 0
    L=$B62 one a_${t}_b62_r$r $t 62 2 1e17
    L=$B60 one a_${t}_b60_r$r $t 60 2 1e16
  done
  if [ $r = 2 ]; then U="T254 T250"; else U="T250 T254"; fi
  for t in $U; do
    [ -e $W/stop ] && exit 0
    L=$B64 one a_${t}_b64e17_r$r $t 64 1 1e17
    L=$B64 one a_${t}_b64e16_r$r $t 64 1 1e16
  done
done
echo A_DONE $(date -u +%T)
