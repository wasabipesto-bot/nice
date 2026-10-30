#!/bin/bash
# wgpu detailed tests on lavapipe for one tree: lvp.sh <tree> <test binary> [extra filters]
TREE=$1; cd /root/$TREE
T=$2; shift 2
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_API_BASE=http://127.0.0.1:9
{ date -u; git log --oneline -1; vulkaninfo --summary 2>&1 | grep -E "deviceName|driverName"
  $T --ignored --nocapture --test-threads 1 cubecl_backend::tests::cubecl_matches_cpu_detailed cubecl_backend::tests::cubecl_finds_69_in_base_10 cubecl_backend::tests::cubecl_detailed_survives_more_batches_than_the_task_cap cubecl_web::tests::web_kernel_near_miss_matches_cpu_at_base_49 "$@" 2>&1
  date -u; echo LVP_DONE; } > /root/logs/lvp_$TREE.log 2>&1
