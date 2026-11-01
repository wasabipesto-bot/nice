#!/bin/bash
# test.sh NAME BIN FILTER [VAR=VAL ...]: one ignored test (exact name) with the CUDA compat path; log /root/pad/NAME.log
set -u
NAME=$1; BIN=$2; FILT=$3; shift 3
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_TAIL NICE_EXP_JOIN_EPT
cd /root/padsrc
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum /root/pad/$BIN | cut -c1-8) filter=$FILT env=$*" > /root/pad/$NAME.log
env "$@" /root/pad/$BIN --ignored --exact $FILT --nocapture --test-threads 1 >> /root/pad/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> /root/pad/$NAME.log
