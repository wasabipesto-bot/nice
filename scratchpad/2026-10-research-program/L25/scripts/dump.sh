#!/bin/bash
# WGSL dumps on lavapipe: dump.sh <base> -> /root/dumps/b<base>/<kind>.log
source /root/.cargo/env
B=$1
T=$(ls -t /root/nice/target/release/deps/nice_common-* | grep -v '\.d$' | head -1)
D=/root/dumps/b$B; mkdir -p $D
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_API_BASE=http://127.0.0.1:9 L25_BASE=$B
cd /root/nice/common
for k in stride join detailed web; do
  extra=""
  if [ $k = join ] && [ $B = 40 ]; then extra="NICE_JOIN_ROUTE=join L25_SIZE=1e12"; fi
  s=$(date +%s)
  env $extra CUBECL_DEBUG_LOG=$D/$k.log timeout 1500 $T cubecl_backend::l25_dump::l25_$k --ignored --exact --nocapture --test-threads 1 > $D/$k.run.txt 2>&1
  echo "rc=$? secs=$(( $(date +%s) - s ))" >> $D/$k.run.txt
done
echo DUMP_DONE > $D/status
