#!/bin/bash
# lint.sh: CI's `just lint` recipe on the fix tree (pinned toolchain), log /root/w/out/lint.log
. /root/.cargo/env; cd /root/w/fix; export CARGO_TARGET_DIR=/root/w/target-lint
{ git log --oneline -1; git diff --stat | tail -1; rustc --version
  cargo fmt --all --check && echo FMT_OK
  cargo clippy -j 16 -p "*" --all-targets -- -D warnings && echo CLIPPY_ALL_OK
  cargo clippy -j 16 -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings && echo CLIPPY_GPU_SPIRV_OK
  echo LINT_DONE; } > /root/w/out/lint.log 2>&1
