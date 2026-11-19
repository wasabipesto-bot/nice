#!/bin/sh
# run_main.sh NAME START: one process of main's throughput harness (untimed warm-up, then one b64 field of SZ64 at
# START), sampled (port/window/run_main.sh with t_mo as main's binary).
. "$(dirname "$(readlink -f "$0")")/env.sh"
NAME=$1; START=$2
sh "$SCRIPTS/smp.sh" "$OUT/$NAME.gpu" & MON=$!
echo "START $NAME $(date -u +%T) dev=$DEV md5=$(md5sum "$BIN/t_mo" | cut -c1-8) start=$START size=$SZ64" > "$OUT/$NAME.log"
NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=$SZ64 NICE_TEST_JOIN_BASES=64 NICE_TEST_JOIN_STARTS=64:$START \
  "$BIN/t_mo" --ignored --exact $HARNESS --nocapture --test-threads 1 >> "$OUT/$NAME.log" 2>&1
RC=$?
echo "END $NAME $(date -u +%T) rc=$RC" >> "$OUT/$NAME.log"
kill $MON 2>/dev/null
echo "$(date -u +%T) $NAME rc=$RC $(grep -h 'JOIN THROUGHPUT' "$OUT/$NAME.log" | grep -o 'secs=[0-9.]*\|survivors=[0-9]*\|checked=[0-9]*' | tr '\n' ' ')"
