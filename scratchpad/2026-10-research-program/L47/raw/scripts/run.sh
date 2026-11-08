#!/bin/bash
# run.sh NAME BIN BASES FIELDS SIZE: throughput harness (one untimed 1e14 warm-up field per base); logs NAME.{log,smi}.
# Each process runs in /root/l47/run/NAME with a cubecl.toml that turns on CubeCL's PTX cache at /root/l47/ptx/NAME:
# fresh (empty) unless PTXFROM=<dir> is given, whose content is copied in first (pins every kernel's PTX).
# HUNT_TIMEOUT=<s>: kill the process after <s> seconds (variant hunting: only the PTX cache matters).
# NICE_EXP_GPU_PROFILE, NICE_EXP_JOIN_ABL, NICE_EXP_JOIN_TMIN, NICE_EXP_JOIN_SPILLCNT pass through and are logged.
set -u
NAME=$1; BIN=$2; BASES=$3; N=$4; SIZE=$5
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
STARTS=${STARTS:-57:28151599893042801193,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568}
OUT=/root/l47/logs
RUND=/root/l47/run/$NAME; PTXD=/root/l47/ptx/$NAME
rm -rf $RUND $PTXD; mkdir -p $RUND $PTXD
if [ -n "${PTXFROM:-}" ]; then cp -a $PTXFROM/. $PTXD/; fi
printf '[compilation]\ncache = { file = "%s" }\n' $PTXD > $RUND/cubecl.toml
cd $RUND
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $OUT/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) bases=$BASES n=$N size=$SIZE P=${NICE_EXP_GPU_PROFILE:-unset} ABL=${NICE_EXP_JOIN_ABL:-unset} TMIN=${NICE_EXP_JOIN_TMIN:-unset} SPC=${NICE_EXP_JOIN_SPILLCNT:-unset} CHK=${NICE_EXP_CHECK:-unset} CUBES=${NICE_EXP_CHECK_CUBES:-unset} G=${NICE_EXP_CHECK_G:-unset} PTXFROM=${PTXFROM:-fresh} bin=$BIN md5=$(md5sum /root/l47/bin/$BIN | cut -c1-8)" > $OUT/$NAME.log
TO=""; if [ -n "${HUNT_TIMEOUT:-}" ]; then TO="timeout -s KILL $HUNT_TIMEOUT"; fi
NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASES NICE_TEST_JOIN_STARTS=$STARTS \
  $TO /root/l47/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $OUT/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $OUT/$NAME.log
kill $SMI
