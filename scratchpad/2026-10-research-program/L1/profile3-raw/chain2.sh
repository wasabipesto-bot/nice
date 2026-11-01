#!/bin/bash
# The b62 1e17 field at the start of b62's live field list (first unchecked field, 2026-10-31), profiled and unprofiled.
R=/root/run2.sh
export STARTS=62:3226266762397899821056
echo CHAIN2_START $(date -u +%T)
$R e17f_b62_prof_r1 62 1 1e17 1
$R e17f_b62_noprof_r1 62 1 1e17 0
echo CHAIN2_DONE $(date -u +%T)
