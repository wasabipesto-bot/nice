#!/bin/bash
# build.sh TREE LABEL KIND [FEATURES]: KIND test = nice_common's release test binary, client = nice_client release.
# Own target dir per tree ($W/target-TREE). Prints time, md5 and the tree's commit.
W=/root/prp; . /root/.cargo/env; export NICE_BUILD_SHA=test
T=$1; L=$2; K=$3; F=${4:-gpu,cubecl-spirv}
cd $W/wt/$T || exit 1
export CARGO_TARGET_DIR=$W/target-$T
t0=$(date +%s)
if [ $K = test ]; then
  nice -n 10 cargo test --release -j ${JOBS:-10} -p nice_common --features "$F" --no-run > $W/out/build_$L.log 2>&1 || { echo "BUILD FAILED $L"; tail -40 $W/out/build_$L.log; exit 1; }
  bin=$(grep -o "$CARGO_TARGET_DIR/release/deps/nice_common-[0-9a-f]*" $W/out/build_$L.log | head -1)
else
  nice -n 10 cargo build --release -j ${JOBS:-10} -p nice_client --features "$F" > $W/out/build_$L.log 2>&1 || { echo "BUILD FAILED $L"; tail -40 $W/out/build_$L.log; exit 1; }
  bin=$CARGO_TARGET_DIR/release/nice_client
fi
cp "$bin" $W/bin/$L && echo "built $L ($T $(git -C $W/wt/$T log --oneline -1 | cut -c1-60), $K, features $F) in $(( $(date +%s) - t0 )) s: md5 $(md5sum $W/bin/$L | cut -c1-8) from $bin"
