#!/bin/bash
# on box: upstream main's client with CUDA from the bundle, own target dir; log SHA
set -e
source ~/.cargo/env
cd /root
[ -d nice ] || git clone -q /root/mo/main.bundle nice
cd nice && git checkout -q --detach be9cc923342cadb547fdae388fe6c6f457dd562e
git rev-parse HEAD > /root/mo/main_sha.txt
export CARGO_TARGET_DIR=/root/t/main
cargo build --release -p nice_client --features gpu,cubecl-cuda > /root/mo/build_main.log 2>&1
cp $CARGO_TARGET_DIR/release/nice_client /root/mo/nice-main
md5sum /root/mo/nice-main >> /root/mo/runs.log
echo "$(date -u +%FT%TZ) built main $(cat /root/mo/main_sha.txt)" >> /root/mo/runs.log
