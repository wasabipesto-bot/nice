#!/bin/sh
# go_window.sh: the whole window after setup_window.sh, in priority order; run as
#   $W/run.sh sh $W/scripts/go_window.sh > $W/out/go.out 2>&1 &
# END_AT (epoch) stops new runs: default start + 84 min, so the last run ends by ~T+87 and pull + cleanup fit in 90.
# Touch $W/stop to end it before the next run. Progress lines in $W/out/go.out; build lines in $W/out/builds.out.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
S=$SCRIPTS
export END_AT=${END_AT:-$(( $(date +%s) + 84 * 60 ))}
echo "GO_START $(date -u +%T) END_AT $(date -u -d @$END_AT +%T)"
# 1. the N16 build (nothing timed meanwhile)
sh $S/build.sh N16 N16 >> $OUT/builds.out 2>&1 || { cat $OUT/builds.out; echo "N16 BUILD FAILED"; exit 1; }
cat $OUT/builds.out
# 2. MUST: the corrected profile by doubling, b62 1e17 (3 base runs) then b64 1e17 (2 base runs)
ROUND=1 sh $S/chain_must.sh
# 3. survivor-path and tops switches (b62), removal modes unprofiled with clocks (b60)
ROUND=1 sh $S/chain_surv.sh
# 4. geometry, shared-memory occupancy and launches (b60)
ROUND=1 sh $S/chain_geo.sh
# 5. Task D: build main and D (nothing timed meanwhile), then main against the denser plan (b62, b60; 3 rounds)
if [ "$(date +%s)" -lt "$END_AT" ]; then
  sh $S/build.sh M M >> $OUT/builds.out 2>&1 && sh $S/build.sh D D >> $OUT/builds.out 2>&1 && tail -4 $OUT/builds.out &&
    sh $S/chain_D.sh
fi
# 6. second round of the b62 doubling (reversed)
ROUND=2 L64= sh $S/chain_must.sh
echo "GO_DONE $(date -u +%T)"
