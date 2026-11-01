#!/bin/bash
# build.sh <label> <rev>: check out <rev> in /root/nice, append the box-local
# l28 test module (labelled L28TREE-<label>) to cubecl_detailed_fd.rs, build
# the nice_common test binary and the client (features gpu), copy them to
# /root/bin/<label>-{test,client}, restore the file. One target dir.
source /root/.cargo/env
LABEL=$1; REV=$2
L=/root/logs; mkdir -p $L /root/bin
cd /root/nice
{ date -u
  git fetch -q upstream main
  git fetch -q origin pr/fd-u32-mask 2>/dev/null
  git checkout -q -f $REV && git log --oneline -1
  if [ -n "$PATCH" ]; then eval "$PATCH"; echo "patched: $PATCH"; git diff --stat; git diff | grep "^[-+] "; fi
  sed "s/L28TREE/L28TREE-$LABEL/" /root/l28_local.rs >> common/src/cubecl_detailed_fd.rs
  s=$(date +%s)
  cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "Executable unittests|^error|^warning|Finished" 
  T=$(ls -t target/release/deps/nice_common-* | grep -v '\.d$' | head -1)
  cp $T /root/bin/$LABEL-test
  echo "test: $T -> /root/bin/$LABEL-test ($(( $(date +%s) - s )) s); label hits: $(grep -c L28TREE-$LABEL /root/bin/$LABEL-test)"
  git checkout -q -- common/src/cubecl_detailed_fd.rs
  if [ -n "$PATCH" ]; then eval "$PATCH"; fi
  s=$(date +%s)
  cargo build --release -p nice_client --features gpu 2>&1 | grep -E "^error|^warning|Finished"
  cp target/release/nice_client /root/bin/$LABEL-client
  echo "client -> /root/bin/$LABEL-client ($(( $(date +%s) - s )) s)"
  sha256sum /root/bin/$LABEL-test /root/bin/$LABEL-client
  git checkout -q -- . ; git status --short
  date -u
  echo BUILD_DONE $LABEL; } > $L/build-$LABEL.log 2>&1
