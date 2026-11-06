#!/bin/bash
# chain_regs19.sh: after the A/B: registers/SASS of W3 with WB 19 (TT2 + WH, the A/B's combination), 17 and 2.
L=/root/l43/logs
until [ -e $L/ab.done ]; do sleep 10; done
for wb in 19 17 2 1 8; do NICE_EXP_JOIN_WB=$wb /root/l43/regs.sh W3 W3_wb$wb W3 > $L/regs_W3_wb$wb.out 2>&1; done
echo REGS19_DONE $(date -u +%T) > $L/regs19.done
