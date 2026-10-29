#!/bin/bash
# fmt + clippy on the PR tree, as `just lint` (nice_common and nice_client; the server crates need libpq).
source ~/.cargo/env
cd /root/pr
echo "== $(date -u +%T) $(git log --oneline -1)"
cargo fmt --all --check && echo FMT_OK
export CARGO_TARGET_DIR=/root/tgt_clippy
cargo clippy -j ${J:-8} -p nice_common -p nice_client --all-targets -- -D warnings 2>&1 | grep -E "^(warning|error)|-->" | head -40
echo "CLIPPY_DEFAULT_EXIT ${PIPESTATUS[0]}"
cargo clippy -j ${J:-8} -p nice_common -p nice_client --all-targets --features nice_client/gpu -- -D warnings 2>&1 | grep -E "^(warning|error)|-->" | head -40
echo "CLIPPY_GPU_EXIT ${PIPESTATUS[0]}"
cargo clippy -j ${J:-8} -p nice_common -p nice_client --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings > /root/ab/clippy_spirv.log 2>&1
echo "CLIPPY_GPU_SPIRV_EXIT $?"; grep -E "^(warning|error)|-->" /root/ab/clippy_spirv.log | head -20
echo LINT_DONE $(date -u +%T)
