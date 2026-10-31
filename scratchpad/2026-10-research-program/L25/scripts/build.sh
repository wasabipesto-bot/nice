#!/bin/bash
# Build 472c9a0 (upstream main) with --features gpu: test binary + client.
source /root/.cargo/env
mkdir -p /root/logs
cd /root/nice
{ date -u
  git remote add up https://github.com/wasabipesto/nice.git 2>/dev/null
  git fetch -q up main && git checkout -q 472c9a0 && git log --oneline -1
  cargo --version
  cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "Executable|error|warning: unused|Finished"
  cargo build --release -p nice_client --features gpu 2>&1 | tail -n 2
  date -u; echo BUILD_DONE; } > /root/logs/build.log 2>&1
