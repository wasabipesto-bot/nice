#!/bin/bash
# Build a test binary of a fork ref on the box: setup.sh REF OUTNAME. /root/nice = fork clone.
source ~/.cargo/env
REF=$1; OUT=$2
mkdir -p /root/l30
cd /root/nice
git fetch -q origin "$REF" && git checkout -q --detach FETCH_HEAD && echo "tree: $(git log --oneline -1)"
J=10
t0=$(date +%s)
cargo test --release -j $J -p nice_common --features gpu --no-run > /root/l30/build_$OUT.log 2>&1 || { echo "test build FAILED"; tail -60 /root/l30/build_$OUT.log; exit 1; }
bin=$(grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/l30/build_$OUT.log | head -1)
cp /root/nice/$bin /root/l30/$OUT
md5sum /root/l30/$OUT
echo "built in $(( $(date +%s) - t0 )) s from $bin commit=$(git rev-parse --short HEAD)"
echo SETUP_DONE $OUT $(date -u +%T)
