#!/bin/bash
# buildtree.sh SRC KIND: KIND=test -> nice_common test binary /root/sc/SRC; KIND=client -> nice_client --features gpu /root/sc/client_SRC.
# Per-tree target dir /root/tgt_SRC (seeded from main's after main's test build), cargo clean -p nice_common -p nice_client first.
source ~/.cargo/env
SRC=$1; KIND=$2; J=${J:-4}
export CARGO_TARGET_DIR=/root/tgt_$SRC
L=/root/sc
cd /root/$SRC
t0=$(date +%s)
cargo clean --release -p nice_common -p nice_client > /dev/null 2>&1
if [ "$KIND" = test ]; then
  cargo test --release -j $J -p nice_common --features gpu --no-run > $L/build_$SRC.log 2>&1 || { echo "BUILD FAILED $SRC"; tail -60 $L/build_$SRC.log; exit 1; }
  bin=$(grep -o "$CARGO_TARGET_DIR/release/deps/nice_common-[0-9a-f]*" $L/build_$SRC.log | head -1)
  cp $bin $L/$SRC; OUT=$SRC
else
  cargo build --release -j $J -p nice_client --features gpu > $L/build_client_$SRC.log 2>&1 || { echo "BUILD FAILED client $SRC"; tail -60 $L/build_client_$SRC.log; exit 1; }
  cp $CARGO_TARGET_DIR/release/nice_client $L/client_$SRC; OUT=client_$SRC
fi
md5sum $L/$OUT
echo "built $OUT in $(( $(date +%s) - t0 )) s src=$SRC"
echo BUILD_DONE $OUT $(date -u +%T)
