#!/bin/bash
# test.sh NAME BIN FILTER [env...]: one ignored test (exact name) from tree ${SRCD:-S}; log /root/l46/logs/NAME.log
set -u
NAME=$1; BIN=$2; FILT=$3; shift 3
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
L=/root/l46/logs
cd /root/l46/src/${SRCD:-S}
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum /root/l46/bin/$BIN | cut -c1-8) filter=$FILT env=$*" > $L/$NAME.log
env "$@" /root/l46/bin/$BIN --ignored --exact $FILT --nocapture --test-threads 1 >> $L/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $L/$NAME.log
