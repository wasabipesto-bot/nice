#!/bin/bash
# run.sh NAME BIN BASES FIELDS SIZE: production throughput harness (one untimed 1e14 warm-up field per base); logs
# NAME.{log,smi}; CubeCL PTX cache per process at /root/n1/ptx/NAME (ptxjit.py replays it). NICE_EXP_* pass through.
set -u
NAME=$1; BIN=$2; BASES=$3; N=$4; SIZE=$5
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
# The brief's field: 3226266762397899821056 + 40000e17.
STARTS=${STARTS:-62:7226266762397899821056}
OUT=/root/n1/logs
RUND=/root/n1/run/$NAME; PTXD=/root/n1/ptx/$NAME
rm -rf $RUND $PTXD; mkdir -p $RUND $PTXD
printf '[compilation]\ncache = { file = "%s" }\n' $PTXD > $RUND/cubecl.toml
cd $RUND
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $OUT/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) bases=$BASES n=$N size=$SIZE starts=$STARTS env=[$(env | grep '^NICE_EXP_' | sort | tr '\n' ' ')] bin=$BIN md5=$(md5sum /root/n1/bin/$BIN | cut -c1-8)" > $OUT/$NAME.log
NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASES NICE_TEST_JOIN_STARTS=$STARTS \
  /root/n1/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $OUT/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $OUT/$NAME.log
kill $SMI
python3 /root/n1/ptxjit.py --only join $PTXD > $OUT/${NAME}_jit.txt 2>&1
