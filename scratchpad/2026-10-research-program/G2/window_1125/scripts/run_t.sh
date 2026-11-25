#!/bin/sh
# run_t.sh NAME TEST [VAR=VALUE ...]: one ignored library test of t_mo (exactness), sampled.
. "$(dirname "$(readlink -f "$0")")/env.sh"
NAME=$1; T=$2; shift 2
sh "$SCRIPTS/smp.sh" "$OUT/$NAME.gpu" & MON=$!
echo "START $NAME $(date -u +%T) dev=$DEV md5=$(md5sum "$BIN/t_mo" | cut -c1-8) test=$T env=[$*]" > "$OUT/$NAME.log"
env "$@" "$BIN/t_mo" --ignored --exact "$T" --nocapture --test-threads 1 >> "$OUT/$NAME.log" 2>&1
RC=$?
echo "END $NAME $(date -u +%T) rc=$RC" >> "$OUT/$NAME.log"
kill $MON 2>/dev/null
echo "$(date -u +%T) $NAME rc=$RC $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed\| W [0-9]*' "$OUT/$NAME.log" | sort -u | tr '\n' ' ')"
