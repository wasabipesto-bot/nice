#!/bin/bash
# build.sh <main sha> <fix sha>: one checkout, one target dir; each tree's
# test binary (with the box-local l26 module, labelled) copied to /root/bin.
source /root/.cargo/env
MAIN=$1; FIX=$2
L=/root/logs; mkdir -p $L /root/bin
cd /root/nice
{ date -u
  git fetch -q origin pr/metal-halfshift-prefilter
  for tree in main fix; do
    if [ $tree = main ]; then rev=$MAIN; else rev=$FIX; fi
    git checkout -q -f $rev && git log --oneline -1
    sed "s/L26TREE/L26TREE-$tree/" /root/l26_local.rs >> common/src/cubecl_backend.rs
    s=$(date +%s)
    cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "Executable unittests|^error|^warning|Finished"
    T=$(ls -t target/release/deps/nice_common-* | grep -v '\.d$' | head -1)
    cp $T /root/bin/$tree-test
    echo "$tree: $T -> /root/bin/$tree-test ($(( $(date +%s) - s )) s); labels: main=$(grep -c L26TREE-main /root/bin/$tree-test) fix=$(grep -c L26TREE-fix /root/bin/$tree-test)"
    git checkout -q -- common/src/cubecl_backend.rs
    git status --short
    date -u
  done
  echo BUILD_DONE; } > $L/build.log 2>&1
