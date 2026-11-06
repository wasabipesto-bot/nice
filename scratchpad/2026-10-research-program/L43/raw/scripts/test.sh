#!/bin/bash
# test.sh NAME BIN FILTER [env...]: one ignored test (exact name); log /root/l43/logs/NAME.log
set -u
NAME=$1; BIN=$2; FILT=$3; shift 3
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
L=/root/l43/logs
cd /root/l43/src/${SRCD:-M}
echo "START $NAME $(date -u +%T) wb=${NICE_EXP_JOIN_WB:-unset} bin=$BIN md5=$(md5sum /root/l43/bin/$BIN | cut -c1-8) filter=$FILT env=$*" > $L/$NAME.log
env "$@" /root/l43/bin/$BIN --ignored --exact $FILT --nocapture --test-threads 1 >> $L/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $L/$NAME.log
