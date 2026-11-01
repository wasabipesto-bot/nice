#!/bin/bash
# buildclient.sh SRC OUT: nice_client --features gpu of /root/SRC -> /root/cmb/OUT.
source ~/.cargo/env
SRC=$1; OUT=$2
export CARGO_TARGET_DIR=/root/tgt
L=/root/cmb
cd /root/$SRC
t0=$(date +%s)
cargo clean --release -p nice_common -p nice_client > /dev/null 2>&1
cargo build --release -j 9 -p nice_client --features gpu > $L/build_$OUT.log 2>&1 || { echo "BUILD FAILED $OUT"; tail -60 $L/build_$OUT.log; exit 1; }
cp /root/tgt/release/nice_client $L/$OUT
md5sum $L/$OUT
echo "built $OUT in $(( $(date +%s) - t0 )) s src=$SRC"
echo BUILD_DONE $OUT $(date -u +%T)
