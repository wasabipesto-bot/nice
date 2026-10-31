#!/bin/bash
# 4-core timing of the new web tests (CI runners have 4 vCPUs), lavapipe
source /root/.cargo/env
cd /root/nice
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json LP_NUM_THREADS=4
L=/root/logs
cargo test --release -p nice_common --features gpu --no-run > $L/t5-build.log 2>&1
for t in web_fd_seed_matches_cpu web_fd_matches_cpu_detailed web_kernel_matches_cpu_detailed web_kernel_near_miss_matches_cpu_at_base_49 web_kernel_finds_69_in_base_10; do
  s=$SECONDS
  taskset -c 0-3 cargo test --release -p nice_common --features gpu --lib -- --ignored --exact cubecl_web::tests::$t --nocapture > $L/t5-$t.log 2>&1
  echo "rc=$? wall=$((SECONDS-s))s" >> $L/t5-$t.log
done
echo done > $L/t5.done
