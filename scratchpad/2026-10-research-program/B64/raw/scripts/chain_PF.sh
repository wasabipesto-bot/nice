#!/bin/bash
# chain_PF.sh: tree EF (E + patchF) profiled (mode c) with the FD top kernel on at b64 and off, b64 1e16 at 0.05, 0.35,
# 0.55 and the 1e17 field at 0.55; order on, off.
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
IFS=, read -ra A <<< "$L64"
echo PF_START $(date -u +%T)
export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0
for o in on off; do
  unset NICE_EXP_FD_POW2; [ $o = on ] && export NICE_EXP_FD_POW2=1
  export NICE_TEST_JOIN_LIST=${A[0]},${A[3]},${A[5]}
  n=pf_${o}_e16; $R $n EF 64 3 1e16; bash /root/b64/scripts/jit.sh $n
  echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1)"
  export NICE_TEST_JOIN_LIST=${A[5]}
  n=pf_${o}_e17; $R $n EF 64 1 1e17; bash /root/b64/scripts/jit.sh $n
  echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1)"
done
echo PF_DONE $(date -u +%T)
