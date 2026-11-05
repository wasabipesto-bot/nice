#!/bin/bash
# chain_g.sh TREE [TAG]: after the base chain, the test binary of TREE (-> bin TAG), its registers and 1e14 counts,
# then a screen against M: b62 1e16 and b60 1e16 (2 fields each), order M TAG, nothing else on the GPU.
L=/root/l40/logs; W=$1; T=${2:-$1}
until [ -e $L/base.done ]; do sleep 5; done
/root/l40/build.sh $W $T || exit 1
/root/l40/regs.sh $T $T $W > $L/regs_$T.out 2>&1
grep join_kernel /root/l40/sass/$T/registers.txt
head -1 $L/regs_$T.out
R=/root/l40/run.sh
for f in "62 e16_b62" "60 e16_b60"; do
  set -- $f
  for t in M $T; do SRCD=$( [ $t = M ] && echo M || echo $W ) $R scr_${t}_$2 $t $1 2 1e16; grep -o 'device=[0-9.]*s\|survivors=[0-9]*\|checked=[0-9]*' $L/scr_${t}_$2.log | tr '\n' ' '; echo " $t $2"; done
done
echo CHAIN_G_DONE $T $(date -u +%T)
