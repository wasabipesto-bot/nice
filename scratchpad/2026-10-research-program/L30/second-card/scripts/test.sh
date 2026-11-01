#!/bin/bash
# test.sh NAME BIN FILTER [env...]: one ignored test (exact name) with the CUDA compat path; log /root/sc/NAME.log
set -u
NAME=$1; BIN=$2; FILT=$3; shift 3
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
cd /root/main
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum /root/sc/$BIN | cut -c1-8) filter=$FILT env=$*" > /root/sc/$NAME.log
env "$@" /root/sc/$BIN --ignored --exact $FILT --nocapture --test-threads 1 >> /root/sc/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> /root/sc/$NAME.log
