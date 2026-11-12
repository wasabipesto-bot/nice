#!/bin/sh
# chain_geo.sh (~6 min on the RX 9070 XT): work-group geometry and launches at b60 1e16 (one field, ~13 s a run):
# TOP_CAP 128, smaller survivor stages (shared-memory occupancy), groups of 128 and 64 threads, the denser plan, partitions per launch 1/2/4 (the slope and intercept of
# seconds against launches), the accounting's own cost (c_nohost).
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
R=${ROUND:-1}; PFX=${PFX0:-}ge-
echo "GEO_START $(date -u +%T)"
# The occupancy modes (sc512 sc256 tcsc) need a binary with NICE_EXP_JOIN_SCAP (exp/n16-join-base from cd8b808).
OCC=""; strings "$BIN/$NB" | grep -q NICE_EXP_JOIN_SCAP && OCC="sc512 sc256 tcsc"
for m in ${MODES:-c tc128 $OCC wg128 wg64 wg128tc wg128e4 wg64tc c2 vram tcvram s4 s2 s1 c_nohost c3}; do one $m b60 $R; done
echo "GEO_DONE $(date -u +%T)"
