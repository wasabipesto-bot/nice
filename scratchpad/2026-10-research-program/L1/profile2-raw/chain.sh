#!/bin/bash
# Round 1: 1e14 x20 unprofiled, profiled; 1e16 x2 profiled, unprofiled. Then round 2 in reverse order.
R=/root/run.sh
$R e14_noprof_r1 20 1e14 0
$R e14_prof_r1 20 1e14 1
$R e16_prof_r1 2 1e16 1
$R e16_noprof_r1 2 1e16 0
echo ROUND1_DONE $(date -u +%T)
$R e16_noprof_r2 2 1e16 0
$R e16_prof_r2 2 1e16 1
$R e14_prof_r2 20 1e14 1
$R e14_noprof_r2 20 1e14 0
echo CHAIN_DONE $(date -u +%T)
