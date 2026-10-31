#!/bin/bash
# usage: t2.sh TAG FEATURES test...   (ignored tests on lavapipe, one log each)
source /root/.cargo/env
cd /root/nice
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
L=/root/logs; tag=$1; feat=$2; shift 2
for t in "$@"; do
  s=$SECONDS
  cargo test --release -p nice_common --features $feat --lib -- --ignored --exact $t --nocapture > $L/$tag-${t##*::}.log 2>&1; rc=$?
  echo "rc=$rc wall=$((SECONDS-s))s" >> $L/$tag-${t##*::}.log
done
echo done > $L/$tag.done
