#!/bin/bash
# run.sh NAME BIN BASES FIELDS SIZE: throughput harness (one untimed 1e14 warm-up field per base); logs NAME.{log,smi}.
# Each process runs in /root/l53/run/NAME with a cubecl.toml that turns on CubeCL's PTX cache at /root/l53/ptx/NAME
# (fresh), so every process's kernels can be replayed through the driver's JIT afterwards (ptxjit.py).
# Every NICE_EXP_* variable in the environment passes through and is logged.
set -u
NAME=$1; BIN=$2; BASES=$3; N=$4; SIZE=$5
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
STARTS=${STARTS:-57:28151599893042801193,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568}
OUT=/root/l53/logs
RUND=/root/l53/run/$NAME; PTXD=/root/l53/ptx/$NAME
rm -rf $RUND $PTXD; mkdir -p $RUND $PTXD
printf '[compilation]\ncache = { file = "%s" }\n' $PTXD > $RUND/cubecl.toml
cd $RUND
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $OUT/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) bases=$BASES n=$N size=$SIZE env=[$(env | grep '^NICE_EXP_' | sort | tr '\n' ' ')] bin=$BIN md5=$(md5sum /root/l53/bin/$BIN | cut -c1-8)" > $OUT/$NAME.log
NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASES NICE_TEST_JOIN_STARTS=$STARTS \
  /root/l53/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $OUT/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $OUT/$NAME.log
kill $SMI
