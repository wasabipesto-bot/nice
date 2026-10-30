#!/bin/bash
# build.sh TREE: test binary + client, release, gpu features
source ~/.cargo/env
cd /root/$1
cargo test --release -p nice_common --features gpu --no-run > /root/logs/build_$1_test.log 2>&1
echo "test exit $?" >> /root/logs/build_$1_test.log
cargo build --release -p nice_client --features gpu > /root/logs/build_$1_client.log 2>&1
echo "client exit $?" >> /root/logs/build_$1_client.log
