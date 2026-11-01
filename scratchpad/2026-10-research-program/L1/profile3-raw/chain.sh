#!/bin/bash
# Round 1: b62 1e17 (1 field) unprofiled, profiled; then 1e16 b62 (2), b60 (2), b64 (1) profiled and unprofiled.
# Round 2 in reverse order.
R=/root/run.sh
echo CHAIN_START $(date -u +%T)
$R e17_b62_noprof_r1 62 1 1e17 0
$R e17_b62_prof_r1 62 1 1e17 1
$R e16_b62_prof_r1 62 2 1e16 1
$R e16_b62_noprof_r1 62 2 1e16 0
$R e16_b60_prof_r1 60 2 1e16 1
$R e16_b60_noprof_r1 60 2 1e16 0
$R e16_b64_prof_r1 64 1 1e16 1
$R e16_b64_noprof_r1 64 1 1e16 0
echo ROUND1_DONE $(date -u +%T)
$R e16_b64_noprof_r2 64 1 1e16 0
$R e16_b64_prof_r2 64 1 1e16 1
$R e16_b60_noprof_r2 60 2 1e16 0
$R e16_b60_prof_r2 60 2 1e16 1
$R e16_b62_noprof_r2 62 2 1e16 0
$R e16_b62_prof_r2 62 2 1e16 1
$R e17_b62_prof_r2 62 1 1e17 1
$R e17_b62_noprof_r2 62 1 1e17 0
echo CHAIN_DONE $(date -u +%T)
