#!/bin/bash
# dump40.sh: b40 stride dumps at 1e9 (1e7 left no MSD range in the window), both trees,
# plus the Vulkan device list lavapipe runs see.
while ! grep -q PIPELINE_DONE /root/logs/tests.status 2>/dev/null; do sleep 10; done
cd /root/nice/common
export NICE_API_BASE=http://127.0.0.1:9 VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
vulkaninfo --summary > /root/logs/vulkaninfo_lvp.txt 2>&1
for tree in main fix; do
  s=$(date +%s)
  { echo "== $tree"; date -u
    CUBECL_DEBUG_LOG=/root/logs/$tree/wgsl_stride_b40_1e9.log L26_BASE=40 L26_SIZE=1e9 \
      /root/bin/$tree-test cubecl_backend::l26_local::l26_stride --ignored --exact --nocapture --test-threads 1 2>&1
    echo "rc=$? secs=$(( $(date +%s) - s ))"; } > /root/logs/$tree/dump_b40_1e9.log 2>&1
done
echo "DUMP40_DONE $(date -u +%T)" >> /root/logs/tests.status
