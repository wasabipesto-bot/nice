#!/bin/bash
# usage: build.sh <tree>
set -e
source /root/.cargo/env
cd /root/$1
{ date -u; git log --oneline -1
  cargo build --release -p nice_client --features gpu
  cargo test --release -p nice_common --features gpu --no-run
  date -u; echo BUILD_DONE; } > /root/logs/build_$1.log 2>&1
