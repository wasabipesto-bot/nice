#!/bin/bash
# chain_fx3.sh: a third prototype field round (X4 off vs 3584, b62 1e17 and b60 1e16), then all5 (S) and main (M)
# once more at b62 1e17, to see whether the A/B's lower all5 clock persists.
L=/root/l36/logs; R=/root/l36/run_abl.sh; R0=/root/l36/run.sh
SRCD=X4 NICE_EXP_TOP_FD_ABL=0 $R fx_off_e17_b62_r3 X4 62 1 1e17
SRCD=X4 NICE_EXP_TOP_FD_ABL=3584 $R fx_on_e17_b62_r3 X4 62 1 1e17
SRCD=X4 NICE_EXP_TOP_FD_ABL=0 $R fx_off_e16_b60_r3 X4 60 2 1e16
SRCD=X4 NICE_EXP_TOP_FD_ABL=3584 $R fx_on_e16_b60_r3 X4 60 2 1e16
SRCD=S $R0 late_S_e17_b62 S 62 1 1e17
SRCD=M $R0 late_M_e17_b62 M 62 1 1e17
echo FX3_DONE $(date -u +%T) > $L/fx3.done
