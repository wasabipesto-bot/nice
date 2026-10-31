#!/bin/bash
# Phase 1 on the box: checkouts (main 7362e18, branch 215952d), builds, fmt, clippy, host suite.
set -u
source /root/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
mkdir -p /root/v /root/bin
log() { echo "=== $(date -u +%T) $*"; }
MAIN=7362e18; PR=${PR:-215952d}
testbin() { grep -E 'Executable unittests src/lib.rs' "$1" | sed 's/.*(\(.*\))/\1/'; }
{
log setup
cd /root/nice
git remote add upstream https://github.com/wasabipesto/nice.git 2>/dev/null
git fetch -q upstream main && git fetch -q origin pr/fd-seed-split16
git checkout -q $MAIN && git log --oneline -1
test -d /root/pr || git worktree add -q --detach /root/pr $PR
(cd /root/pr && git checkout -q $PR && git log --oneline -1 && git status --short | head -3)
cd /root/pr && rustup show active-toolchain 2>&1 | tail -1; rustc --version; cargo --version
log fetch
export CARGO_NET_RETRY=10 CARGO_HTTP_MULTIPLEXING=false CARGO_HTTP_TIMEOUT=120
for i in 1 2 3 4 5 6; do cargo fetch > /root/v/fetch-$i.txt 2>&1 && { echo "FETCH ok try $i"; break; }; echo "FETCH try $i failed: $(tail -1 /root/v/fetch-$i.txt)"; sleep 10; done
for t in main pr; do
  d=/root/nice; [ $t = pr ] && d=/root/pr
  cd $d
  log build-$t
  cargo build --release -p nice_client --features gpu 2>&1 | tail -2; echo "BUILD_$t rc ${PIPESTATUS[0]}"
  cp target/release/nice_client /root/bin/nice_client_$t
  /root/bin/nice_client_$t --version 2>&1 | head -2; sha256sum /root/bin/nice_client_$t
  log testbuild-$t
  cargo test --release -p nice_common --features gpu --no-run > /root/v/norun-$t.txt 2>&1; echo "NORUN_$t rc $?"
  tail -4 /root/v/norun-$t.txt
  cp "$d/$(testbin /root/v/norun-$t.txt)" /root/bin/test_$t && sha256sum /root/bin/test_$t
done
cd /root/pr
log fmt
cargo fmt --all --check; echo "FMT rc $?"
log clippy-default
cargo clippy -p nice_common --all-targets -- -D warnings 2>&1 | tail -3; echo "CLIPPY_DEFAULT rc ${PIPESTATUS[0]}"
log clippy-gpu
cargo clippy -p nice_common --all-targets --features gpu -- -D warnings 2>&1 | tail -3; echo "CLIPPY_GPU rc ${PIPESTATUS[0]}"
log clippy-gpu-spirv
cargo clippy -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings 2>&1 | tail -3; echo "CLIPPY_GPU_SPIRV rc ${PIPESTATUS[0]}"
log host-suite
cargo test --release -p nice_common --features gpu > /root/v/host-full.log 2>&1; echo "HOST rc $?"
grep -E "^test result|FAILED|panicked" /root/v/host-full.log
log done-p1
} > /root/v/p1.log 2>&1
