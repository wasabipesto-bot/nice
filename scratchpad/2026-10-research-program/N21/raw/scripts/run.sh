#!/bin/bash
# run.sh NAME BIN N21 BASE N SIZE START: one process of the CUDA throughput harness with NICE_EXP_N21=N21 (one untimed
# 1e14 warm-up field below START, then N fields of SIZE from START). Logs $W/logs/NAME.{log,smi}; the process runs in
# its own directory with CubeCL's PTX cache on (fresh) so its join kernel is replayed through the driver JIT afterwards
# (ptxjit.py -> NAME_jit.txt: the register variant this process got). Every run starts at <= ${COOL_C:-60} C.
set -u
W=/root/n21; NAME=$1; BIN=$2; N21=$3; BASE=$4; N=$5; SIZE=$6; START=$7
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
L=$W/logs; mkdir -p $L
RUND=$W/run/$NAME; PTXD=$W/ptx/$NAME
rm -rf $RUND $PTXD; mkdir -p $RUND $PTXD
printf '[compilation]\ncache = { file = "%s" }\n' $PTXD > $RUND/cubecl.toml
cd $RUND
t0=$(date +%s); while [ $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits) -gt ${COOL_C:-60} ] && [ $(( $(date +%s) - t0 )) -lt 300 ]; do sleep 3; done
TSTART="cooled $(( $(date +%s) - t0 ))s to $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)C"
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 2; done ) > $L/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) n21=$N21 base=$BASE n=$N size=$SIZE start=$START bin=$BIN md5=$(md5sum $W/bin/$BIN | cut -c1-8) load=$(cut -d' ' -f1 /proc/loadavg) $TSTART" > $L/$NAME.log
NICE_EXP_N21=$N21 NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASE NICE_TEST_JOIN_STARTS=$BASE:$START \
  $W/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $L/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $L/$NAME.log
kill $SMI
python3 $W/scripts/ptxjit.py --only join $PTXD > $L/${NAME}_jit.txt 2>&1
echo "$(date -u +%T) $NAME n21=$N21 $(grep -o 'secs=[0-9.]*' $L/$NAME.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$NAME.log | tail -1) $(grep -o 'join_kernel.*regs=[0-9]* local=[0-9]*' $L/${NAME}_jit.txt | head -1 | grep -o 'regs.*')"
