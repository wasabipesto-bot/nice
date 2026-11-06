#!/bin/bash
# chain_screen.sh W: one binary, NICE_EXP_JOIN_WB = 0 (base kernel), 1 TT, 2 WH, 4 AU, 8 PC, 15 all; b62 1e17 (1 field)
# and b60 1e16 (2 fields), 2 interleaved rounds (round 2 in reverse order), nothing else on the box.
R=/root/l43/run.sh; L=/root/l43/logs; W=$1
until [ -e $L/screen_go ]; do sleep 10; done
echo SCREEN_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 2 ]; then O=${O2:-"15 8 4 2 1 0"}; else O=${O1:-"0 1 2 4 8 15"}; fi
  for v in $O; do NICE_EXP_JOIN_WB=$v SRCD=$W $R scr_wb${v}_e17_b62_r$r $W 62 1 1e17; done
  for v in $O; do NICE_EXP_JOIN_WB=$v SRCD=$W $R scr_wb${v}_e16_b60_r$r $W 60 2 1e16; done
done
echo SCREEN_DONE $(date -u +%T) > $L/screen.done
