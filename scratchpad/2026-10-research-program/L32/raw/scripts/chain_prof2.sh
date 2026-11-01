#!/bin/bash
# More profile + accounting: b62 1e16 (2 fields) and b64 1e16 (1 field), off then tail; EPT 1 accounting at b62 1e16.
R=/root/run.sh; L=/root/pad; P=NICE_EXP_GPU_PROFILE=1
$R p_off_e16_b62 prof 62 2 1e16 0 $P
$R p_tail_e16_b62 prof 62 2 1e16 0 $P NICE_EXP_JOIN_TAIL=1
$R p_off_e16_b64 prof 64 1 1e16 0 $P
$R p_tail_e16_b64 prof 64 1 1e16 0 $P NICE_EXP_JOIN_TAIL=1
echo PROF2_DONE $(date -u +%T) > $L/prof2.done
