#!/bin/bash
# CUDA device tests; the regression tests with the host check removed (must fail); the whole workspace suite
# (`just test`'s -p "*" form); a Metal-feature check. Same worktree, same target dir.
source ~/.cargo/env
cd /root/sra/nice
export CARGO_TARGET_DIR=/root/sra/target
L=/root/sra/logs/phase2; mkdir -p $L
step() { local n=$1; shift; echo "$(date -u +%FT%TZ) start $n: $*" >> $L/steps.log; "$@" > $L/$n.log 2>&1; local rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/steps.log; }
git log --oneline -1 > $L/head.txt
step cuda_device cargo test --release --features cubecl-cuda -p nice_common -- --ignored --nocapture cubecl_cuda_
# without the fix: drop the host's check (the kernel's count stays; nothing reads it)
grep -c '    ran_complete(base, counts, cubes)?;' common/src/cubecl_backend.rs > $L/nofix_patch.txt
sed -i '/^    ran_complete(base, counts, cubes)?;$/d' common/src/cubecl_backend.rs
git diff >> $L/nofix_patch.txt
step nofix_cuda cargo test --release --features cubecl-cuda -p nice_common -- --ignored --nocapture cubecl_cuda_dropped_launches_fail_the_field
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json step nofix_lvp_wgsl cargo test --release --features cubecl -p nice_common -- --ignored --nocapture cubecl_dropped_launches_fail_the_field
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json step nofix_lvp_spirv cargo test --release --features cubecl-spirv -p nice_common -- --ignored --nocapture cubecl_dropped_launches_fail_the_field
git checkout -- common/src/cubecl_backend.rs
git status --short > $L/restored.txt
step workspace_suite cargo test --release -p "*" --no-fail-fast
step metal_check cargo check -p nice_common --all-targets --features cubecl-metal
echo done > $L/done
