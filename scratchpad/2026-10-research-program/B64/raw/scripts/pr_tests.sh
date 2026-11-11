#!/bin/bash
# pr_tests.sh: the branch's tests. Three streams in parallel (none timed): G = CUDA device tests and host tests on
# binary P; L = lavapipe (naga: CI's WGSL dump + lint, then every wgpu test of cubecl_join with the WGSL logged and
# linted too; then CubeCL's SPIR-V compiler); C = cargo fmt --check and clippy as `just lint` runs it.
L=/root/b64/logs/pr; mkdir -p $L; B=/root/b64/bin
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test RUST_BACKTRACE=1
echo PRT_START $(date -u +%T)
( cd /root/b64/run && mkdir -p prt && cd prt
  for t in "join_plan::" "cubecl_join::" "overlap_join::"; do
    $B/P $t --test-threads 8 > $L/host_${t%::}.log 2>&1; echo "host $t: $(grep 'test result' $L/host_${t%::}.log)"
  done
  for t in cubecl_cuda_join_matches_the_cpu_reference cubecl_cuda_top_fd_matches_the_top_kernel \
           cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu cubecl_cuda_join_matches_the_reference_on_a_whole_field; do
    $B/P --ignored --exact cubecl_join::tests::$t --nocapture --test-threads 1 > $L/cuda_$t.log 2>&1
    echo "cuda $t: $(grep 'test result' $L/cuda_$t.log)"
  done
  cd /root/b64/scripts
  bash exact.sh pr_x_e16 P 39667831862957161709568 1e16 48; mv /root/b64/logs/pr_x_e16.log $L/
  echo "dense b64 1e16: $(grep -o 'survivors [0-9]* checked [0-9]*' $L/pr_x_e16.log) $(grep -o 'test result: [a-z]*' $L/pr_x_e16.log)"
  bash exact.sh pr_x_e17 P 58557331862957161709568 1e17 32; mv /root/b64/logs/pr_x_e17.log $L/
  echo "dense b64 1e17: $(grep -o 'survivors [0-9]* checked [0-9]*' $L/pr_x_e17.log) $(grep -o 'test result: [a-z]*' $L/pr_x_e17.log)"
  echo G_DONE $(date -u +%T)
) > $L/stream_G.out 2>&1 &
( export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
  cd /root/b64/src/P
  REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
  rm -f $L/wgsl_ci.log $L/wgsl_join.log
  CUBECL_DEBUG_LOG=$L/wgsl_ci.log $B/P_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > $L/lint_dump.log 2>&1
  python3 scripts/wgsl-lint.py $L/wgsl_ci.log $REQ > $L/wgsl_lint_ci.log 2>&1; echo "CI lint rc=$? $(tail -1 $L/wgsl_lint_ci.log)"
  CUBECL_DEBUG_LOG=$L/wgsl_join.log timeout 3000 $B/P_naga --ignored cubecl_join:: --nocapture --test-threads 1 > $L/lvp_naga.log 2>&1
  echo "lavapipe naga: $(grep 'test result' $L/lvp_naga.log)"
  python3 scripts/wgsl-lint.py $L/wgsl_join.log --verbose > $L/wgsl_lint_join.log 2>&1; echo "join-test WGSL lint rc=$? $(grep -c . $L/wgsl_lint_join.log) lines; b64 shaders: $(grep -c " b64:" $L/wgsl_lint_join.log); $(grep -i "fd.* b64" $L/wgsl_lint_join.log | head -2 | tr "\n" " ") $(tail -1 $L/wgsl_lint_join.log)"
  gzip -f $L/wgsl_ci.log $L/wgsl_join.log
  timeout 3000 $B/P_spv --ignored cubecl_join:: --nocapture --test-threads 1 > $L/lvp_spv.log 2>&1
  echo "lavapipe spirv: $(grep 'test result' $L/lvp_spv.log)"
  echo L_DONE $(date -u +%T)
) > $L/stream_L.out 2>&1 &
( source ~/.cargo/env; cd /root/b64/src/P; export CARGO_TARGET_DIR=/root/tgtc
  cargo fmt --all --check > $L/fmt.log 2>&1; echo "fmt rc=$?"
  nice -n 15 cargo clippy -j 8 -p "*" --all-targets -- -D warnings > $L/clippy_default.log 2>&1; echo "clippy default rc=$?"
  nice -n 15 cargo clippy -j 8 -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings > $L/clippy_gpu_spirv.log 2>&1; echo "clippy gpu+spirv rc=$?"
  echo C_DONE $(date -u +%T)
) > $L/stream_C.out 2>&1 &
wait
echo PRT_DONE $(date -u +%T) | tee $L/prt.done
