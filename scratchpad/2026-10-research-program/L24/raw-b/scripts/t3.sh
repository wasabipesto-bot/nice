#!/bin/bash
source /root/.cargo/env
cd /root/nice
L=/root/logs
run() { # tag cmd...
  local tag=$1; shift; local s=$SECONDS
  "$@" > $L/$tag.log 2>&1; local rc=$?
  echo "rc=$rc wall=$((SECONDS-s))s" >> $L/$tag.log
}
# 1. WGSL dumps of the web kernels (lavapipe, naga WGSL)
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
for t in web_fd_matches_cpu_detailed web_kernel_matches_cpu_detailed web_fd_seed_matches_cpu; do
  rm -f $L/wgsl-$t.log
  CUBECL_DEBUG_LOG=$L/wgsl-$t.log run t3-dump-$t cargo test --release -p nice_common --features gpu --lib -- --ignored --exact cubecl_web::tests::$t
done
# 2. native lavapipe FD suite (regression)
for t in cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed cubecl_backend::tests::cubecl_reads_back_every_near_miss cubecl_backend::tests::cubecl_matches_cpu_detailed; do
  run t3-lvp-${t##*::} cargo test --release -p nice_common --features gpu --lib -- --ignored --exact $t --nocapture
done
unset VK_ICD_FILENAMES
# 3. CUDA FD suite (regression: native kernel unchanged)
for t in cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss; do
  run t3-cuda-${t##*::} cargo test --release -p nice_common --features gpu --lib -- --ignored --exact $t --nocapture
done
# 4. clippy
run t3-clippy-default cargo clippy -p nice_common --all-targets -- -D warnings
run t3-clippy-gpu cargo clippy -p nice_common --all-targets --features gpu -- -D warnings
run t3-clippy-gpu-spirv cargo clippy -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings
run t3-clippy-wasm-client cargo clippy -p nice-wasm-client --all-targets -- -D warnings
echo done > $L/t3.done
