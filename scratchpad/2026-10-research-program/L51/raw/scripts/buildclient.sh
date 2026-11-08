#!/bin/bash
# buildclient.sh SRC OUT: nice_client --features gpu of /root/l51/src/SRC -> /root/l51/bin/OUT.
source ~/.cargo/env
SRC=$1; OUT=$2; TGT=${3:-/root/tgtc}
export CARGO_TARGET_DIR=$TGT NICE_BUILD_SHA=test
L=/root/l51/logs; B=/root/l51/bin
cd /root/l51/src/$SRC || exit 1
t0=$(date +%s)
cargo clean --release -p nice_common -p nice_client > /dev/null 2>&1
nice -n ${NICEN:-0} cargo build --release -j ${J:-10} -p nice_client --features gpu > $L/build_$OUT.log 2>&1 || { echo "BUILD FAILED $OUT"; tail -60 $L/build_$OUT.log; exit 1; }
cp $TGT/release/nice_client $B/$OUT
md5sum $B/$OUT
echo "built $OUT in $(( $(date +%s) - t0 )) s src=$SRC"
echo BUILD_DONE $OUT $(date -u +%T)
