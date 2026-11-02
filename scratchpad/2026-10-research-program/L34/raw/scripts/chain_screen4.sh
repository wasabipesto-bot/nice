#!/bin/bash
# Head-to-head at b62 1e16 (2 fields), 2 rounds: T3 off, T3 G=4, T2 G=4 (looped build), T3 G=2.
L=/root/l34/logs; R=/root/l34/run.sh
G4="NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4"; G2="NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=2"
for r in 1 2; do
  $R s4_t3off_r$r T3 62 2 1e16
  env $G4 $R s4_t3g4_r$r T3 62 2 1e16
  env $G4 $R s4_t2g4_r$r T2 62 2 1e16
  env $G2 $R s4_t3g2_r$r T3 62 2 1e16
done
echo SCREEN4_DONE $(date -u +%T) > $L/screen4.done
