#!/bin/bash
# Profile + padding accounting (prof binary): b62 1e17 and b60 1e16, off then tail.
R=/root/run.sh; L=/root/pad; P=NICE_EXP_GPU_PROFILE=1
$R p_off_e17_b62 prof 62 1 1e17 0 $P
$R p_tail_e17_b62 prof 62 1 1e17 0 $P NICE_EXP_JOIN_TAIL=1
$R p_off_e16_b60 prof 60 2 1e16 0 $P
$R p_tail_e16_b60 prof 60 2 1e16 0 $P NICE_EXP_JOIN_TAIL=1
echo PROF1_DONE $(date -u +%T) > $L/prof1.done
