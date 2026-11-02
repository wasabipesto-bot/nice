#!/bin/bash
# After T is built and the profile is done: registers per variant, a 1e14 compare at b62 (T on vs off),
# then a quick screen at b62 1e16 (2 fields): off, G=8, G=4, G=2, G=1, off.
L=/root/l34/logs; S=/root/l34; R=$S/run.sh
until [ -e $L/t.done ]; do sleep 10; done
for g in 8 4 2 1; do $S/regs.sh T g$g NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$g; done
$S/regs.sh T off
until [ -e $L/prof.done ]; do sleep 10; done
NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=8 $R scr_cmp_g8_e14 T 62 1 1e14 1
$R scr_cmp_off_e14 T 62 1 1e14 1
$R scr_off_r1 T 62 2 1e16
for g in 8 4 2 1; do NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$g $R scr_g${g}_r1 T 62 2 1e16; done
$R scr_off_r2 T 62 2 1e16
echo SCREEN_DONE $(date -u +%T) > $L/screen.done
