#!/bin/bash
# lint.sh: fmt + the three clippy runs of `just lint` on the checked-out fix
# tree (a separate worktree /root/nice-lint at origin/pr/fd-u32-mask, so the
# release builds in /root/nice are untouched).
source /root/.cargo/env
L=/root/logs/lint; mkdir -p $L
cd /root/nice
git fetch -q origin pr/fd-u32-mask
[ -d /root/nice-lint ] || git worktree add -q /root/nice-lint origin/pr/fd-u32-mask
cd /root/nice-lint && git checkout -q --detach origin/pr/fd-u32-mask && git log --oneline -1 > $L/rev.txt
export CARGO_TARGET_DIR=/root/target-lint
{ date -u; cargo fmt --all --check; echo "fmt rc=$?"; } > $L/fmt.log 2>&1
{ date -u; cargo clippy -p "*" --all-targets -- -D warnings; echo "clippy-default rc=$?"; date -u; } > $L/clippy-default.log 2>&1
{ date -u; cargo clippy -p "*" --all-targets --features nice_client/gpu -- -D warnings; echo "clippy-gpu rc=$?"; date -u; } > $L/clippy-gpu.log 2>&1
{ date -u; cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings; echo "clippy-gpu-spirv rc=$?"; date -u; } > $L/clippy-gpu-spirv.log 2>&1
echo LINT_DONE >> $L/rev.txt
