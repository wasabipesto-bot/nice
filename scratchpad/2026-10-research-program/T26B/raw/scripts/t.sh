#!/bin/bash
# t.sh NAME BIN TEST [extra env...]: one ignored test of $W/bin/BIN, logged to $W/logs/NAME.log (exact name match)
W=/root/t26b; NAME=$1; BIN=$2; TEST=$3; shift 3
export NICE_BUILD_SHA=test LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum $W/bin/$BIN | cut -c1-8) test=$TEST env=[$*]" > $W/logs/$NAME.log
timeout ${TMO:-3600} env "$@" $W/bin/$BIN --ignored --exact cubecl_join::tests::$TEST --nocapture --test-threads 1 >> $W/logs/$NAME.log 2>&1
RC=$?
echo "END $NAME $(date -u +%T) rc=$RC" >> $W/logs/$NAME.log
echo "$(date -u +%T) $NAME rc=$RC"
