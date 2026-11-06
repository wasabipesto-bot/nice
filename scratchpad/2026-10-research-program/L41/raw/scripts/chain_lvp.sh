#!/bin/bash
# chain_lvp.sh W: lavapipe (llvmpipe) on tree W: builds (cubecl = naga, cubecl-spirv = direct SPIR-V; own target dir,
# niced), CI's WGSL dump + lint (naga, the workflow's 13 requires), and on naga and SPIR-V every wgpu test of
# cubecl_join (join parity incl. b50/b54, the FD-vs-top-kernel test, the certificate test, ...).
L=/root/l41/logs; BIN=/root/l41/bin; W=$1

[ -e $BIN/${W}_naga ] || NICEN=15 J=10 /root/l41/build.sh $W ${W}_naga cubecl /root/tgt_lvp
[ -e $BIN/${W}_spv ] || NICEN=15 J=10 /root/l41/build.sh $W ${W}_spv cubecl-spirv /root/tgt_lvp
touch $L/lvp_${W}.built
[ -n "$LVP_WAIT" ] && until [ -e $L/lvp_go ]; do sleep 10; done
echo LVP_START $W $(date -u +%T)
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
vulkaninfo 2>/dev/null | grep -i "subgroupSize\|minSubgroupSize\|maxSubgroupSize\|maxStorageBufferRange" | head -8 >> $L/lvp_device.txt
cd /root/l41/src/$W
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
rm -f $L/wgsl_${W}.log
( date -u; CUBECL_DEBUG_LOG=$L/wgsl_${W}.log timeout 900 $BIN/${W}_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_${W}.log 2>&1
( python3 scripts/wgsl-lint.py $L/wgsl_${W}.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_${W}.log 2>&1
gzip -f $L/wgsl_${W}.log
for c in naga spv; do
  ( date -u; timeout 3600 $BIN/${W}_$c --ignored cubecl_join:: --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_${c}_${W}.log 2>&1
done
echo LVP_DONE $W $(date -u +%T) > $L/lvp_${W}.done
