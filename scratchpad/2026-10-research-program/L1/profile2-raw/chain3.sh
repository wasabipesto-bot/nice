#!/bin/bash
# EPT 1 (256-entry waves) at 1e16, bases 62 and 64 (padded/pairs 1.5 and 1.8 at EPT 2), against the
# knob binary unset; two interleaved rounds unprofiled, then EPT 1 profiled.
export BIN=/root/nice_common_test_x BASES=62,64
R=/root/run3.sh
for r in 1 2; do
  NICE_EXP_JOIN_EPT=1 $R x16_ept1_r$r 2 1e16 0
  $R x16_ctl_r$r 2 1e16 0
done
NICE_EXP_JOIN_EPT=1 $R x16_ept1_prof_r1 2 1e16 1
echo CHAIN3_DONE $(date -u +%T)
