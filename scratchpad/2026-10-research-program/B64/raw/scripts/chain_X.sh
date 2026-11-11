#!/bin/bash
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
echo X_START $(date -u +%T)
for r in 2 3; do
  if [ $((r % 2)) = 1 ]; then T="M S"; else T="S M"; fi
  for t in $T; do
    [ -e $L/stop ] && exit 0
    export NICE_TEST_JOIN_LIST=$L64; n=a_${t}_b64_1e17_r$r
    $R $n $t 64 10 1e17; bash /root/b64/scripts/jit.sh $n
    echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1)"
  done
done
echo X_DONE $(date -u +%T)
