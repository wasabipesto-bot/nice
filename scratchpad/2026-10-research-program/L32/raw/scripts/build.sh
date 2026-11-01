#!/bin/bash
# build.sh SRC OUT [FEATURES]: nice_common test binary of /root/SRC -> /root/pad/OUT. Shared target /root/tgt, one build at a time.
source ~/.cargo/env
SRC=$1; OUT=$2; FEAT=${3:-gpu}
export CARGO_TARGET_DIR=/root/tgt
L=/root/pad
cd /root/$SRC
t0=$(date +%s)
cargo clean --release -p nice_common > /dev/null 2>&1
cargo test --release -j 9 -p nice_common --features $FEAT --no-run > $L/build_$OUT.log 2>&1 || { echo "BUILD FAILED $OUT"; tail -60 $L/build_$OUT.log; exit 1; }
bin=$(grep -o "/root/tgt/release/deps/nice_common-[0-9a-f]*" $L/build_$OUT.log | head -1)
cp $bin $L/$OUT
md5sum $L/$OUT
echo "built $OUT in $(( $(date +%s) - t0 )) s from $bin src=$SRC feat=$FEAT"
echo BUILD_DONE $OUT $(date -u +%T)
