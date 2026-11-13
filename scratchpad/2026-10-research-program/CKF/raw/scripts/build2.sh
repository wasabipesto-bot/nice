#!/bin/bash
# build.sh TREE LABEL [FEATURES]: release test binary of nice_common in $W/wt/TREE -> $W/bin/LABEL, target dir $W/target-TREE
W=/root/ckf2; T=$1; L=$2; F=${3:-gpu}
. /root/.cargo/env
cd $W/wt/$T || exit 1
export CARGO_TARGET_DIR=$W/target-$T NICE_BUILD_SHA=test
t0=$(date +%s)
cargo test --release -j ${JOBS:-12} -p nice_common --features "$F" --no-run > $W/out/build_$L.log 2>&1 || { echo "BUILD FAILED $L"; tail -40 $W/out/build_$L.log; exit 1; }
bin=$(grep -o "$CARGO_TARGET_DIR/release/deps/nice_common-[0-9a-f]*" $W/out/build_$L.log | head -1)
cp "$bin" $W/bin/$L && echo "built $L ($T $(git -C $W/wt/$T log --oneline -1 | cut -c1-12) +$(git -C $W/wt/$T diff --stat | tail -1)) features $F in $(( $(date +%s) - t0 )) s md5 $(md5sum $W/bin/$L | cut -c1-8)"
