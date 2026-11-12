#!/bin/sh
# chain_must.sh: the window's must-have (~31 min on the RX 9070 XT): the corrected profile by DOUBLING, unprofiled, at
# b62 1e17 (0.45) with three base runs spread through it, then b64 1e17 (0.55) with two. ROUND=1 (default) or 2
# (round 2 runs each list reversed). The first base run prints the device and plane lines (mode info).
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
R=${ROUND:-1}
L62="info d_pf d_walk d_and d_check c2 d_copy d_load d_wave d_bar c3"
L64="c d_pf d_walk d_and d_check c2"
[ "$R" = 2 ] && { L62="c d_bar d_wave d_load d_copy c2 d_check d_and d_walk d_pf c3"; L64="c d_check d_and d_walk d_pf c2"; }
echo "MUST_START r$R $(date -u +%T)"
for m in $L62; do one $m b62 $R; done
for m in $L64; do one $m b64 $R; done
echo "MUST_DONE r$R $(date -u +%T)"
