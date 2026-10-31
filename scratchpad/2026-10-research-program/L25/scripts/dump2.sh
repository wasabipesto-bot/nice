#!/bin/bash
# WGSL dumps on lavapipe at production-shaped fields: dump2.sh <base> <start> <kinds...>
source /root/.cargo/env
B=$1; S=$2; shift 2
T=$(ls -t /root/nice/target/release/deps/nice_common-* | grep -v '\.d$' | head -1)
D=/root/dumps/b$B; mkdir -p $D
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_API_BASE=http://127.0.0.1:9 L25_BASE=$B L25_START=$S
cd /root/nice/common
for k in "$@"; do
  extra="L25_SIZE=1e14 L25_PARTS=0,700,1400,2100,2800"
  [ $k = stride ] && extra="L25_SIZE=2e11"
  s=$(date +%s)
  env $extra CUBECL_DEBUG_LOG=$D/$k.log timeout 1500 $T cubecl_backend::l25_dump::l25_$k --ignored --exact --nocapture --test-threads 1 > $D/$k.run.txt 2>&1
  echo "rc=$? secs=$(( $(date +%s) - s ))" >> $D/$k.run.txt
done
echo DUMP2_DONE >> $D/status
