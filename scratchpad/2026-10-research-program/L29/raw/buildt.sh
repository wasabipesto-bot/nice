#!/bin/bash
# buildt.sh TREE: release test binary only, for /root/src/TREE -> /root/bin/TREE.
T=$1
source /root/.cargo/env
cd /root/src/$T || exit 1
mkdir -p /root/bin/$T
echo "== $(date -u +%T) build $T"
nice -n 5 cargo test --release -p nice_common --features gpu --no-run --message-format=json 2>/root/logs/build_$T.err > /root/logs/build_$T.json
BIN=$(grep -o '"executable":"[^"]*nice_common-[^"]*"' /root/logs/build_$T.json | tail -1 | cut -d'"' -f4)
cp "$BIN" /root/bin/$T/nice_common_test && md5sum /root/bin/$T/nice_common_test
echo "== $(date -u +%T) built $T"
