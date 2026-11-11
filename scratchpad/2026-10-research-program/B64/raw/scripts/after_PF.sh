#!/bin/bash
# after_PF.sh: after chain_PF: b64 1e17 base-mean round 4 of S then M (S's round 2 ran its fields 1-6 at half speed
# with the card at full power and clock: a disturbance outside this container).
cd /root/b64
until grep -q PF_DONE logs/chain_PF.out 2>/dev/null; do sleep 15; done
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
{
echo X4_START $(date -u +%T)
for t in S M; do
  [ -e $L/stop ] && exit 0
  export NICE_TEST_JOIN_LIST=$L64; n=a_${t}_b64_1e17_r4
  $R $n $t 64 10 1e17; bash /root/b64/scripts/jit.sh $n
  echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1)"
done
echo X4_DONE $(date -u +%T)
} > $L/chain_X4.out 2>&1
