#!/bin/bash
# chain_w.sh REF NAME: tree NAME at the fork's REF, its test binary, and registers/SASS for each NICE_EXP_JOIN_WB
# value (0 = base kernel, 1 TT, 2 WH, 4 AU, 8 PC, 15 all) on the b62/b60/b64 1e14 fields.
L=/root/l43/logs; REF=$1; W=$2
until [ -e $L/base.done ]; do sleep 10; done
/root/l43/tree.sh $W $REF
/root/l43/build.sh $W $W || exit 1
for wb in ${WBS:-0 1 2 4 8 15}; do NICE_EXP_JOIN_WB=$wb /root/l43/regs.sh $W ${W}_wb$wb $W > $L/regs_${W}_wb$wb.out 2>&1; done
echo CHAIN_W_DONE $W $(date -u +%T) > $L/w_$W.done
