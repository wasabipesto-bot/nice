#!/bin/bash
# run.sh NAME BIN BASE SIZE START: throughput harness (one untimed 1e14 warm-up field, then one field), with a fresh
# CubeCL PTX cache per process (for ptxjit.py) and nvidia-smi every second; logs $W/logs/NAME.{log,smi}.
set -u
W=/root/n21v; NAME=$1; BIN=$2; BASE=$3; SIZE=$4; START=$5; N=${6:-1}
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
RUND=$W/run/$NAME; PTXD=$W/ptx/$NAME
rm -rf $RUND $PTXD; mkdir -p $RUND $PTXD
printf '[compilation]\ncache = { file = "%s" }\n' $PTXD > $RUND/cubecl.toml
cd $RUND
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 1; done ) > $W/logs/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) base=$BASE size=$SIZE start=$START fields=$N bin=$BIN md5=$(md5sum $W/bin/$BIN | cut -c1-8) temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)" > $W/logs/$NAME.log
NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASE NICE_TEST_JOIN_STARTS=$BASE:$START \
  $W/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $W/logs/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $W/logs/$NAME.log
kill $SMI
grep -h 'JOIN THROUGHPUT' $W/logs/$NAME.log | grep -o 'device=[0-9.]*s\|secs=[0-9.]*\|survivors=[0-9]*\|checked=[0-9]*\|found=[0-9]*' | tr '\n' ' ' | sed "s/^/$(date -u +%T) $NAME /"; echo
