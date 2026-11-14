#!/bin/bash
# build.sh TREE LABEL FEATURES -> /srv/r26/root/r2bin/LABEL (own target dirs)
T=$1; L=$2; F=$3; . /root/.cargo/env; cd /root/r2/$T || exit 1
export CARGO_TARGET_DIR=/root/r2/target-$T-${F//,/_} NICE_BUILD_SHA=test
mkdir -p /srv/r26/root/r2bin
cargo test --release -j ${J:-24} -p nice_common --features "$F" --no-run > /root/r2/out/build_$L.log 2>&1 || { echo "FAIL $L" >> /root/r2/out/builds.txt; exit 1; }
bin=$(grep -a "Executable unittests src/lib.rs" /root/r2/out/build_$L.log | grep -o "($CARGO_TARGET_DIR[^)]*)" | tr -d "()" | head -1)
cp "$bin" /srv/r26/root/r2bin/$L && echo "built $L $T $F $(md5sum /srv/r26/root/r2bin/$L | cut -c1-8) $(date -u +%T)" >> /root/r2/out/builds.txt
