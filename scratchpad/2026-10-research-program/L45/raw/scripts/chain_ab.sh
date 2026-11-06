#!/bin/bash
# chain_ab.sh: unprofiled interleaved A/B of the stage cadence (after chain_post.sh): full (#246, mode 0) against the
# stage checked every 8 chunks (8) and once per top batch (15), 3 rounds, order rotating, b62 1e17 then b60 1e16.
R=/root/l45/run.sh; L=/root/l45/logs
until [ -e $L/post.done ] || [ -e $L/stop ]; do sleep 10; done
[ -e $L/stop ] && exit 0
echo AB_START $(date -u +%T)
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_SPILLCNT
for r in 1 2 3; do
  case $r in 1) ORDER="0:c 8:s8 15:s15";; 2) ORDER="15:s15 0:c 8:s8";; 3) ORDER="8:s8 15:s15 0:c";; esac
  for spec in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $spec
    for m in $ORDER; do
      [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
      IFS=: read abl tag <<< "$m"
      NICE_EXP_JOIN_ABL=$abl $R ab_${tag}_$4_r$r E2 $1 $2 $3
      echo "$(date -u +%T) ab_${tag}_$4_r$r $(grep -o 'device=[0-9.]*s' $L/ab_${tag}_$4_r$r.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/ab_${tag}_$4_r$r.log | tail -1)"
    done
  done
done
python3 /root/l45/ptxjit.py --only join /root/l45/ptx/ab_* > $L/ab_jit.txt 2>&1
echo AB_DONE $(date -u +%T) | tee $L/ab.done
