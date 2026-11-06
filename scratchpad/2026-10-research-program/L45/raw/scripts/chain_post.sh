#!/bin/bash
# chain_post.sh: after chain_main.sh: chain_sn.sh (spill vs no-spill), then one spill-count run per cadence mode
# (NICE_EXP_JOIN_SPILLCNT=1: pairs written past a full stage), profile on.
R=/root/l45/run.sh; L=/root/l45/logs
until [ -e $L/main.done ] || [ -e $L/stop ]; do sleep 10; done
[ -e $L/stop ] && exit 0
bash /root/l45/chain_sn.sh > /root/l45/chain_sn.out 2>&1
export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_SPILLCNT=1
for spec in "62 1 1e17 e17_b62 0:c 15:s15" "60 2 1e16 e16_b60 0:c 7:s7 8:s8 15:s15"; do
  set -- $spec; b=$1; n=$2; z=$3; f=$4; shift 4
  for m in "$@"; do
    [ -e $L/stop ] && exit 0
    IFS=: read abl tag <<< "$m"
    NICE_EXP_JOIN_ABL=$abl $R spc_${tag}_$f E2 $b $n $z
    echo "$(date -u +%T) spc_${tag}_$f $(grep -o 'spilled=[0-9]*' $L/spc_${tag}_$f.log | tr '\n' ' ')"
  done
done
echo POST_DONE $(date -u +%T) | tee $L/post.done
