#!/bin/bash
# chain_screen.sh W: the one-binary screen of levels 0-4 (NICE_EXP_JOIN_PF) of binary W: b62 1e17 (1 field) and b60 1e16
# (2 fields), 2 rounds, order 0-4 then 4-0; then the walk counters (NICE_EXP_JOIN_ROUNDS=1: plane-rounds) at levels
# 0, 3, 4 on the same fields. Nothing else on the box.
R=/root/l41/run.sh; L=/root/l41/logs; W=$1
# Nothing else on the box: wait for the P build/registers and the mutant build.
until [ -e $L/p_P.done ] && [ -e $L/mut_built.done ]; do sleep 10; done
echo SCREEN_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 2 ]; then O="4 3 2 1 0"; else O="0 1 2 3 4"; fi
  for lv in $O; do NICE_EXP_JOIN_PF=$lv SRCD=$W $R scr_L${lv}_e17_b62_r$r $W 62 1 1e17; done
  for lv in $O; do NICE_EXP_JOIN_PF=$lv SRCD=$W $R scr_L${lv}_e16_b60_r$r $W 60 2 1e16; done
done
echo SCREEN_TIMED_DONE $(date -u +%T)
for lv in 0 4 3; do
  NICE_EXP_JOIN_ROUNDS=1 NICE_EXP_JOIN_PF=$lv SRCD=$W $R ctr_L${lv}_e17_b62 $W 62 1 1e17
  NICE_EXP_JOIN_ROUNDS=1 NICE_EXP_JOIN_PF=$lv SRCD=$W $R ctr_L${lv}_e16_b60 $W 60 2 1e16
done
echo SCREEN_DONE $(date -u +%T) > $L/screen.done
