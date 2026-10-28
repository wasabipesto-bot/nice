#!/bin/bash
# Build both trees on the Vast box. Run under nohup.
set -ex
source ~/.cargo/env
cd /root/nice
git fetch https://github.com/wasabipesto/nice.git main
git fetch origin rp/field-cert-prune
git log --oneline -1 FETCH_HEAD
# main = 85b5b4e + the test-only harness commit 71a085e (bases 58/62, NICE_TEST_JOIN_SIZE)
[ -d /root/main ] || git worktree add --detach /root/main 71a085e
[ -d /root/prune ] || git worktree add --detach /root/prune c1306b5
for t in main prune; do
  cd /root/$t
  git log --oneline -1
  cargo build --release -p nice_client --features gpu
  cargo test --release -p nice_common --features gpu --no-run 2>&1 | tee /root/ab/testbin_$t.txt
done
echo SETUP_DONE
