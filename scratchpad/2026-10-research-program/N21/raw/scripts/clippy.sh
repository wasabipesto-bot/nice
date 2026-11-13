#!/bin/bash
# clippy.sh TREE...: cargo fmt --check and clippy -D warnings (all targets, gpu,cubecl-spirv) per tree, own target dir.
W=/root/n21; . /root/.cargo/env; L=$W/logs/t; mkdir -p $L
for T in "$@"; do
  cd $W/wt/$T; export CARGO_TARGET_DIR=$W/target-clippy-$T
  cargo fmt --all --check > $L/fmt_$T.log 2>&1; echo "fmt $T rc=$?"
  nice -n 10 cargo clippy -j 8 -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings > $L/clippy_$T.log 2>&1; echo "clippy $T rc=$?"
done
echo CLIPPY_DONE $(date -u +%T)
