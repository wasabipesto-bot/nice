#!/bin/bash
# spirv.sh: the fix tree's nice_common test binary with gpu,cubecl-spirv (own
# target dir), then the lavapipe FD tests through CubeCL's SPIR-V compiler.
source /root/.cargo/env
L=/root/logs/spirv; mkdir -p $L /root/bin
cd /root/nice
git fetch -q origin pr/fd-u32-mask
[ -d /root/nice-spirv ] || git worktree add -q /root/nice-spirv origin/pr/fd-u32-mask
cd /root/nice-spirv && git checkout -q -f --detach origin/pr/fd-u32-mask
sed "s/L28TREE/L28TREE-spirv/" /root/l28_local.rs >> common/src/cubecl_detailed_fd.rs
export CARGO_TARGET_DIR=/root/target-spirv
{ date -u; git log --oneline -1
  cargo test --release -p nice_common --features gpu,cubecl-spirv --no-run 2>&1 | grep -E "Executable unittests|^error|^warning|Finished"
  T=$(ls -t /root/target-spirv/release/deps/nice_common-* | grep -v '\.d$' | head -1); cp $T /root/bin/spirv-test
  git checkout -q -- common/src/cubecl_detailed_fd.rs; date -u; } > $L/build.log 2>&1
cd /root/nice-spirv/common
{ date -u; VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_API_BASE=http://127.0.0.1:9 /root/bin/spirv-test \
    --ignored --nocapture --test-threads 1 --exact \
    cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu \
    cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed \
    cubecl_backend::tests::cubecl_reads_back_every_near_miss \
    cubecl_backend::tests::cubecl_matches_cpu_detailed \
    cubecl_detailed_fd::l28_local::l28_wgpu_fd_sweep; echo "rc=$?"; date -u; } > $L/lvp-spirv.log 2>&1
echo SPIRV_DONE >> $L/build.log
