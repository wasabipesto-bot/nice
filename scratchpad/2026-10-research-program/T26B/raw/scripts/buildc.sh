#!/bin/bash
# buildc.sh TREE LABEL: release nice_client --features gpu from $W/wt/TREE -> $W/bin/LABEL (target dir $W/target-TREE)
W=/root/t26b; T=$1; L=$2
. /root/.cargo/env
cd $W/wt/$T || exit 1
export CARGO_TARGET_DIR=$W/target-$T
t0=$(date +%s)
cargo build --release -j ${JOBS:-19} -p nice_client --features gpu > $W/out/build_$L.log 2>&1 || { echo "BUILD FAILED $L"; tail -30 $W/out/build_$L.log; exit 1; }
cp $CARGO_TARGET_DIR/release/nice_client $W/bin/$L && echo "built $L ($T $(git -C $W/wt/$T log --oneline -1 | cut -c1-12) +$(git -C $W/wt/$T diff --stat | tail -1)) nice_client gpu in $(( $(date +%s) - t0 )) s md5 $(md5sum $W/bin/$L | cut -c1-8)" | tee -a $W/out/builds.txt
