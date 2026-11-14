#!/bin/bash
# timing_rv.sh: reviewer's interleaved pair, my own builds MT (main + harness) and FTH (fix + harness):
# b54 at 2778136280153679229, 40 fields of 1e13, NICE_JOIN_ROUTE=stride, rounds M F / F M; card cooled before each run.
W=/root/rv; O=$W/out/timing.out
cool() { for i in $(seq 1 150); do t=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader); [ "$t" -le 40 ] && break; sleep 2; done; echo "cool: $(nvidia-smi --query-gpu=temperature.gpu,power.draw,clocks.sm,power.limit --format=csv,noheader) after $((i*2)) s" >> $O; }
run() { NAME=$1; BIN=$2; cool
  export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test NICE_JOIN_ROUTE=stride
  ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,power.limit,temperature.gpu,utilization.gpu --format=csv,noheader; sleep 1; done ) > $W/logs/$NAME.smi 2>&1 &
  SMI=$!
  echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum $W/bin/$BIN | cut -c1-8) builds running: $(pgrep -c cargo) tests running: $(pgrep -fc 't.sh')" > $W/logs/$NAME.log
  NICE_TEST_FIELDS=40 NICE_TEST_STRIDE_FIELD=54:2778136280153679229:10000000000000 timeout 1200 $W/bin/$BIN --ignored --exact cubecl_backend::tests::cubecl_cuda_stride_throughput_fixed_fields --nocapture --test-threads 1 >> $W/logs/$NAME.log 2>&1
  echo "END $NAME $(date -u +%T) rc=$?" >> $W/logs/$NAME.log; kill $SMI
  echo "$(date -u +%T) $NAME $(head -1 $W/logs/$NAME.log | grep -o 'builds running.*') $(grep -o 'secs=[0-9.]*\|rate=[0-9.e+]*\|found=[0-9]*' $W/logs/$NAME.log | tr '\n' ' ')" >> $O; }
echo "TIMING START $(date -u +%T)" >> $O
run t_M_r1 MT; run t_F_r1 FTH; run t_F_r2 FTH; run t_M_r2 MT
echo "TIMING DONE $(date -u +%T)" >> $O
