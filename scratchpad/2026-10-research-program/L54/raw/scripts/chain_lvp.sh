#!/bin/bash
# chain_lvp.sh W SRC: lavapipe (llvmpipe) for tree SRC with binaries W_naga (cubecl) and W_spv (cubecl-spirv) (built by
# the caller): CI's WGSL dump + lint (naga, the workflow's 13 requires), then every wgpu test of cubecl_join on naga and
# on direct SPIR-V (CPU reference parity incl. b50/b54, the FD-vs-top test, ...).
L=/root/l54/logs; BIN=/root/l54/bin; W=$1; SRC=$2
echo LVP_START $W $(date -u +%T)
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
cd /root/l54/src/$SRC
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
rm -f $L/wgsl_$W.log
( date -u; CUBECL_DEBUG_LOG=$L/wgsl_$W.log timeout 900 $BIN/${W}_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_$W.log 2>&1
( python3 scripts/wgsl-lint.py $L/wgsl_$W.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_$W.log 2>&1
gzip -f $L/wgsl_$W.log
echo "LVP lint: $(tail -1 $L/wgsl_lint_$W.log) $(grep -c . $L/wgsl_lint_$W.log) lines $(date -u +%T)"
for c in naga spv; do
  ( date -u; timeout 3600 $BIN/${W}_$c --ignored cubecl_join:: --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_${c}_$W.log 2>&1
  echo "LVP $c: $(grep -h 'test result' $L/lvp_${c}_$W.log) $(date -u +%T)"
done
echo LVP_DONE $W $(date -u +%T) > $L/lvp_$W.done
