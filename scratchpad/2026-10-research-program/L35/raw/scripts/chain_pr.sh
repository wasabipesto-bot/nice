#!/bin/bash
# chain_pr.sh: PR branch pr/top-fd (P) against its base 51410e7 (P0, built by build_p0.sh).
# fmt; build P; CUDA exactness on P (+ P0 1e14 compare); client/naga/spv builds and clippy beside it;
# lavapipe (lint, FD test, parity on both compilers); then the A/B (chain_prab.sh).
L=/root/l35/logs; BIN=/root/l35/bin; T=/root/l35/test.sh; R=/root/l35/run2.sh
source ~/.cargo/env
until [ -e $L/p0.done ]; do sleep 10; done
cd /root/nice && git fetch -q origin pr/top-fd && (git worktree add -q /root/l35/src/P FETCH_HEAD 2>/dev/null || (cd /root/l35/src/P && git checkout -q --detach FETCH_HEAD))
cd /root/l35/src/P && git log --oneline -2 > $L/p_tree.txt && md5sum common/src/cubecl_join.rs >> $L/p_tree.txt
( cargo fmt --all --check > $L/p_fmt.log 2>&1; echo "fmt rc=$?" >> $L/p_fmt.log )
/root/l35/build.sh P P gpu
( export SRCD=P
  $T px_fd P cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
  $T px_cert P cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
  $T px_ref P cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
  $T px_dense58 P cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
  $T px_dense62 P cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
  $T px_whole P cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
  $R P_cmp_e14 P 57,60,62,64 1 1e14 1
  SRCD=P0 $R P0_cmp_e14 P0 57,60,62,64 1 1e14 1
  echo PCUDA_DONE $(date -u +%T) > $L/pcuda.done ) &
/root/l35/buildclient.sh P client_P
CARGO_TARGET_DIR=/root/tgt_lvp /root/l35/build.sh P P_naga cubecl /root/tgt_lvp
CARGO_TARGET_DIR=/root/tgt_lvp /root/l35/build.sh P P_spv cubecl-spirv /root/tgt_lvp
cd /root/l35/src/P
export CARGO_TARGET_DIR=/root/tgt_clippy NICE_BUILD_SHA=test
( cargo clippy -j 6 -p "*" --all-targets -- -D warnings > $L/p_clippy_default.log 2>&1; echo "clippy default rc=$?" >> $L/p_clippy_default.log
  cargo clippy -j 6 -p "*" --all-targets --features nice_client/gpu -- -D warnings > $L/p_clippy_gpu.log 2>&1; echo "clippy gpu rc=$?" >> $L/p_clippy_gpu.log )
unset CARGO_TARGET_DIR
echo PBUILDS_DONE $(date -u +%T) > $L/pbuilds.done
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
rm -f $L/p_wgsl.log
( date -u; CUBECL_DEBUG_LOG=$L/p_wgsl.log timeout 900 $BIN/P_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/p_lint_dump.log 2>&1
( python3 scripts/wgsl-lint.py $L/p_wgsl.log $REQ --verbose; echo "lint rc=$?" ) > $L/p_wgsl_lint.log 2>&1
( python3 scripts/wgsl-lint.py $L/p_wgsl.log $REQ --require TopFdKernel@57 --verbose; echo "lint rc=$?" ) > $L/p_wgsl_lint_fd.log 2>&1
gzip -f $L/p_wgsl.log
( date -u; timeout 2400 $BIN/P_naga --ignored --exact cubecl_join::tests::top_fd_matches_the_top_kernel --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/p_lvp_fd_naga.log 2>&1
rm -f $L/p_fddump_spv.log
( date -u; CUBECL_DEBUG_LOG=$L/p_fddump_spv.log timeout 2400 $BIN/P_spv --ignored --exact cubecl_join::tests::top_fd_matches_the_top_kernel --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/p_lvp_fd_spv.log 2>&1
python3 /root/l35/blocks.py $L/p_fddump_spv.log --top 30 > $L/p_blocks_fd_spv.txt 2>&1
gzip -f $L/p_fddump_spv.log
( date -u; timeout 1800 $BIN/P_spv --ignored --exact cubecl_join::tests::cubecl_join_matches_the_cpu_reference --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/p_lvp_par_spv.log 2>&1
( date -u; timeout 1800 $BIN/P_naga --ignored --exact cubecl_join::tests::cubecl_join_matches_the_cpu_reference --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/p_lvp_par_naga.log 2>&1
echo PLVP_DONE $(date -u +%T) > $L/plvp.done
