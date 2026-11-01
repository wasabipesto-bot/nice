#!/bin/bash
# build.sh TREE: release test binary + client for /root/src/TREE, copied to /root/bin/TREE.
T=$1
source /root/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
cd /root/src/$T || exit 1
mkdir -p /root/bin/$T
echo "== $(date -u +%T) build $T"
cargo test --release -p nice_common --features gpu --no-run --message-format=json 2>/root/logs/build_$T.err > /root/logs/build_$T.json
BIN=$(grep -o '"executable":"[^"]*nice_common-[^"]*"' /root/logs/build_$T.json | tail -1 | cut -d'"' -f4)
echo "test bin: $BIN"
cp "$BIN" /root/bin/$T/nice_common_test
cargo build --release -p nice_client --features gpu 2>>/root/logs/build_$T.err && cp target/release/nice_client /root/bin/$T/
md5sum /root/bin/$T/* > /root/bin/$T/md5.txt
echo "== $(date -u +%T) built $T"; cat /root/bin/$T/md5.txt
