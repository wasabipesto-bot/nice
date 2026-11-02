#!/bin/bash
# chain_final.sh: fmt, build F (gpu), CUDA exactness on F; builds client/naga/spv beside it; lavapipe after.
L=/root/l35/logs; BIN=/root/l35/bin; T=/root/l35/test.sh; R=/root/l35/run.sh
source ~/.cargo/env
cd /root/l35/src/B && git status --short | head; git log --oneline -1
( cargo fmt --all --check > $L/fmt.log 2>&1; echo "fmt rc=$?" >> $L/fmt.log )
/root/l35/build.sh B F gpu
( # CUDA exactness on F
  $T xf_fd F cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
  $T xf_cert F cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
  $T xf_ref2 F cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference NICE_EXP_TOP_FD=2
  $T xf_ref1 F cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference NICE_EXP_TOP_FD=1
  $T xf_dense58 F cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_EXP_TOP_FD=2 NICE_TEST_JOIN_DENSE=32
  $T xf_dense62 F cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_EXP_TOP_FD=2 NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
  $T xf_whole F cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_EXP_TOP_FD=2 NICE_TEST_JOIN_FULL_FIELD=1
  NICE_EXP_TOP_FD=2 $R F2_cmp_e14 F 57,60,62,64 1 1e14 1
  NICE_EXP_TOP_FD=0 $R F0_cmp_e14 F 57,60,62,64 1 1e14 1
  echo CUDA_X_DONE $(date -u +%T) > $L/cudax.done ) &
/root/l35/buildclient.sh B client_F
CARGO_TARGET_DIR=/root/tgt_lvp /root/l35/build.sh B F_naga cubecl /root/tgt_lvp
CARGO_TARGET_DIR=/root/tgt_lvp /root/l35/build.sh B F_spv cubecl-spirv /root/tgt_lvp
echo BUILDS_DONE $(date -u +%T) > $L/builds.done
# lavapipe
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
cd /root/l35/src/B
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
for FD in 0 2; do
  rm -f $L/wgsl_fd$FD.log
  ( date -u; NICE_EXP_TOP_FD=$FD CUBECL_DEBUG_LOG=$L/wgsl_fd$FD.log timeout 900 $BIN/F_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_fd$FD.log 2>&1
done
( python3 scripts/wgsl-lint.py $L/wgsl_fd0.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_fd0.log 2>&1
( python3 scripts/wgsl-lint.py $L/wgsl_fd2.log $(echo $REQ | sed 's/--require TopKernel@57/--require TopFdKernel@57/') --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_fd2.log 2>&1
gzip -f $L/wgsl_fd0.log $L/wgsl_fd2.log
( date -u; timeout 2400 $BIN/F_naga --ignored --exact cubecl_join::tests::top_fd_matches_the_top_kernel --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_fd_naga.log 2>&1
rm -f $L/fddump_spv.log
( date -u; CUBECL_DEBUG_LOG=$L/fddump_spv.log timeout 2400 $BIN/F_spv --ignored --exact cubecl_join::tests::top_fd_matches_the_top_kernel --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_fd_spv.log 2>&1
python3 /root/l35/blocks.py $L/fddump_spv.log --top 30 > $L/blocks_fd_spv.txt 2>&1
gzip -f $L/fddump_spv.log
( date -u; NICE_EXP_TOP_FD=2 timeout 1800 $BIN/F_spv --ignored --exact cubecl_join::tests::cubecl_join_matches_the_cpu_reference --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_spv_fd2.log 2>&1
echo LVP_DONE $(date -u +%T) > $L/lvp.done
