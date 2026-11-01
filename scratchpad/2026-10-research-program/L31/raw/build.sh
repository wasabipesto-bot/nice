#!/bin/bash
# build.sh TREE: release CUDA test binary for /root/src/TREE -> /root/bin/TREE/nice_common_test
T=$1; FEAT=${2:-gpu}
source /root/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
export CARGO_TARGET_DIR=/root/target_$FEAT
cd /root/src/$T || exit 1
mkdir -p /root/bin/$T
echo "== $(date -u +%T) build $T ($FEAT)"
cargo test --release -p nice_common --features $FEAT --no-run --message-format=json 2>/root/logs/build_${T}_$FEAT.err > /root/logs/build_${T}_$FEAT.json
BIN=$(grep -o '"executable":"[^"]*nice_common-[^"]*"' /root/logs/build_${T}_$FEAT.json | tail -1 | cut -d'"' -f4)
echo "test bin: $BIN"
cp "$BIN" /root/bin/$T/nice_common_$FEAT
md5sum /root/bin/$T/nice_common_$FEAT
echo "== $(date -u +%T) built $T"
