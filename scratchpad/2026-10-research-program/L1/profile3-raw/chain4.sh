#!/bin/bash
# Round 2 of the levers, reverse order, bracketing chain3's control (the card drifts 1425-1510 MHz with temperature).
R=/root/run.sh
export BIN=/root/nice_common_x
echo CHAIN4_START $(date -u +%T)
NICE_EXP_SLICE_MULT=3 NICE_EXP_SURV_PER_PREFIX=1 $R x17_mult3spp1_r2 62 1 1e17 0
NICE_EXP_SURV_PER_PREFIX=1 $R x17_spp1_r2 62 1 1e17 0
$R x17_ctl_r2 62 1 1e17 0
echo CHAIN4_DONE $(date -u +%T)
