#!/bin/bash
# Readback branch: GPU tests under CUDA, then the wgpu ones on lavapipe.
cd /root/rb
T=target/release/deps/nice_common-c0034331d0049e16
export NICE_API_BASE=http://127.0.0.1:9
{ date -u; git log --oneline -1
  $T --ignored --nocapture --test-threads 1 cubecl_cuda_reads_back_every_near_miss cubecl_cuda_matches_cpu_detailed gpu_reads_back_every_near_miss gpu_matches_cpu_detailed_small 2>&1
  echo "== lavapipe"; date -u
  VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json $T --ignored --nocapture --test-threads 1 cubecl_reads_back_every_near_miss cubecl_matches_cpu_detailed 2>&1
  date -u; echo TESTS_DONE; } > /root/logs/tests_rb.log 2>&1
