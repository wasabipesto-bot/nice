#!/bin/bash
# chain_F.sh: the FD top kernel at b64 (tree SF = pr/check-d + harness + NICE_EXP_FD_POW2 switch). Exactness: the dense
# CPU compare on 48 partitions of the 0.05 1e16 field with FD on; 1e14 runs off/on (counts must agree). Then 3 interleaved
# rounds off/on on b64 1e16 at 0.35 + 0.55, and one round on the 1e17 field at 0.55.
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
IFS=, read -ra A <<< "$L64"
echo F_START $(date -u +%T)
NICE_EXP_FD_POW2=1 bash /root/b64/scripts/exact.sh x_SF_fd_e16 SF ${A[0]} 1e16 48
echo "$(date -u +%T) x_SF_fd_e16 $(grep -o 'survivors [0-9]* checked [0-9]*' $L/x_SF_fd_e16.log) $(grep -o 'test result: [a-z]*' $L/x_SF_fd_e16.log)"
for r in 1 2 3; do
  if [ $((r % 2)) = 1 ]; then O="off on"; else O="on off"; fi
  for o in $O; do
    [ -e $L/stop ] && exit 0
    unset NICE_EXP_FD_POW2; [ $o = on ] && export NICE_EXP_FD_POW2=1
    export NICE_TEST_JOIN_LIST=${A[3]},${A[5]}
    n=f_${o}_e16_r$r; $R $n SF 64 2 1e16; bash /root/b64/scripts/jit.sh $n
    echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1)"
  done
done
for o in off on; do
  [ -e $L/stop ] && exit 0
  unset NICE_EXP_FD_POW2; [ $o = on ] && export NICE_EXP_FD_POW2=1
  export NICE_TEST_JOIN_LIST=${A[5]}
  n=f_${o}_e17_r1; $R $n SF 64 1 1e17; bash /root/b64/scripts/jit.sh $n
  echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1)"
done
echo F_DONE $(date -u +%T)
