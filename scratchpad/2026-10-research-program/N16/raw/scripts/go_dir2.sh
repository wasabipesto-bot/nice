#!/bin/sh
# go_dir2.sh (director, 2026-11-12 window, stage 2): three interleaved rounds of the candidates CAND against the base
# at b62 1e17 and b60 1e16 (order rotated per round; names ab-ge-<mode>_<tag>_r<round>), then Task D's binary (the
# denser plan behind its device rule): build D, one run at b60 and b62 (its batch count shows whether the rule
# engaged), then a second b64 round of B64CAND if END_AT allows.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
S=$SCRIPTS
: "${END_AT:?set END_AT}" "${CAND:?set CAND}"; export END_AT
echo "STAGE2_START $(date -u +%T) CAND=[$CAND] B64CAND=[${B64CAND:-}]"
# 0. N20 probe (PROBE = a commit of fork exp/n20-mul-probe): rebuild in wt/N16 as binary P, time the three probe
#    variants at b62, then two tiny runs with RADV_DEBUG=shaders to see which multiply opcodes the driver emitted.
if [ -n "${PROBE:-}" ]; then
  git -C $W/src/nice fetch -q origin exp/n20-mul-probe && git -C $W/wt/N16 checkout -q --detach "$PROBE" &&
    sh $S/build.sh N16 P >> $OUT/builds.out 2>&1 && tail -2 $OUT/builds.out && {
      PFX0=pr- NB=P ROUND=1 TAG=b64 MODES="c pfsh" sh $S/chain_geox.sh
      PFX0=pr- NB=P ROUND=1 TAG=b62 MODES="c p_m0 p_m32 p_m24" sh $S/chain_geox.sh
      RADV_DEBUG=shaders PFX0=dump- NB=P ROUND=1 TAG=b60 SZ60=1e14 MODES="p_m24 p_m32" sh $S/chain_geox.sh
    }
fi
rev() { r=""; for x in "$@"; do r="$x $r"; done; echo $r; }
set -- $CAND
O1="c $*"; O2="$(rev "$@") c"; h=$(( ($# + 1) / 2 )); a=""; b=""; i=0
for x in "$@"; do i=$((i+1)); if [ $i -le $h ]; then a="$a $x"; else b="$b $x"; fi; done
O3="$b c $a"
r=0
for O in "$O1" "$O2" "$O3"; do
  r=$((r+1))
  PFX0=ab- ROUND=$r TAG=b62 MODES="$O" sh $S/chain_geox.sh
  PFX0=ab- ROUND=$r TAG=b60 MODES="$O" sh $S/chain_geox.sh
done
if [ "$(date +%s)" -lt "$END_AT" ] && [ ! -e "$W/stop" ]; then
  sh $S/build.sh D D >> $OUT/builds.out 2>&1 && tail -2 $OUT/builds.out &&
    { PFX=DD- ; . $S/lib.sh; PFX=DD- one c b60 1 D; PFX=DD- one c b62 1 D; }
fi
[ -n "${B64CAND:-}" ] && PFX0=ab- ROUND=2 TAG=b64 MODES="c $B64CAND" sh $S/chain_geox.sh
echo "STAGE2_DONE $(date -u +%T)"
