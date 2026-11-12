#!/bin/sh
# chain_geo62.sh (~12 min on the RX 9070 XT): the geometry winners and the launches at b62 1e17 (if time allows).
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
R=${ROUND:-1}
for m in ${MODES:-c tc128 wg128 wg64 vram tcvram s4 c2}; do one $m b62 $R; done
echo "GEO62_DONE $(date -u +%T)"
