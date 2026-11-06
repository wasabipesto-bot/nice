#!/bin/bash
# chain_sanity.sh: every mode at b62,b60 1e14 (1 field each, profile on): runs, counts, PTX cache, JIT variants.
R=/root/l45/run.sh; L=/root/l45/logs
until [ -e /root/l45/bin/E ]; do sleep 5; done
echo SAN_START $(date -u +%T)
export NICE_EXP_GPU_PROFILE=1
for m in c:0: a:1: b:2: p:3: z:4: d:0:1073741824 s7:7: s8:8: s15:15:; do
  IFS=: read tag abl tmin <<< "$m"
  if [ -n "$tmin" ]; then export NICE_EXP_JOIN_TMIN=$tmin; else unset NICE_EXP_JOIN_TMIN; fi
  NICE_EXP_JOIN_ABL=$abl $R san_${tag}_e14 E 62,60 1 1e14
  grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/san_${tag}_e14.log | sed 's/rate.*survivors/survivors/'
done
unset NICE_EXP_JOIN_TMIN
NICE_EXP_JOIN_ABL=0 NICE_EXP_JOIN_SPILLCNT=1 $R san_c_spc_e14 E 62,60 1 1e14
python3 /root/l45/ptxjit.py --only join /root/l45/ptx/san_* > $L/san_jit.txt 2>&1
python3 /root/l45/ptxjit.py /root/l45/ptx/san_c_e14 >> $L/san_jit.txt 2>&1
echo SAN_DONE $(date -u +%T) | tee $L/san.done
