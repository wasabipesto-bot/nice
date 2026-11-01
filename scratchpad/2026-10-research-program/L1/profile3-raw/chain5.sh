#!/bin/bash
# Round 3 of the levers: the control drifts ~3 % between runs beyond the clock, so more interleaved rounds.
R=/root/run.sh
export BIN=/root/nice_common_x
echo CHAIN5_START $(date -u +%T)
$R x17_ctl_r3 62 1 1e17 0
NICE_EXP_SURV_PER_PREFIX=1 $R x17_spp1_r3 62 1 1e17 0
NICE_EXP_SLICE_MULT=3 NICE_EXP_SURV_PER_PREFIX=1 $R x17_mult3spp1_r3 62 1 1e17 0
$R x17_ctl_r4 62 1 1e17 0
echo CHAIN5_DONE $(date -u +%T)
