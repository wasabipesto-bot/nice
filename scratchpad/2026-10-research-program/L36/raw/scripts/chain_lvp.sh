#!/bin/bash
# chain_lvp.sh: lavapipe on all5: CI's WGSL dump + lint (naga, the workflow's 13 requires), join parity on naga and on the direct SPIR-V compiler.
L=/root/l36/logs; BIN=/root/l36/bin
until [ -e $L/lvp.built ]; do sleep 10; done
echo LVP_START $(date -u +%T)
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
cd /root/l36/src/S
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
rm -f $L/wgsl.log
( date -u; CUBECL_DEBUG_LOG=$L/wgsl.log timeout 900 $BIN/S_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump.log 2>&1
( python3 scripts/wgsl-lint.py $L/wgsl.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint.log 2>&1
( python3 scripts/wgsl-lint.py $L/wgsl.log $REQ --require TopFdKernel@57 --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_fd.log 2>&1
gzip -f $L/wgsl.log
P=cubecl_join::tests::cubecl_join_matches_the_cpu_reference
( date -u; timeout 2400 $BIN/S_naga --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_naga.log 2>&1
( date -u; timeout 2400 $BIN/S_spv --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_spv.log 2>&1
echo LVP_DONE $(date -u +%T) > $L/lvp.done
