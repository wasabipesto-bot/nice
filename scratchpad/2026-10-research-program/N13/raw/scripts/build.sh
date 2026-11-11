#!/bin/sh
# build.sh TREE OUT FEATURES: nice_common test binary (release) of $W/wt/TREE -> $W/bin/OUT, under nice -n 19 -j 8.
W=/tmp/claude-exp-2026-11-11-amd; T=$1; O=$2; F=${3:-gpu,cubecl-spirv}
cd $W/wt/$T || exit 1
export NICE_BUILD_SHA=test
t0=$(date +%s)
cargo clean --release -p nice_common > /dev/null 2>&1
nice -n 19 cargo test --release -j 8 -p nice_common --features $F --no-run > $W/out/build_$O.log 2>&1 || { echo "BUILD FAILED $O"; tail -30 $W/out/build_$O.log; exit 1; }
bin=$(grep -o "$CARGO_TARGET_DIR/release/deps/nice_common-[0-9a-f]*" $W/out/build_$O.log | head -1)
cp $bin $W/bin/$O && echo "built $O ($T, features $F) in $(( $(date +%s) - t0 )) s: $(md5sum $W/bin/$O | cut -c1-8) from $bin"
