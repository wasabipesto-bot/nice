#!/bin/bash
# chain_bfreq.sh BIN TAG N: N processes of BIN at 1e14 (b62 then b60, one field each), each with its own fresh PTX cache,
# then every process's join kernels through the driver's JIT: how often the compile lands on each register variant.
# The process's NICE_EXP_* environment passes through.
R=/root/l54/run.sh; L=/root/l54/logs; BIN=$1; TAG=$2; N=${3:-16}
for i in $(seq 1 $N); do
  [ -e $L/stop ] && exit 0
  nm=bf_${TAG}; [ $N -gt 1 ] && nm=bf_${TAG}_$i
  $R $nm $BIN 62,60 1 1e14
  python3 /root/l54/ptxjit.py --only join /root/l54/ptx/$nm > $L/${nm}_jit.txt 2>&1
  echo "$nm $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$nm.log | tr '\n' ' ') $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${nm}_jit.txt | tr '\n' ' ')"
done
echo BFREQ_DONE $TAG $(date -u +%T)
