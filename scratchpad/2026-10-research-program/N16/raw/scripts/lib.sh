# lib.sh (sourced by the chains): one MODE TAG ROUND [BINLABEL] runs wrun.sh as $OUT/${PFX}MODE_TAG_rROUND.
# TAG: b62 = b62 1e17 at 0.45, b64 = b64 1e17 at 0.55, b60 = b60 1e16 at 0.55; SZ62/SZ64/SZ60 override the size
# (the box's lavapipe validation runs the same chains at 1e12). A file $W/stop ends a chain before its next run.
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
: "${SZ62:=1e17}" "${SZ64:=1e17}" "${SZ60:=1e16}" "${PFX:=}" "${NB:=N16}"
one() {
  [ -e "$W/stop" ] && { echo "stopped by $W/stop"; exit 0; }
  m=$1; t=$2; r=$3; b=${4:-$NB}
  case $t in
    b62) set -- 62 $SZ62 $F62;; b64) set -- 64 $SZ64 $F64;; b60) set -- 60 $SZ60 $F60;;
    *) echo "unknown tag $t"; return 1;;
  esac
  sh "$SCRIPTS/wrun.sh" "${PFX}${m}_${t}_r$r" "$b" "$m" "$@"
}
