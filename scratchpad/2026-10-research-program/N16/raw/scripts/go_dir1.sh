#!/bin/sh
# go_dir1.sh (director, 2026-11-12 window, stage 1): build N16; the doubling profile (b62 with 3 base runs, b64 with 2);
# the occupancy / geometry / launch screen at b60; removal unprofiled at b60; a b64 screen of the candidates.
# END_AT (epoch) must be set: no run starts after it. Touch $W/stop to end before the next run.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
S=$SCRIPTS
: "${END_AT:?set END_AT}"; export END_AT
echo "GO_START $(date -u +%T) END_AT $(date -u -d @$END_AT +%T)"
sh $S/build.sh N16 N16 >> $OUT/builds.out 2>&1 || { cat $OUT/builds.out; echo "N16 BUILD FAILED"; exit 1; }
cat $OUT/builds.out
ROUND=1 sh $S/chain_must.sh
ROUND=1 MODES="c tc128 sc512 sc256 sc128 tcsc tcsc256 vram scvram all3 all3b c2 wg128 wg64 wg128tc wg64tc s4 s2 s1 c_nohost c3" sh $S/chain_geo.sh
ROUND=1 S62="" sh $S/chain_surv.sh
ROUND=1 TAG=b64 MODES="c sc256 tcsc vram all3" sh $S/chain_geox.sh
echo "STAGE1_DONE $(date -u +%T)"
