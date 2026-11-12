#!/bin/sh
# go_dir3.sh (director, 2026-11-12 window, stage 3): the denser-plan rule on today's main (D = exp/n14-wgpu-dense-plan-v2
# bb58878 on a7a59c1, built by stage 2) against that main (M = a7a59c1, built here): b64 1e17 first (main now steps the
# top certificates at b64, which the denser plan needs), then main's b62 and b60 runs as the baseline of stage 2's D runs.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
S=$SCRIPTS
: "${END_AT:?set END_AT}"; export END_AT
echo "STAGE3_START $(date -u +%T)"
[ "$(date +%s)" -lt "$END_AT" ] || { echo "past END_AT"; exit 0; }
sh $S/build.sh M M >> $OUT/builds.out 2>&1 && tail -2 $OUT/builds.out || { echo "M BUILD FAILED"; exit 1; }
. $S/lib.sh
PFX=DM- one c b64 1 M
PFX=DD- one c b64 1 D
PFX=DM- one c b62 1 M
PFX=DM- one c b60 1 M
echo "STAGE3_DONE $(date -u +%T)"
