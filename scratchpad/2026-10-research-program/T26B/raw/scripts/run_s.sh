#!/bin/bash
# run_s.sh NAME BIN BASE START SIZE N: the stride pipeline on CUDA (NICE_JOIN_ROUTE=stride), one untimed warm-up of
# size/10 before START, then N fields of SIZE timed; nvidia-smi every 1 s -> $W/logs/NAME.{log,smi}
W=/root/t26b; NAME=$1; BIN=$2; BASE=$3; START=$4; SIZE=$5; N=$6
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test NICE_JOIN_ROUTE=stride
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 1; done ) > $W/logs/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum $W/bin/$BIN | cut -c1-8) b$BASE start=$START size=$SIZE n=$N temp=$(nvidia-smi --query-gpu=temperature.gpu,power.limit --format=csv,noheader)" > $W/logs/$NAME.log
NICE_TEST_FIELDS=$N NICE_TEST_STRIDE_FIELD=$BASE:$START:$SIZE timeout 1800 $W/bin/$BIN --ignored --exact cubecl_backend::tests::cubecl_cuda_stride_throughput_fixed_fields --nocapture --test-threads 1 >> $W/logs/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $W/logs/$NAME.log
kill $SMI
echo "$(date -u +%T) $NAME $(grep -o 'secs=[0-9.]*\|rate=[0-9.e+]*\|found=[0-9]*' $W/logs/$NAME.log | tr '\n' ' ')"
