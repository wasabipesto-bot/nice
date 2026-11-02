#!/bin/bash
# chain_lvp.sh G: lavapipe with the transposed AND on (group G): CI's WGSL dump + lint (naga), join parity on naga and
# on the direct SPIR-V compiler (with a dump for the JoinKernel block count), and parity with the switch off on SPIR-V.
G=${1:-8}
L=/root/l34/logs; BIN=/root/l34/bin
until [ -e $L/lvpbuilds.done ]; do sleep 10; done
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
cd /root/l34/src/F
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
ON="NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$G"
rm -f $L/wgsl_g$G.log
( date -u; env $ON CUBECL_DEBUG_LOG=$L/wgsl_g$G.log timeout 900 $BIN/F_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_g$G.log 2>&1
( python3 /root/l34/src/F/scripts/wgsl-lint.py $L/wgsl_g$G.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_g$G.log 2>&1
gzip -f $L/wgsl_g$G.log
P=cubecl_join::tests::cubecl_join_matches_the_cpu_reference
( date -u; env $ON timeout 1800 $BIN/F_naga --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_naga_g$G.log 2>&1
rm -f $L/pardump_spv_g$G.log
( date -u; env $ON CUBECL_DEBUG_LOG=$L/pardump_spv_g$G.log timeout 1800 $BIN/F_spv --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_spv_g$G.log 2>&1
python3 /root/l34/blocks.py $L/pardump_spv_g$G.log --name JoinKernel --top 40 > $L/blocks_par_g$G.txt 2>&1
gzip -f $L/pardump_spv_g$G.log
rm -f $L/pardump_spv_off.log
( date -u; CUBECL_DEBUG_LOG=$L/pardump_spv_off.log timeout 1800 $BIN/F_spv --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_spv_off.log 2>&1
python3 /root/l34/blocks.py $L/pardump_spv_off.log --name JoinKernel --top 40 > $L/blocks_par_off.txt 2>&1
gzip -f $L/pardump_spv_off.log
echo LVP_DONE $(date -u +%T) > $L/lvp_g$G.done
