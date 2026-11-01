#!/bin/bash
# l9.sh TAG DEADLINE_EPOCH BIG(0|1): build upstream main, then the L9 protocol.
# Logs to /root/l9/. Phase marks in /root/l9/phases.log.
TAG=$1; DEADLINE=$2; BIG=$3
L=/root/l9; mkdir -p $L
mark() { echo "$(date -u +%FT%TZ) $*" >> $L/phases.log; }
mark start $TAG
while [ ! -f /root/READY ]; do sleep 10; done
mark ready
source ~/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
unset NICE_BENCHMARK_UPLOAD
cd /root/nice
git fetch -q https://github.com/wasabipesto/nice.git main && git checkout -q FETCH_HEAD
git log -1 --format='%H %cI %s' > $L/commit.txt
mark fetched $(cat $L/commit.txt)
cargo build --release -p nice_client --features gpu > $L/build_client.log 2>&1
echo "exit $?" >> $L/build_client.log
mark built_client
# Test-only logging change: the throughput harness gets test_log so the
# join's per-field debug line (slices, partitions, batches, slots) prints.
python3 - <<'PY'
import re
p='common/src/cubecl_join.rs'
s=open(p).read()
old='    #[test]\n    #[cfg(feature = "cubecl-cuda")]\n    #[ignore = "requires an NVIDIA device; prints throughput"]\n    fn cubecl_cuda_join_throughput_fixed_fields'
assert s.count(old)==1, "pattern"
s=s.replace(old, old.replace('#[test]','#[test_log::test]',1))
open(p,'w').write(s)
PY
git diff > $L/test_patch.diff
cargo test --release -p nice_common --features gpu --no-run > $L/build_test.log 2>&1
echo "exit $?" >> $L/build_test.log
TB=/root/nice/$(grep 'unittests src/lib.rs' $L/build_test.log | grep -o 'target/release/deps/nice_common-[0-9a-f]*' | tail -1)
echo "$TB" > $L/test_binary.txt
mark built_test $TB
nvidia-smi dmon -s puc -o T -d 5 > $L/dmon.log 2>&1 &
DMON=$!
nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,enforced.power.limit,temperature.gpu,clocks_throttle_reasons.active,utilization.gpu,memory.used --format=csv -l 5 > $L/smi.csv 2>&1 &
SMI=$!
B=./target/release/nice_client
for i in 1 2 3; do
  mark niceonly_$i begin
  $B niceonly --gpu --benchmark --benchmark-secs 150 < /dev/null > $L/niceonly_$i.log 2>&1
  echo "exit $?" >> $L/niceonly_$i.log
  mark niceonly_$i end
done
for i in 1 2; do
  mark detailed_$i begin
  $B detailed --gpu --benchmark --benchmark-secs 120 < /dev/null > $L/detailed_$i.log 2>&1
  echo "exit $?" >> $L/detailed_$i.log
  mark detailed_$i end
done
join() { # join NAME BASE SIZE
  mark join_$1 begin
  RUST_LOG=nice_common::cubecl_join=debug NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=$3 NICE_TEST_JOIN_BASES=$2 \
    NICE_TEST_JOIN_STARTS=60:1366406074057412100454,62:7997740455941656911841 \
    $TB --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/join_$1.log 2>&1
  echo "exit $?" >> $L/join_$1.log
  mark join_$1 end
}
join b60_1e16 60 1e16
join b62_1e16_r1 62 1e16
join b62_1e16_r2 62 1e16
if [ "$BIG" = 1 ] && [ $(( $(date +%s) + 1500 )) -le $DEADLINE ]; then
  join b62_1e17 62 1e17
else
  mark skip_b62_1e17 big=$BIG
fi
kill $DMON $SMI
mark done
touch $L/DONE
