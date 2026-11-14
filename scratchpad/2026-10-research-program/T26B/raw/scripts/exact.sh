#!/bin/bash
# exact.sh: exactness of the commit's tree (F2 = gpu, F2S = gpu,cubecl-spirv): the cubecl_backend device suites
# (CUDA tests on the 3080, wgpu tests on lavapipe with both compilers, each test in its own process), the kernel
# identity check against main (ident.sh), CI's host-test command, fmt and clippy (pinned toolchain).
W=/root/t26b; S=$W/scripts; O=$W/out
echo "EXACT START $(date -u +%T)" > $O/exact.out
ONLY=cuda bash $S/suite.sh F2 > $O/suite_cuda_F2.out 2>&1
BINS="M F2" bash $S/ident.sh > $O/ident.out 2>&1
echo "cuda+ident done $(date -u +%T)" >> $O/exact.out
( ONLY=lvp bash $S/suite.sh F2 > $O/suite_lvp_F2.out 2>&1; ONLY=lvp bash $S/suite.sh F2S > $O/suite_lvp_F2S.out 2>&1 ) &
. /root/.cargo/env
cd $W/wt/fix
CARGO_TARGET_DIR=$W/target-fix cargo test --release -j 8 -p nice_common --features gpu --lib > $W/logs/F2_host_tests.log 2>&1; echo "HOST rc=$? $(grep 'test result' $W/logs/F2_host_tests.log)" >> $O/exact.out
{ cargo fmt --all --check && echo FMT_OK
  CARGO_TARGET_DIR=$W/target-lint cargo clippy -j 8 -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings && echo CLIPPY_COMMON_OK
  CARGO_TARGET_DIR=$W/target-lint cargo clippy -j 8 -p "*" --all-targets -- -D warnings && echo CLIPPY_ALL_OK
  CARGO_TARGET_DIR=$W/target-lint cargo clippy -j 8 -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings && echo CLIPPY_ALL_GPU_OK
  rustc --version; } > $O/lint_F2.log 2>&1
grep "_OK\|rustc" $O/lint_F2.log >> $O/exact.out
wait
echo "EXACT DONE $(date -u +%T)" >> $O/exact.out
