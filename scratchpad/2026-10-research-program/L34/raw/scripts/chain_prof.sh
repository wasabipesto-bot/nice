#!/bin/bash
# Baseline profile: P with NICE_EXP_GPU_PROFILE=1, b62 1e17 x1 field, b60 1e16 x2 fields.
L=/root/l34/logs; R=/root/l34/run.sh
until [ -e $L/p.done ]; do sleep 10; done
export NICE_EXP_GPU_PROFILE=1
$R prof_A_b62_e17 P 62 1 1e17
$R prof_A_b60_e16 P 60 2 1e16
echo PROF_DONE $(date -u +%T) > $L/prof.done
