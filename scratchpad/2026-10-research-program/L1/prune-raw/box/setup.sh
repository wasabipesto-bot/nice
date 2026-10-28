#!/bin/bash
# Build both trees on the Vast box (run under nohup). A = 2d740d3 (85b5b4e + test-only
# harness commits), B = 4670ffe (A's harness + the prune).
source ~/.cargo/env
mkdir -p /root/ab
cd /root/nice
git fetch -q origin rp/field-cert-prune rp/field-cert-prune-base rp/gpu-profile
git fetch -q https://github.com/wasabipesto/nice.git main
echo "upstream main: $(git rev-parse --short FETCH_HEAD)"
[ -d /root/main ] || git worktree add -q --detach /root/main 2d740d3
[ -d /root/prune ] || git worktree add -q --detach /root/prune 4670ffe
(rustup component add clippy > /root/ab/clippy_install.log 2>&1) &
build() {
  cd /root/$1
  echo "[$1] $(git log --oneline -1)"
  cargo build --release -j 24 -p nice_client --features gpu > /root/ab/build_$1.log 2>&1 || { echo "[$1] client build FAILED"; return 1; }
  cargo test --release -j 24 -p nice_common --features gpu --no-run > /root/ab/testbuild_$1.log 2>&1 || { echo "[$1] test build FAILED"; return 1; }
  grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/ab/testbuild_$1.log | head -1 | sed "s|^|/root/$1/|" > /root/ab/bin_$1
  echo "[$1] built $(cat /root/ab/bin_$1)"
}
build main & build prune & wait
echo SETUP_DONE
