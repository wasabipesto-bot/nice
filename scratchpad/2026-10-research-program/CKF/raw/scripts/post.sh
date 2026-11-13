#!/bin/bash
# post.sh: after the timing chain. (1) ptxjit over every timed run's PTX cache (registers / spill variant), (2) host tests
# of the fix tree (CI's test-gpu-host command), (3) CUDA device tests on F3, then the dense compares; lavapipe suites
# run beside (4) with both compilers.
W=/root/ckf; S=$W/scripts; . /root/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
python3 $S/ptxjit.py $(ls -d $W/ptx/b6*_r*) > $W/out/ptxjit.out 2>&1; echo "PTXJIT rc=$? $(date -u +%T)"
# lavapipe: every wgpu test of cubecl_join (all ignored, cuda ones skipped), naga then SPIR-V, beside the CUDA runs
( for b in F3 FS; do
    echo "START lvp_$b $(date -u +%T)" > $W/logs/lvp_$b.log
    $W/bin/$b --ignored cubecl_join::tests:: --skip cuda --nocapture --test-threads 1 >> $W/logs/lvp_$b.log 2>&1
    echo "END lvp_$b $(date -u +%T) rc=$?" >> $W/logs/lvp_$b.log; echo "$(date -u +%T) lvp_$b $(tail -1 $W/logs/lvp_$b.log)"
  done ) > $W/out/lvp.out 2>&1 &
cd $W/wt/fix && CARGO_TARGET_DIR=$W/target-fix NICE_BUILD_SHA=test cargo test --release -j 6 -p nice_common --features gpu --lib > $W/logs/host_tests_F3.log 2>&1; echo "HOST rc=$? $(date -u +%T) $(grep 'test result' $W/logs/host_tests_F3.log)"
for t in cubecl_cuda_check_takes_every_entry_on_partly_filled_warps cubecl_cuda_check_counts_match_the_cpu cubecl_cuda_join_matches_the_cpu_reference cubecl_cuda_top_fd_matches_the_top_kernel; do
  bash $S/t.sh F3_$t F3 $t
done
for f in "60:1447429612114824200908:1e16" "62:7520566762397899821056:1e17" "64:58557331862957161709568:1e17"; do
  IFS=: read b s z <<< "$f"
  bash $S/t.sh F3_dense_b$b F3 cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=${DENSE_N:-8} NICE_TEST_JOIN_DENSE_FIELD=$b:$s:$(python3 -c "print(int(float('$z')))")
done
echo POST_DONE $(date -u +%T)
