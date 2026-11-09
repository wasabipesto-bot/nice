#!/bin/bash
# test.sh NAME BIN FILTER [env...]: one ignored test (exact name) of /root/l54/bin/BIN, run in /root/l54/src/${SRCD:-P};
# log /root/l54/logs/NAME.log.
set -u
NAME=$1; BIN=$2; FILT=$3; shift 3
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
L=/root/l54/logs
cd /root/l54/src/${SRCD:-P}
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum /root/l54/bin/$BIN | cut -c1-8) filter=$FILT env=$* exp=[$(env | grep '^NICE_EXP_' | tr '\n' ' ')]" > $L/$NAME.log
env "$@" /root/l54/bin/$BIN --ignored --exact $FILT --nocapture --test-threads 1 >> $L/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $L/$NAME.log
