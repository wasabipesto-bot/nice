#!/bin/bash
# chain_prx.sh M: checks at the PR head (src P$M, binaries P$M, client_P$M): CUDA exactness and the 1e14 compare
# (PR vs #236's head) on the GPU after the gate screen; then lavapipe parity (naga + direct SPIR-V) and CI's WGSL
# lint with the binaries chain_prcpu.sh built; waits for its fmt/clippy.
M=$1; P=P$M
L=/root/l34/logs; S=/root/l34; R=$S/run.sh; T=$S/test.sh; BIN=/root/l34/bin
until [ -e $L/min.done ]; do sleep 10; done
$T prx${M}_ref $P cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T prx${M}_dense58 $P cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T prx${M}_dense62 $P cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T prx${M}_whole $P cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
$R prcmp${M}_e14 $P 57,60,62,64 1 1e14 1
$R b236cmp_e14 B236 57,60,62,64 1 1e14 1
until [ -e $L/prlb_$M.done ]; do sleep 10; done
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
cd /root/l34/src/$P
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
rm -f $L/wgsl_pr$M.log
( date -u; CUBECL_DEBUG_LOG=$L/wgsl_pr$M.log timeout 900 $BIN/${P}_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/pr${M}_lint_dump.log 2>&1
( python3 /root/l34/src/$P/scripts/wgsl-lint.py $L/wgsl_pr$M.log $REQ --verbose; echo "lint rc=$?" ) > $L/pr${M}_wgsl_lint.log 2>&1
gzip -f $L/wgsl_pr$M.log
PT=cubecl_join::tests::cubecl_join_matches_the_cpu_reference
( date -u; timeout 1800 $BIN/${P}_naga --ignored --exact $PT --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/pr${M}_lvp_par_naga.log 2>&1
rm -f $L/pardump_pr$M.log
( date -u; CUBECL_DEBUG_LOG=$L/pardump_pr$M.log timeout 1800 $BIN/${P}_spv --ignored --exact $PT --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/pr${M}_lvp_par_spv.log 2>&1
python3 /root/l34/blocks.py $L/pardump_pr$M.log --name JoinKernel --top 40 > $L/pr${M}_blocks.txt 2>&1
gzip -f $L/pardump_pr$M.log
until [ -e $L/prlint_$M.done ]; do sleep 10; done
echo PRX_DONE $(date -u +%T) > $L/prx_$M.done
