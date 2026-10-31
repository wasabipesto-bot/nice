#!/bin/bash
# Final tree (5d4ce8a): host tests, WGSL dumps + lint, CUDA and lavapipe regression.
source /root/.cargo/env
cd /root/nice
L=/root/logs
run() { local tag=$1; shift; local s=$SECONDS; "$@" > $L/$tag.log 2>&1; echo "rc=$? wall=$((SECONDS-s))s" >> $L/$tag.log; }
run t7-host cargo test --release -p nice_common --features gpu --lib
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
for t in web_fd_matches_cpu_detailed web_kernel_matches_cpu_detailed web_fd_seed_matches_cpu; do
  rm -f $L/wgsl7-$t.log
  CUBECL_DEBUG_LOG=$L/wgsl7-$t.log run t7-dump-$t cargo test --release -p nice_common --features gpu --lib -- --ignored --exact cubecl_web::tests::$t --nocapture
done
req=""; for b in 10 12 13 14 15 17 18 19 20 22 23 24 25 27 28 29 30 32 33 34 35 37 38 39 40 42 43 44 45 47 48 49 50 52 53 54 55 57 58 59 60 62 63 64; do req="$req --require DetailedFdKernelU32@$b --require FdSeedProbeKernelU32@$b"; done
python3 /root/wgsl-lint.py --verbose $L/wgsl7-*.log $req --require DetailedKernelU32@40 --require DetailedKernelU32@50 --require DetailedKernelU32@80 --require DetailedKernelU32@97 > $L/t7-lint.log 2>&1; echo "rc=$?" >> $L/t7-lint.log
for t in cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed cubecl_backend::tests::cubecl_reads_back_every_near_miss cubecl_backend::tests::cubecl_matches_cpu_detailed; do
  run t7-lvp-${t##*::} cargo test --release -p nice_common --features gpu --lib -- --ignored --exact $t --nocapture
done
unset VK_ICD_FILENAMES
for t in cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss; do
  run t7-cuda-${t##*::} cargo test --release -p nice_common --features gpu --lib -- --ignored --exact $t --nocapture
done
gzip -kf $L/wgsl7-*.log
echo done > $L/t7.done
