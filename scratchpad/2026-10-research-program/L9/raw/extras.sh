#!/bin/bash
# extras.sh BIG17(0|1): after l9.sh. 2-field 1e16 joins at b60/62/64 (like-for-like with
# the 3080's L29 runs), optional b62 1e17, and 2 niceonly --benchmark-json sweeps (join layout).
BIG=$1
L=/root/l9; cd /root/nice
mark() { echo "$(date -u +%FT%TZ) $*" >> $L/phases.log; }
source ~/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
unset NICE_BENCHMARK_UPLOAD
TB=$(cat $L/test_binary.txt)
nvidia-smi dmon -s puc -o T -d 5 > $L/dmon_x.log 2>&1 &
DMON=$!
nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,enforced.power.limit,temperature.gpu,clocks_throttle_reasons.active,utilization.gpu,memory.used --format=csv -l 5 > $L/smi_x.csv 2>&1 &
SMI=$!
join() { # join NAME BASE SIZE FIELDS
  mark x_join_$1 begin
  RUST_LOG=nice_common::cubecl_join=debug NICE_TEST_JOIN_FIELDS=$4 NICE_TEST_JOIN_SIZE=$3 NICE_TEST_JOIN_BASES=$2 \
    NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
    $TB --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/xjoin_$1.log 2>&1
  echo "exit $?" >> $L/xjoin_$1.log
  mark x_join_$1 end
}
join b62_1e16_f2 62 1e16 2
join b60_1e16_f2 60 1e16 2
join b64_1e16_f2 64 1e16 2
[ "$BIG" = 1 ] && join b62_1e17 62 1e17 1
for i in 1 2; do
  mark x_niceonly_json_$i begin
  ./target/release/nice_client niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/xniceonly_json_$i.json 2> $L/xniceonly_json_$i.err
  echo "exit $?" >> $L/xniceonly_json_$i.err
  mark x_niceonly_json_$i end
done
kill $DMON $SMI
mark x_done
touch $L/XDONE
