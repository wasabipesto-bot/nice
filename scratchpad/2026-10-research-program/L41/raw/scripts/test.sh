#!/bin/bash
# test.sh NAME BIN FILTER [env...]: one ignored test (exact name); log /root/l41/logs/NAME.log
set -u
NAME=$1; BIN=$2; FILT=$3; shift 3
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
L=/root/l41/logs
cd /root/l41/src/${SRCD:-B}
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum /root/l41/bin/$BIN | cut -c1-8) filter=$FILT pf=${NICE_EXP_JOIN_PF:-} env=$*" > $L/$NAME.log
env "$@" /root/l41/bin/$BIN --ignored --exact $FILT --nocapture --test-threads 1 >> $L/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $L/$NAME.log
