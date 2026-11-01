#!/bin/bash
# lavapipe: CubeCL direct SPIR-V compiler, then naga (WGSL) join tests, then the WGSL lint.
L=/root/l30pr
export VK_ICD_FILENAMES="$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)"
unset RUST_MIN_STACK
cd /root/src-pr
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
echo "START lvp_spirv $(date -u +%T) md5=$(md5sum $L/pr_spirv | cut -c1-8) RUST_MIN_STACK=${RUST_MIN_STACK:-unset}" > $L/lvp_spirv.log
$L/pr_spirv --ignored cubecl_join:: --nocapture --test-threads 1 >> $L/lvp_spirv.log 2>&1
echo "END lvp_spirv $(date -u +%T) rc=$?" >> $L/lvp_spirv.log
echo "START lvp_naga $(date -u +%T) md5=$(md5sum $L/pr_wgpu | cut -c1-8)" > $L/lvp_naga.log
$L/pr_wgpu --ignored cubecl_join:: --nocapture --test-threads 1 >> $L/lvp_naga.log 2>&1
echo "END lvp_naga $(date -u +%T) rc=$?" >> $L/lvp_naga.log
rm -f $L/wgsl.log
CUBECL_DEBUG_LOG=$L/wgsl.log $L/pr_wgpu --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > $L/wgsl_dump.log 2>&1
echo "dump rc=$?" >> $L/wgsl_dump.log
python3 /root/src-pr/scripts/wgsl-lint.py $L/wgsl.log \
  --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 \
  --require DetailedFdKernelU32@50 \
  --require DetailedFdKernel@23 --require DetailedFdKernel@40 \
  --require DetailedFdKernel@50 --require DetailedFdKernel@62 \
  --require DetailedKernel@80 --require NiceonlyKernel@40 \
  --require BucketKernel@57 --require JoinKernel@57 \
  --require TopKernel@57 --require CheckKernel@57 --verbose > $L/wgsl_lint.log 2>&1
echo "lint rc=$?" >> $L/wgsl_lint.log
gzip -kf $L/wgsl.log
echo CHAIN_F_DONE $(date -u +%T) > $L/chainF.done
