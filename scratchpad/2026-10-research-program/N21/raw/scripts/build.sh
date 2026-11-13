#!/bin/bash
# build.sh TREE LABEL [FEATURES]: nice_common's release test binary of $W/wt/TREE -> $W/bin/LABEL; own target dir
# per tree ($W/target-TREE). Prints time, md5, the tree's commit and whether the binary carries the N21 switch string.
W=/root/n21; . /root/.cargo/env; export NICE_BUILD_SHA=test
T=$1; L=$2; F=${3:-gpu,cubecl-spirv}
cd $W/wt/$T || exit 1
export CARGO_TARGET_DIR=$W/target-$T${TSUF:-}
t0=$(date +%s)
nice -n 10 cargo test --release -j ${JOBS:-14} -p nice_common --features "$F" --no-run > $W/out/build_$L.log 2>&1 || { echo "BUILD FAILED $L"; tail -40 $W/out/build_$L.log; exit 1; }
bin=$(grep -o "$CARGO_TARGET_DIR/release/deps/nice_common-[0-9a-f]*" $W/out/build_$L.log | head -1)
cp "$bin" $W/bin/$L && echo "built $L ($T $(git -C $W/wt/$T log --oneline -1 | cut -c1-60), dirty=$(git -C $W/wt/$T status --porcelain | wc -l), features $F) in $(( $(date +%s) - t0 )) s: md5 $(md5sum $W/bin/$L | cut -c1-8) from $bin; N21 strings: $(strings $W/bin/$L | grep -c NICE_EXP_N21)"
