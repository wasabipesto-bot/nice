#!/bin/bash
# after_X.sh: after chain_X: FD at b64 on the 1e17 fields at 0.05 + 0.55, rounds 2-3 (off/on alternated), tree SF.
cd /root/b64
until grep -q X_DONE logs/chain_X.out 2>/dev/null; do sleep 15; done
[ -e logs/stop ] && exit 0
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
IFS=, read -ra A <<< "$L64"
{
echo F2_START $(date -u +%T)
for r in 2 3; do
  if [ $r = 2 ]; then O="on off"; else O="off on"; fi
  for o in $O; do
    [ -e $L/stop ] && exit 0
    unset NICE_EXP_FD_POW2; [ $o = on ] && export NICE_EXP_FD_POW2=1
    export NICE_TEST_JOIN_LIST=${A[0]},${A[5]}
    n=f_${o}_e17_r$r; $R $n SF 64 2 1e17; bash /root/b64/scripts/jit.sh $n
    echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1)"
  done
done
echo F2_DONE $(date -u +%T)
} > $L/chain_F2.out 2>&1
