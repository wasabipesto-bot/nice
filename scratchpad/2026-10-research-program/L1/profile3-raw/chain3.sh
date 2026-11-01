#!/bin/bash
# Levers at b62 1e17 (unprofiled, knob binary): per-batch cost (SURV_PER_PREFIX 2 -> 1 doubles
# partitions per launch) and per-slice cost (SLICE_MULT scales the slice cap: 11 slices -> 6 / 4).
R=/root/run.sh
export BIN=/root/nice_common_x
echo CHAIN3_START $(date -u +%T)
$R x17_ctl_r1 62 1 1e17 0
NICE_EXP_SURV_PER_PREFIX=1 $R x17_spp1_r1 62 1 1e17 0
NICE_EXP_SLICE_MULT=2 $R x17_mult2_r1 62 1 1e17 0
NICE_EXP_SLICE_MULT=3 NICE_EXP_SURV_PER_PREFIX=1 $R x17_mult3spp1_r1 62 1 1e17 0
NICE_EXP_SLICE_MULT=3 NICE_EXP_SURV_PER_PREFIX=1 $R x17_mult3spp1_prof_r1 62 1 1e17 1
echo CHAIN3_DONE $(date -u +%T)
