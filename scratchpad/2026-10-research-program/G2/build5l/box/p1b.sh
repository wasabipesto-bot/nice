#!/bin/bash
# box: piece 1 at the default switch: builds, CPU + client tests, the b65 (4,8,5) field through the production path
# with the sampled check, and the route end to end against the local coordinator in both coordinates; $1 = log dir
set -u
L=$1; mkdir -p $L; source /root/mo/guard.sh $L || exit 1
/root/m5build.sh $L/build p1b
source ~/.cargo/env; cd /root/m5; export CARGO_TARGET_DIR=/root/t/m5
cargo build --release -p nice_client --features cubecl-cuda > $L/b_client.log 2>&1; echo rc=$? >> $L/b_client.log
cargo build --release -p nice_common --example midout_fields > $L/b_fields.log 2>&1; echo rc=$? >> $L/b_fields.log
cp /root/t/m5/release/nice_client /root/m5bin/p1b/nice_mo; cp /root/t/m5/release/examples/midout_fields /root/m5bin/p1b/
T=/root/m5bin/p1b/tests
$T midout::coord midout::cpu::tests midout::wire > $L/cpu_tests.log 2>&1; echo rc=$? >> $L/cpu_tests.log
cargo test --release -p nice_client --features cubecl-cuda -- midout_route > $L/client_tests.log 2>&1; echo rc=$? >> $L/client_tests.log
# the route end to end: b64 (4,8,5) t 77777 and 5461, b65 (4,8,5) t 13731, b64 (4,9,6) t 77777
R=$L/e2e; mkdir -p $R; F=/root/m5bin/p1b/midout_fields
$F --base 64 --t 77777,5461 > $R/w1.json && $F --base 65 --t 13731 > $R/w2.json && $F --base 64 --t 77777 --digits 4,9,6 > $R/w3.json
python3 -c 'import json,sys; print(json.dumps(sum((json.load(open(f)) for f in sys.argv[1:]), []), indent=0))' $R/w1.json $R/w2.json $R/w3.json > $R/work.json
python3 /root/m5/scripts/midout_coordinator.py --worklist $R/work.json --state $R/state --port 8475 2> $R/coord.log & CP=$!
sleep 1
echo "$(date -u +%FT%T.%3NZ) client start" >> $R/run.log
/root/m5bin/p1b/nice_mo niceonly --midout-coordinator http://127.0.0.1:8475 --repeat --username mo-e2e-local > $R/client.log 2>&1
echo "$(date -u +%FT%T.%3NZ) client rc=$?" >> $R/run.log
curl -s http://127.0.0.1:8475/status >> $R/run.log; echo >> $R/run.log
kill $CP
# b65 (4,8,5) whole field through the production path with the sampled CPU check
MIDOUT_CUDA=1 MIDOUT_485_D8=0 MIDOUT_485_WHOLE=1 MIDOUT_485_CHECK=1 RUST_LOG=warn timeout 1200 $T --ignored --exact --nocapture midout::gpu_wide::tests::wide_field_485_equals_496_slice_by_slice > $L/wfield485_whole.log 2>&1; echo rc=$? >> $L/wfield485_whole.log
echo done > $L/done
