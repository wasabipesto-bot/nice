#!/bin/bash
# build.sh TREE LABEL FEATURES: release test binary of nice_common from /root/w/TREE -> /srv/r26/root/bin/LABEL
# (target dir /root/w/target-TREE-FEATURES); built on the 24.04 host, run inside the 26.04 chroot.
T=$1; L=$2; F=$3; . /root/.cargo/env; cd /root/w/$T || exit 1
export CARGO_TARGET_DIR=/root/w/target-$T-${F//,/_} NICE_BUILD_SHA=test
mkdir -p /srv/r26/root/bin /root/w/out
t0=$(date +%s)
cargo test --release -j 40 -p nice_common --features "$F" --no-run > /root/w/out/build_$L.log 2>&1 || { echo "BUILD FAILED $L"; tail -30 /root/w/out/build_$L.log; exit 1; }
bin=$(grep -a "Executable unittests src/lib.rs" /root/w/out/build_$L.log | grep -o "($CARGO_TARGET_DIR[^)]*)" | tr -d '()' | head -1)
cp "$bin" /srv/r26/root/bin/$L && echo "built $L ($T $(git -C /root/w/$T log --oneline -1 | cut -c1-12) +$(git -C /root/w/$T diff --stat | tail -1)) $F in $(( $(date +%s) - t0 )) s md5 $(md5sum /srv/r26/root/bin/$L | cut -c1-8)" | tee -a /root/w/out/builds.txt
