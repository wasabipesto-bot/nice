#!/bin/sh
# run_pr.sh NAME: PR #270's two tests from their own binary ($BIN/t_pr270), sampled.
. "$(dirname "$(readlink -f "$0")")/env.sh"
NAME=$1
sh "$SCRIPTS/smp.sh" "$OUT/$NAME.gpu" & MON=$!
echo "START $NAME $(date -u +%T) dev=$DEV md5=$(md5sum "$BIN/t_pr270" | cut -c1-8) tests=[$PR270_TESTS]" > "$OUT/$NAME.log"
"$BIN/t_pr270" --ignored --nocapture --test-threads 1 $PR270_TESTS >> "$OUT/$NAME.log" 2>&1
RC=$?
echo "END $NAME $(date -u +%T) rc=$RC" >> "$OUT/$NAME.log"
kill $MON 2>/dev/null
echo "$(date -u +%T) $NAME rc=$RC $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' "$OUT/$NAME.log")"
