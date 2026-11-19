#!/bin/bash
# Branch as is, own target dir. Reviewer's run.
source ~/.cargo/env
cd /root/rev/a
export CARGO_TARGET_DIR=/root/rev/ta
L=/root/rev/logs/a; mkdir -p $L
step() { local n=$1; shift; echo "$(date -u +%FT%TZ) start $n: $*" >> $L/steps.log; "$@" > $L/$n.log 2>&1; local rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/steps.log; }
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
step just_lint just lint
step clippy_cuda cargo clippy -p nice_common --all-targets --features cubecl-cuda,cubecl-spirv -- -D warnings
step suite cargo test --locked --release --no-fail-fast
step suite_all cargo test --release -p "*" --no-fail-fast
step gpu_unit env NICE_REQUIRE_NVRTC=1 cargo test --locked --release -p nice_common --features gpu --lib
step metal_check cargo check -p nice_common --all-targets --features cubecl-metal
step cuda_stride cargo test --release --features cubecl-cuda -p nice_common --lib -- --ignored --nocapture --test-threads=1 cubecl_backend::tests::cubecl_cuda_
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
vulkaninfo --summary 2>&1 | grep -iE "deviceName|driverName" > $L/vulkan.txt
step lvp_wgsl cargo test --release --features cubecl -p nice_common -- --ignored --nocapture
export CUBECL_DEBUG_LOG=$L/wgsl.log
step wgsl_lint sh -c 'cargo test --release --features cubecl -p nice_common --lib -- --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture && python3 scripts/wgsl-lint.py "$CUBECL_DEBUG_LOG" --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57'
unset CUBECL_DEBUG_LOG
step lvp_spirv cargo test --release --features cubecl-spirv -p nice_common -- --ignored --nocapture cubecl_
echo done > $L/done
