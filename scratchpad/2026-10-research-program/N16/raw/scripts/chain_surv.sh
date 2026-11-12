#!/bin/sh
# chain_surv.sh (~14 min on the RX 9070 XT): survivor path and tops switches at b62 1e17, then the removal modes run
# UNPROFILED (whole-field wall time; does the clock hold?) at b60 1e16.
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
R=${ROUND:-1}
echo "SURV_START $(date -u +%T)"
for m in c wsync bal0 bal2 bal1 c2; do one $m b62 $R; done
for m in c r_p r_b r_a r_z r_s8 r_s7 r_s6 r_s5 c2 prof_c; do one $m b60 $R; done
echo "SURV_DONE $(date -u +%T)"
