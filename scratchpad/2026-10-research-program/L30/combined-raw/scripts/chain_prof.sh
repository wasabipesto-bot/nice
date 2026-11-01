#!/bin/bash
# Profiled combined tree (NICE_EXP_GPU_PROFILE=1): one b62 1e17 field, one b60 1e16 field.
set -u
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
L=/root/cmb
STARTS=60:1366406074057412100454,62:7997740455941656911841
cd /root/main
for spec in "62 1e17" "60 1e16"; do
  set -- $spec; B=$1; SZ=$2; NAME=prof_b${B}_${SZ}
  ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/$NAME.smi 2>&1 &
  SMI=$!
  echo "START $NAME $(date -u +%T) md5=$(md5sum $L/prof | cut -c1-8)" > $L/$NAME.log
  NICE_EXP_GPU_PROFILE=1 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=$SZ NICE_TEST_JOIN_BASES=$B NICE_TEST_JOIN_STARTS=$STARTS \
    $L/prof --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $L/$NAME.log 2>&1
  echo "END $NAME $(date -u +%T) rc=$?" >> $L/$NAME.log
  kill $SMI
done
echo CHAIN_PROF_DONE $(date -u +%T) > $L/chainProf.done
