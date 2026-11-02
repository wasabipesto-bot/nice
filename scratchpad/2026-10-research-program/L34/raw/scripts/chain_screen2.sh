#!/bin/bash
# Attempt 2 (T2 = 4a04000): registers per config, then b62 1e16 (2 fields): off, G=4/2/8 with and without
# top ids from global (TID), and the build-only diagnostic G=16 (with/without TID), then off again.
L=/root/l34/logs; S=/root/l34; R=$S/run.sh
until grep -q BUILD_DONE $L/build_T2.out 2>/dev/null; do sleep 5; done
cfg() { case $1 in off) echo "";; g*t) echo "NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$(echo $1 | tr -dc 0-9) NICE_EXP_JOIN_TRANSPOSE_TID=1";; g*) echo "NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$(echo $1 | tr -dc 0-9)";; esac; }
for c in off g4 g2 g8 g4t g2t g8t g16 g16t; do $S/regs.sh T2 t2$c $(cfg $c); done
for c in off g4 g2 g8 g4t g2t g8t g16 g16t off; do
  n=s2_${c}_r1; [ -e $L/$n.log ] && n=s2_${c}_r2
  env $(cfg $c) $R $n T2 62 2 1e16
done
echo SCREEN2_DONE $(date -u +%T) > $L/screen2.done
