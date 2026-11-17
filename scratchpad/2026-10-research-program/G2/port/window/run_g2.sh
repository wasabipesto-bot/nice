#!/bin/sh
# run_g2.sh NAME SU ARGS...: one G2 process (the example binary) on super-unit dir SU with ARGS, sampled.
. "$(dirname "$(readlink -f "$0")")/env.sh"
NAME=$1; SUD=$2; shift 2
sh "$SCRIPTS/smp.sh" "$OUT/$NAME.gpu" & MON=$!
echo "START $NAME $(date -u +%T) dev=$DEV md5=$(md5sum "$BIN/g2" | cut -c1-8) su=$(basename $SUD) args=[$*]" > "$OUT/$NAME.log"
"$BIN/g2" "$SUD" --jobs "$G2JOBS" --batch "$G2BATCH" "$@" >> "$OUT/$NAME.log" 2>&1
RC=$?
echo "END $NAME $(date -u +%T) rc=$RC" >> "$OUT/$NAME.log"
kill $MON 2>/dev/null
echo "$(date -u +%T) $NAME rc=$RC $(grep -h 'ALL CHECKS\|FAILED\|RESULT end' "$OUT/$NAME.log" | tr '\n' ' ' | cut -c1-200)"
