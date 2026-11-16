#!/bin/bash
# build.sh TREE LABEL FEATURES: release test binary of nice_common in /root/mu/TREE -> /root/mu/bin/LABEL
# (and /srv/r26/root/bin/LABEL for the chroot); one target dir per tree, /root/mu/target-TREE.
W=/root/mu; T=$1; L=$2; F=$3; . /root/.cargo/env; cd $W/$T || exit 1
export CARGO_TARGET_DIR=$W/target-$T NICE_BUILD_SHA=test
t0=$(date +%s)
mkdir -p /srv/r26/root/bin
cargo test --release -j ${J:-24} -p nice_common --features "$F" --no-run > $W/out/build_$L.log 2>&1 || { echo "BUILD FAILED $L"; tail -30 $W/out/build_$L.log; exit 1; }
bin=$(grep -a "Executable unittests src/lib.rs" $W/out/build_$L.log | grep -o "($CARGO_TARGET_DIR[^)]*)" | tr -d '()' | head -1)
cp "$bin" $W/bin/$L && cp "$bin" /srv/r26/root/bin/$L && echo "built $L ($T $(git -C $W/$T log --oneline -1 | cut -c1-12) dirty:$(git -C $W/$T status --porcelain | wc -l)) features $F in $(( $(date +%s) - t0 )) s md5 $(md5sum $W/bin/$L | cut -c1-8)" | tee -a $W/out/builds.txt
