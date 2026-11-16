#!/bin/bash
# on box: build upstream main's client with CUDA (MU260/T28 recipe); log SHA
set -e
[ -f ~/.cargo/env ] || curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source ~/.cargo/env
cd /root
[ -d nice ] || git clone -q https://github.com/wasabipesto/nice.git
cd nice && git fetch -q origin && git checkout -q --detach origin/main
git rev-parse HEAD > /root/g2/main_sha.txt
export CARGO_TARGET_DIR=/root/t/main
cargo build --release -p nice_client --features gpu,cubecl-cuda > /root/g2/build_main.log 2>&1
cp $CARGO_TARGET_DIR/release/nice_client /root/g2/nice-main
echo "$(date -u +%FT%TZ) built $(cat /root/g2/main_sha.txt)" >> /root/g2/runs.log
