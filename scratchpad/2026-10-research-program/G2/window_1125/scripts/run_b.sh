#!/bin/sh
# run_b.sh NAME [VAR=VALUE ...] -- ARGS...: one midout_bench process (whole fields through search_field, or the
# stages up to MIDOUT_STOP), sampled.
. "$(dirname "$(readlink -f "$0")")/env.sh"
NAME=$1; shift; E=""; while [ "$1" != "--" ]; do E="$E $1"; shift; done; shift
sh "$SCRIPTS/smp.sh" "$OUT/$NAME.gpu" & MON=$!
echo "START $NAME $(date -u +%T) dev=$DEV md5=$(md5sum "$BIN/mo_bench" | cut -c1-8) env=[$E] args=[$*]" > "$OUT/$NAME.log"
env $E "$BIN/mo_bench" --threads "$HTHREADS" --classes "$MOCLS" $MOPART "$@" >> "$OUT/$NAME.log" 2>&1
RC=$?
echo "END $NAME $(date -u +%T) rc=$RC" >> "$OUT/$NAME.log"
kill $MON 2>/dev/null
echo "$(date -u +%T) $NAME rc=$RC $(grep -h '^TOTAL' "$OUT/$NAME.log" | cut -c1-120)"
