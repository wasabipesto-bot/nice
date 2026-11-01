#!/bin/bash
# test.sh NAME BIN FILTER [env...]: run one ignored test (exact name) with CUDA compat path; log /root/l30pr/NAME.log
set -u
NAME=$1; BIN=$2; FILT=$3; shift 3
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
cd /root/src-main
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum /root/l30pr/$BIN | cut -c1-8) filter=$FILT env=$*" > /root/l30pr/$NAME.log
env "$@" /root/l30pr/$BIN --ignored --exact $FILT --nocapture --test-threads 1 >> /root/l30pr/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> /root/l30pr/$NAME.log
