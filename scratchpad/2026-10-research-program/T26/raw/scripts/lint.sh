#!/bin/bash
# lint.sh TREE: CI's lint on $W/wt/TREE (fmt check; clippy -D warnings default and with gpu+spirv features), own target dir
W=/root/t26; T=$1; . /root/.cargo/env
cd $W/wt/$T || exit 1
export CARGO_TARGET_DIR=$W/target-lint-$T NICE_BUILD_SHA=test
{
echo "== $T $(git log --oneline -1 | cut -c1-60) diff: $(git diff --stat | tail -1) rustc: $(rustc --version)"
cargo fmt --all --check && echo FMT_OK
cargo clippy -j ${JOBS:-8} -p "*" --all-targets -- -D warnings && echo CLIPPY_DEFAULT_OK
cargo clippy -j ${JOBS:-8} -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings && echo CLIPPY_GPU_OK
} > $W/logs/lint_$T.log 2>&1
grep -E "^== |_OK$|^error" $W/logs/lint_$T.log | head
