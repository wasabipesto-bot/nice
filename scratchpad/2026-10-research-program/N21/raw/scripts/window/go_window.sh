#!/bin/sh
# go_window.sh: the N21 window. Build E, then b62 1e17 rounds over $M62 (rotated each round), then b64 1e17 rounds
# over $M64, then b60 1e16 over $M60 if time remains. Every run is guarded by $W/stop and END_AT (epoch seconds: no
# run starts after it). Names: m<N21>_<b62|b64|b60>_r<round>.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
S=$SCRIPTS
: "${END_AT:?set END_AT}"
: "${M62:=0 9 137 8}" "${M64:=0 9}" "${M60:=0 9 8 1}" "${R62:=1 2 3}" "${R64:=1 2}" "${R60:=1}"
echo "GO_START $(date -u +%T) dev=$DEV END_AT=$(date -u -d @$END_AT +%T 2>/dev/null || echo $END_AT)"
sh $S/build.sh >> $OUT/builds.out 2>&1; tail -2 $OUT/builds.out; grep -q "has the N21" $OUT/builds.out || { echo "BUILD FAILED"; exit 1; }
chain() { # TAG BASE SIZE START "MODES" "ROUNDS"
  _t=$1; _b=$2; _z=$3; _s=$4; _m=$5
  for _r in $6; do
    set -- $_m; _n=$#; _k=$(( (_r - 1) % _n ))
    while [ $_k -gt 0 ]; do _x=$1; shift; set -- "$@" $_x; _k=$((_k - 1)); done
    for _x in "$@"; do
      [ -e "$W/stop" ] && { echo "stopped by $W/stop"; return 1; }
      [ "$(date +%s)" -ge "$END_AT" ] && { echo "stopped at END_AT $(date -u +%T)"; return 1; }
      sh $S/wrun.sh m${_x}_${_t}_r$_r $_x $_b $_z $_s
    done
  done
}
chain b62 62 $SZ62 $F62 "$M62" "$R62" && chain b64 64 $SZ64 $F64 "$M64" "$R64" && chain b60 60 $SZ60 $F60 "$M60" "$R60"
echo "GO_DONE $(date -u +%T)"
