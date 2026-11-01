#!/bin/bash
# wgsl.sh TAG [VAR=VAL]: WGSL lint as CI runs it (wgsl_dump_for_lint on lavapipe, scripts/wgsl-lint.py with CI's requires).
TAG=$1; shift
L=/root/pad
export VK_ICD_FILENAMES="$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)"
cd /root/padsrc
rm -f $L/wgsl_$TAG.log
env "$@" CUBECL_DEBUG_LOG=$L/wgsl_$TAG.log $L/pad_wgpu --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > $L/wgsl_dump_$TAG.log 2>&1
echo "dump rc=$?" >> $L/wgsl_dump_$TAG.log
python3 /root/padsrc/scripts/wgsl-lint.py $L/wgsl_$TAG.log \
  --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 \
  --require DetailedFdKernelU32@50 \
  --require DetailedFdKernel@23 --require DetailedFdKernel@40 \
  --require DetailedFdKernel@50 --require DetailedFdKernel@62 \
  --require DetailedKernel@80 --require NiceonlyKernel@40 \
  --require BucketKernel@57 --require JoinKernel@57 \
  --require TopKernel@57 --require CheckKernel@57 --verbose > $L/wgsl_lint_$TAG.log 2>&1
echo "lint rc=$?" >> $L/wgsl_lint_$TAG.log
gzip -f $L/wgsl_$TAG.log
