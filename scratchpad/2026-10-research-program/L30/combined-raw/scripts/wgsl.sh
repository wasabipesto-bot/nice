#!/bin/bash
# WGSL lint as CI runs it: wgsl_dump_for_lint on lavapipe (naga), then scripts/wgsl-lint.py with CI's require list.
L=/root/cmb
dpkg -s mesa-vulkan-drivers > /dev/null 2>&1 || apt-get install -y -qq mesa-vulkan-drivers libvulkan1 vulkan-tools > $L/apt_lvp.log 2>&1
export VK_ICD_FILENAMES="$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)"
test -n "$VK_ICD_FILENAMES" || { echo "no lavapipe ICD" > $L/wgsl_lint.log; exit 1; }
cd /root/both
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
rm -f $L/wgsl.log
CUBECL_DEBUG_LOG=$L/wgsl.log $L/both_wgpu --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > $L/wgsl_dump.log 2>&1
echo "dump rc=$?" >> $L/wgsl_dump.log
python3 /root/both/scripts/wgsl-lint.py $L/wgsl.log \
  --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 \
  --require DetailedFdKernelU32@50 \
  --require DetailedFdKernel@23 --require DetailedFdKernel@40 \
  --require DetailedFdKernel@50 --require DetailedFdKernel@62 \
  --require DetailedKernel@80 --require NiceonlyKernel@40 \
  --require BucketKernel@57 --require JoinKernel@57 \
  --require TopKernel@57 --require CheckKernel@57 --verbose > $L/wgsl_lint.log 2>&1
echo "lint rc=$?" >> $L/wgsl_lint.log
gzip -kf $L/wgsl.log
echo WGSL_DONE $(date -u +%T) > $L/wgsl.done
