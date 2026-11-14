#!/bin/bash
# ex.sh TREE BIN BINS: exactness of one tree. lavapipe (every wgpu test of cubecl_join, WGSL = BIN, SPIR-V = BINS) beside
# the CUDA chain: the CUDA device suite of cubecl_join (every cubecl_cuda_* test but the timing/throughput/whole-field/
# dense ones, each in its own process), then the dense compares vs the CPU join at b60 1e16, b62 1e17, b64 1e17 (8 partitions of slice 0);
# then CI's host-test command on TREE. Logs $W/logs/<BIN>_*.log.
W=/root/t26; S=$W/scripts; T=$1; B=$2; BS=$3
export NICE_BUILD_SHA=test LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
( bash $S/lvp.sh lvp_$B $B; bash $S/lvp.sh lvp_$BS $BS ) > $W/out/ex_lvp_$B.out 2>&1 &
# Each CUDA test in its own process (CubeCL keeps a device's memory pool for the process: in one process the heavy
# FD comparison ran out of the 3080's 10 GB after the earlier tests).
for t in $($W/bin/$B --list --ignored 2>/dev/null | grep -o 'cubecl_join::tests::cubecl_cuda_[a-z0-9_]*' | sed 's/cubecl_join::tests:://' | grep -v 'throughput\|timing\|whole_field\|dense'); do
  TMO=2400 bash $S/t.sh ${B}_$t $B $t
done
for f in "60:1447429612114824200908:10000000000000000" "62:7520566762397899821056:100000000000000000" "64:58557331862957161709568:100000000000000000"; do
  IFS=: read b s z <<< "$f"
  bash $S/t.sh ${B}_dense_b$b $B cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=${DENSE_N:-8} NICE_TEST_JOIN_DENSE_FIELD=$b:$s:$z
done
cd $W/wt/$T && . /root/.cargo/env && CARGO_TARGET_DIR=$W/target-$T cargo test --release -j 6 -p nice_common --features gpu --lib > $W/logs/${B}_host_tests.log 2>&1; echo "HOST rc=$? $(date -u +%T) $(grep 'test result' $W/logs/${B}_host_tests.log)"
wait
echo "EX_DONE $B $(date -u +%T)"
