#!/bin/bash
# chain_ctr14.sh: the walk counters on the 1e14 set (b57, b62; 3 fields): base (MR) and group walk (GR), modes 1-3.
L=/root/l40/logs; R=/root/l40/run.sh
for b in 57 62; do for m in 1 2 3; do for t in MR GR; do
  SRCD=$t NICE_EXP_JOIN_ROUNDS=$m $R ctr14_${t}_m${m}_e14_b$b $t $b 3 1e14
  echo "ctr14 $t mode $m b$b: $(grep -o 'survivors=[0-9]*\|device=[0-9.]*s' $L/ctr14_${t}_m${m}_e14_b$b.log | tr '\n' ' ')"
done; done; done
echo CTR14_DONE $(date -u +%T)
