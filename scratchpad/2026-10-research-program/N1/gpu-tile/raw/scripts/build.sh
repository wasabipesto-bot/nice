#!/bin/bash
# build.sh SRC OUT: nice_common test binary of /root/n1/src/SRC (features gpu = cuda,cubecl,cubecl-cuda) -> /root/n1/bin/OUT.
source ~/.cargo/env
SRC=$1; OUT=$2; FEAT=${3:-gpu}; TGT=${4:-/root/tgt}
export CARGO_TARGET_DIR=$TGT NICE_BUILD_SHA=test
L=/root/n1/logs; B=/root/n1/bin; mkdir -p $L $B
cd /root/n1/src/$SRC || exit 1
t0=$(date +%s)
cargo clean --release -p nice_common > /dev/null 2>&1
nice -n ${NICEN:-0} cargo test --release -j ${J:-10} -p nice_common --features $FEAT --no-run > $L/build_$OUT.log 2>&1 || { echo "BUILD FAILED $OUT"; grep -E '^(error|warning)' -A12 $L/build_$OUT.log | head -150; exit 1; }
bin=$(grep -o "$TGT/release/deps/nice_common-[0-9a-f]*" $L/build_$OUT.log | head -1)
cp $bin $B/$OUT
md5sum $B/$OUT
echo "built $OUT in $(( $(date +%s) - t0 )) s from $bin src=$SRC feat=$FEAT"
echo BUILD_DONE $OUT $(date -u +%T)
