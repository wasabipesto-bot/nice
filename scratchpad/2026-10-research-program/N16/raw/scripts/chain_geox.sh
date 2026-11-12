#!/bin/sh
# chain_geox.sh (director, 2026-11-12 window): MODES at TAG (b62 | b64 | b60), round ROUND, names ge-<mode>_<tag>_r<round>.
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
R=${ROUND:-1}; PFX=${PFX0:-}ge-
echo "GEOX_START $TAG r$R $(date -u +%T)"
for m in $MODES; do one $m ${TAG:?} $R; done
echo "GEOX_DONE $TAG r$R $(date -u +%T)"
