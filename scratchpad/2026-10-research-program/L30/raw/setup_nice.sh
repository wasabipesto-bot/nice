#!/bin/bash
# niced, -j 4 build of a fork ref in /root/nice (the runs use copied binaries in /root/l30)
source ~/.cargo/env
REF=$1; OUT=$2
cd /root/nice
git fetch -q origin "$REF" && git checkout -q --detach FETCH_HEAD && echo "tree: $(git log --oneline -1)"
t0=$(date +%s)
nice -n 19 cargo test --release -j 4 -p nice_common --features gpu --no-run > /root/l30/build_$OUT.log 2>&1 || { echo "test build FAILED"; tail -60 /root/l30/build_$OUT.log; exit 1; }
bin=$(grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/l30/build_$OUT.log | head -1)
cp /root/nice/$bin /root/l30/$OUT
md5sum /root/l30/$OUT
echo "built in $(( $(date +%s) - t0 )) s commit=$(git rev-parse --short HEAD)"
echo SETUP_DONE $OUT $(date -u +%T)
