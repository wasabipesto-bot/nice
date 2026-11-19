#!/bin/bash
# lint (the `just lint` recipe, plus clippy with cubecl-cuda), the whole suite (CI's command), lavapipe device tests
# with both compilers (CI's commands) and the WGSL lint. One target dir for this worktree: /root/sra/target.
source ~/.cargo/env
cd /root/sra/nice
export CARGO_TARGET_DIR=/root/sra/target
L=/root/sra/logs/checks; mkdir -p $L
step() { local n=$1; shift; echo "$(date -u +%FT%TZ) start $n: $*" >> $L/steps.log; "$@" > $L/$n.log 2>&1; local rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/steps.log; }
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
if command -v just >/dev/null; then step just_lint just lint; else step just_lint sh -c 'cargo fmt --all --check && cargo clippy -p "*" --all-targets -- -D warnings && cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings'; fi
step clippy_cuda cargo clippy -p nice_common --all-targets --features cubecl-cuda,cubecl-spirv -- -D warnings
step suite cargo test --locked --release --no-fail-fast
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
vulkaninfo --summary 2>&1 | grep -iE "deviceName|driverName" > $L/vulkan.txt
step lvp_wgsl cargo test --release --features cubecl -p nice_common -- --ignored --nocapture
export CUBECL_DEBUG_LOG=$L/wgsl.log
step wgsl_lint sh -c 'cargo test --release --features cubecl -p nice_common --lib -- --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture && python3 scripts/wgsl-lint.py "$CUBECL_DEBUG_LOG" --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57'
unset CUBECL_DEBUG_LOG
step lvp_spirv cargo test --release --features cubecl-spirv -p nice_common -- --ignored --nocapture cubecl_
echo done > $L/done
