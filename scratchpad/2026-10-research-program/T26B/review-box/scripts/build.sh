#!/bin/bash
# build.sh TREE LABEL FEATURES
. /root/.cargo/env; T=$1; L=$2; F=$3
cd /root/rv/$T || exit 1
export CARGO_TARGET_DIR=/root/rv/target-$T NICE_BUILD_SHA=test
cargo test --release -j 18 -p nice_common --features "$F" --no-run > /root/rv/out/build_$L.log 2>&1 || { echo FAIL $L; exit 1; }
bin=$(grep "Executable unittests src/lib.rs" /root/rv/out/build_$L.log | grep -o "(/root/rv/target-$T[^)]*)" | tr -d "()" | head -1)
cp "$bin" /root/rv/bin/$L && echo "built $L $T $F $(md5sum /root/rv/bin/$L|cut -c1-8) $(date -u +%T)" >> /root/rv/out/builds.txt
