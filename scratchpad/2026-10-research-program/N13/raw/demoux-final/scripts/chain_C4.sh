#!/bin/sh
# chain_C4.sh: two more rounds of the combination tc128 + vram against base (rounds 4-5), alternating order.
W=/tmp/claude-exp-2026-11-11-amd; O=$W/out
one() { n=$1; shift; NICE_TEST_JOIN_LIST=$L sh $W/scripts/wrun.sh $n "$@"; echo "$(date -u +%T) $n $(grep -h 'JOIN THROUGHPUT' $O/$n.log | grep -o 'secs=[0-9.]*\|slots=[0-9]*\|batches=[0-9]*\|survivors=[0-9]*\|checked=[0-9]*' | tr '\n' ' ')"; }
for r in 4 5; do
  if [ $r = 4 ]; then V="tcvram base"; else V="base tcvram"; fi
  for v in $V; do
    unset NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_TCAP NICE_EXP_VRAM
    [ $v = tcvram ] && export NICE_EXP_JOIN_TCAP=128 NICE_EXP_JOIN_TMIN=96 NICE_EXP_VRAM=1
    L=7520566762397899821056 one s_${v}_b62_r$r E 62 1 1e17
    L=1447429612114824200908 one s_${v}_b60_r$r E 60 1 1e16
  done
done
echo C4_DONE $(date -u +%T)
