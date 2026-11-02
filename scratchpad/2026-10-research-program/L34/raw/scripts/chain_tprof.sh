#!/bin/bash
# Profile (NICE_EXP_GPU_PROFILE=1) of TP = T + the profile commits: b62 1e16 2 fields, off / G=4 / G=8 / off.
L=/root/l34/logs; R=/root/l34/run.sh
until grep -q BUILD_DONE $L/build_TP.out 2>/dev/null; do sleep 5; done
export NICE_EXP_GPU_PROFILE=1
$R tprof_off_r1 TP 62 2 1e16
NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4 $R tprof_g4_r1 TP 62 2 1e16
NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=8 $R tprof_g8_r1 TP 62 2 1e16
$R tprof_off_r2 TP 62 2 1e16
echo TPROF_DONE $(date -u +%T) > $L/tprof.done
