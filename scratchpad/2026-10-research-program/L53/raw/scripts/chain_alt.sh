#!/bin/bash
# chain_alt.sh: in-process A/B (binary Y = the commit + patch53y.py, NICE_EXP_L53_ALT=1): the same field repeated (NICE_EXP_L53_REPEAT=1), alternating between
# 87958fd's path (old: the sort on the device thread) and the commit's (new), one process per base, nvidia-smi every 1 s.
R=/root/l53/run1.sh; L=/root/l53/logs
export NICE_EXP_L53_ALT=1 NICE_EXP_L53_REPEAT=1
echo ALT_START $(date -u +%T)
for f in "62 21 1e16 e16_b62" "60 13 1e16 e16_b60" "62 7 1e17 e17_b62" "64 9 1e16 e16_b64"; do
  set -- $f
  n=alt_$4
  [ -e $L/stop ] && exit 0
  $R $n Y $1 $2 $3
  nice -n 19 python3 /root/l53/ptxjit.py --only join /root/l53/ptx/$n > $L/${n}_jit.txt 2>&1
  echo "$(date -u +%T) $n $(grep -o 'per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1) $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | tail -1) old=$(grep -c 'mode=old' $L/$n.log) new=$(grep -c 'mode=new' $L/$n.log)"
done
echo ALT_DONE $(date -u +%T) | tee $L/alt.done
