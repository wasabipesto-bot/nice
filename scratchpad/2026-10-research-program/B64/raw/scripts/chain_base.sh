#!/bin/bash
# chain_base.sh: base means. Rounds of {M, S} (order alternating per round) x {b64 1e16, b64 1e17} (+ b62 1e17 in the
# rounds listed in B62ROUNDS), 10 fields at 0.05..0.95 each, one process per (tree, base, size). Unprofiled.
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
ROUNDS=${ROUNDS:-"1 2 3"}; B62ROUNDS=${B62ROUNDS:-"1"}
echo BASE_START $(date -u +%T)
for r in $ROUNDS; do
  if [ $((r % 2)) = 1 ]; then T="M S"; else T="S M"; fi
  JOBS="64:1e16"; [ "${FULL:-0}" = 1 ] && JOBS="$JOBS 64:1e17"; [[ " $B62ROUNDS " == *" $r "* ]] && JOBS="$JOBS 62:1e17"
  for j in $JOBS; do
    b=${j%%:*}; sz=${j##*:}
    for t in $T; do
      [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
      n=a_${t}_b${b}_${sz}_r$r
      if [ $b = 64 ]; then export NICE_TEST_JOIN_LIST=$L64; else export NICE_TEST_JOIN_LIST=$L62; fi
      $R $n $t $b 10 $sz
      bash /root/b64/scripts/jit.sh $n
      echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1) $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | head -1)"
    done
  done
done
echo BASE_DONE $(date -u +%T) | tee $L/base.done
