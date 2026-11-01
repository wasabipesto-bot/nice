#!/bin/bash
# buildclient.sh SRC OUT: nice_client --features gpu of /root/l31b/src/SRC -> /root/l31b/bin/OUT.
source ~/.cargo/env
SRC=$1; OUT=$2
export CARGO_TARGET_DIR=/root/tgt NICE_BUILD_SHA=test
L=/root/l31b/logs; B=/root/l31b/bin
cd /root/l31b/src/$SRC || exit 1
t0=$(date +%s)
cargo clean --release -p nice_common -p nice_client > /dev/null 2>&1
cargo build --release -j ${J:-10} -p nice_client --features gpu > $L/build_$OUT.log 2>&1 || { echo "BUILD FAILED $OUT"; tail -60 $L/build_$OUT.log; exit 1; }
cp /root/tgt/release/nice_client $B/$OUT
md5sum $B/$OUT
echo "built $OUT in $(( $(date +%s) - t0 )) s src=$SRC"
echo BUILD_DONE $OUT $(date -u +%T)
