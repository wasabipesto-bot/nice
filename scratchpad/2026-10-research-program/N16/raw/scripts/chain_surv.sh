#!/bin/sh
# chain_surv.sh (~14 min on the RX 9070 XT): survivor path and tops switches at b62 1e17, then the removal modes run
# UNPROFILED (whole-field wall time; does the clock hold?) at b60 1e16.
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
# S62 / S60 override the lists (the box's lavapipe check runs shortened ones).
R=${ROUND:-1}; PFX=${PFX0:-}sv-
echo "SURV_START $(date -u +%T)"
# bal0 (scans) is the default on a 64-lane device and bal1 drops lanes 32-63 there, so the card runs bal2 only.
for m in ${S62-c wsync bal2 c2}; do one $m b62 $R; done
for m in ${S60-c r_p r_b r_a r_z r_s8 r_s7 r_s6 r_s5 c2 prof_c}; do one $m b60 $R; done
echo "SURV_DONE $(date -u +%T)"
