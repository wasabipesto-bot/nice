#!/bin/sh
# chain_must.sh: the window's must-have (~31 min on the RX 9070 XT): the corrected profile by DOUBLING, unprofiled, at
# b62 1e17 (0.45) with three base runs spread through it, then b64 1e17 (0.55) with two. ROUND=1 (default) or 2
# (round 2 runs each list reversed). The first base run prints the device and plane lines (mode info).
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
R=${ROUND:-1}; PFX=${PFX0:-}
if [ "$R" = 2 ]; then
  D62="c d_bar d_wave d_load d_copy c2 d_check d_and d_walk d_pf c3"; D64="c d_check d_and d_walk d_pf c2"
else
  D62="info d_pf d_walk d_and d_check c2 d_copy d_load d_wave d_bar c3"; D64="c d_pf d_walk d_and d_check c2"
fi
# L62 / L64 override the lists (an empty L64 skips b64).
L62=${L62-$D62}; L64=${L64-$D64}
echo "MUST_START r$R $(date -u +%T)"
for m in $L62; do one $m b62 $R; done
for m in $L64; do one $m b64 $R; done
echo "MUST_DONE r$R $(date -u +%T)"
